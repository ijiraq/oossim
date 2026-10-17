"""Physical constants (SI) and Fresnel-scale helpers."""

import numpy as np

AU = 1.495978707e11          # m
LEGACY_AU = 1.5e11           # m, value hard-coded as z = AU*1.5e11 in fresnelT.c
PC = 3.0856775814913673e16   # m
R_SUN = 6.957e8              # m
H = 6.62607015e-34           # J s
C = 2.99792458e8             # m / s
K_B = 1.380649e-23           # J / K
MAS = np.pi / (180.0 * 3600.0 * 1000.0)   # rad
UAS = MAS / 1000.0                          # rad


def fresnel_scale(lam, z):
    """Fresnel scale F = sqrt(lam z / 2) [m] for wavelength ``lam`` [m] and occulter distance ``z`` [m].

    This is the ``fsu`` of the OOSSIM code: the dimensionless Fresnel-integral
    argument is (distance in the occulter plane) / F.
    """
    return np.sqrt(np.asarray(lam) * z / 2.0)


def distance_m(au, legacy=False):
    """Convert an occulter distance in AU to metres (``legacy`` uses 1.5e11 m/AU like fresnelT)."""
    return au * (LEGACY_AU if legacy else AU)


def projected_star_radius(z, angular_radius=None, star_radius=None, star_distance=None):
    """Stellar radius projected into the occulter plane [m].

    Give either ``angular_radius`` [rad] or ``star_radius`` [m] with ``star_distance`` [m].
    """
    if angular_radius is None:
        if star_radius is None or star_distance is None:
            raise ValueError("need angular_radius or (star_radius, star_distance)")
        angular_radius = star_radius / star_distance
    return angular_radius * z
