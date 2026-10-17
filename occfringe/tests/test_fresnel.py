import os
import shutil
import sys

import numpy as np
import pytest

from occfringe import legacy
from occfringe.bandpass import Bandpass, legacy_planck, planck_lambda
from occfringe.fresnel import (aperture_field, circle_obstacle_field, circle_obstacle_intensity, ellipse_strips,
                               fresnel_cs, fresnel_cs_legacy, knife_edge_intensity, legacy_ellipse_boxes,
                               obstacle_intensity)
from occfringe.star import StellarDisk, average_radial

F = 1000.0
BIG = 1e10


def test_unobstructed_field_is_one():
    rect = np.array([[0.0, 0.0, BIG, BIG]])
    u = aperture_field(rect, np.linspace(-5 * F, 5 * F, 11), 0.0, F)
    np.testing.assert_allclose(u, 1.0, atol=1e-9)


def test_far_from_small_occulter_intensity_is_one():
    boxes = ellipse_strips(100.0, thickness=5.0)
    i = obstacle_intensity(boxes, np.array([200 * F]), 0.0, F)
    assert abs(i[0] - 1.0) < 1e-2


def test_half_plane_matches_cornu_formula():
    half_plane = np.array([[BIG, 0.0, BIG, BIG]])   # opaque for x > 0
    x = np.linspace(-6 * F, 4 * F, 201)
    i = obstacle_intensity(half_plane, x, 0.0, F)
    np.testing.assert_allclose(i, knife_edge_intensity(-x, F), atol=1e-7)   # finite BIG leaves ~1/(pi BIG/F)
    assert abs(knife_edge_intensity(0.0, F) - 0.25) < 1e-12


def test_circular_aperture_on_axis():
    # phase convention exp(+i pi t^2 / 2): U_ap(0) = 1 - exp(i pi R^2 / 2F^2)
    R = 1.7 * F
    strips = ellipse_strips(R, thickness=F / 200)
    u = aperture_field(strips, 0.0, 0.0, F)
    expected = 1.0 - np.exp(1j * np.pi * R ** 2 / (2 * F ** 2))
    assert abs(u - expected) < 1e-4
    assert abs(circle_obstacle_field(R, 0.0, F) - (1.0 - expected)) < 1e-10


def _hankel_reference(R, r, F, n=400001):
    """Brute-force Simpson quadrature of the Hankel-transform field of an opaque disk."""
    from scipy.integrate import simpson
    from scipy.special import j0
    rho = np.linspace(0.0, R, n)
    a = np.pi / (2 * F * F)
    out = []
    for rv in r:
        f = np.exp(1j * a * rho ** 2) * j0(2 * a * rv * rho) * rho
        out.append(abs(1.0 - (2 * a / 1j) * np.exp(1j * a * rv ** 2) * simpson(f, x=rho)) ** 2)
    return np.array(out)


@pytest.mark.parametrize("RF", [0.7, 5.0, 30.0])
def test_circle_solver_matches_hankel_quadrature(RF):
    R = RF * F
    r = np.array([0.0, 0.3 * R, max(R - 3 * F, 0.0), R, R + 0.5 * F, R + 3 * F, R + 20 * F])
    np.testing.assert_allclose(circle_obstacle_intensity(R, r, F), _hankel_reference(R, r, F), atol=1e-8)


def test_circle_solver_branches_agree():
    R = 13 * F
    r = np.linspace(0.0, 40 * F, 301)
    direct = circle_obstacle_intensity(R, r, F, direct_max_RF=20.0)
    contour = circle_obstacle_intensity(R, r, F, direct_max_RF=10.0)
    np.testing.assert_allclose(contour, direct, atol=1e-9)


def test_poisson_spot_and_deep_shadow():
    R = 300 * F
    i = circle_obstacle_intensity(R, np.array([0.0, 0.5 * R, R - 10 * F]), F)
    assert abs(i[0] - 1.0) < 1e-10          # Arago spot at the centre
    assert i[1] < 1e-4                      # dark elsewhere deep in the shadow
    assert i[2] < 2e-3


def test_large_disk_approaches_knife_edge():
    R = 3000 * F
    u = np.linspace(-8 * F, 8 * F, 81)
    np.testing.assert_allclose(circle_obstacle_intensity(R, R + u, F), knife_edge_intensity(u, F), atol=2e-4)


def test_fine_strips_converge_to_exact_disk_for_small_bodies():
    R = 1.0 * F
    r = np.linspace(0.0, 10 * F, 200)
    exact = circle_obstacle_intensity(R, r, F)
    strips = obstacle_intensity(ellipse_strips(R, thickness=F / 80), r, 0.0, F)
    assert np.max(np.abs(strips - exact)) < 1e-3


def test_strip_tiling_area():
    a, b = 3000.0, 1500.0
    s = ellipse_strips(a, b, thickness=10.0, fine_extent=300.0, growth=0.1)
    area = np.sum(4 * s[:, 2] * s[:, 3])
    assert abs(area - np.pi * a * b) / (np.pi * a * b) < 1e-10


def test_legacy_fresnel_table_close_to_exact():
    x = np.linspace(-39.9, 39.9, 1001)
    c, s = fresnel_cs(x)
    cl, sl = fresnel_cs_legacy(x)
    assert np.max(np.abs(c - cl)) < 3e-3
    assert np.max(np.abs(s - sl)) < 3e-3


def test_legacy_planck_is_wien_shape():
    lam = np.linspace(4e-7, 8e-7, 20)
    T = 5800.0
    wien = lam ** -5 * np.exp(-6.62607015e-34 * 2.99792458e8 / (lam * 1.380649e-23 * T))
    ratio = legacy_planck(lam, T) / wien
    assert np.ptp(ratio / ratio.mean()) < 1e-4   # CGS constants of fresnelT.c differ slightly from SI
    exact = planck_lambda(lam, T)
    rel = (wien / wien.sum()) / (exact / exact.sum())
    assert np.max(np.abs(rel - 1.0)) < 0.05      # Wien vs Planck weights across 0.4-0.8 um at 5800 K


def test_legacy_boxes_cover_disk():
    boxes = legacy_ellipse_boxes(1000.0, 1.0, 5)
    area = np.sum(4 * boxes[:, 2] * boxes[:, 3])
    assert 0.95 < area / (np.pi * 1e6) < 1.0


def test_disk_average_of_constant_is_constant():
    r = np.linspace(0, 10 * F, 1001)
    disk = StellarDisk.uniform_grid(2 * F, F / 5, limb_darkening=0.6)
    out = average_radial(r, np.full_like(r, 0.7), np.linspace(3 * F, 7 * F, 5), disk)
    np.testing.assert_allclose(out, 0.7, atol=1e-12)


def test_bandpass_weights_normalised():
    b = Bandpass.tophat(1.0e-6, 2.0e-6, 11, T=5000.0)
    assert abs(b.w.sum() - 1.0) < 1e-12
    assert 1.0e-6 < b.mean < 2.0e-6


def test_fresnelT_port_self_consistent():
    p = legacy.FresnelParams(5.0e-7, 7.0e-7, 5, 6000.0, 50.0, 200.0, 30, 40.0, 0.0, 1.0, 5)
    pat = legacy.fresnelT(800.0, 5800.0, p, legacy=False)
    assert abs(pat.Idisk[-1] - 1.0) < 0.05
    assert pat.Idisk.min() < 0.9


@pytest.mark.skipif(shutil.which("cc") is None, reason="needs a C compiler")
def test_port_matches_c_fresnelT(tmp_path):
    here = os.path.join(os.path.dirname(__file__), "..", "validation")
    sys.path.insert(0, here)
    import compare_fresnelT as cmp
    exe = cmp.build_fresnelT(str(tmp_path))
    for aa, T, p in cmp.CASES[:3]:
        c = cmp.run_c(exe, aa, T, p, str(tmp_path))
        port = legacy.fresnelT(aa, T, p, legacy=True)
        assert np.max(np.abs(c.Idisk - port.Idisk)) < 1e-7
        assert np.max(np.abs(c.Ihole - port.Ihole)) < 1e-7
