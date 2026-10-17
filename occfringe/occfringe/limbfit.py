"""Fast light-curve models for non-spherical occulters: osculating circles at the two limbs.

Near each limb only a few Fresnel scales of the outline matter, so the
pattern there is well approximated by that of the limb's osculating circle
(the circle with the local radius of curvature and centre of curvature).  A
:class:`LimbLibrary` holds band- and star-averaged limb profiles P(q, u) of
circles with curvature q = 1/rho (q = 0 is the straight edge), u = r - rho;
:func:`limb_flux` evaluates a chord through any outline described by the
position, curvature radius and centre of curvature at its two chord crossings.

:func:`ellipse_limbs` supplies those for an ellipse, giving a 5-parameter
shape model (area-equivalent radius, axis ratio, orientation, centre) that
can be fitted to a single chord.  ``validation/limbfit_vs_tiling.py`` checks
it against strip-tiled outlines.
"""

from dataclasses import dataclass

import numpy as np
from scipy.interpolate import CubicSpline
from scipy.optimize import brentq, least_squares

from .constants import fresnel_scale
from .edge import knife_edge_profile
from .lightcurve import exposure_average, radial_profile
from .star import StellarDisk


class LimbLibrary:
    """Limb profiles P(q, u) for curvatures 0 <= q <= q_max, cubic in q."""

    def __init__(self, z, band, disk=None, rho_min=5e3, n_nodes=25, window_F=10.0):
        disk = StellarDisk.point() if disk is None else disk
        self.F_min = float(fresnel_scale(band.lam_min, z))
        self.F_max = float(fresnel_scale(band.lam_max, z))
        self.F_mid = float(fresnel_scale(band.mean, z))
        half = window_F * self.F_max + disk.radius
        self.u = np.arange(-half, half + self.F_min / 20.0, self.F_min / 20.0)
        self.q_max = 1.0 / rho_min
        q = np.linspace(0.0, self.q_max, n_nodes)
        prof = [knife_edge_profile(z, band, disk, window_F)(self.u)]
        prof += [radial_profile(1.0 / qj, z, band, disk, r_out=np.abs(1.0 / qj + self.u)).I for qj in q[1:]]
        self.q = q
        self.spline = CubicSpline(q, np.array(prof), axis=0)
        self.q_dense = np.linspace(0.0, self.q_max, 16 * (n_nodes - 1) + 1)
        self.grid = self.spline(self.q_dense)

    def profile(self, q):
        return self.spline(np.clip(q, 0.0, self.q_max))

    def __call__(self, q, u):
        p = self.profile(q)
        return np.interp(u, self.u, p, left=p[0], right=1.0)

    def eval_pointwise(self, q, u):
        """P(q_i, u_i) for arrays of curvatures and distances (bilinear on the dense grid)."""
        q = np.clip(np.asarray(q, dtype=float), 0.0, self.q_max)
        u = np.asarray(u, dtype=float)
        fq = q / self.q_max * (self.q_dense.size - 1)
        iq = np.minimum(fq.astype(int), self.q_dense.size - 2)
        wq = fq - iq
        du = self.u[1] - self.u[0]
        fu = np.clip((u - self.u[0]) / du, 0.0, self.u.size - 1.0)
        iu = np.minimum(fu.astype(int), self.u.size - 2)
        wu = fu - iu
        g = self.grid
        val = ((1 - wq) * ((1 - wu) * g[iq, iu] + wu * g[iq, iu + 1])
               + wq * ((1 - wu) * g[iq + 1, iu] + wu * g[iq + 1, iu + 1]))
        return np.where(u > self.u[-1], 1.0, val)


@dataclass
class Limb:
    x: float          # chord crossing [m]
    cx: float         # centre of curvature [m]
    cy: float
    rho: float        # radius of curvature [m]


def ellipse_limbs(R_eq, axis_ratio, theta, xc, yc):
    """Ingress/egress :class:`Limb` of an ellipse crossed by the chord y = 0 (None if it misses).

    Semi-axes a = R_eq sqrt(axis_ratio), b = R_eq / sqrt(axis_ratio); ``theta``
    rotates the a axis from the chord direction; (xc, yc) is the centre.
    """
    a = R_eq * np.sqrt(axis_ratio)
    b = R_eq / np.sqrt(axis_ratio)
    st, ct = np.sin(theta), np.cos(theta)
    A, B = a * st, b * ct
    M = np.hypot(A, B)
    if abs(yc) >= M:
        return None
    base = np.arctan2(B, A)
    d = np.arccos(-yc / M)
    limbs = []
    for phi in (base + d, base - d):
        ex, ey = a * np.cos(phi), b * np.sin(phi)
        px = xc + ex * ct - ey * st
        py = yc + ex * st + ey * ct
        nbx, nby = b * np.cos(phi), a * np.sin(phi)
        nn = np.hypot(nbx, nby)
        nx, ny = (nbx * ct - nby * st) / nn, (nbx * st + nby * ct) / nn
        rho = (a * a * np.sin(phi) ** 2 + b * b * np.cos(phi) ** 2) ** 1.5 / (a * b)
        limbs.append(Limb(px, px - rho * nx, py - rho * ny, rho))
    return sorted(limbs, key=lambda L: L.x)


def ellipse_nearest(R_eq, axis_ratio, theta, xc, yc, x, n_iter=6):
    """Signed distance (positive outside) from chord points (x, 0) to an ellipse, and the radius of
    curvature at the nearest boundary point."""
    a = R_eq * np.sqrt(axis_ratio)
    b = R_eq / np.sqrt(axis_ratio)
    st, ct = np.sin(theta), np.cos(theta)
    dx, dy = np.asarray(x, dtype=float) - xc, -yc
    px, py = dx * ct + dy * st, -dx * st + dy * ct          # body frame
    grid = np.linspace(-np.pi, np.pi, 32, endpoint=False)
    d2 = (px[:, None] - a * np.cos(grid)[None, :]) ** 2 + (py - b * np.sin(grid))[None, :] ** 2 \
        if np.ndim(py) == 0 else (px[:, None] - a * np.cos(grid)) ** 2 + (py[:, None] - b * np.sin(grid)) ** 2
    phi = grid[np.argmin(d2, axis=1)]
    for _ in range(n_iter):
        s, c = np.sin(phi), np.cos(phi)
        f = (a * a - b * b) * s * c - px * a * s + py * b * c
        fp = (a * a - b * b) * (c * c - s * s) - px * a * c - py * b * s
        phi = phi - f / np.where(np.abs(fp) > 1e-12 * a * a, fp, 1e-12 * a * a)
    s, c = np.sin(phi), np.cos(phi)
    d = np.hypot(px - a * c, py - b * s)
    inside = (px / a) ** 2 + (py / b) ** 2 < 1.0
    rho = (a * a * s * s + b * b * c * c) ** 1.5 / (a * b)
    return np.where(inside, -d, d), rho


def ellipse_flux(lib, R_eq, axis_ratio, theta, xc, yc, x):
    """Chord intensity behind an ellipse using the osculating circle at each point's nearest limb point."""
    x = np.asarray(x, dtype=float)
    out = np.ones_like(x)
    reach = R_eq * np.sqrt(max(axis_ratio, 1.0 / axis_ratio)) + lib.u[-1]
    near = np.abs(x - xc) < reach
    if near.any():
        d, rho = ellipse_nearest(R_eq, axis_ratio, theta, xc, yc, x[near])
        out[near] = lib.eval_pointwise(1.0 / rho, np.maximum(d, -0.5 * rho))
    return out


def ellipse_chord(R_eq, axis_ratio, theta, yc):
    lim = ellipse_limbs(R_eq, axis_ratio, theta, 0.0, yc)
    return 0.0 if lim is None else lim[1].x - lim[0].x


def limb_flux(lib, limbs, x):
    """Point-in-time intensity along the chord at positions ``x`` (1 everywhere if ``limbs`` is None).

    Deeper than half the curvature radius inside a limb the osculating circle
    (and its Arago spot) no longer represents the body, so the profile is held
    at its value there.
    """
    x = np.asarray(x, dtype=float)
    if limbs is None:
        return np.ones_like(x)
    l1, l2 = limbs
    out = np.empty_like(x)
    sel = x < 0.5 * (l1.x + l2.x)
    for L, s in ((l1, sel), (l2, ~sel)):
        u = np.hypot(x[s] - L.cx, L.cy) - L.rho
        out[s] = lib(1.0 / L.rho, np.maximum(u, -0.5 * L.rho))
    return out


class ChordData:
    """Simultaneous light curves in one or more bands sharing the same sample intervals."""

    def __init__(self, libs, t_a, t_b, speed, sigma, data=None, n_sub=4):
        self.libs = libs
        self.t_a, self.t_b = t_a, t_b
        self.speed = speed
        self.sigma = sigma            # list of arrays, one per band
        self.data = data
        self.n_sub = n_sub

    def model(self, shape, f0):
        """Exposure-averaged flux per band; ``shape`` = (R_eq, axis_ratio, theta, xc, yc) or None (no event)."""
        if shape is None:
            return [f * np.ones(self.t_a.size) for f in f0]
        if not hasattr(self, "_x_sub"):
            w = np.linspace(0.0, 1.0, self.n_sub + 1)
            self._x_sub = self.speed * (self.t_a[:, None] + (self.t_b - self.t_a)[:, None] * w[None, :])
            self._w_sub = np.full(self.n_sub + 1, 1.0 / self.n_sub)
            self._w_sub[[0, -1]] *= 0.5
        R_eq, e, th, xc, yc = shape
        x = self._x_sub.ravel()
        reach = R_eq * np.sqrt(max(e, 1.0 / e)) + max(lib.u[-1] for lib in self.libs)
        near = np.abs(x - xc) < reach
        d, rho = ellipse_nearest(R_eq, e, th, xc, yc, x[near]) if near.any() else (None, None)
        out = []
        for lib, f in zip(self.libs, f0):
            flux = np.ones_like(x)
            if near.any():
                flux[near] = lib.eval_pointwise(1.0 / rho, np.maximum(d, -0.5 * rho))
            out.append(f * (flux.reshape(self._x_sub.shape) @ self._w_sub))
        return out


# ---------------------------------------------------------------------------
# Fitting
# ---------------------------------------------------------------------------

ELLIPSE_PARAMS = ("R_eq", "ln_axis_ratio", "theta", "yc", "xc")


def _limbs(model, p):
    """Ellipse parameters (R_eq, axis_ratio, theta, xc, yc) for a parameter vector."""
    if model == "sphere":
        R, yc, xc = p[:3]
        return (R, 1.0, 0.0, xc, yc)
    R, lne, th, yc, xc = p[:5]
    return (R, np.exp(lne), th, xc, yc)


def n_shape(model):
    return 3 if model == "sphere" else 5


def residuals(cd, model, p, data):
    ns = n_shape(model)
    limbs = _limbs(model, p)
    mods = cd.model(limbs, p[ns:])
    return np.concatenate([(d - m) / s for d, m, s in zip(data, mods, cd.sigma)])


def jacobian(cd, model, p, data=None, central=True):
    """sigma-normalised model derivatives d m / d p (the negative of the residual Jacobian)."""
    data = cd.data if data is None else data
    steps = _steps(cd, model, p)
    r0 = None if central else residuals(cd, model, p, data)
    cols = []
    for k, h in enumerate(steps):
        pp = p.copy()
        pp[k] += h
        if central:
            pm = p.copy()
            pm[k] -= h
            cols.append((residuals(cd, model, pm, data) - residuals(cd, model, pp, data)) / (2 * h))
        else:
            cols.append((r0 - residuals(cd, model, pp, data)) / h)
    return np.column_stack(cols)


def _steps(cd, model, p):
    F = cd.libs[0].F_min
    if model == "sphere":
        s = [0.05 * F, 0.05 * F, 0.05 * F]
    else:
        s = [0.05 * F, 0.01, 0.01, 0.05 * F, 0.05 * F]
    return np.array(s + [1e-3] * len(cd.libs))


def sigma_R(cd, model, p, data=None):
    J = jacobian(cd, model, p, data)
    try:
        cov = np.linalg.inv(J.T @ J)
    except np.linalg.LinAlgError:
        return np.inf
    return float(np.sqrt(cov[0, 0])) if cov[0, 0] > 0 else np.inf


def _starts(cd, model, data, L_obs, x_mid, R_hint):
    """Starting points consistent with the observed chord length."""
    nb = len(cd.libs)
    starts = []
    if model == "sphere":
        for R in (R_hint, 0.75 * R_hint, 1.35 * R_hint, max(0.5 * L_obs * 1.02, 0.55 * R_hint)):
            if R > 0.5 * L_obs:
                starts.append([R, np.sqrt(R * R - 0.25 * L_obs ** 2), x_mid] + [1.0] * nb)
        return starts
    for e in (1.05, 1.4, 2.0, 2.7):
        for th in np.radians(np.arange(0.0, 180.0, 22.5)):
            for R in (0.8 * R_hint, R_hint, 1.25 * R_hint):
                M = np.hypot(R * np.sqrt(e) * np.sin(th), R / np.sqrt(e) * np.cos(th))
                if ellipse_chord(R, e, th, 0.0) < L_obs:
                    continue
                yc = brentq(lambda y: ellipse_chord(R, e, th, y) - L_obs, 0.0, M * (1 - 1e-9))
                for sgn in (1.0, -1.0):
                    starts.append([R, np.log(e), th, sgn * yc, x_mid] + [1.0] * nb)
    return starts


def observed_chord(cd, data):
    """Half-flux chord length and midpoint [m]: longest run below 0.5 in the smoothed, band-weighted data."""
    t = 0.5 * (cd.t_a + cd.t_b)
    w = [1.0 / np.median(s) ** 2 for s in cd.sigma]
    f = sum(wi * d for wi, d in zip(w, data)) / sum(w)
    snr = 1.0 / np.sqrt(1.0 / sum(w))
    n = int(np.clip(np.ceil((4.0 / snr) ** 2), 1, 25))
    if n > 1:
        f = np.convolve(f, np.ones(n) / n, mode="same")
    low = np.concatenate([[False], f < 0.5, [False]])
    edges = np.flatnonzero(np.diff(low.astype(int)))
    if edges.size == 0:
        return 0.0, 0.0
    runs = edges.reshape(-1, 2)
    i1, i2 = runs[np.argmax(runs[:, 1] - runs[:, 0])]
    t1, t2 = t[i1], t[i2 - 1]
    return cd.speed * (t2 - t1), 0.5 * cd.speed * (t1 + t2)


def fit(cd, model, data=None, R_hint=None, e_max=3.0, n_refine=4, R_bounds=(0.0, np.inf), central=True):
    """Least-squares fit; returns (params, chi2, sigma_R_eq).

    Scans starting points consistent with the observed chord, then refines
    the ``n_refine`` best.  Axis ratio is bounded to [1, ``e_max``] and the
    (area-equivalent) radius to ``R_bounds`` (e.g. from H and an albedo range).
    """
    data = cd.data if data is None else data
    L_obs, x_mid = observed_chord(cd, data)
    R_hint = 0.55 * L_obs if R_hint is None else R_hint
    starts = [s for s in _starts(cd, model, data, L_obs, x_mid, R_hint) if R_bounds[0] < s[0] < R_bounds[1]]
    if not starts:
        R0 = float(np.sqrt(max(R_bounds[0], 1.0) * min(R_bounds[1], 1e9)))
        starts = [s for s in _starts(cd, model, data, min(L_obs, 1.9 * R0), x_mid, R0)
                  if R_bounds[0] < s[0] < R_bounds[1]]
    if not starts:
        R0 = float(np.sqrt(max(R_bounds[0], 1.0) * min(R_bounds[1], 1e9))) if np.isfinite(R_bounds[1]) \
            else max(0.55 * L_obs, 1e3)
        starts = [[R0, 0.0, x_mid] + [1.0] * len(cd.libs)] if model == "sphere" else \
            [[R0, np.log(1.05), 0.0, 0.0, x_mid] + [1.0] * len(cd.libs)]
    chi = [np.sum(residuals(cd, model, np.array(s), data) ** 2) for s in starts]
    order = np.argsort(chi)[:n_refine]
    nb = len(cd.libs)
    if model == "sphere":
        lo = [max(0.3 * L_obs, R_bounds[0]), 0.0, -np.inf]
        hi = [R_bounds[1], np.inf, np.inf]
    else:
        lo = [max(0.2 * L_obs, R_bounds[0]), 0.0, -np.inf, -np.inf, -np.inf]
        hi = [R_bounds[1], np.log(e_max), np.inf, np.inf, np.inf]
    lo[0] = min(lo[0], 0.9 * hi[0])
    lo, hi = np.array(lo + [0.0] * nb), np.array(hi + [np.inf] * nb)
    best = None
    for i in order:
        x0 = np.clip(np.array(starts[i], dtype=float), lo + 1e-9, hi - 1e-9)
        res = least_squares(lambda p: residuals(cd, model, p, data), x0,
                            jac=lambda p: -jacobian(cd, model, p, data, central=central), bounds=(lo, hi),
                            x_scale=_steps(cd, model, x0) * 20, method="trf", max_nfev=150)
        c2 = float(np.sum(res.fun ** 2))
        if best is None or c2 < best[1]:
            best = (res.x, c2)
    p, c2 = best
    return p, c2, sigma_R(cd, model, p, data)
