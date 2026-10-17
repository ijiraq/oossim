import numpy as np
import pytest

from occfringe.nircam import (FILTERS, NIRCamSetup, filter_pivot, load_filter, photon_rate_ab, saturation_mag)


@pytest.mark.parametrize("name,pivot", [("F150W", 1.50), ("F200W", 1.99), ("F356W", 3.56), ("F444W", 4.40)])
def test_filter_pivots(name, pivot):
    assert abs(filter_pivot(name) * 1e6 - pivot) < 0.03


def test_zeropoints_near_ab_28():
    for name in FILTERS:
        zp = 2.5 * np.log10(photon_rate_ab(name, 0.0))
        assert 27.3 < zp < 29.0


def test_rate_scales_with_magnitude():
    assert abs(photon_rate_ab("F200W", 10.0) / photon_rate_ab("F200W", 12.5) - 10.0) < 1e-9


def test_saturation_logic():
    m_sat = saturation_mag("F200W", "SUB64P")
    assert NIRCamSetup("F200W", "SUB64P", mag_ab=m_sat - 0.3).saturated
    ok = NIRCamSetup("F200W", "SUB64P", mag_ab=m_sat + 0.3)
    assert not ok.saturated and ok.ngroups >= 2
    assert NIRCamSetup("F200W", "SUB64P", mag_ab=m_sat + 5).ngroups == 10


def test_sample_intervals_cadence():
    s = NIRCamSetup("F356W", "SUB64P", mag_ab=14.0)
    ta, tb = s.sample_intervals(0.0, 5.0, phase=0.013)
    np.testing.assert_allclose(tb - ta, s.t_frame)
    assert np.all(ta >= 0) and np.all(tb <= 5.0)
    frac = len(ta) * s.t_frame / 5.0
    assert abs(frac - s.duty_cycle) < 0.15


def test_noise_model_poisson_limit():
    s = NIRCamSetup("F150W", "SUB160P", mag_ab=14.0, read_noise_scale=0.0, background=0.0, flat_noise=0.0)
    expected = 1.0 / np.sqrt(s.signal_per_sample)
    assert abs(s.sigma(1.0) - expected) / expected < 1e-3


def test_noise_components_add_in_quadrature():
    s = NIRCamSetup("F200W", "SUB64P", mag_ab=13.0, flat_noise=2e-3)
    f = np.array([0.0, 0.5, 1.3])
    c = s.noise_components(f)
    np.testing.assert_allclose(c["flat"], 2e-3 * f)
    np.testing.assert_allclose(s.sigma(f), np.sqrt(sum(v ** 2 for v in c.values())))
    floor = np.sqrt(s.noise_floor) / s.signal_per_sample
    np.testing.assert_allclose(np.hypot(c["read"], c["background"]), floor)


def test_bandpass_within_filter():
    s = NIRCamSetup("F444W", "SUB64P", mag_ab=14.0)
    b = s.bandpass(4000.0)
    lam, thr = load_filter("F444W")
    assert lam.min() <= b.lam.min() and b.lam.max() <= lam.max()
    assert abs(b.mean - filter_pivot("F444W")) / filter_pivot("F444W") < 0.05
