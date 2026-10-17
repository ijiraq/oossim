import numpy as np

from occfringe.fresnel import circle_obstacle_intensity, obstacle_intensity
from occfringe.shapes import Outline


def test_outline_geometry():
    R = 1000.0
    c = Outline.circle(R)
    assert abs(c.equivalent_radius() / R - 1) < 1e-5
    np.testing.assert_allclose(c.intervals(600.0), [[-800.0, 800.0]], rtol=1e-5)
    cb = Outline.contact_binary().scaled_to_radius(R)
    assert abs(cb.equivalent_radius() / R - 1) < 1e-6
    np.testing.assert_allclose(cb.centroid(), 0.0, atol=1e-3 * R)
    assert len(cb.intervals(0.0)) == 1          # merged through the neck
    rough = Outline.rough_circle(R, 0.03 * R, seed=1)
    r = np.hypot(*rough.polygons[0].T)
    assert abs(np.std(r) / R - 0.03) < 1e-3


def test_strips_converge_to_exact_disk():
    F, R, b = 1.0, 8.0, 3.0
    L = np.sqrt(R * R - b * b)
    x = np.linspace(-L - 5, -L + 5, 201)
    exact = circle_obstacle_intensity(R, np.hypot(x, b), F)
    err = [np.abs(obstacle_intensity(Outline.circle(R).strips(F / k), x, b, F) - exact).max() for k in (10, 80)]
    assert err[1] < 0.3 * err[0] and err[1] < 1e-2
