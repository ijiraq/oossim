"""Ingress/egress of geometric occultations: limb-window diffraction and straight-edge references.

For a body much larger than the Fresnel scale only a few Fresnel scales
around the limb carry diffraction signal.  :func:`limb_profile` evaluates the
exact circular-disk pattern (bandpass and stellar disk included) on that
window only.  :func:`knife_edge_profile` is the same calculation for a straight
edge, i.e. the R -> infinity limit with no dependence on radius, and
:func:`geometric_edge_profile` drops diffraction altogether.

All three are :class:`~occfringe.lightcurve.Profile` objects; the limb profile
is a function of radius r, the straight-edge ones of the signed distance u
from the edge (u > 0 on the lit side).
"""

import numpy as np
from scipy.interpolate import CubicSpline

from .constants import fresnel_scale
from .fresnel import knife_edge_intensity
from .lightcurve import Profile, radial_profile
from .star import StellarDisk, average_linear, visible_fraction_straight_edge


def _scales(z, band):
    return float(fresnel_scale(band.lam_min, z)), float(fresnel_scale(band.lam_max, z))


def limb_profile(R, z, band, disk=None, window_F=12.0, step_F=1.0 / 20.0):
    """Radial profile of a circular body within ``window_F`` Fresnel scales (longest wavelength) of the limb.

    Inside the window the shadow is taken as black and outside as unit flux.
    For R smaller than the window the profile starts at the shadow centre.
    """
    disk = StellarDisk.point() if disk is None else disk
    f_min, f_max = _scales(z, band)
    half = window_F * f_max + disk.radius
    lo = max(0.0, R - half)
    r_out = np.arange(lo, R + half + step_F * f_min, step_F * f_min)
    return radial_profile(R, z, band, disk, r_out=r_out, left=0.0, right=1.0)


def knife_edge_profile(z, band, disk=None, window_F=12.0, step_F=1.0 / 20.0):
    """Straight-edge diffraction profile K(u) with the same bandpass and stellar disk as :func:`limb_profile`."""
    disk = StellarDisk.point() if disk is None else disk
    f_min, f_max = _scales(z, band)
    half = window_F * f_max + disk.radius
    pad = disk.radius + 2.0 * f_min
    du = f_min / 40.0
    u_base = np.arange(-half - pad, half + pad + du, du)
    i_base = np.zeros_like(u_base)
    for lam, w in zip(band.lam, band.w):
        i_base += w * knife_edge_intensity(u_base, float(fresnel_scale(lam, z)))
    u_out = np.arange(-half - step_F * f_min, half + 2.0 * step_F * f_min, step_F * f_min)
    spline = CubicSpline(u_base, i_base)
    if disk.n == 1 and disk.radius == 0.0:
        i_out = spline(u_out)
    else:
        i_out = average_linear(u_base, i_base, u_out, disk, interpolator=spline)
    return Profile(u_out, i_out, left=0.0, right=1.0)


def geometric_edge_profile(star_radius, limb_darkening=0.0, n=801):
    """Visible stellar flux behind a straight geometric edge (no diffraction) versus distance u."""
    if star_radius <= 0.0:
        return Profile(np.array([-1e-9, 1e-9]), np.array([0.0, 1.0]), left=0.0, right=1.0)
    u = np.linspace(-star_radius, star_radius, n)
    return Profile(u, visible_fraction_straight_edge(u, star_radius, limb_darkening), left=0.0, right=1.0)


def curvature_signal(R, z, band, disk=None, window_F=12.0):
    """Largest |I_circle(R + u) - K(u)| within the window, outside the central half of the shadow.

    Measures how much the limb pattern differs from a straight edge; the
    central Arago spot of small bodies is excluded (u > -R/2).
    """
    limb = limb_profile(R, z, band, disk, window_F)
    knife = knife_edge_profile(z, band, disk, window_F)
    u = limb.x - R
    sel = u > -0.5 * R
    return float(np.max(np.abs(limb.I[sel] - knife(u[sel]))))
