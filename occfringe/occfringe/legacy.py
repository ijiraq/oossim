"""Python port of the OOSSIM ``fresnelT`` pipeline and its file formats.

``fresnelT(aa, T, params, legacy=True)`` reproduces ``cdiffracSim/fresnelT.c``
including its numerical quirks, so results can be compared line by line:

* Fresnel integrals from a truncated trapezoid table, clamped at argument 40;
* ``planck()`` evaluates exp(x - 1) instead of exp(x) - 1 (Wien's law after
  normalisation);
* stellar-disk resampling uses I[i] + f (I[i] - I[i+1]) instead of
  I[i] + f (I[i+1] - I[i]);
* z = AU * 1.5e11 m.

``legacy=False`` keeps the same geometry and sampling but uses exact Fresnel
integrals, correct interpolation, the IAU AU, and photon-weighted Planck
spectra.
"""

from dataclasses import dataclass, field, asdict

import numpy as np

from .bandpass import Bandpass
from .constants import AU, distance_m, fresnel_scale
from .fresnel import aperture_field, legacy_ellipse_boxes
from .star import StellarDisk, average_radial

PARAM_NAMES = ("lambLo", "lambHi", "nLambda", "maxX00", "x00Step", "RStarProj",
               "Nptsrc", "AU", "offset", "aspectRatio", "order")
_INT_PARAMS = {"nLambda", "Nptsrc", "order"}


@dataclass
class FresnelParams:
    """The 11 values of a fresnelBox/fresnelT parameter file (SI units, AU for distance)."""

    lambLo: float = 4.0e-7
    lambHi: float = 7.0e-7
    nLambda: int = 1
    maxX00: float = 20000.0
    x00Step: float = 50.0
    RStarProj: float = 100.0
    Nptsrc: int = 1
    AU: float = 100.0
    offset: float = 0.0
    aspectRatio: float = 1.0
    order: int = 5

    def to_line(self):
        return " ".join(repr(v) if isinstance(v, float) else str(v) for v in asdict(self).values())


def read_params(path):
    """Read a fresnelT parameter file (last non-comment line wins, as in the C code)."""
    values = None
    with open(path) as fh:
        for line in fh:
            if line.startswith("#") or len(line.strip()) < 1:
                continue
            values = line.split()
    if values is None or len(values) < 11:
        raise ValueError(f"{path}: expected 11 parameters")
    kw = {name: (int(float(v)) if name in _INT_PARAMS else float(v)) for name, v in zip(PARAM_NAMES, values)}
    return FresnelParams(**kw)


def write_params(path, params):
    # fresnelT.c reads lines into an 80-byte buffer, so every line must stay shorter than that.
    line = params.to_line()
    if len(line) >= 79:
        raise ValueError("parameter line too long for fresnelT.c; use fewer digits")
    with open(path, "w") as fh:
        fh.write("# lLo lHi nL maxX step Rstar Npt AU off AR ord\n")
        fh.write(line + "\n")


def _perl_round(value, unit):
    intpart = int(value / unit)
    if value / unit - intpart > 0.5:
        intpart += 1
    return intpart * unit


def write_fres_params(lam_lo, lam_hi, star_radius, star_distance, au, offset=0.0, aspect_ratio=1.0, order=5):
    """Sampling rules of ``writeFresParams.pl`` given the star's radius and distance [m].

    The Perl script looks these up from an MK type and V magnitude; here they
    are passed directly.  Step is ~F/20 at the mid-band wavelength, the profile
    extends 200 steps, and the disk gets ~100 point sources per F^2.
    """
    lam = 0.5 * (lam_lo + lam_hi)
    fs = float(fresnel_scale(lam, au * AU))
    step = _perl_round(fs / 20.0, 1)
    rstar = int(star_radius / star_distance * au * AU)
    nstar = int(100.0 * np.pi * rstar ** 2 / fs ** 2)
    return FresnelParams(lam_lo, lam_hi, int(round((lam_hi - lam_lo) * 1.0e8)), 200.0 * step, step,
                         float(rstar), nstar, float(au), offset, aspect_ratio, order)


@dataclass
class FresnelPattern:
    """A radial (or along-track) diffraction profile as written to ``fres-AAAAA_DDDDD`` files."""

    x: np.ndarray
    Ihole: np.ndarray
    Idisk: np.ndarray
    header: dict = field(default_factory=dict)


QUIRKS = ("table", "planck", "interp", "au")


def fresnelT(aa, T, params, legacy=True, **quirks):
    """Diffraction profile of an elliptical KBO of semi-axis ``aa`` [m] seen against a star of temperature ``T``.

    Returns a :class:`FresnelPattern` with the profile along x at the
    parameter-file offset, averaged over the uniform stellar disk.

    ``legacy`` switches all fresnelT.c quirks on or off; individual ones can be
    overridden with keywords ``table``, ``planck``, ``interp``, ``au``.  With
    ``planck=False`` the spectrum is photon-weighted lam B_lam(T) with
    trapezoid wavelength weights.
    """
    unknown = set(quirks) - set(QUIRKS)
    if unknown:
        raise TypeError(f"unknown quirks {unknown}")
    q = {name: quirks.get(name, legacy) for name in QUIRKS}
    p = params
    max_x = p.maxX00 + p.RStarProj
    n_x = int(max_x / p.x00Step + 2)
    x = p.x00Step * np.arange(n_x)

    boxes = legacy_ellipse_boxes(aa, p.aspectRatio, p.order)
    disk = StellarDisk.legacy(p.RStarProj, p.Nptsrc)
    if q["planck"]:
        band = Bandpass.legacy(p.lambLo, p.lambHi, p.nLambda, T)
    else:
        band = Bandpass.tophat(p.lambLo, p.lambHi, p.nLambda, T, weighting="photon")
    z = distance_m(p.AU, legacy=q["au"])

    ihole = np.zeros(n_x)
    idisk = np.zeros(n_x)
    for lam, w in zip(band.lam, band.w):
        u = aperture_field(boxes, x, p.offset, float(fresnel_scale(lam, z)), legacy_table=q["table"])
        i0 = u.real ** 2 + u.imag ** 2
        ihole += w * i0
        idisk += w * (1.0 - 2.0 * u.real + i0)

    n_out = int((max_x - p.RStarProj) / p.x00Step + 1)
    x_out = x[:n_out]
    hole = average_radial(x, ihole, x_out, disk, legacy_interp=q["interp"])
    dsk = average_radial(x, idisk, x_out, disk, legacy_interp=q["interp"])
    header = dict(aa=aa, Teff=T, lambLo=p.lambLo, lambHi=p.lambHi, nLambda=p.nLambda, maxX00=p.maxX00,
                  x00Step=p.x00Step, RStar=p.RStarProj, nStars=disk.n, AU=p.AU, offset=p.offset,
                  aspectRatio=p.aspectRatio, order=p.order)
    return FresnelPattern(x_out, hole, dsk, header)


_HEADER_LINES = [
    ("aa", "KBO_radius:"), ("Teff", "T_effective:"), ("lambLo", "lambda_Low:"), ("lambHi", "lambda_High:"),
    ("nLambda", "Num_lambdas:"), ("maxX00", "max_dist_from_shadow_centre(m):"), ("x00Step", "step_size:"),
    ("RStar", "Projected_Star_Radius:"), ("nStars", "Num_point_sources_for_star:"), ("AU", "dist_to_KBO_(AU):"),
    ("offset", "offset_from_line_of_sight:"), ("aspectRatio", "aspectRatio_of_KBO_occulter(x/y):"),
    ("order", "order_of_approximation:"),
]


def fres_filename(aa, au, prefix="fres"):
    return f"{prefix}-{int(aa):05d}_{int(au):05d}"


def write_fres_file(path, pattern):
    with open(path, "w") as fh:
        for key, label in _HEADER_LINES:
            if key in pattern.header:
                fh.write(f"# {key} \t{label} \t{pattern.header[key]:g}\n")
        for xv, h, d in zip(pattern.x, pattern.Ihole, pattern.Idisk):
            fh.write(f"{xv:.0f} {h:.8f} {d:.8f}\n")


def read_fres_file(path):
    """Read a ``fres-*`` file written by fresnelT/fresnelBox or :func:`write_fres_file`."""
    header = {}
    rows = []
    with open(path) as fh:
        for line in fh:
            if line.startswith("#"):
                parts = line[1:].split()
                if len(parts) >= 2:
                    try:
                        header[parts[0]] = float(parts[-1])
                    except ValueError:
                        pass
            elif line.strip():
                rows.append([float(v) for v in line.split()[:3]])
    arr = np.array(rows)
    return FresnelPattern(arr[:, 0], arr[:, 1], arr[:, 2], header)


def offset_pattern(x, intensity, offset, x_out=None):
    """Profile along a chord at impact parameter ``offset`` from a radial profile (``offsetFresPatt``).

    Assumes a circularly symmetric shadow: I(x; b) = I(sqrt(x^2 + b^2)).
    """
    x = np.asarray(x, dtype=float)
    x_out = x if x_out is None else np.asarray(x_out, dtype=float)
    r = np.hypot(x_out, offset)
    return np.interp(r, x, intensity, right=intensity[-1])
