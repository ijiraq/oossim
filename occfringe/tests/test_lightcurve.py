import numpy as np

from occfringe.bandpass import Bandpass
from occfringe.constants import AU, fresnel_scale
from occfringe.legacy import offset_pattern
from occfringe.lightcurve import Profile, chord_lightcurve, chord_radius, exposure_average, radial_profile
from occfringe.star import StellarDisk

Z = 40 * AU
BAND = Bandpass.tophat(1.4e-6, 1.6e-6, 9, T=5800.0)
F = float(fresnel_scale(1.5e-6, Z))


def test_exposure_average_exact_for_linear_model():
    t0 = np.array([0.0, 1.0, 2.5])
    avg = exposure_average(lambda t: 3.0 * t + 1.0, t0, t0 + 0.5, 5)
    np.testing.assert_allclose(avg, 3.0 * (t0 + 0.25) + 1.0)


def test_chord_radius_and_offset_pattern_agree():
    x = np.linspace(0, 10 * F, 200)
    I = 1.0 - np.exp(-(x / F) ** 2)
    b = 2 * F
    via_chord = np.interp(chord_radius(x / 1e4, 0.0, 1e4, b), x, I)
    np.testing.assert_allclose(via_chord, offset_pattern(x, I, b), atol=1e-12)


def test_radial_profile_limits():
    R = 20 * F
    disk = StellarDisk.for_fresnel_scale(0.5 * F, F)
    prof = radial_profile(R, Z, BAND, disk, r_out=np.array([0.5 * R, R, R + 25 * F]))
    assert prof.I[0] < 3e-3        # edge waves ~ (F / 10F)^2 / pi^2 at 10 F inside the limb
    assert 0.15 < prof.I[1] < 0.35
    assert abs(prof.I[2] - 1.0) < 0.02


def test_star_smoothing_reduces_fringe_contrast():
    R = 20 * F
    r = np.linspace(R - 5 * F, R + 8 * F, 400)
    point = radial_profile(R, Z, BAND, None, r_out=r)
    big = radial_profile(R, Z, BAND, StellarDisk.for_fresnel_scale(2 * F, F), r_out=r)
    outside = r > R + F
    assert np.ptp(big.I[outside]) < 0.5 * np.ptp(point.I[outside])


def test_chord_lightcurve_symmetric():
    prof = Profile(np.linspace(0, 10.0, 101), np.clip(np.linspace(0, 10.0, 101) - 4.0, 0, 1))
    t = np.linspace(-2, 2, 41)
    lc = chord_lightcurve(prof, t - 0.05, t + 0.05, 0.0, 5.0, 1.0, 8)
    np.testing.assert_allclose(lc, lc[::-1], atol=1e-12)
