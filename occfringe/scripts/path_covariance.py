"""Cross-track shadow-path uncertainty from a single-season Roman arc.

A representative TNO is placed on the GBTDS field; its heliocentric state at
the arc midpoint is fitted (linearised Fisher matrix, two-body motion) to Roman
astrometry taken every 12.1 minutes from Sun-Earth L2, and the covariance is
propagated to later epochs.  The quantity returned is the 1-sigma sky-plane
position error, in km at the object's distance, perpendicular to the shadow's
motion relative to the observer: the component that decides whether the shadow
covers JWST.

Per-exposure astrometric error for a D = 40 km object (albedo 0.1):
the archival search reaches F146 = 27.7 at S/N = STACK_SNR in 2-day stacks of
N_STACK exposures, so a single exposure has S/N = STACK_SNR / sqrt(N_STACK) at
27.7, scaled by flux to the object's magnitude (background-limited), and
sigma_1 = sqrt(2) * sigma_PSF / S/N.  Background-limited astrometry scales as
flux^-1, i.e. D^-2 at fixed distance.

An optional orbit-class prior (Gaussian in a and e, as in the bound-orbit prior
of Bernstein & Khushalani 2000) regularises the poorly measured range rate.
"""
import numpy as np
from astropy.time import Time
from scipy.optimize import least_squares

import gbtds_tno_rate as g

CADENCE_D = 12.1 / 1440.0
N_STACK = 238                  # exposures in a 2-day stack (4.65 h)
STACK_SNR = 6.0                # S/N at the F146 = 27.7 search limit
FWHM_ARCSEC = 0.13             # F146 PSF
D_REF = 40.0
MAS = np.radians(1.0 / 3.6e6)
MU = g.K_GAUSS ** 2


def rv2elem(r, v):
    h = np.cross(r, v)
    rn, v2 = np.linalg.norm(r), v @ v
    a = 1.0 / (2.0 / rn - v2 / MU)
    evec = np.cross(v, h) / MU - r / rn
    e = np.linalg.norm(evec)
    inc = np.arccos(h[2] / np.linalg.norm(h))
    nvec = np.array([-h[1], h[0], 0.0])
    node = np.arctan2(nvec[1], nvec[0])
    peri = np.arctan2(np.dot(np.cross(nvec, evec), h) / np.linalg.norm(h), nvec @ evec)
    nu = np.arctan2(np.dot(np.cross(evec, r), h) / np.linalg.norm(h), evec @ r)
    E = 2 * np.arctan(np.sqrt((1 - e) / (1 + e)) * np.tan(nu / 2))
    M = E - e * np.sin(E)
    return a, e, inc, node, peri, M


def positions(state, t_ref, times_jd):
    a, e, inc, node, peri, M = rv2elem(state[:3], state[3:])
    n = g.K_GAUSS / a ** 1.5
    r, v = g.kepler_state(a, e, inc, node, peri, np.mod(M + n * (np.asarray(times_jd) - t_ref), 2 * np.pi))
    return r, v


def sky_offsets(state, t_ref, times_jd, ro):
    r, _ = positions(state, t_ref, times_jd)
    d = r - ro.T
    delta = np.linalg.norm(d, axis=0)
    return np.arctan2(d[1], d[0]), np.arcsin(d[2] / delta), delta


def place_orbit(lam_c, beta_c, t_ref, a=43.0, e=0.15, inc_deg=10.0, peri_deg=90.0):
    ro = g.observer(Time([t_ref], format="jd"))[0]

    def state_of(p):
        r, v = g.kepler_state(a, e, np.radians(inc_deg), p[0], np.radians(peri_deg), p[1])
        return np.concatenate([np.ravel(r), np.ravel(v)])

    def resid(p):
        lam, bet, _ = sky_offsets(state_of(p), t_ref, [t_ref], ro)
        return [((lam[0] - lam_c + np.pi) % (2 * np.pi) - np.pi) * np.cos(beta_c), bet[0] - beta_c]

    best = None
    for node0 in np.radians(np.arange(0, 360, 30)):
        for m0 in np.radians(np.arange(0, 360, 30)):
            s = least_squares(resid, [node0, m0])
            if best is None or s.cost < best.cost:
                best = s
    return state_of(best.x)


STEPS = np.array([1e-5, 1e-5, 1e-5, 1e-8, 1e-8, 1e-8])


def jac(state, t_ref, times_jd, ro, beta_c):
    J = np.zeros((len(times_jd), 2, 6))
    for k in range(6):
        sp, sm = state.copy(), state.copy()
        sp[k] += STEPS[k]
        sm[k] -= STEPS[k]
        lp, bp, _ = sky_offsets(sp, t_ref, times_jd, ro)
        lm, bm, _ = sky_offsets(sm, t_ref, times_jd, ro)
        J[:, 0, k] = ((lp - lm + np.pi) % (2 * np.pi) - np.pi) * np.cos(beta_c) / (2 * STEPS[k])
        J[:, 1, k] = (bp - bm) / (2 * STEPS[k])
    return J


def ae_grad(state):
    G = np.zeros((2, 6))
    for k in range(6):
        sp, sm = state.copy(), state.copy()
        sp[k] += STEPS[k]
        sm[k] -= STEPS[k]
        ep, em = rv2elem(sp[:3], sp[3:]), rv2elem(sm[:3], sm[3:])
        G[0, k] = (ep[0] - em[0]) / (2 * STEPS[k])
        G[1, k] = (ep[1] - em[1]) / (2 * STEPS[k])
    return G


def sigma1_mas(D_km=D_REF, albedo=g.ALBEDO, delta_au=43.0, r_au=43.6, phase_deg=1.2):
    h = g.h_from_d(D_km, albedo)
    mag = h + 5 * np.log10(r_au * delta_au) + g.PHASE_COEFF * phase_deg - g.R_MINUS_F146
    snr1 = STACK_SNR / np.sqrt(N_STACK) * 10 ** (0.4 * (g.MAG_LIMIT - mag))
    sig_psf = FWHM_ARCSEC / 2.355 * 1e3
    return np.sqrt(2.0) * sig_psf / snr1, mag, snr1


def cross_dirs(state, t_ref, t_ev, ro_ev, vo_ev):
    r_ev, v_ev = positions(state, t_ref, t_ev)
    d = r_ev - ro_ev.T
    dv = v_ev - vo_ev.T
    dhat = d / np.linalg.norm(d, axis=0)
    vt = dv - np.sum(dv * dhat, axis=0) * dhat
    lam = np.arctan2(d[1], d[0])
    e_lam = np.stack([-np.sin(lam), np.cos(lam), np.zeros_like(lam)])
    e_bet = np.cross(dhat.T, e_lam.T).T
    m = np.stack([np.sum(vt * e_lam, axis=0), np.sum(vt * e_bet, axis=0)])
    m /= np.linalg.norm(m, axis=0)
    return np.stack([-m[1], m[0]]), np.linalg.norm(d, axis=0)


def sigma_table(lam_c, beta_c, t_r0, t_r1, arc_days, ext_days, prior=None, sigma1_scale=1.0, **orbit):
    """sigma_cross [km] for D = 40 km, for arcs starting at t_r0 of length arc_days, extrapolated
    ext_days beyond the arc end.  prior = (sigma_a [au], sigma_e).
    Returns (table[len(arc), len(ext)], (sigma_1 [mas], F146, S/N_1))."""
    t_ref = 0.5 * (t_r0 + t_r1)
    state = place_orbit(lam_c, beta_c, t_ref, **orbit)
    s1, mag, snr1 = sigma1_mas()
    s1 *= sigma1_scale
    t_obs = np.arange(t_r0, t_r1, CADENCE_D)
    ro_obs = g.observer(Time(t_obs, format="jd"))[0]
    J = jac(state, t_ref, t_obs, ro_obs, beta_c)
    Fcum = np.cumsum(np.einsum("tij,tik->tjk", J, J), axis=0) / (s1 * MAS) ** 2
    Fp = np.zeros((6, 6))
    if prior is not None:
        G = ae_grad(state)
        Fp = np.outer(G[0], G[0]) / prior[0] ** 2 + np.outer(G[1], G[1]) / prior[1] ** 2
    out = np.full((len(arc_days), len(ext_days)), np.nan)
    for i, T in enumerate(arc_days):
        k = np.searchsorted(t_obs, t_r0 + T) - 1
        if k < 10:
            continue
        F = Fcum[k] + Fp
        s = 1.0 / np.sqrt(np.diag(F))
        cov = np.linalg.inv(F * np.outer(s, s)) * np.outer(s, s)
        t_ev = t_obs[k] + np.asarray(ext_days, float)
        ro_ev, vo_ev = g.observer(Time(t_ev, format="jd"))
        Je = jac(state, t_ref, t_ev, ro_ev, beta_c)
        cross, dist = cross_dirs(state, t_ref, t_ev, ro_ev, vo_ev)
        ct = np.einsum("it,tik->tk", cross, Je)
        out[i] = np.sqrt(np.einsum("tk,kl,tl->t", ct, cov, ct)) * dist * g.AU_KM
    return out, (s1, mag, snr1)
