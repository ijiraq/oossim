"""JWST/NIRCam time-series imaging: filters, subarray cadence, count rates, and noise.

Numbers are from JDox (retrieved 2026-09-26):

* NIRCam Detector Performance, Table 1: CDS read noise, dark current, gain,
  well capacity (superbias subtracted);
* NIRCam Detector Subarrays, Table 3 (time-series imaging): frame times;
* NIRCam Detector Readout Patterns: RAPID saves every frame, up to 10 groups
  per integration for subarrays.

Filter curves are SVO copies of the JDox total system throughputs (OTE,
NIRCam optics, dichroic, and detector QE), stored in ``data/nircam``.

Photometry model: each sample is the difference of two consecutive RAPID
reads within an integration (one frame time of exposure).  An integration of
``ngroups`` reads is preceded by a one-frame reset, so each integration
yields ``ngroups - 1`` samples.  ``ngroups`` is the largest value (at most 10)
that keeps the brightest pixel below ``well_fraction`` of full well.
Correlated read noise between adjacent differences is neglected.
"""

import os
from dataclasses import dataclass, field

import numpy as np
from scipy.special import erf

from .bandpass import Bandpass, n_lambda_for_window
from .constants import C, H

DATA_DIR = os.path.join(os.path.dirname(__file__), "data", "nircam")

COLLECTING_AREA = 25.4          # m^2, JWST primary
AB_ZERO_FNU = 3631e-26          # W m^-2 Hz^-1
RAPID_MAX_GROUPS = 10


@dataclass(frozen=True)
class Detector:
    cds_read_noise: float   # e-, difference of two reads
    dark: float             # e- / s
    full_well: float        # e-
    pixel_scale: float      # arcsec / pixel
    gain: float             # e- / ADU


DETECTORS = {
    "SW": Detector(cds_read_noise=15.77, dark=1.9e-3, full_well=105_750.0, pixel_scale=0.031, gain=2.05),
    "LW": Detector(cds_read_noise=13.25, dark=34.2e-3, full_well=83_300.0, pixel_scale=0.063, gain=1.82),
}

# time-series imaging subarrays: frame time [s]
SUBARRAYS = {
    "SUB64P": 0.05016,
    "SUB160P": 0.27864,
    "SUB400P": 1.65624,
    "FULLP": 10.73677,
}

# channel and approximate PSF FWHM [arcsec] (JDox NIRCam PSF page, rounded)
FILTERS = {
    "F150W": ("SW", 0.050),
    "F200W": ("SW", 0.064),
    "F322W2": ("LW", 0.106),
    "F356W": ("LW", 0.116),
    "F444W": ("LW", 0.145),
}

# zodiacal + thermal background, e- / s / pixel (order of magnitude; negligible at subarray cadences)
DEFAULT_BACKGROUND = {"SW": 0.2, "LW": 0.5}


def load_filter(name):
    """Return (wavelength [m], throughput) for a NIRCam filter."""
    data = np.loadtxt(os.path.join(DATA_DIR, f"{name}.dat"))
    return data[:, 0] * 1e-10, data[:, 1]


def filter_pivot(name):
    lam, thr = load_filter(name)
    return float(np.sqrt(np.trapezoid(thr * lam, lam) / np.trapezoid(thr / lam, lam)))


def photon_rate_ab(name, mag_ab, area=COLLECTING_AREA):
    """Detected electrons per second from a source of AB magnitude ``mag_ab`` in filter ``name``.

    rate = A f_nu int T(lam) / (h lam) d lam, the photon-counting AB definition,
    so it holds for any spectral shape given the in-band AB magnitude.
    """
    lam, thr = load_filter(name)
    fnu = AB_ZERO_FNU * 10.0 ** (-0.4 * mag_ab)
    return area * fnu * np.trapezoid(thr / lam, lam) / H


def psf_fractions(name, peak_scale=0.8, aperture_fwhm=2.0, encircled=0.8):
    """Approximate PSF numbers for filter ``name``.

    Returns (peak pixel fraction for a star centred on a pixel, aperture
    radius [pix], number of aperture pixels, encircled-energy fraction).  The
    peak comes from a Gaussian of the JDox FWHM, reduced by ``peak_scale`` for
    the light JWST's segmented PSF puts into its diffraction wings.
    """
    channel, fwhm = FILTERS[name]
    fwhm_pix = fwhm / DETECTORS[channel].pixel_scale
    sigma = fwhm_pix / (2.0 * np.sqrt(2.0 * np.log(2.0)))
    peak = peak_scale * erf(0.5 / (np.sqrt(2.0) * sigma)) ** 2
    r_ap = max(2.0, aperture_fwhm * fwhm_pix)
    return float(peak), float(r_ap), float(np.pi * r_ap ** 2), encircled


@dataclass
class NIRCamSetup:
    """A NIRCam time-series imaging setup observing one star."""

    filter: str = "F200W"
    subarray: str = "SUB64P"
    mag_ab: float = 12.0
    ngroups: int | None = None
    max_groups: int = RAPID_MAX_GROUPS
    well_fraction: float = 0.8
    background: float | None = None
    read_noise_scale: float = 1.0
    # fractional per-sample error on the stellar flux from flat-field (intra- and inter-pixel)
    # errors sampled by pointing jitter; scales with the star's flux
    flat_noise: float = 1e-3
    psf: dict = field(default_factory=dict)

    def __post_init__(self):
        if self.filter not in FILTERS:
            raise ValueError(f"unknown filter {self.filter}; have {sorted(FILTERS)}")
        if self.subarray not in SUBARRAYS:
            raise ValueError(f"unknown subarray {self.subarray}; have {sorted(SUBARRAYS)}")
        self.channel = FILTERS[self.filter][0]
        self.detector = DETECTORS[self.channel]
        self.t_frame = SUBARRAYS[self.subarray]
        self.peak_fraction, self.r_aperture, self.n_pix, self.encircled = psf_fractions(self.filter, **self.psf)
        if self.background is None:
            self.background = DEFAULT_BACKGROUND[self.channel]
        self.rate = photon_rate_ab(self.filter, self.mag_ab)
        self.aperture_rate = self.encircled * self.rate
        self.peak_rate = self.peak_fraction * self.rate
        if self.ngroups is None:
            fill = self.well_fraction * self.detector.full_well
            self.ngroups = int(min(self.max_groups, np.floor(fill / (self.peak_rate * self.t_frame))))

    @property
    def saturated(self):
        """True if fewer than two reads fit before the brightest pixel saturates."""
        return self.ngroups < 2

    @property
    def duty_cycle(self):
        return max(self.ngroups - 1, 0) / (self.ngroups + 1)

    @property
    def signal_per_sample(self):
        """Electrons in the aperture per sample from the unocculted star."""
        return self.aperture_rate * self.t_frame

    @property
    def noise_floor(self):
        """Variance per sample [e-^2] from read noise, dark current, and background."""
        d = self.detector
        return self.n_pix * ((self.read_noise_scale * d.cds_read_noise) ** 2
                             + (d.dark + self.background) * self.t_frame)

    def noise_components(self, relative_flux):
        """Per-sample 1-sigma terms in units of the unocculted stellar flux.

        ``shot`` (stellar photons), ``read`` (CDS read noise), ``background``
        (dark current plus sky/thermal photons in the aperture) and ``flat``
        (flat-field/jitter systematic); they add in quadrature.
        """
        s0 = self.signal_per_sample
        f = np.clip(np.asarray(relative_flux, dtype=float), 0.0, None)
        d = self.detector
        return dict(
            shot=np.sqrt(f * s0) / s0,
            read=np.full_like(f, np.sqrt(self.n_pix) * self.read_noise_scale * d.cds_read_noise / s0),
            background=np.full_like(f, np.sqrt(self.n_pix * (d.dark + self.background) * self.t_frame) / s0),
            flat=self.flat_noise * f,
        )

    def sigma(self, relative_flux):
        """1-sigma noise per sample in units of the unocculted stellar flux."""
        return np.sqrt(sum(c ** 2 for c in self.noise_components(relative_flux).values()))

    def sample_intervals(self, t_begin, t_end, phase=0.0):
        """Start and stop times of every sample between ``t_begin`` and ``t_end``.

        ``phase`` [s] shifts the readout pattern relative to ``t_begin``.
        """
        if self.saturated:
            return np.empty(0), np.empty(0)
        cycle = (self.ngroups + 1) * self.t_frame
        n_cycles = int(np.ceil((t_end - t_begin) / cycle)) + 2
        start = t_begin - (phase % cycle) - cycle + cycle * np.arange(n_cycles)
        # reset occupies [start, start + t_frame]; read j ends at start + (j + 1) t_frame, j = 1..ngroups;
        # samples are the differences of reads j and j + 1
        j = np.arange(1, self.ngroups)
        t_a = (start[:, None] + (j[None, :] + 1) * self.t_frame).ravel()
        t_b = t_a + self.t_frame
        keep = (t_a >= t_begin) & (t_b <= t_end)
        return t_a[keep], t_b[keep]

    def bandpass(self, teff, window_F=10.0, n=None):
        """Photon-weighted bandpass: filter throughput times lam B_lam(teff)."""
        lam, thr = load_filter(self.filter)
        if n is None:
            good = thr >= 1e-3 * thr.max()
            n = n_lambda_for_window(lam[good].min(), lam[good].max(), window_F)
        return Bandpass.from_throughput(lam, thr, teff, n=n)

    def summary(self):
        return dict(filter=self.filter, subarray=self.subarray, mag_ab=self.mag_ab, rate=self.rate,
                    peak_rate=self.peak_rate, ngroups=self.ngroups, saturated=self.saturated,
                    t_frame=self.t_frame, duty_cycle=self.duty_cycle,
                    flat_noise=self.flat_noise,
                    snr_per_sample=float(1.0 / self.sigma(1.0)) if not self.saturated else 0.0)


def saturation_mag(filter_name, subarray, ngroups=2, well_fraction=0.8, **psf):
    """AB magnitude at which the brightest pixel reaches ``well_fraction`` of full well after ``ngroups`` frames."""
    channel = FILTERS[filter_name][0]
    peak, *_ = psf_fractions(filter_name, **psf)
    rate_limit = well_fraction * DETECTORS[channel].full_well / (ngroups * SUBARRAYS[subarray] * peak)
    return float(-2.5 * np.log10(rate_limit / photon_rate_ab(filter_name, 0.0)))
