#!/usr/bin/env python3
"""Expected Roman-predicted TNO occultations of usable GBTDS stars observable by JWST.

Two estimates are produced for one GBTDS high-cadence season:

1. Model-based (primary).  TNOs are drawn from the OSSOS++ Kuiper-belt model
   (Model_KB_0.txt, NewHorizons/2021ModelKuiperBelt; normalised like Petit et
   al. 2023).  The file is randomly ordered, so a leading chunk is scaled by the
   byte fraction read.  Orbits are propagated (two-body) from the model epoch,
   fixed by Neptune's longitude implied by the resonant angles, to the season.
   Every object near the field's ecliptic latitude is slid in ecliptic
   longitude across the WFI footprint; its sky track through the Roman season
   decides whether and when it is detected (F146 < MAG_LIMIT for at least
   MIN_DAYS inside the detectors), and its shadow sweep during the JWST window
   is integrated against the usable-star density from gbtds_star_catalog.py.

2. Analytic (the requested back-of-envelope).  Petit et al. (2023) hot
   main-belt H_r distribution, inclinations p(i) ~ sin i exp(-i^2 / 2 sigma^2),
   all objects at 43 au, the WFI footprint area, and a mean shadow speed times
   9-50 days of JWST visibility.

Candidates are star-TNO pairs whose predicted interception probability,
P(x) = Phi((x+R)/s) - Phi((x-R)/s) for cross-track offset x and cross-track
uncertainty s, is at least P_TRIGGER.  s = SIGMA0 while Roman is observing
the object and grows at SIGMA_RATE after its last Roman measurement.

Writes results/gbtds/tno_rate.md, tno_rate.png and tno_rate_objects.csv.
"""
import argparse
import os
import sys

import numpy as np
from astropy.coordinates import get_body_barycentric, get_body_barycentric_posvel
from astropy.table import Table
from astropy.time import Time
import astropy.units as u
from scipy.special import ndtr
from scipy.optimize import brentq

sys.path.insert(0, os.path.dirname(__file__))
from gbtds_star_catalog import wfi_polygons, FIELD_NAMES  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "results", "gbtds")
MODEL = os.environ.get("KB_MODEL", os.path.join(OUT, "cache", "Model_KB_0.txt"))
MODEL_BYTES = 2703000102           # full size of Model_KB_0.txt on VOSpace

OBLIQUITY = np.radians(23.4392911)
K_GAUSS = 0.01720209895            # rad / day
AU_KM = 1.495978707e8
AUD_TO_KMS = AU_KM / 86400.0
L2_SCALE = 1.01                    # JWST at Sun-Earth L2

# survey and object assumptions
MAG_LIMIT = 27.7                   # F146 AB, archival search depth
R_MINUS_F146 = 0.5                 # typical hot TNO colour (AB)
PHASE_COEFF = 0.14                 # mag / deg
ALBEDO = 0.10
SUN_R_AB = -26.93                  # apparent solar r (AB)
MIN_DAYS = 5.0                     # days inside the detectors needed for detection
LEAD_DAYS = 5.0                    # detection to earliest triggerable event
SIGMA0 = 20.0                      # km, cross-track uncertainty while Roman observes
SIGMA_RATE = 300.0 / 45.0          # km / day after the last Roman measurement
P_TRIGGER = 0.5
N_TRIGGER = 6
D_TARGET = 40.0                    # km

# observing geometry (Sun-target elongation, deg)
ROMAN_ELONG = (54.0, 126.0)
JWST_ELONG = (85.0, 135.0)
YEAR = 2027

LON_WINDOW = 15.0                  # deg, half width of the longitude band sampled from the model
LAT_WINDOW = 1.5                   # deg, half height about the footprint centre
X_STEP = 0.01                      # deg, longitude-slide step
T_STEP = 0.25                      # days
PIX = 0.004                        # deg, footprint raster


def d_from_h(h, albedo=ALBEDO):
    return 2.0 * AU_KM * 10 ** (0.2 * (SUN_R_AB - h)) / np.sqrt(albedo)


def h_from_d(d, albedo=ALBEDO):
    return SUN_R_AB - 5.0 * np.log10(d * np.sqrt(albedo) / (2.0 * AU_KM))


# ---------------------------------------------------------------- geometry
def icrs_to_ecl(v):
    x, y, z = v
    return np.array([x, np.cos(OBLIQUITY) * y + np.sin(OBLIQUITY) * z,
                     -np.sin(OBLIQUITY) * y + np.cos(OBLIQUITY) * z])


def observer(times):
    """Heliocentric ecliptic J2000 position [au] and velocity [au/day] of JWST (L2 approximation)."""
    pe, ve = get_body_barycentric_posvel("earth", times)
    ps, vs = get_body_barycentric_posvel("sun", times)
    r = icrs_to_ecl((pe - ps).xyz.to(u.au).value) * L2_SCALE
    v = icrs_to_ecl((ve - vs).xyz.to(u.au / u.day).value) * L2_SCALE
    return r.T, v.T


def neptune_lon(t):
    v = icrs_to_ecl((get_body_barycentric("neptune", t) - get_body_barycentric("sun", t)).xyz.to(u.au).value)
    return np.degrees(np.arctan2(v[1], v[0])) % 360.0


def kepler_state(a, e, inc, node, peri, M):
    """Heliocentric ecliptic position [au] and velocity [au/day]; angles in radians, arrays broadcast."""
    a, e, inc, node, peri, M = np.broadcast_arrays(a, e, inc, node, peri, M)
    E = np.where(e > 0.8, np.pi * np.ones_like(M), M + e * np.sin(M))
    for _ in range(60):
        f = E - e * np.sin(E) - M
        E = E - f / (1.0 - e * np.cos(E))
    n = K_GAUSS / a ** 1.5
    cE, sE = np.cos(E), np.sin(E)
    q = np.sqrt(1.0 - e * e)
    xo, yo = a * (cE - e), a * q * sE
    fac = a * n / (1.0 - e * cE)
    vxo, vyo = -fac * sE, fac * q * cE
    cw, sw, cO, sO, ci, si = np.cos(peri), np.sin(peri), np.cos(node), np.sin(node), np.cos(inc), np.sin(inc)
    P = np.array([cw * cO - sw * sO * ci, cw * sO + sw * cO * ci, sw * si])
    Q = np.array([-sw * cO - cw * sO * ci, -sw * sO + cw * cO * ci, cw * si])
    return xo * P + yo * Q, vxo * P + vyo * Q


def model_epoch():
    """JD at which Neptune had the longitude implied by the model's resonant angles (see main)."""
    return MODEL_EPOCH_JD


def season_times(lam_c, beta_c):
    """JD of the elongation crossings for the spring (rising) and autumn (falling) seasons."""
    days = Time(f"{YEAR}-01-01") + np.arange(0, 366, 0.05) * u.day
    r, _ = observer(days)
    uc = np.array([np.cos(beta_c) * np.cos(lam_c), np.cos(beta_c) * np.sin(lam_c), np.sin(beta_c)])
    elong = np.degrees(np.arccos(np.clip(-(r @ uc) / np.linalg.norm(r, axis=1), -1, 1)))
    rising = np.gradient(elong) > 0
    out = {}
    for name, sel in (("spring", rising), ("autumn", ~rising)):
        cross = {}
        for target in sorted(set(ROMAN_ELONG + JWST_ELONG)):
            idx = np.flatnonzero(sel[:-1] & sel[1:] & (np.sign(elong[:-1] - target) != np.sign(elong[1:] - target)))
            cross[target] = days[idx[0]].jd if len(idx) else np.nan
        out[name] = cross
    return out


# ---------------------------------------------------------------- probabilities
def p_intercept(x, R, s):
    return ndtr((x + R) / s) - ndtr((x - R) / s)


def _band_tables():
    rho = np.geomspace(0.05, 200.0, 800)
    x50 = np.zeros_like(rho)
    s50 = np.zeros_like(rho)
    for k, r in enumerate(rho):
        if p_intercept(0.0, r, 1.0) < P_TRIGGER:
            continue
        x50[k] = brentq(lambda x: p_intercept(x, r, 1.0) - P_TRIGGER, 0.0, r + 10.0)
        xx = np.linspace(-x50[k], x50[k], 401)
        s50[k] = np.trapezoid(p_intercept(xx, r, 1.0), xx)
    return rho, x50, s50


RHO_T, X50_T, S50_T = _band_tables()


def band_width(R, s):
    """Width [same units] of the cross-track band with P >= P_TRIGGER, and the summed P over that band."""
    rho = R / s
    return 2.0 * s * np.interp(rho, RHO_T, X50_T, left=0.0), s * np.interp(rho, RHO_T, S50_T, left=0.0)


def _half_width(p):
    xp = np.zeros_like(RHO_T)
    for k, r in enumerate(RHO_T):
        if p_intercept(0.0, r, 1.0) >= p:
            xp[k] = brentq(lambda x: p_intercept(x, r, 1.0) - p, 0.0, r + 10.0)
    return xp


_BAND_CACHE = {}


def band_width_p(R, s, p):
    """band_width for an arbitrary trigger threshold p."""
    if p not in _BAND_CACHE:
        xp = _half_width(p)
        sp = np.zeros_like(RHO_T)
        for k, r in enumerate(RHO_T):
            if xp[k] > 0:
                xx = np.linspace(-xp[k], xp[k], 401)
                sp[k] = np.trapezoid(p_intercept(xx, r, 1.0), xx)
        _BAND_CACHE[p] = (xp, sp)
    xp, sp = _BAND_CACHE[p]
    rho = R / s
    return 2.0 * s * np.interp(rho, RHO_T, xp, left=0.0), s * np.interp(rho, RHO_T, sp, left=0.0)


Q_T = np.geomspace(1.0, 30.0, 48)
_WD_CACHE = {}


def _withdraw_tables(p_act):
    """Activate on the early prediction if P_early >= p_act, execute only if the refined prediction
    has P_late >= P_TRIGGER.  Early error sigma_e = q * sigma_l, nested (refinement adds information).
    Tables in units of sigma_l over (rho_l = R/sigma_l, q): executed width and expected hits."""
    if p_act in _WD_CACHE:
        return _WD_CACHE[p_act]
    xa_tab = _half_width(p_act)
    ex = np.zeros((len(RHO_T), len(Q_T)))
    hit = np.zeros_like(ex)
    for i, rho in enumerate(RHO_T):
        x50 = X50_T[i]
        if x50 <= 0:
            continue
        y = np.linspace(-x50, x50, 401)
        p_true = p_intercept(y, rho, 1.0)
        for k, q in enumerate(Q_T):
            xa = q * np.interp(rho / q, RHO_T, xa_tab, left=0.0)
            sd = np.sqrt(max(q * q - 1.0, 1e-12))
            gy = ndtr((xa - y) / sd) - ndtr((-xa - y) / sd) if xa > 0 else np.zeros_like(y)
            ex[i, k] = np.trapezoid(gy, y)
            hit[i, k] = np.trapezoid(gy * p_true, y)
    from scipy.interpolate import RegularGridInterpolator
    grid = (np.log(RHO_T), np.log(Q_T))
    _WD_CACHE[p_act] = (xa_tab, RegularGridInterpolator(grid, ex), RegularGridInterpolator(grid, hit))
    return _WD_CACHE[p_act]


def withdraw_width(R, s_early, s_late, p_act):
    """(activation width, executed width, expected hits) for activate-early / withdraw-late."""
    xa_tab, ex, hit = _withdraw_tables(p_act)
    s_late = np.minimum(s_late, s_early)
    act = 2.0 * s_early * np.interp(R / s_early, RHO_T, xa_tab, left=0.0)
    rho = np.clip(R / s_late, RHO_T[0], RHO_T[-1])
    q = np.clip(s_early / s_late, Q_T[0], Q_T[-1])
    pts = np.stack([np.log(rho), np.log(q)], axis=-1)
    e = ex(pts) * s_late
    h = hit(pts) * s_late
    small = R / s_late < RHO_T[0]
    return act, np.where(small, 0.0, e), np.where(small, 0.0, h)


# ---------------------------------------------------------------- footprint
def footprint_raster():
    polys = wfi_polygons()
    lam, bet = [], []
    ecl_polys = []
    for name, i, ra, dec in polys:
        ra, dec = np.radians(ra), np.radians(dec)
        v = icrs_to_ecl(np.array([np.cos(dec) * np.cos(ra), np.cos(dec) * np.sin(ra), np.sin(dec)]))
        l, b = np.arctan2(v[1], v[0]), np.arcsin(v[2])
        ecl_polys.append((name, np.degrees(l) % 360, np.degrees(b)))
        lam += list(np.degrees(l) % 360)
        bet += list(np.degrees(b))
    lam_c, beta_c = np.mean(lam), np.mean(bet)
    cb = np.cos(np.radians(beta_c))
    from matplotlib.path import Path
    xs = [(p[1] - lam_c) * cb for p in ecl_polys]
    ys = [p[2] - beta_c for p in ecl_polys]
    x0, x1 = min(map(np.min, xs)) - 0.05, max(map(np.max, xs)) + 0.05
    y0, y1 = min(map(np.min, ys)) - 0.05, max(map(np.max, ys)) + 0.05
    gx = np.arange(x0, x1, PIX) + PIX / 2
    gy = np.arange(y0, y1, PIX) + PIX / 2
    GX, GY = np.meshgrid(gx, gy, indexing="ij")
    pts = np.column_stack([GX.ravel(), GY.ravel()])
    mask = np.zeros(pts.shape[0], dtype=np.int8)
    for k, (x, y) in enumerate(zip(xs, ys)):
        inside = Path(np.column_stack([x, y])).contains_points(pts)
        mask[inside] = FIELD_NAMES.index(ecl_polys[k][0]) + 1
    mask = mask.reshape(GX.shape)
    area = np.count_nonzero(mask) * PIX ** 2
    return dict(mask=mask, x0=x0, y0=y0, nx=len(gx), ny=len(gy), lam_c=lam_c, beta_c=beta_c, area=area,
                xs=xs, ys=ys)


def lookup(fp, x, y):
    ix = np.floor((x - fp["x0"]) / PIX).astype(int)
    iy = np.floor((y - fp["y0"]) / PIX).astype(int)
    ok = (ix >= 0) & (ix < fp["nx"]) & (iy >= 0) & (iy < fp["ny"])
    out = np.zeros(x.shape, dtype=np.int8)
    out[ok] = fp["mask"][ix[ok], iy[ok]]
    return out


# ---------------------------------------------------------------- model
def load_model(max_bytes=None):
    import pandas as pd
    import io
    names = ["a", "e", "inc", "node", "peri", "M", "H", "cls"]
    if max_bytes is None:
        df = pd.read_csv(MODEL, sep=r"\s+", header=None, skiprows=1, names=names,
                         usecols=range(8), engine="c", on_bad_lines="skip",
                         dtype={n: np.float32 for n in names[:7]} | {"cls": "category"})
        df[names[:7]] = df[names[:7]].astype(np.float64)
        return df, MODEL_BYTES / os.path.getsize(MODEL)
    size = os.path.getsize(MODEL) if max_bytes is None else int(min(max_bytes, os.path.getsize(MODEL)))
    with open(MODEL, "rb") as f:
        head = f.readline()
        f.seek(0)
        data = f.read(size)
    data = data[:data.rfind(b"\n") + 1]
    df = pd.read_csv(io.BytesIO(data[len(head):]), sep=r"\s+", header=None,
                     names=["a", "e", "inc", "node", "peri", "M", "H", "cls"], usecols=range(8),
                     engine="c", on_bad_lines="skip")
    scale = MODEL_BYTES / len(data)
    return df, scale


def resonant_neptune_lon(df):
    """Neptune longitude [deg] implied by the 3:2, 5:2 and 2:1 resonant angles being centred on 180 deg."""
    lam = np.radians(df.node + df.peri + df.M)
    varpi = np.radians(df.node + df.peri)

    def cmean(x):
        return np.arctan2(np.mean(np.sin(x)), np.mean(np.cos(x)))
    s21 = df.cls.str.startswith("Resonant--2:1").values
    lam_n = np.degrees(cmean(2 * lam[s21] - varpi[s21] - np.pi)) % 360
    s32 = df.cls.str.startswith("Resonant--3:2").values
    two = np.degrees(cmean(3 * lam[s32] - varpi[s32] - np.pi)) % 360
    cands = np.array([two / 2, two / 2 + 180])
    lam_n32 = cands[np.argmin(np.abs(((cands - lam_n) + 180) % 360 - 180))]
    return lam_n, lam_n32


def epoch_from_neptune(lam_n):
    ts = Time("2000-01-01") + np.arange(0, 30 * 365.25, 5.0) * u.day
    lon = neptune_lon(ts)
    d = ((lon - lam_n) + 180) % 360 - 180
    k = np.flatnonzero(np.sign(d[:-1]) != np.sign(d[1:]))[0]
    return ts[k].jd + 5.0 * (-d[k]) / (d[k + 1] - d[k])


# ---------------------------------------------------------------- main computation
def propagate(df, jd, epoch):
    a = df.a.values
    n = K_GAUSS / a ** 1.5
    M = np.radians(df.M.values) + n * (jd - epoch)
    return kepler_state(a, df.e.values, np.radians(df.inc.values), np.radians(df.node.values),
                        np.radians(df.peri.values), np.mod(M, 2 * np.pi))


def sky(r, v, ro, vo):
    d = r - ro
    delta = np.linalg.norm(d, axis=0)
    lam = np.degrees(np.arctan2(d[1], d[0])) % 360
    bet = np.degrees(np.arcsin(d[2] / delta))
    dv = v - vo
    dhat = d / delta
    vt = dv - np.sum(dv * dhat, axis=0) * dhat
    speed = np.linalg.norm(vt, axis=0) * AUD_TO_KMS
    rh = np.linalg.norm(r, axis=0)
    phase = np.degrees(np.arccos(np.clip(np.sum(r * d, axis=0) / (rh * delta), -1, 1)))
    return lam, bet, delta, rh, speed, phase


def run_season(df, scale, fp, season, cross, epoch, star_density, args):
    t_r0, t_r1 = cross[ROMAN_ELONG[0]], cross[ROMAN_ELONG[1]]
    t_j0, t_j1 = cross[JWST_ELONG[0]], cross[JWST_ELONG[1]]
    if season == "autumn":
        t_r0, t_r1 = cross[ROMAN_ELONG[1]], cross[ROMAN_ELONG[0]]
        t_j0, t_j1 = cross[JWST_ELONG[1]], cross[JWST_ELONG[0]]
    t_start, t_end = min(t_r0, t_j0), max(t_r1, t_j1)
    tgrid = np.arange(t_start, t_end + T_STEP / 2, T_STEP)
    ttime = Time(tgrid, format="jd")
    ro, vo = observer(ttime)
    t_mid = 0.5 * (t_r0 + t_r1)
    ro_m, vo_m = observer(Time([t_mid], format="jd"))

    # preselect near the field at mid-season
    r, v = propagate(df, t_mid, epoch)
    lam, bet, delta, rh, speed, phase = sky(r, v, ro_m[0][:, None], vo_m[0][:, None])
    dl = ((lam - fp["lam_c"]) + 180) % 360 - 180
    mag = df.H.values + 5 * np.log10(rh * delta) + PHASE_COEFF * phase - args.colour
    sel = (np.abs(dl) < LON_WINDOW) & (np.abs(bet - fp["beta_c"]) < LAT_WINDOW) & (mag < args.mag_limit + 0.5)
    sub = df[sel].reset_index(drop=True)
    print(f"  {season}: {sel.sum()} model objects in the sampling box", flush=True)

    # ephemerides on the time grid
    r_t, v_t = propagate(sub, tgrid[:, None], epoch)          # (3, nT, nObj)
    d = r_t - ro.T[:, :, None]
    delta_t = np.linalg.norm(d, axis=0)
    lam_t = np.degrees(np.arctan2(d[1], d[0])) % 360
    bet_t = np.degrees(np.arcsin(d[2] / delta_t))
    dv = v_t - vo.T[:, :, None]
    dhat = d / delta_t
    vt = dv - np.sum(dv * dhat, axis=0) * dhat
    speed_t = np.linalg.norm(vt, axis=0) * AUD_TO_KMS          # km/s
    rh_t = np.linalg.norm(r_t, axis=0)
    phase_t = np.degrees(np.arccos(np.clip(np.sum(r_t * d, axis=0) / (rh_t * delta_t), -1, 1)))
    mag_t = sub.H.values[None, :] + 5 * np.log10(rh_t * delta_t) + PHASE_COEFF * phase_t - args.colour

    cb = np.cos(np.radians(fp["beta_c"]))
    lam_ref = lam_t[np.argmin(np.abs(tgrid - t_mid))]
    dx = (((lam_t - lam_ref[None, :]) + 180) % 360 - 180) * cb
    y = bet_t - fp["beta_c"]
    D = d_from_h(sub.H.values, args.albedo)
    R_km = 0.5 * D
    delta_km = delta_t * AU_KM

    in_roman = (tgrid >= t_r0) & (tgrid <= t_r1)
    in_jwst = (tgrid >= t_j0) & (tgrid <= t_j1)
    x_lo = min(map(np.min, fp["xs"])) - 1.0
    x_hi = max(map(np.max, fp["xs"])) + 1.0
    X0 = np.arange(x_lo, x_hi, X_STEP)
    w_slide = X_STEP / (2 * LON_WINDOW * cb) * scale
    n_rad = star_density * (180 / np.pi * 3600) ** 2          # usable stars per rad^2

    recs = []
    for j in range(len(sub)):
        if not np.any((y[:, j] > min(map(np.min, fp["ys"]))) & (y[:, j] < max(map(np.max, fp["ys"])))):
            continue
        xx = X0[:, None] + dx[None, :, j]
        field = lookup(fp, xx, np.broadcast_to(y[None, :, j], xx.shape))
        visible = (field > 0) & in_roman[None, :] & (mag_t[None, :, j] < args.mag_limit)
        cum = np.cumsum(visible, axis=1) * T_STEP
        det = cum[:, -1] >= args.min_days
        if not det.any():
            continue
        rows = np.flatnonzero(det)
        t_det = tgrid[np.argmax(cum[rows] >= args.min_days, axis=1)]
        last_idx = visible.shape[1] - 1 - np.argmax(visible[rows, ::-1], axis=1)
        t_last = tgrid[last_idx]
        fld = field[rows, np.argmax(visible[rows], axis=1)]
        t_first = tgrid[np.argmax(visible[rows], axis=1)]
        rate = speed_t[:, j] * 86400.0 / delta_km[:, j] ** 2 * T_STEP        # rad^2 per km of width per step
        def path_sigma(L, jwst_rate):
            t_act = tgrid[None, :] - L
            arc_end = np.minimum(t_last[:, None], t_act)
            T_arc = np.clip(arc_end - t_first[:, None], 0, None)
            ext = np.clip(tgrid[None, :] - arc_end, 0, None)
            s_obj = args.sigtab[season](T_arc, ext) * (args.d_ref / D[j]) ** 2
            s = np.sqrt(s_obj ** 2 + args.sig_floor ** 2 + args.sig_star ** 2 + (jwst_rate * L) ** 2)
            return s, in_jwst[None, :] & (t_act >= t_det[:, None])

        configs = getattr(args, "act_leads", None) or [None]
        for icfg, cfg in enumerate(configs):
            if cfg is None:
                ok_t = in_jwst[None, :] & (tgrid[None, :] >= (t_det + args.lead)[:, None])
                sig = np.sqrt(args.sigma0 ** 2
                              + (args.sigma_rate * np.clip(tgrid[None, :] - t_last[:, None], 0, None)) ** 2)
                width, psum = band_width(R_km[j], sig)
                act_w = width
            elif len(cfg) == 2:
                sig, ok_t = path_sigma(*cfg)
                width, psum = band_width(R_km[j], sig)
                act_w = width
            elif len(cfg) == 3:
                sig, ok_t = path_sigma(cfg[0], cfg[1])
                width, psum = band_width_p(R_km[j], sig, cfg[2])
                act_w = width
            else:
                L, jwst_rate, L_ref, p_act = cfg
                s_e, ok_t = path_sigma(L, jwst_rate)
                s_l, _ = path_sigma(L_ref, jwst_rate)
                act_w, width, psum = withdraw_width(R_km[j], s_e, s_l, p_act)
            geo = np.sum(ok_t * rate[None, :], axis=1) * D[j] * n_rad
            cand = np.sum(ok_t * rate[None, :] * width, axis=1) * n_rad
            succ = np.sum(ok_t * rate[None, :] * psum, axis=1) * n_rad
            nact = np.sum(ok_t * rate[None, :] * act_w, axis=1) * n_rad
            ok_speed = np.where(ok_t, speed_t[None, :, j], np.nan)
            track_days = ok_t.sum(axis=1) * T_STEP
            for k in range(len(rows)):
                recs.append((j, sub.cls.values[j], sub.H.values[j], D[j], sub.a.values[j], sub.e.values[j],
                             sub.inc.values[j], float(np.median(delta_t[in_jwst, j])), w_slide,
                             FIELD_NAMES[fld[k] - 1], t_det[k] - t_r0, t_last[k] - t_r0, track_days[k],
                             float(np.nanmean(ok_speed[k])) if track_days[k] > 0 else np.nan,
                             geo[k], cand[k], succ[k], nact[k], -1 if cfg is None else icfg))
    names = ["obj", "cls", "H", "D_km", "a", "e", "inc", "delta_au", "weight", "field", "t_det", "t_last",
             "track_days", "mean_speed", "n_geo", "n_cand", "n_succ", "n_act", "config"]
    tab = Table(rows=recs, names=names) if recs else Table(names=names)
    info = dict(t_r0=t_r0, t_r1=t_r1, t_j0=t_j0, t_j1=t_j1, n_box=int(sel.sum()), tgrid=tgrid,
                speed_example=speed_t, delta_example=delta_t)
    return tab, info


def summarise(tab, sel):
    w = tab["weight"][sel]
    out = dict(n_det=np.sum(w), n_geo=np.sum(w * tab["n_geo"][sel]), n_cand=np.sum(w * tab["n_cand"][sel]),
               n_succ=np.sum(w * tab["n_succ"][sel]))
    if "n_act" in tab.colnames:
        out["n_act"] = np.sum(w * tab["n_act"][sel])
    return out


def trigger_mc(n_cand, n_succ, rng, n_trig=N_TRIGGER, n_mc=200000):
    """Poisson number of candidates, P per candidate drawn to match the mean success per candidate."""
    if n_cand <= 0:
        return 0.0, 0.0, 0.0, 0.0
    p_mean = n_succ / n_cand
    # P over a candidate band ranges from P_TRIGGER to its peak; use a uniform spread with the right mean
    lo, hi = P_TRIGGER, min(1.0, 2 * p_mean - P_TRIGGER)
    N = rng.poisson(n_cand, n_mc)
    succ = np.zeros(n_mc)
    at_least_one = np.zeros(n_mc)
    for m in range(1, N.max() + 1):
        idx = np.flatnonzero(N == m)
        if len(idx) == 0:
            continue
        p = np.sort(rng.uniform(lo, hi, (len(idx), m)), axis=1)[:, ::-1][:, :n_trig]
        succ[idx] = np.sum(p, axis=1)
        hits = rng.uniform(size=p.shape) < p
        at_least_one[idx] = hits.any(axis=1)
    return float(np.mean(N >= n_trig)), float(np.mean(np.minimum(N, n_trig))), float(np.mean(succ)), \
        float(np.mean(at_least_one))


# ---------------------------------------------------------------- analytic estimate
def petit_hot_cumulative(h):
    """Petit et al. (2023): hot main belt = 2.2 x Kavelaars et al. (2021) cold-belt exponential taper."""
    return 2.2 * 10 ** (0.4 * (h + 2.6)) * np.exp(-10 ** (-0.25 * (h - 8.1)))


def lat_density_fraction(beta_deg, sigma_i=12.0):
    """Fraction of a population per steradian at ecliptic latitude beta for p(i) ~ sin i exp(-i^2/2 s^2)."""
    i = np.radians(np.linspace(0.01, 90, 200000))
    p = np.sin(i) * np.exp(-np.degrees(i) ** 2 / (2 * sigma_i ** 2))
    p /= np.trapezoid(p, i)
    sb = np.sin(np.radians(abs(beta_deg)))
    ok = np.sin(i) > sb
    g = np.zeros_like(i)
    g[ok] = 1.0 / (2 * np.pi ** 2 * np.sqrt(np.sin(i[ok]) ** 2 - sb ** 2))
    return np.trapezoid(p * g, i)


def circular_speed_curve(fp, cross, season, dist_au=43.0):
    """Shadow speed versus time for a circular orbit at dist_au placed at the field centre at mid-JWST window."""
    if season == "spring":
        t0, t1 = cross[JWST_ELONG[0]], cross[JWST_ELONG[1]]
    else:
        t0, t1 = cross[JWST_ELONG[1]], cross[JWST_ELONG[0]]
    tg = np.arange(t0, t1, 0.5)
    ro, vo = observer(Time(tg, format="jd"))
    lam, bet = np.radians(fp["lam_c"]), np.radians(fp["beta_c"])
    uc = np.array([np.cos(bet) * np.cos(lam), np.cos(bet) * np.sin(lam), np.sin(bet)])
    # heliocentric position at the mid time, then circular motion in the ecliptic-inclined plane through it
    rm = ro[len(tg) // 2]
    b = rm @ uc
    s = -b + np.sqrt(b * b - rm @ rm + dist_au ** 2)
    p0 = rm + s * uc
    h = np.cross(p0, np.array([0, 0, 1.0]))
    vdir = np.cross(np.array([0, 0, 1.0]), p0)
    vdir /= np.linalg.norm(vdir)
    vc = np.sqrt(K_GAUSS ** 2 / dist_au)
    speeds = []
    for k, t in enumerate(tg):
        ang = vc / dist_au * (t - tg[len(tg) // 2])
        pos = p0 * np.cos(ang) + vdir * dist_au * np.sin(ang)
        vel = (-p0 / dist_au * np.sin(ang) + vdir * np.cos(ang)) * vc
        d = pos - ro[k]
        dh = d / np.linalg.norm(d)
        dv = vel - vo[k]
        vt = dv - (dv @ dh) * dh
        speeds.append(np.linalg.norm(vt) * AUD_TO_KMS)
    del h
    return tg - t0, np.array(speeds)


def analytic(fp, area_deg2, star_density, mean_speed, days_list, args):
    beta = fp["beta_c"]
    f_sr = lat_density_fraction(beta, args.sigma_i)
    per_deg2 = f_sr * (np.pi / 180) ** 2
    dist = 43.0
    alpha = np.degrees(np.arcsin(1.0 / dist))
    h_lim = args.mag_limit + args.colour - 5 * np.log10(dist * dist) - PHASE_COEFF * alpha
    h40 = h_from_d(D_TARGET, args.albedo)
    hh = np.linspace(3.0, h_lim, 4000)
    dN = np.gradient(petit_hot_cumulative(hh), hh)
    n_rad = star_density * (180 / np.pi * 3600) ** 2
    out = dict(beta=beta, f_per_deg2=per_deg2, h_lim=h_lim, h40=h40, D_lim=d_from_h(h_lim, args.albedo),
               N_all=petit_hot_cumulative(h_lim), N_40=petit_hot_cumulative(h40))
    out["n_det_all"] = out["N_all"] * per_deg2 * area_deg2
    out["n_det_40"] = out["N_40"] * per_deg2 * area_deg2
    out["events"] = {}
    for days in days_list:
        L_rad = mean_speed * 86400.0 * days / (dist * AU_KM)
        sumD_all = np.trapezoid(dN * d_from_h(hh, args.albedo), hh) * per_deg2 * area_deg2
        m40 = hh <= h40
        sumD_40 = np.trapezoid(dN[m40] * d_from_h(hh[m40], args.albedo), hh[m40]) * per_deg2 * area_deg2
        single = n_rad * (D_TARGET / (dist * AU_KM)) * L_rad
        out["events"][days] = dict(single40=single, all=n_rad * sumD_all / (dist * AU_KM) * L_rad,
                                   ge40=n_rad * sumD_40 / (dist * AU_KM) * L_rad)
    return out


def parser():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--k-limit", type=float, default=13.5)
    ap.add_argument("--fringe-min", type=float, default=0.7)
    ap.add_argument("--mag-limit", type=float, default=MAG_LIMIT)
    ap.add_argument("--colour", type=float, default=R_MINUS_F146, help="r - F146 (AB)")
    ap.add_argument("--albedo", type=float, default=ALBEDO)
    ap.add_argument("--min-days", type=float, default=MIN_DAYS)
    ap.add_argument("--lead", type=float, default=LEAD_DAYS)
    ap.add_argument("--sigma0", type=float, default=SIGMA0)
    ap.add_argument("--sigma-rate", type=float, default=SIGMA_RATE)
    ap.add_argument("--sigma-i", type=float, default=12.0)
    ap.add_argument("--max-mb", type=float, default=None, help="read only this many MB of the model")
    ap.add_argument("--tag", default="")
    return ap


def main():
    args = parser().parse_args()

    stars = Table.read(os.path.join(OUT, "gbtds_stars.csv"))
    fields = Table.read(os.path.join(OUT, "gbtds_fields.csv"))
    k_sat = stars.meta.get("k_sat_2groups", None)
    if k_sat is None:
        from gbtds_star_catalog import K_MINUS_F200W, VEGA_TO_AB_F200W, FILTER, SUBARRAY
        from occfringe.nircam import saturation_mag
        k_sat = saturation_mag(FILTER, SUBARRAY, ngroups=2) - VEGA_TO_AB_F200W + K_MINUS_F200W
    area = float(fields["area_deg2"][fields["field"] == "ALL"][0])

    def density(klim, fmin=args.fringe_min):
        use = (stars["Ks"] < klim) & (stars["Ks"] > k_sat) & (stars["fringe_retained"] >= fmin)
        return np.sum(use) / (area * 3600.0 ** 2)
    n_star = density(args.k_limit)

    fp = footprint_raster()
    print(f"footprint {fp['area']:.3f} deg^2 (raster), centre ecliptic ({fp['lam_c']:.3f}, {fp['beta_c']:.3f})")
    print(f"usable stars K < {args.k_limit}: {n_star:.4f} arcsec^-2")

    df, scale = load_model(None if args.max_mb is None else args.max_mb * 1e6)
    print(f"model: {len(df)} objects read, scale factor {scale:.3f} -> {len(df) * scale:.3e} objects", flush=True)
    lam_n21, lam_n32 = resonant_neptune_lon(df)
    global MODEL_EPOCH_JD
    MODEL_EPOCH_JD = epoch_from_neptune(0.5 * (lam_n21 + lam_n32))
    print(f"model epoch from resonances: lambda_N = {lam_n21:.2f} (2:1), {lam_n32:.2f} (3:2) ->"
          f" {Time(MODEL_EPOCH_JD, format='jd').iso[:10]}")

    crosses = season_times(np.radians(fp["lam_c"]), np.radians(fp["beta_c"]))
    rng = np.random.default_rng(1)
    results = {}
    for season in ("spring", "autumn"):
        tab, info = run_season(df, scale, fp, season, crosses[season], MODEL_EPOCH_JD, n_star, args)
        results[season] = (tab, info)
        tab.write(os.path.join(OUT, f"tno_rate_objects_{season}{args.tag}.csv"), overwrite=True)

    t_sp, s_sp = circular_speed_curve(fp, crosses["spring"], "spring")
    t_au, s_au = circular_speed_curve(fp, crosses["autumn"], "autumn")
    mean_speed = float(np.mean(s_sp))
    days_user = [50.0, 38.3, 9.0]
    an = analytic(fp, area, n_star, mean_speed, days_user, args)

    write_report(results, an, crosses, fp, area, n_star, density, k_sat, scale, len(df), mean_speed,
                 (t_sp, s_sp, t_au, s_au), rng, args)
    plot(results, (t_sp, s_sp, t_au, s_au), density, k_sat, args)


def write_report(results, an, crosses, fp, area, n_star, density, k_sat, scale, n_read, mean_speed, curves, rng,
                 args):
    t_sp, s_sp, t_au, s_au = curves
    L = [f"# Roman-predicted TNO occultations of GBTDS stars observable by JWST{args.tag}", "",
         "## Inputs", "",
         f"- Footprint {area:.3f} deg^2 (6 WFI pointings), centre ecliptic (lambda, beta) ="
         f" ({fp['lam_c']:.2f}, {fp['beta_c']:.2f}) deg.",
         f"- Usable stars: {k_sat:.2f} < Ks < {args.k_limit}, projected disk keeping >= {args.fringe_min:.0%} of the"
         f" F200W fringe contrast at 43 au: {n_star:.4f} arcsec^-2 (footprint mean).",
         f"- TNO detection: F146 < {args.mag_limit} for >= {args.min_days:g} days inside the detectors during the"
         f" Roman season; r - F146 = {args.colour}, phase coefficient {PHASE_COEFF} mag/deg, albedo {args.albedo}"
         f" -> D = {d_from_h(10.0, args.albedo):.1f} km at H_r = 10;"
         f" D = {D_TARGET:g} km at H_r = {h_from_d(D_TARGET, args.albedo):.2f}.",
         f"- Prediction: cross-track sigma = {args.sigma0:g} km while Roman observes the object, growing by"
         f" {args.sigma_rate:.1f} km/day after its last Roman measurement; first trigger {args.lead:g} days after"
         f" detection. Candidate = predicted P(intercept) >= {P_TRIGGER}.",
         f"- OSSOS++ model: {n_read:,} objects read, scaled by {scale:.2f} (random file order).", "",
         "## Season timing (2027)", "", "| season | Roman start | Roman end | JWST start | JWST end |",
         "|---|---|---|---|---|"]
    for s in ("spring", "autumn"):
        info = results[s][1]
        iso = [Time(info[k], format="jd").iso[:10] for k in ("t_r0", "t_r1", "t_j0", "t_j1")]
        L.append(f"| {s} | " + " | ".join(iso) + " |")
    L += ["", f"Shadow speed of a circular 43 au orbit at the field during the spring JWST window: "
          f"{s_sp.min():.1f}-{s_sp.max():.1f} km/s, mean {np.mean(s_sp):.1f} km/s (autumn: mean {np.mean(s_au):.1f}).", ""]

    L += ["## Model-based expectation per season", "",
          "n_det = TNOs detected; n_geo = shadows crossing usable stars inside the triggerable JWST window with"
          " perfect prediction; n_cand = star-TNO pairs with predicted P >= 0.5; n_succ = expected interceptions"
          " if every such candidate were observed.", "",
          "| season | sample | n_det | n_geo | n_cand | n_succ | P(>= 6 cand) | E[attempts] | E[successes], best 6"
          " | P(>= 1 success) |", "|---|---|---|---|---|---|---|---|---|---|"]
    h40 = h_from_d(D_TARGET, args.albedo)
    for s in ("spring", "autumn"):
        tab = results[s][0]
        if len(tab) == 0:
            continue
        hot = np.array(["cold" not in c for c in tab["cls"]])
        for label, sel in (("all", np.ones(len(tab), bool)), (f"D >= {D_TARGET:g} km", tab["H"] <= h40),
                           (f"D >= {D_TARGET:g} km, no cold classicals", (tab["H"] <= h40) & hot)):
            m = summarise(tab, sel)
            p6, natt, esucc, p1 = trigger_mc(m["n_cand"], m["n_succ"], rng)
            L.append(f"| {s} | {label} | {m['n_det']:.1f} | {m['n_geo']:.2f} | {m['n_cand']:.2f} | "
                     f"{m['n_succ']:.2f} | {p6:.2f} | {natt:.2f} | {esucc:.2f} | {p1:.2f} |")
    tab = results["spring"][0]
    if len(tab):
        sel = tab["H"] <= h40
        w = tab["weight"][sel]
        L += ["", "Spring, D >= 40 km, weighted means: "
              f"distance {np.average(tab['delta_au'][sel], weights=w):.1f} au, triggerable track"
              f" {np.average(tab['track_days'][sel], weights=w):.1f} days, shadow speed"
              f" {np.nanmean(tab['mean_speed'][sel]):.1f} km/s."]
        L += ["", "### Spring, by population (D >= 40 km)", "", "| population | n_det | n_geo | n_cand |", "|---|---|---|---|"]
        groups = {}
        for c in np.unique(tab["cls"][sel]):
            key = c.split("--")[0] if not c.startswith("Resonant") else "--".join(c.split("--")[:2])
            if c.startswith("Classical"):
                key = "Classical cold" if "cold" in c else "Classical hot"
            groups.setdefault(key, []).append(c)
        for key, cl in sorted(groups.items()):
            s2 = sel & np.isin(tab["cls"], cl)
            m = summarise(tab, s2)
            L.append(f"| {key} | {m['n_det']:.2f} | {m['n_geo']:.3f} | {m['n_cand']:.3f} |")
        L += ["", "### Spring, by diameter", "", "| D (km) | n_det | n_geo | n_cand | n_succ |", "|---|---|---|---|---|"]
        edges = [0, 20, 30, 40, 60, 100, 1e4]
        for lo, hi in zip(edges[:-1], edges[1:]):
            s2 = (tab["D_km"] >= lo) & (tab["D_km"] < hi)
            m = summarise(tab, s2)
            L.append(f"| {lo:g}-{hi:g} | {m['n_det']:.1f} | {m['n_geo']:.2f} | {m['n_cand']:.2f} | {m['n_succ']:.2f} |")
        L += ["", "### Spring, D >= 40 km versus stellar magnitude limit", "",
              "| K limit | usable stars (arcsec^-2) | n_geo | n_cand | P(>= 6 cand) | E[successes], best 6 |",
              "|---|---|---|---|---|---|"]
        for kl in (12.5, 13.0, 13.5, 14.0, 14.5):
            f = density(kl) / n_star
            m = summarise(tab, sel)
            p6, _, es, _ = trigger_mc(m["n_cand"] * f, m["n_succ"] * f, rng)
            L.append(f"| {kl} | {density(kl):.4f} | {m['n_geo'] * f:.2f} | {m['n_cand'] * f:.2f} | {p6:.2f} | {es:.2f} |")

    L += ["", "## Analytic estimate (Petit et al. 2023 hot main belt only, 43 au)", "",
          f"- Latitude factor at beta = {an['beta']:.2f} deg, sigma_i = {args.sigma_i} deg:"
          f" {an['f_per_deg2']:.3e} of the population per deg^2.",
          f"- Detection limit H_r < {an['h_lim']:.2f} (D > {an['D_lim']:.1f} km);"
          f" N(<H) = {an['N_all']:.3e} -> {an['n_det_all']:.1f} in the footprint at one instant.",
          f"- D >= {D_TARGET:g} km: H_r < {an['h40']:.2f}, N(<H) = {an['N_40']:.3e} -> {an['n_det_40']:.1f} in the footprint.",
          f"- Mean shadow speed {mean_speed:.1f} km/s.", "",
          "| JWST track (days) | occultations of usable stars by one 40 km TNO | all hot TNOs | hot TNOs D >= 40 km |",
          "|---|---|---|---|"]
    for days, e in an["events"].items():
        L.append(f"| {days:g} | {e['single40']:.4f} | {e['all']:.2f} | {e['ge40']:.2f} |")
    with open(os.path.join(OUT, f"tno_rate{args.tag}.md"), "w") as f:
        f.write("\n".join(L) + "\n")
    print("\n".join(L))


def plot(results, curves, density, k_sat, args):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    t_sp, s_sp, t_au, s_au = curves
    fig, ax = plt.subplots(1, 3, figsize=(16, 4.8))
    a = ax[0]
    a.plot(t_sp, s_sp, label="spring (elongation 85 -> 135)")
    a.plot(t_au, s_au, label="autumn (elongation 135 -> 85)")
    a.set_xlabel("days into the JWST window"); a.set_ylabel("shadow speed (km/s)")
    a.set_title("Circular 43 au orbit at the GBTDS field"); a.legend(fontsize=8); a.grid(alpha=0.3)
    a = ax[1]
    tab = results["spring"][0]
    if len(tab):
        order = np.argsort(tab["D_km"])[::-1]
        dd = tab["D_km"][order]
        a.step(dd, np.cumsum((tab["weight"] * tab["n_cand"])[order]), where="post", label="n_cand (P >= 0.5)")
        a.step(dd, np.cumsum((tab["weight"] * tab["n_geo"])[order]), where="post", label="n_geo (perfect prediction)")
        a.step(dd, np.cumsum((tab["weight"] * tab["n_succ"])[order]), where="post", label="n_succ")
        a.axvline(D_TARGET, c="k", ls=":")
        a.set_xscale("log"); a.set_xlabel("TNO diameter D (km)"); a.set_ylabel("cumulative number (> D) per season")
        a.set_title(f"Spring season, usable stars K < {args.k_limit}"); a.legend(fontsize=8); a.grid(alpha=0.3)
    a = ax[2]
    kl = np.arange(11.5, 14.51, 0.1)
    a.plot(kl, [density(k) for k in kl])
    a.set_yscale("log"); a.set_xlabel("K limit (Vega)"); a.set_ylabel("usable stars per arcsec^2")
    a.set_title(f"GBTDS usable-star density (K > {k_sat:.1f}, fringe >= {args.fringe_min:.0%})"); a.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(os.path.join(OUT, f"tno_rate{args.tag}.png"), dpi=130)


MODEL_EPOCH_JD = None

if __name__ == "__main__":
    main()
