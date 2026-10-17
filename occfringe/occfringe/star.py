"""Finite stellar disk: point-source decomposition and averaging of diffraction patterns."""

from dataclasses import dataclass

import numpy as np

_LEGACY_PI = 3.141592654


@dataclass
class StellarDisk:
    """Point sources ``(x, y)`` [m, occulter plane] with weights ``w`` summing to 1."""

    x: np.ndarray
    y: np.ndarray
    w: np.ndarray
    radius: float

    @classmethod
    def point(cls):
        return cls(np.zeros(1), np.zeros(1), np.ones(1), 0.0)

    @classmethod
    def uniform_grid(cls, radius, spacing, limb_darkening=0.0):
        """Cell-centred square grid inside the disk.

        ``limb_darkening`` is the linear coefficient u in I(mu) = 1 - u (1 - mu);
        0 gives the uniform disk assumed by fresnelT.c.
        """
        if radius <= 0.0:
            return cls.point()
        n_side = max(1, int(np.ceil(2.0 * radius / spacing)))
        cell = 2.0 * radius / n_side
        c = -radius + cell * (np.arange(n_side) + 0.5)
        xx, yy = np.meshgrid(c, c, indexing="ij")
        rr2 = xx ** 2 + yy ** 2
        inside = rr2 <= radius ** 2
        if not inside.any():
            return cls.point()
        mu = np.sqrt(np.clip(1.0 - rr2[inside] / radius ** 2, 0.0, 1.0))
        w = 1.0 - limb_darkening * (1.0 - mu)
        return cls(xx[inside], yy[inside], w / w.sum(), radius)

    @classmethod
    def for_fresnel_scale(cls, radius, F, points_per_F=10, max_side=160, limb_darkening=0.0):
        """Grid fine enough to resolve fringes of scale ``F`` (capped at ``max_side`` points across)."""
        spacing = max(F / points_per_F, 2.0 * radius / max_side)
        return cls.uniform_grid(radius, spacing, limb_darkening)

    @classmethod
    def legacy(cls, radius, n_ptsrc):
        """Point-source grid of fresnelT.c (``boxesPerSide = int(sqrt(4 Nptsrc / pi))``)."""
        per_side = int(np.sqrt(n_ptsrc * 4.0 / _LEGACY_PI))
        box = 2.0 * radius / per_side
        rx = radius - box / 2.0
        pts = []
        xp = -rx
        while xp <= radius:
            yp = -rx
            while yp <= radius:
                if xp * xp + yp * yp <= radius * radius:
                    pts.append((xp, yp))
                yp += box
            xp += box
        pts = np.array(pts)
        return cls(pts[:, 0], pts[:, 1], np.full(len(pts), 1.0 / len(pts)), radius)

    @property
    def n(self):
        return self.w.size


def average_radial(r_grid, intensity, rho, disk, legacy_interp=False, interpolator=None, chunk_elems=4_000_000):
    """Stellar-disk average of a circularly symmetric pattern I(r).

    Returns sum_s w_s I(|(rho, 0) - (x_s, y_s)|).  ``r_grid`` must be
    increasing and cover every distance needed.  ``interpolator`` (a callable
    of r) replaces linear interpolation of ``intensity`` when given.
    ``legacy_interp`` reproduces the fresnelT.c resampling I[i] + f (I[i] - I[i+1])
    on a uniform grid starting at 0 (the sign of the correction is reversed there).
    """
    rho = np.asarray(rho, dtype=float)
    out = np.zeros(rho.size)
    step = max(1, chunk_elems // max(rho.size, 1))
    if legacy_interp:
        dr = r_grid[1] - r_grid[0]
    for s0 in range(0, disk.n, step):
        xs = disk.x[s0:s0 + step, None]
        ys = disk.y[s0:s0 + step, None]
        ws = disk.w[s0:s0 + step, None]
        dist = np.hypot(xs - rho[None, :], ys)
        if legacy_interp:
            i = (dist / dr).astype(np.int64)
            frac = (dist - i * dr) / dr
            val = intensity[i] + frac * (intensity[i] - intensity[i + 1])
        elif interpolator is not None:
            val = interpolator(dist)
        else:
            val = np.interp(dist, r_grid, intensity)
        out += np.sum(ws * val, axis=0)
    return out


def average_linear(u_grid, intensity, u, disk, interpolator=None):
    """Stellar-disk average of a pattern that varies only along one axis, I(u)."""
    xs, inv = np.unique(disk.x, return_inverse=True)
    ws = np.bincount(inv, disk.w)
    u = np.asarray(u, dtype=float)
    shifted = u[None, :] - xs[:, None]
    vals = interpolator(shifted) if interpolator is not None else np.interp(shifted, u_grid, intensity)
    return np.sum(ws[:, None] * vals, axis=0)


def visible_fraction_straight_edge(u, radius, limb_darkening=0.0, n=2001):
    """Fraction of stellar flux on the lit side of a straight edge at distance ``u`` from the disk centre.

    ``u > 0`` means the centre is on the lit side.  No diffraction.
    """
    u = np.asarray(u, dtype=float)
    if radius <= 0.0:
        return (u > 0).astype(float) + 0.5 * (u == 0)
    if limb_darkening == 0.0:
        q = np.clip(u / radius, -1.0, 1.0)
        return 0.5 + (np.arcsin(q) + q * np.sqrt(1.0 - q * q)) / np.pi
    # strip brightness of a limb-darkened disk, integrated numerically
    xg = np.linspace(-radius, radius, n)
    yy = np.linspace(0.0, radius, n)
    X, Y = np.meshgrid(xg, yy, indexing="ij")
    rr2 = (X ** 2 + Y ** 2) / radius ** 2
    mu = np.sqrt(np.clip(1.0 - rr2, 0.0, 1.0))
    brightness = np.where(rr2 <= 1.0, 1.0 - limb_darkening * (1.0 - mu), 0.0)
    strip = np.trapezoid(brightness, yy, axis=1)
    cum = np.concatenate([[0.0], np.cumsum(0.5 * (strip[1:] + strip[:-1]) * np.diff(xg))])
    cum /= cum[-1]
    # lit side is x < u in the star frame
    return np.interp(u, xg, cum, left=0.0, right=1.0)
