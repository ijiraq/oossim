"""Non-circular occulters: outlines, strip tilings, and band/star-averaged chord profiles.

An outline is a union of closed polygons in the occulter plane, with x along
the shadow trajectory.  Its diffraction pattern is the Fresnel sum over
horizontal strips (one rectangle per scanline interval), which converges to the
exact pattern as the strip height shrinks (see ``validation/tiling_vs_circle.py``).
"""

from dataclasses import dataclass, field

import numpy as np

from .constants import fresnel_scale
from .fresnel import circle_obstacle_intensity, obstacle_intensity
from .lightcurve import Profile
from .star import StellarDisk


@dataclass
class Outline:
    """Union of closed polygons (each an (n, 2) array of vertices, metres)."""

    polygons: list = field(default_factory=list)
    name: str = ""

    # -- constructors ------------------------------------------------------
    @classmethod
    def circle(cls, R, n=4096, name="circle"):
        return cls.radial(lambda th: np.full_like(th, R), n=n, name=name)

    @classmethod
    def radial(cls, r_of_theta, n=4096, name=""):
        th = np.linspace(0.0, 2.0 * np.pi, n, endpoint=False)
        r = r_of_theta(th)
        return cls([np.column_stack([r * np.cos(th), r * np.sin(th)])], name=name)

    @classmethod
    def ellipse(cls, a, b, angle=0.0, center=(0.0, 0.0), n=4096, name="ellipse"):
        th = np.linspace(0.0, 2.0 * np.pi, n, endpoint=False)
        xy = np.column_stack([a * np.cos(th), b * np.sin(th)])
        return cls([_rotate(xy, angle) + np.asarray(center)], name=name)

    @classmethod
    def rough_circle(cls, R, rms, slope=2.0, k_min=2, k_max=256, seed=0, n=8192, name="rough"):
        """Circle with random radial topography: Fourier modes k_min..k_max with amplitude ~ k^-slope/2.

        ``rms`` is the rms radial deviation [m]; slope = 2 gives a Brownian
        (fractal dimension 1.5) limb, larger values a smoother one.
        """
        rng = np.random.default_rng(seed)
        k = np.arange(k_min, k_max + 1)
        amp = k ** (-slope / 2.0) * rng.standard_normal(k.size)
        phase = rng.uniform(0.0, 2.0 * np.pi, k.size)
        th = np.linspace(0.0, 2.0 * np.pi, n, endpoint=False)
        dr = (amp[:, None] * np.cos(k[:, None] * th[None, :] + phase[:, None])).sum(axis=0)
        dr *= rms / np.sqrt(np.mean(dr ** 2))
        return cls.radial(lambda t: np.interp(t, th, R + dr, period=2.0 * np.pi), n=n, name=name)

    @classmethod
    def contact_binary(cls, lobe1=(11.0, 10.0), lobe2=(7.0, 6.5), overlap=1.5, angle=0.0, n=4096,
                       name="contact binary"):
        """Two touching elliptical lobes (semi-axes in arbitrary units), e.g. Arrokoth's projected outline.

        The lobes lie on the x axis with their outlines overlapping by
        ``overlap`` before the pair is rotated by ``angle`` [rad] and centred on
        its area centroid.  Scale with :meth:`scaled_to_radius`.
        """
        (a1, b1), (a2, b2) = lobe1, lobe2
        sep = a1 + a2 - overlap
        out = cls([cls.ellipse(a1, b1, n=n).polygons[0],
                   cls.ellipse(a2, b2, center=(sep, 0.0), n=n).polygons[0]], name=name)
        out = out.rotated(angle)
        return out.shifted(-out.centroid())

    # -- geometry ----------------------------------------------------------
    def rotated(self, angle):
        return Outline([_rotate(p, angle) for p in self.polygons], name=self.name)

    def shifted(self, d):
        return Outline([p + np.asarray(d) for p in self.polygons], name=self.name)

    def scaled(self, f):
        return Outline([p * f for p in self.polygons], name=self.name)

    @property
    def bounds(self):
        allp = np.vstack(self.polygons)
        return allp.min(axis=0), allp.max(axis=0)

    def intervals(self, y):
        """Merged x intervals of the union at height ``y``: array (m, 2)."""
        segs = []
        for p in self.polygons:
            x1, y1 = p[:, 0], p[:, 1]
            x2, y2 = np.roll(x1, -1), np.roll(y1, -1)
            hit = (y1 <= y) != (y2 <= y)
            xs = np.sort(x1[hit] + (y - y1[hit]) * (x2[hit] - x1[hit]) / (y2[hit] - y1[hit]))
            segs += list(xs.reshape(-1, 2))
        if not segs:
            return np.empty((0, 2))
        segs = sorted(segs, key=lambda s: s[0])
        merged = [list(segs[0])]
        for a, b in segs[1:]:
            if a <= merged[-1][1]:
                merged[-1][1] = max(merged[-1][1], b)
            else:
                merged.append([a, b])
        return np.array(merged)

    def area(self, dy=None):
        lo, hi = self.bounds
        dy = (hi[1] - lo[1]) / 4000.0 if dy is None else dy
        ys = np.arange(lo[1] + 0.5 * dy, hi[1], dy)
        return float(sum(np.sum(iv[:, 1] - iv[:, 0]) for iv in map(self.intervals, ys)) * dy)

    def equivalent_radius(self):
        return float(np.sqrt(self.area() / np.pi))

    def centroid(self, dy=None):
        lo, hi = self.bounds
        dy = (hi[1] - lo[1]) / 4000.0 if dy is None else dy
        ys = np.arange(lo[1] + 0.5 * dy, hi[1], dy)
        a = mx = my = 0.0
        for y in ys:
            iv = self.intervals(y)
            w = iv[:, 1] - iv[:, 0]
            a += w.sum()
            mx += np.sum(w * 0.5 * (iv[:, 0] + iv[:, 1]))
            my += w.sum() * y
        return np.array([mx / a, my / a])

    def scaled_to_radius(self, R_eq):
        return self.scaled(R_eq / self.equivalent_radius())

    def strips(self, thickness):
        """Rectangles (xc, yc, hx, hy): one per scanline interval, strips of height ``thickness``."""
        lo, hi = self.bounds
        n = int(np.ceil((hi[1] - lo[1]) / thickness))
        edges = lo[1] + (hi[1] - lo[1]) * np.arange(n + 1) / n
        h = 0.5 * (edges[1] - edges[0])
        rects = []
        for yc in 0.5 * (edges[:-1] + edges[1:]):
            for a, b in self.intervals(yc):
                rects.append((0.5 * (a + b), yc, 0.5 * (b - a), h))
        return np.array(rects).reshape(-1, 4)


def _rotate(xy, angle):
    c, s = np.cos(angle), np.sin(angle)
    return xy @ np.array([[c, s], [-s, c]])


def chord_profile(point_intensity, x, b, z, band, disk=None):
    """Band- and star-averaged intensity along the chord y = ``b`` at positions ``x``.

    ``point_intensity(X, Y, F)`` returns the monochromatic point-source
    intensity on the broadcast grid (X, Y).  ``x`` must be uniform and fine
    enough to resolve every fringe (it is also the interpolation grid for the
    stellar-disk average).
    """
    disk = StellarDisk.point() if disk is None else disk
    x = np.asarray(x, dtype=float)
    rows, row_of = np.unique(np.round(disk.y, 6), return_inverse=True)
    pad = disk.radius
    dx = x[1] - x[0]
    npad = int(np.ceil(pad / dx)) + 1
    xg = x[0] + dx * np.arange(-npad, x.size + npad)
    grid = np.zeros((rows.size, xg.size))
    for lam, w in zip(band.lam, band.w):
        grid += w * point_intensity(xg[None, :], b + rows[:, None], float(fresnel_scale(lam, z)))
    out = np.zeros(x.size)
    for k in range(disk.w.size):
        out += disk.w[k] * np.interp(x + disk.x[k], xg, grid[row_of[k]])
    return out


def outline_profile(outline, b, z, band, disk=None, window_F=10.0, thickness_F=1.0 / 40.0, step_F=1.0 / 40.0,
                    rects=None):
    """Chord profile I(x) at y = ``b`` behind ``outline`` from a strip tiling.

    Covers the chord from ``window_F`` Fresnel scales (longest wavelength)
    before the first edge to after the last.  Strip height and x step are
    ``thickness_F`` and ``step_F`` times the shortest-wavelength Fresnel scale;
    after band and stellar-disk averaging the F/40 defaults agree with the
    exact disk to ~1e-4.
    """
    disk = StellarDisk.point() if disk is None else disk
    F_min = float(fresnel_scale(band.lam_min, z))
    F_max = float(fresnel_scale(band.lam_max, z))
    if rects is None:
        rects = outline.strips(thickness_F * F_min)
    step = step_F * F_min
    ivs = np.vstack([outline.intervals(b + dy) for dy in (-disk.radius, 0.0, disk.radius)] or [np.empty((0, 2))])
    if ivs.size == 0:
        ivs = np.array([[0.0, 0.0]])
    x0 = ivs.min() - window_F * F_max - disk.radius
    x1 = ivs.max() + window_F * F_max + disk.radius
    x = np.arange(x0, x1 + step, step)
    I = chord_profile(lambda X, Y, F: obstacle_intensity(rects, X, Y, F), x, b, z, band, disk)
    return Profile(x, I, left=1.0, right=1.0)


def circle_chord_profile(R, b, x, z, band, disk=None):
    """Exact-disk counterpart of :func:`outline_profile` on the same chord grid (coherent limbs)."""
    return Profile(x, chord_profile(lambda X, Y, F: circle_obstacle_intensity(R, np.hypot(X, Y), F), x, b, z,
                                    band, disk), left=1.0, right=1.0)
