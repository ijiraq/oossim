import numpy as np

from occfringe.limbfit import ellipse_chord, ellipse_limbs, ellipse_nearest


def test_ellipse_nearest_matches_brute_force():
    R, e, th, xc, yc = 20e3, 2.0, np.radians(60.0), 1500.0, -9000.0
    x = np.linspace(-40e3, 40e3, 401)
    d, rho = ellipse_nearest(R, e, th, xc, yc, x)
    a, b = R * np.sqrt(e), R / np.sqrt(e)
    phi = np.linspace(-np.pi, np.pi, 200001)
    bx = xc + a * np.cos(phi) * np.cos(th) - b * np.sin(phi) * np.sin(th)
    by = yc + a * np.cos(phi) * np.sin(th) + b * np.sin(phi) * np.cos(th)
    brute = np.min(np.hypot(x[:, None] - bx[None, :], by[None, :]), axis=1)
    assert np.allclose(np.abs(d), brute, atol=1.0)
    assert np.all((rho >= b * b / a - 1e-6) & (rho <= a * a / b + 1e-6))


def test_crossings_lie_on_ellipse_with_zero_distance():
    R, e, th, yc = 20e3, 1.3, np.radians(30.0), 9000.0
    l1, l2 = ellipse_limbs(R, e, th, 0.0, yc)
    d, rho = ellipse_nearest(R, e, th, 0.0, yc, np.array([l1.x, l2.x]))
    assert np.all(np.abs(d) < 1e-3)
    assert np.allclose(rho, [l1.rho, l2.rho], rtol=1e-6)
    assert np.isclose(l2.x - l1.x, ellipse_chord(R, e, th, yc))
