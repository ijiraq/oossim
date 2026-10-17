"""Wavelength sampling and spectral weights for band-integrated diffraction patterns."""

from dataclasses import dataclass

import numpy as np

from .constants import C, H, K_B

# CGS constants exactly as defined in fresnelT.c
_H_CGS = 6.6260755e-27
_C_CGS = 2.99792458e10
_K_CGS = 1.380658e-16
_EXP = 2.718281828


def planck_lambda(lam, T):
    """Planck spectral radiance B_lambda(T) [W m^-3 sr^-1] for ``lam`` in metres."""
    lam = np.asarray(lam, dtype=float)
    return 2.0 * H * C ** 2 / lam ** 5 / np.expm1(H * C / (lam * K_B * T))


def legacy_planck(lam, T):
    """fresnelT.c ``planck()``: the ``- 1`` sits inside the exponent, i.e. e * Wien's law.

    ``lam`` in metres (fresnelT.c converts to cm before calling).
    """
    lam_cm = np.asarray(lam, dtype=float) * 100.0
    x = _H_CGS * _C_CGS / (lam_cm * _K_CGS * T)
    return (2.0 * _H_CGS * _C_CGS * _C_CGS / lam_cm ** 5) / np.power(_EXP, x - 1.0)


def legacy_wavelength_grid(lam_lo, lam_hi, n):
    """Wavelength grid of fresnelT.c: n evenly spaced points including both ends, or the midpoint if n == 1."""
    if n == 1:
        return np.array([0.5 * (lam_lo + lam_hi)])
    step = (lam_hi - lam_lo) / (n - 1)
    return lam_lo + np.arange(n) * step


@dataclass
class Bandpass:
    """Discrete wavelengths ``lam`` [m] with normalised weights ``w`` (sum to 1)."""

    lam: np.ndarray
    w: np.ndarray

    def __post_init__(self):
        self.lam = np.atleast_1d(np.asarray(self.lam, dtype=float))
        self.w = np.atleast_1d(np.asarray(self.w, dtype=float))
        self.w = self.w / self.w.sum()

    @property
    def mean(self):
        return float(np.sum(self.w * self.lam))

    @property
    def lam_min(self):
        return float(self.lam[self.w > 0].min())

    @property
    def lam_max(self):
        return float(self.lam[self.w > 0].max())

    @classmethod
    def legacy(cls, lam_lo, lam_hi, n, T=None):
        """fresnelT.c weighting (``T`` given) or fresnelBox.c equal weighting (``T`` None)."""
        lam = legacy_wavelength_grid(lam_lo, lam_hi, n)
        w = np.ones_like(lam) if T is None else legacy_planck(lam, T)
        return cls(lam, w)

    @classmethod
    def tophat(cls, lam_lo, lam_hi, n, T=None, weighting="photon"):
        """Rectangular band; ``weighting`` is 'photon' (lam B_lam), 'energy' (B_lam), or 'flat'."""
        lam = legacy_wavelength_grid(lam_lo, lam_hi, n)
        return cls(lam, _spectral_weight(lam, T, weighting) * _trapezoid_weights(lam))

    @classmethod
    def from_throughput(cls, lam_curve, throughput, T, n=None, window_F=None, weighting="photon", cut=1e-3):
        """Resample a throughput curve onto ``n`` wavelengths and weight by the stellar spectrum.

        Wavelengths where the throughput is below ``cut`` x peak are dropped.
        If ``n`` is None it is set by :func:`n_lambda_for_window`.
        """
        lam_curve = np.asarray(lam_curve, dtype=float)
        throughput = np.asarray(throughput, dtype=float)
        good = np.nonzero(throughput >= cut * throughput.max())[0]
        lo, hi = lam_curve[good[0]], lam_curve[good[-1]]
        if n is None:
            n = n_lambda_for_window(lo, hi, 10.0 if window_F is None else window_F)
        lam = np.linspace(lo, hi, n)
        thr = np.interp(lam, lam_curve, throughput)
        return cls(lam, thr * _spectral_weight(lam, T, weighting) * _trapezoid_weights(lam))


def _spectral_weight(lam, T, weighting):
    if weighting == "flat" or T is None:
        return np.ones_like(lam)
    b = planck_lambda(lam, T)
    if weighting == "energy":
        return b
    if weighting == "photon":
        return lam * b
    raise ValueError(f"unknown weighting {weighting!r}")


def _trapezoid_weights(lam):
    if lam.size == 1:
        return np.ones(1)
    d = np.diff(lam)
    w = np.zeros_like(lam)
    w[:-1] += 0.5 * d
    w[1:] += 0.5 * d
    return w


def n_lambda_for_window(lam_lo, lam_hi, window_F, max_phase_step=1.0, n_min=8):
    """Number of wavelengths needed to integrate fringes out to ``window_F`` Fresnel scales.

    Fringe phase at distance w (in Fresnel scales) is ~ pi w^2 / 2 and scales
    as 1/lam, so a fractional wavelength step d(lam)/lam shifts it by
    (pi w^2 / 2) d(lam)/lam.  The grid keeps that below ``max_phase_step`` rad.
    """
    frac = (lam_hi - lam_lo) / (0.5 * (lam_lo + lam_hi))
    return max(n_min, int(np.ceil(frac * 0.5 * np.pi * window_F ** 2 / max_phase_step)) + 1)
