"""Band- and star-averaged shadow profiles, chords, and exposure-averaged light curves."""

from dataclasses import dataclass

import numpy as np
from scipy.interpolate import CubicSpline

from .constants import fresnel_scale
from .fresnel import circle_obstacle_intensity, obstacle_intensity
from .star import StellarDisk, average_radial


@dataclass
class Profile:
    """Intensity sampled on an increasing coordinate ``x`` with constant values beyond each end."""

    x: np.ndarray
    I: np.ndarray
    left: float = 0.0
    right: float = 1.0

    def __call__(self, q):
        return np.interp(q, self.x, self.I, left=self.left, right=self.right)


def band_intensity_circle(R, r, z, band, coherent=True):
    """Band-weighted point-source intensity behind a disk of radius ``R`` [m] at radii ``r``.

    ``coherent=False`` averages the near/far-limb interference term (see
    :func:`~occfringe.fresnel.circle_obstacle_intensity`).
    """
    out = np.zeros(np.shape(r))
    for lam, w in zip(band.lam, band.w):
        out += w * circle_obstacle_intensity(R, r, float(fresnel_scale(lam, z)), coherent=coherent)
    return out


def band_intensity_rects(rects, x, y, z, band):
    """Band-weighted point-source intensity behind an occulter built from rectangles."""
    out = np.zeros(np.broadcast(np.asarray(x), np.asarray(y)).shape)
    for lam, w in zip(band.lam, band.w):
        out += w * obstacle_intensity(rects, x, y, float(fresnel_scale(lam, z)))
    return out


def radial_profile(R, z, band, disk=None, r_out=None, step_F=1.0 / 20.0, left=0.0, right=1.0, coherent=None):
    """Radial shadow profile of a circular body: exact diffraction, bandpass, then stellar-disk average.

    ``R`` body radius [m], ``z`` distance [m], ``band`` a :class:`Bandpass`,
    ``disk`` a :class:`StellarDisk` (point source if None), ``r_out`` output
    radii [m].  The monochromatic patterns are computed on a grid of spacing
    ``step_F`` x (Fresnel scale at the shortest wavelength) and cubic-spline
    interpolated for the disk average.

    ``coherent=None`` keeps the near/far-limb interference only when the grid
    resolves its period F^2 / R (with 4 samples); otherwise it is averaged.
    """
    disk = StellarDisk.point() if disk is None else disk
    F_min = float(fresnel_scale(band.lam_min, z))
    if r_out is None:
        r_out = np.arange(0.0, R + 20.0 * F_min, F_min / 20.0)
    r_out = np.asarray(r_out, dtype=float)
    pad = disk.radius + 2.0 * F_min
    lo = max(0.0, r_out.min() - pad)
    hi = r_out.max() + pad
    dr = step_F * F_min
    r_base = np.arange(lo, hi + dr, dr)
    if coherent is None:
        coherent = F_min ** 2 / R >= 4.0 * dr
    i_base = band_intensity_circle(R, r_base, z, band, coherent=coherent)
    if lo == 0.0:
        # I(r) is even in r; mirror so the spline has the right slope at the centre.
        spline = CubicSpline(np.concatenate([-r_base[:0:-1], r_base]), np.concatenate([i_base[:0:-1], i_base]))
    else:
        spline = CubicSpline(r_base, i_base)
    if disk.n == 1 and disk.radius == 0.0:
        i_out = spline(r_out)
    else:
        i_out = average_radial(r_base, i_base, r_out, disk, interpolator=spline)
    return Profile(r_out, i_out, left=left, right=right)


def chord_radius(t, t0, speed, impact):
    """Distance from the shadow centre along a straight chord: sqrt((v (t - t0))^2 + b^2)."""
    return np.hypot(speed * (np.asarray(t, dtype=float) - t0), impact)


def exposure_average(model, t_start, t_stop, n_sub):
    """Mean of ``model(t)`` over each interval [t_start, t_stop] by the trapezoid rule with ``n_sub`` sub-steps.

    This is the finite-exposure integration of ``makeKernel()`` in
    libdetection.c, applied in time rather than shadow-plane distance.
    """
    t_start = np.asarray(t_start, dtype=float)
    t_stop = np.asarray(t_stop, dtype=float)
    f = np.linspace(0.0, 1.0, n_sub + 1)
    tt = t_start[:, None] + (t_stop - t_start)[:, None] * f[None, :]
    vals = np.asarray(model(tt.ravel())).reshape(tt.shape)
    w = np.full(n_sub + 1, 1.0 / n_sub)
    w[0] = w[-1] = 0.5 / n_sub
    return vals @ w


def n_substeps(speed, dt, F, per_F=10, n_min=4):
    """Sub-steps per exposure so the shadow moves less than F / ``per_F`` per step."""
    return max(n_min, int(np.ceil(speed * dt * per_F / F)))


def chord_lightcurve(profile, t_start, t_stop, t0, speed, impact, n_sub):
    """Exposure-averaged relative flux of a star crossing the radial ``profile`` along a chord."""
    return exposure_average(lambda t: profile(chord_radius(t, t0, speed, impact)), t_start, t_stop, n_sub)
