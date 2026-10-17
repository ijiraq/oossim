import numpy as np

from occfringe.bandpass import Bandpass, n_lambda_for_window
from occfringe.constants import AU, fresnel_scale
from occfringe.edge import curvature_signal, geometric_edge_profile, knife_edge_profile, limb_profile
from occfringe.lightcurve import radial_profile
from occfringe.star import StellarDisk

Z = 40 * AU
LO, HI = 1.33e-6, 1.67e-6
F = float(fresnel_scale(1.5e-6, Z))
BAND = Bandpass.tophat(LO, HI, n_lambda_for_window(LO, HI, 12.0), T=5800.0)


def test_limb_window_matches_full_profile():
    R = 8 * F
    disk = StellarDisk.for_fresnel_scale(0.4 * F, F)
    limb = limb_profile(R, Z, BAND, disk, window_F=6.0)
    full = radial_profile(R, Z, BAND, disk, r_out=limb.x)
    np.testing.assert_allclose(limb.I, full.I, atol=1e-10)


def test_huge_body_limb_equals_knife_edge():
    R = 5000 * F
    disk = StellarDisk.for_fresnel_scale(0.3 * F, F)
    limb = limb_profile(R, Z, BAND, disk, window_F=8.0)
    knife = knife_edge_profile(Z, BAND, disk, window_F=8.0)
    assert np.max(np.abs(limb.I - knife(limb.x - R))) < 2e-4


def test_curvature_signal_falls_with_radius():
    s = [curvature_signal(RF * F, Z, BAND, None, window_F=8.0) for RF in (3.0, 10.0, 100.0)]
    assert s[0] > s[1] > s[2]
    assert s[2] < 0.01


def test_wavelength_sampling_converged():
    R = 30 * F
    n = BAND.lam.size
    fine = Bandpass.tophat(LO, HI, 2 * n, T=5800.0)
    a = limb_profile(R, Z, BAND, None, window_F=12.0)
    b = limb_profile(R, Z, fine, None, window_F=12.0)
    assert np.max(np.abs(a.I - b(a.x))) < 5e-3


def test_geometric_edge_limits():
    g = geometric_edge_profile(100.0)
    assert g(-200.0) == 0.0 and g(200.0) == 1.0
    assert abs(g(0.0) - 0.5) < 1e-12
    p = geometric_edge_profile(0.0)
    assert p(-1.0) == 0.0 and p(1.0) == 1.0
