"""Fresnel diffraction by opaque occulters built from rectangles.

The field behind a rectangular aperture follows Goodman, *Introduction to
Fourier Optics*, pp. 70-74, exactly as in ``cdiffracSim/fresnelT.c``.  With
the Fresnel scale F = sqrt(lam z / 2), an aperture spanning
[x_l, x_r] x [y_l, y_r] gives, at observation point (x, y),

    U = (1 / 2i) [dC_x + i dS_x] [dC_y + i dS_y],
    dC_x = C((x_r - x)/F) - C((x_l - x)/F),   (same for S and for y)

so that an unobstructed plane wave has U = 1.  Fields of disjoint rectangles
add, and Babinet's principle gives the field behind the complementary opaque
occulter as 1 - U.

Rectangles are stored as an (N, 4) array of ``(xc, yc, hx, hy)``: centre and
half widths.
"""

import math

import numpy as np
from scipy.special import fresnel as _scipy_fresnel

LEGACY_TABLE_N = 40000
LEGACY_TABLE_STEP = 1.0e-3

_legacy_tables = None


def fresnel_cs(x):
    """Fresnel integrals C(x) = int_0^x cos(pi t^2/2) dt and S(x) (same with sin)."""
    s, c = _scipy_fresnel(x)
    return c, s


def _get_legacy_tables():
    """C and S tables built exactly as in fresnelT.c (trapezoid, step 0.001, C[40000] = 0.5)."""
    global _legacy_tables
    if _legacy_tables is None:
        j = np.arange(LEGACY_TABLE_N)
        a2 = j.astype(float) * j / 1e6
        ic = np.cos(0.5 * np.pi * a2)
        is_ = np.sin(0.5 * np.pi * a2)
        tc = np.empty(LEGACY_TABLE_N)
        ts = np.empty(LEGACY_TABLE_N)
        # j = 0 uses "previous integrand" 0, so the table starts at 0.0005 rather than 0.
        tc[0] = 0.5 * ic[0] * LEGACY_TABLE_STEP
        ts[0] = 0.5 * is_[0] * LEGACY_TABLE_STEP
        tc[1:] = 0.5 * (ic[:-1] + ic[1:]) * LEGACY_TABLE_STEP
        ts[1:] = 0.5 * (is_[:-1] + is_[1:]) * LEGACY_TABLE_STEP
        C = np.append(np.cumsum(tc), 0.5)
        S = np.append(np.cumsum(ts), 0.5)
        _legacy_tables = (C, S)
    return _legacy_tables


def fresnel_cs_legacy(x):
    """Table lookup used by fresnelT.c: truncated index int(|1000 x|), clamped at x = 40."""
    C, S = _get_legacy_tables()
    x = np.asarray(x, dtype=float)
    idx = np.minimum(np.abs(x * 1000.0).astype(np.int64), LEGACY_TABLE_N)
    sign = np.where(x > 0.0, 1.0, -1.0)
    return sign * C[idx], sign * S[idx]


# --------------------------------------------------------------------------
# Tilings of an elliptical occulter
# --------------------------------------------------------------------------

def legacy_ellipse_boxes(aa, aspect_ratio=1.0, order=5):
    """Hierarchical rectangle tiling of an ellipse, reproducing fresnelT.c.

    ``aa`` is the semi-axis along the trajectory (x), ``aa / aspect_ratio`` the
    perpendicular one.  fresnelT.c only works for ``aspect_ratio >= 1``.
    """
    if aspect_ratio < 1.0:
        raise ValueError("legacy tiling requires aspect_ratio >= 1 (fresnelT.c takes sqrt of a negative otherwise)")
    pihalf = 3.141592654 / 2.0
    smaj = aa
    smin = aa / aspect_ratio
    k_val = math.sqrt(smaj * smaj - smin * smin) / smaj
    pow2order = int(math.pow(2, order))
    seg_length = (1.0 / math.pow(2, order)) * (1.0 / smaj) * pihalf * math.sqrt((smaj * smaj + smin * smin) / 2.0)
    dtheta = pihalf / 200.0

    coords = []  # [order, xur, yur, xll, yll]
    nsegment = 1
    arclength = 0.0
    theta = 0.0
    while theta < pihalf:
        arclength += math.sqrt(1.0 - k_val * k_val * math.sin(theta) * math.sin(theta)) * dtheta
        if (arclength - nsegment * seg_length) > 0.0 and nsegment < pow2order:
            st, ct = math.sin(theta), math.cos(theta)
            r = math.sqrt((smaj * smaj * smin * smin) / ((smaj * smaj * st * st) + (smin * smin * ct * ct)))
            ord_ = 1
            for ordtmp in range(1, order + 1):
                ord_ = ordtmp
                mod = int(pow2order / math.pow(2, ord_))
                if nsegment % mod == 0:
                    break
            coords.append([ord_, r * ct, r * st, -r * ct, -r * st])
            nsegment += 1
        theta += dtheta

    for ci in coords:
        for cj in coords:
            if cj[0] >= ci[0]:
                continue
            if ci[3] < cj[1] < ci[1]:
                ci[3] = cj[1]
            if ci[4] < cj[2] < ci[2]:
                ci[4] = cj[2]

    boxes = []
    for _, xur, yur, xll, yll in coords:
        x = (xur + xll) / 2.0
        y = (yur + yll) / 2.0
        dx = (xur - xll) / 2.0
        dy = (yur - yll) / 2.0
        boxes.append((x, y, dx, dy))
        if xll > 0 and yll > 0:
            boxes += [(-x, -y, dx, dy), (x, -y, dx, dy), (-x, y, dx, dy)]
        elif xll > 0 and yll < 0:
            boxes.append((-x, y, dx, dy))
        elif xll < 0 and yll > 0:
            boxes.append((x, -y, dx, dy))
    return np.array(boxes, dtype=float).reshape(-1, 4)


def _strip_edges(b, thickness, fine_extent, growth):
    """Non-negative strip boundaries 0 = y_0 < ... < y_n = b.

    Spacing is ``thickness`` for y < fine_extent, then grows geometrically by
    a factor (1 + growth) per strip, never shrinking below ``thickness``.
    """
    edges = [0.0]
    y = 0.0
    while y < b:
        dy = thickness if y < fine_extent else max(thickness, growth * y)
        y = min(y + dy, b)
        if b - y < 0.25 * dy:
            y = b
        edges.append(y)
    return np.array(edges)


def ellipse_strips(a, b=None, thickness=None, fine_extent=None, growth=0.0):
    """Tile an ellipse (semi-axes ``a`` along x, ``b`` along y) with horizontal strips.

    Each strip spans the full chord, so both limbs near y = 0, where a
    trajectory along x enters and leaves the shadow, are represented by
    nearly vertical steps.  The strip half length preserves the strip's area.

    ``thickness``: strip height near y = 0.
    ``fine_extent``: |y| out to which strips keep that height; beyond it their
    height grows as ``growth * |y|`` (``growth = 0`` keeps them uniform).
    """
    b = a if b is None else b
    if thickness is None:
        thickness = b / 64.0
    if fine_extent is None:
        fine_extent = b
    pos = _strip_edges(b, thickness, fine_extent, growth)
    edges = np.concatenate([-pos[:0:-1], pos])
    y1, y2 = edges[:-1], edges[1:]

    def g(y):
        y = np.clip(y, -b, b)
        return 0.5 * (y * np.sqrt(np.maximum(b * b - y * y, 0.0)) + b * b * np.arcsin(y / b))

    half_len = (a / b) * (g(y2) - g(y1)) / (y2 - y1)
    keep = half_len > 0
    return np.column_stack([np.zeros(keep.sum()), 0.5 * (y1 + y2)[keep], half_len[keep], 0.5 * (y2 - y1)[keep]])


# --------------------------------------------------------------------------
# Field evaluation
# --------------------------------------------------------------------------

def aperture_field(rects, x, y, F, legacy_table=False, chunk_elems=4_000_000):
    """Complex field U(x, y) transmitted by the union of disjoint rectangles.

    ``x`` and ``y`` broadcast to a common shape; ``F`` is the Fresnel scale [m].
    Work is grouped by unique y so the y factors are computed once per
    rectangle, and x factors once per unique x edge.
    """
    fcs = fresnel_cs_legacy if legacy_table else fresnel_cs
    rects = np.asarray(rects, dtype=float).reshape(-1, 4)
    xc, yc, hx, hy = rects.T
    x, y = np.broadcast_arrays(np.asarray(x, dtype=float), np.asarray(y, dtype=float))
    shape = x.shape
    x = x.ravel()
    y = y.ravel()
    out = np.empty(x.size, dtype=complex)
    n = rects.shape[0]

    ux, inv = np.unique(np.concatenate([xc - hx, xc + hx]), return_inverse=True)
    inv_l, inv_r = inv[:n], inv[n:]
    nu = ux.size
    step = max(1, chunk_elems // max(nu, 1))

    yu, yinv = np.unique(y, return_inverse=True)
    for k, yv in enumerate(yu):
        sel = np.nonzero(yinv == k)[0]
        c2, s2 = fcs((yc + hy - yv) / F)
        c1, s1 = fcs((yc - hy - yv) / F)
        ce, se = c2 - c1, s2 - s1
        # Ur = 0.5 sum(dCx Se + dSx Ce), Ui = 0.5 sum(dSx Se - dCx Ce); fold per-rect
        # y factors onto the unique x edges (+ for right edges, - for left edges).
        wse = np.bincount(inv_r, se, nu) - np.bincount(inv_l, se, nu)
        wce = np.bincount(inv_r, ce, nu) - np.bincount(inv_l, ce, nu)
        for i0 in range(0, sel.size, step):
            idx = sel[i0:i0 + step]
            cx, sx = fcs((ux[:, None] - x[None, idx]) / F)
            ur = 0.5 * (wse @ cx + wce @ sx)
            ui = 0.5 * (wse @ sx - wce @ cx)
            out[idx] = ur + 1j * ui
    return out.reshape(shape)


def obstacle_field(rects, x, y, F, legacy_table=False):
    """Field behind the opaque occulter made of ``rects`` (Babinet: 1 - U)."""
    return 1.0 - aperture_field(rects, x, y, F, legacy_table=legacy_table)


def obstacle_intensity(rects, x, y, F, legacy_table=False):
    """Monochromatic point-source intensity |1 - U|^2 behind the opaque occulter."""
    u = aperture_field(rects, x, y, F, legacy_table=legacy_table)
    return (1.0 - u.real) ** 2 + u.imag ** 2


# --------------------------------------------------------------------------
# Exact circular occulter
# --------------------------------------------------------------------------
#
# For a circular aperture of radius R the Fresnel field at radius r is
#
#   U_ap(r) = (2a/i) e^{i a r^2} int_0^R e^{i a rho^2} J0(2 a r rho) rho d rho,   a = pi / (2 F^2),
#
# (same phase convention as the rectangle sum), and the occulter field is
# U = 1 - U_ap.  Using int_0^inf e^{i a rho^2} J0(b rho) rho d rho = (i/2a) e^{-i b^2/4a},
#
#   U(r) = -i a [ T1 + T2 ],
#   T1 = int_R^inf e^{i a (rho + r)^2} H1e(2 a r rho) rho d rho,
#   T2 = int_R^inf e^{i a (rho - r)^2} H2e(2 a r rho) rho d rho,
#
# with exponentially scaled Hankel functions H1e(z) = H0^(1)(z) e^{-iz},
# H2e(z) = H0^(2)(z) e^{iz}.  Both tails are integrated along steepest-descent
# contours where the integrand decays without oscillating, so the cost does
# not grow with R/F.  Small bodies use direct quadrature of U_ap.

_GL8 = np.polynomial.legendre.leggauss(8)
_GL16 = np.polynomial.legendre.leggauss(16)
_GH = np.polynomial.hermite.hermgauss(48)
_GLAG = np.polynomial.laguerre.laggauss(48)


def _panel_nodes(edges, rule=_GL8):
    x, w = rule
    lo, hi = edges[:-1, None], edges[1:, None]
    half = 0.5 * (hi - lo)
    return (0.5 * (hi + lo) + half * x[None, :]).ravel(), (half * w[None, :]).ravel()


def _circle_direct(R, r, a):
    """Direct Gauss-Legendre quadrature of U_ap; cost grows as R (R + r) / F^2."""
    from scipy.special import j0
    out = np.empty(r.size, dtype=complex)
    order = np.argsort(r)
    for i0 in range(0, r.size, 64):
        idx = order[i0:i0 + 64]
        rmax = r[idx].max()
        n_pan = int(np.ceil(a * (R + rmax) * R / 1.5)) + 4    # <= ~3 rad of phase per 8-node panel
        rho, w = _panel_nodes(np.linspace(0.0, R, n_pan + 1))
        rr = r[idx, None]
        integ = np.exp(1j * a * rho[None, :] ** 2) * j0(2.0 * a * rr * rho[None, :]) * rho[None, :]
        uap = (2.0 * a / 1j) * np.exp(1j * a * r[idx] ** 2) * (integ @ w)
        out[idx] = 1.0 - uap
    return out


def _circle_inner(R, r, a):
    """Contour rho^2 = R^2 + i tau for r well inside the shadow (r < R/2)."""
    from scipy.special import jv
    y, wy = _GLAG
    f = 1.0 - r / R
    x = y[None, :] / f[:, None]
    z = 2.0 * a * r[:, None] * np.sqrt(R * R + 1j * x / a)
    vals = jv(0, z) * np.exp(y[None, :] - x) / f[:, None]
    return np.exp(1j * a * (r * r + R * R)) * (vals @ wy)


def _descent_path(d, a, n_panels=14):
    """Nodes on w(t) = sqrt(d^2 + t^2) + i t, t >= 0, where e^{i a w^2} = e^{i a d^2} e^{-2 a t sqrt(d^2+t^2)}."""
    d = np.abs(d)[:, None]
    tmax = np.sqrt(0.5 * (-d * d + np.sqrt(d ** 4 + (40.0 / (2.0 * a)) ** 2 * 4.0)))  # decay e^-40
    frac = np.concatenate([[0.0], np.geomspace(2.0 ** -(n_panels - 1), 1.0, n_panels)])
    x, w = _GL8
    lo, hi = frac[:-1], frac[1:]
    u = (0.5 * (hi + lo)[:, None] + 0.5 * (hi - lo)[:, None] * x[None, :]).ravel()
    wu = (0.5 * (hi - lo)[:, None] * w[None, :]).ravel()
    t = tmax * u[None, :]
    wt = tmax * wu[None, :]
    s = np.sqrt(d * d + t * t)
    wpath = s + 1j * t
    dw = t / np.where(s > 0, s, 1.0) + 1j
    decay = np.exp(-2.0 * a * t * s)
    return wpath, dw * decay * wt


# Hankel asymptotic coefficients a_k(0) = prod_{j<=k} (-(2j-1)^2) / (k! 8^k)
_HANKEL_AK = np.array([1.0, -0.125, 0.0703125, -0.0732421875, 0.112152099609375,
                       -0.2271080017089844, 0.5725014209747314, -1.7277275025844574])
_HANKEL_ASYMP_MIN = 60.0


def _hankel0e(z, kind):
    """Exponentially scaled Hankel function H0^(kind)(z) e^{-/+ i z}; asymptotic series for |z| >= 60."""
    from scipy.special import hankel1e, hankel2e
    z = np.asarray(z, dtype=complex)
    big = np.abs(z) >= _HANKEL_ASYMP_MIN
    out = np.empty_like(z)
    if big.any():
        zb = z[big]
        ik = 1j if kind == 1 else -1j
        inv = ik / zb
        series = np.full(zb.shape, _HANKEL_AK[-1], dtype=complex)
        for coef in _HANKEL_AK[-2::-1]:
            series = series * inv + coef
        out[big] = np.sqrt(2.0 / (np.pi * zb)) * np.exp(-0.25j * np.pi if kind == 1 else 0.25j * np.pi) * series
    if (~big).any():
        out[~big] = (hankel1e if kind == 1 else hankel2e)(0, z[~big])
    return out


def _circle_descent(R, r, a, split=False):
    """Steepest-descent evaluation of T1 + T2 (needs r >~ 4 F so contours avoid rho <= 0).

    T1 carries the edge wave from the far limb (phase a (R + r)^2); T2 the
    near-limb edge wave plus, outside the shadow, the geometric wave.  With
    ``split`` the two fields are returned separately as (far, near).
    """
    hankel1e = lambda _, z: _hankel0e(z, 1)   # noqa: E731
    hankel2e = lambda _, z: _hankel0e(z, 2)   # noqa: E731
    # T1: rho + r = w, endpoint w = R + r
    d1 = R + r
    w1, k1 = _descent_path(d1, a)
    rho1 = w1 - r[:, None]
    t1 = np.exp(1j * a * d1 ** 2) * np.sum(hankel1e(0, 2.0 * a * r[:, None] * rho1) * rho1 * k1, axis=1)

    # T2: rho - r = w, endpoint w = d = R - r
    d = R - r
    w2, k2 = _descent_path(d, a)
    sgn = np.where(d >= 0.0, 1.0, -1.0)[:, None]
    rho2 = r[:, None] + sgn * w2
    t2 = np.exp(1j * a * d ** 2) * np.sum(hankel2e(0, 2.0 * a * r[:, None] * rho2) * rho2 * sgn * k2, axis=1)

    beyond = d < 0.0
    if beyond.any():
        # outside the geometric shadow the path from R descends into the opposite valley;
        # return through the saddle at rho = r along rho = r + e^{i pi/4} s.
        y, wy = _GH
        s = y / np.sqrt(a)
        e = np.exp(0.25j * np.pi)
        rr = r[beyond, None]
        rho_s = rr + e * s[None, :]
        t2[beyond] += e / np.sqrt(a) * np.sum(hankel2e(0, 2.0 * a * rr * rho_s) * rho_s * wy[None, :], axis=1)
    if split:
        return -1j * a * t1, -1j * a * t2
    return -1j * a * (t1 + t2)


def circle_obstacle_field(R, r, F, direct_max_RF=12.0):
    """Exact Fresnel field behind an opaque disk of radius ``R`` at distances ``r`` from the shadow centre.

    Point source, single wavelength.  Bodies with R <= ``direct_max_RF`` F use
    direct quadrature; larger bodies use steepest-descent contours for r >= 5 F
    and an inner contour closer to the centre.
    """
    r = np.abs(np.asarray(r, dtype=float))
    shape = r.shape
    r = r.ravel()
    a = np.pi / (2.0 * F * F)
    out = np.empty(r.size, dtype=complex)
    if R <= direct_max_RF * F:
        out[:] = _circle_direct(R, r, a)
    else:
        inner = r < 5.0 * F
        if inner.any():
            out[inner] = _circle_inner(R, r[inner], a)
        if (~inner).any():
            out[~inner] = _circle_descent(R, r[~inner], a)
    return out.reshape(shape)


def circle_obstacle_intensity(R, r, F, coherent=True, direct_max_RF=12.0):
    """|U|^2 behind an opaque disk (see :func:`circle_obstacle_field`).

    With ``coherent=False`` and R > ``direct_max_RF`` F, points more than 5 F
    from the centre return |U_near|^2 + |U_far|^2: the interference between
    the near- and far-limb edge waves, which oscillates in r with period
    F^2 / R, is replaced by its average.  Any bandpass, stellar disk, or
    exposure wider than that period averages it away in reality.
    """
    if coherent or R <= direct_max_RF * F:
        u = circle_obstacle_field(R, r, F, direct_max_RF=direct_max_RF)
        return u.real ** 2 + u.imag ** 2
    r = np.abs(np.asarray(r, dtype=float))
    shape = r.shape
    r = r.ravel()
    out = np.empty(r.size)
    inner = r < 5.0 * F
    if inner.any():
        out[inner] = np.abs(circle_obstacle_field(R, r[inner], F, direct_max_RF=direct_max_RF)) ** 2
    if (~inner).any():
        far, near = _circle_descent(R, r[~inner], np.pi / (2.0 * F * F), split=True)
        out[~inner] = np.abs(far) ** 2 + np.abs(near) ** 2
    return out.reshape(shape)


def knife_edge_intensity(u, F):
    """Straight-edge intensity at distance ``u`` into the lit side (u < 0 is behind the edge)."""
    c, s = fresnel_cs(np.asarray(u, dtype=float) / F)
    return 0.5 * ((c + 0.5) ** 2 + (s + 0.5) ** 2)
