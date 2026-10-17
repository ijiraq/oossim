#!/usr/bin/env python3
"""Per-sample S/N of NIRCam SUB64P/RAPID photometry calibrated to the JWST ETC, and the fainter-star limit
for detecting limb fringes of a 43 au occultation.

Calibration: JWST ETC (Pandeia) runs in results/gbtds/cache/wb*: NIRCam F200W, SUB64P, RAPID, 10 groups,
K0 III spectrum normalised to 2MASS Ks (Vega), 0.15" aperture with a 0.22-0.40" sky annulus.  From each run
the extracted flux, its standard deviation and the detector-plane PSF image are read.  The read-noise term is
recovered from the MULTIACCUM variance used by Pandeia (Robberto 2009, nframe = 1),
    var = 6(n^2+1)/(5n(n+1)) S + 12(n-1)/(n(n+1)) R,   S = signal over (n-1) frame times,
with R = N_pix sigma_read^2 (1 + N_pix / N_sky).

Photometry strategies compared (per 50.16 ms difference of consecutive reads):
    ETC ap      the ETC's 0.15" aperture and annulus, independent differences
    r=2pix ap   2-pixel radius aperture (best fixed aperture for these stars), independent differences
    PSF         PSF-weighted photometry with the ETC PSF, independent differences
    PSF+GLS     PSF-weighted photometry, light curve fitted to the reads (differences with their
                tridiagonal read-noise covariance), the optimal use of the same data

For each strategy, stellar K and projected stellar radius, a single straight-limb crossing is sampled with
the real RAPID pattern (9 differences per 11 frames) and two numbers are computed, averaged over readout phase:
    dchi2_fringe  chi^2 by which the diffraction model beats the best-shifted geometric (no-fringe) edge
    sigma_edge    Fisher 1-sigma limb position [km] with the diffraction model

Writes results/snr/snr_fringe_limits.{md,png,csv}.
"""
import os
import sys

import numpy as np
from scipy.optimize import minimize_scalar

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from occfringe.constants import AU, UAS  # noqa: E402
from occfringe.edge import geometric_edge_profile, knife_edge_profile  # noqa: E402
from occfringe.nircam import DETECTORS, NIRCamSetup  # noqa: E402
from occfringe.star import StellarDisk  # noqa: E402
from occfringe.constants import fresnel_scale  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "results", "snr")

ETC_DIR = os.path.join(os.path.dirname(__file__), "..", "results", "gbtds", "cache")
ETC_NGROUPS = 10
SMALL_AP_PIX = 2.0

T_FRAME = 0.05016
NGROUPS = 10
SW = DETECTORS["SW"]
DARK_BG = SW.dark + 0.2                            # e-/s/pix
FLAT = 1e-3
READ_VAR_PIX = None                                # set from the ETC runs in main()

DIST_AU = 43.0
TEFF = 4500.0
SPEEDS = (3.0, 6.0, 11.0)
K_GRID = np.arange(12.0, 16.51, 0.25)
RADII_UAS = (0.0, 5.0, 10.0, 20.0, 30.0, 45.0)
N_PHASE = 8
DCHI2_DETECT = 25.0


def load_etc_runs():
    """[(K_vega, extracted flux e-/s, sigma e-/s, PSF image e-/s/pix, input dict)] from the ETC output folders."""
    import glob
    import json
    from astropy.io import fits
    runs = []
    for d in sorted(glob.glob(os.path.join(ETC_DIR, "wb*"))):
        inp = json.load(open(os.path.join(d, "input.json")))
        k = float(inp["scene"][0]["spectrum"]["normalization"]["norm_flux"])

        def line(name):
            return float(fits.open(os.path.join(d, "lineplot", f"lineplot_{name}.fits"))[1].data[0][1])
        img = fits.getdata(os.path.join(d, "image", "image_detector.fits"))
        runs.append((k, line("extracted_flux"), line("extracted_noise"), np.asarray(img, float), inp))
    return sorted(runs)


def etc_calibration():
    """Read variance per pixel per read, aperture signal scale and PSF numbers from the ETC runs."""
    runs = load_etc_runs()
    n = ETC_NGROUPS
    T = (n - 1) * T_FRAME
    a = 6 * (n ** 2 + 1) / (5 * n * (n + 1))
    b = 12 * (n - 1) / (n * (n + 1))
    strat = runs[0][4]["strategy"]
    r_ap = strat["aperture_size"] / SW.pixel_scale
    n_ap = np.pi * r_ap ** 2
    n_sky = np.pi * (strat["sky_annulus"][1] ** 2 - strat["sky_annulus"][0] ** 2) / SW.pixel_scale ** 2
    read_var = []
    for k, flux, sig, img, _ in runs:
        R = (sig * T) ** 2 - a * flux * T
        read_var.append(R / b / (n_ap * (1 + n_ap / n_sky)))
    k0, flux0, _, img0, _ = runs[0]
    y, x = np.indices(img0.shape)
    w = img0.clip(0)
    r = np.hypot(y - (w * y).sum() / w.sum(), x - (w * x).sum() / w.sum())
    small = r <= SMALL_AP_PIX
    return dict(runs=runs, k_ref=k0, flux_ap=flux0, flux_img=img0.sum(), psf=img0 / img0.sum(),
                read_var=float(np.mean(read_var)), read_var_each=read_var, n_ap=n_ap, n_sky=n_sky,
                small_frac=img0[small].sum() / img0.sum(), small_n=int(small.sum()))


def psf_effective_npix(cal, k_vega):
    """Read-noise pixel count giving the PSF-weighted S/N of one difference with all the flux as signal."""
    p = cal["psf"] * cal["flux_img"] * 10 ** (-0.4 * (k_vega - cal["k_ref"])) * T_FRAME
    snr2 = np.sum(p ** 2 / (p + 2 * READ_VAR_PIX))
    s = p.sum()
    return (s ** 2 / snr2 - s) / (2 * READ_VAR_PIX)


def strategies(cal):
    s_ap = cal["flux_ap"] * T_FRAME
    s_all = cal["flux_img"] * T_FRAME
    n_psf = psf_effective_npix(cal, cal["k_ref"])
    return {
        "ETC ap": dict(S_ref=s_ap, npix=cal["n_ap"] * (1 + cal["n_ap"] / cal["n_sky"]), gls=False),
        "r=2pix ap": dict(S_ref=s_all * cal["small_frac"], npix=cal["small_n"], gls=False),
        "PSF": dict(S_ref=s_all, npix=n_psf, gls=False),
        "PSF+GLS": dict(S_ref=s_all, npix=n_psf, gls=True),
    }


K_REF = None


def frame_signal(strat, k_vega):
    return strat["S_ref"] * 10 ** (-0.4 * (k_vega - K_REF))


def snr_difference(strat, k_vega):
    """Unocculted S/N of one difference treated on its own (two reads of read noise)."""
    s = frame_signal(strat, k_vega)
    var = s + strat["npix"] * (2 * READ_VAR_PIX + DARK_BG * T_FRAME) + (FLAT * s) ** 2
    return s / np.sqrt(var)


def readout(t_lo, t_hi, phase):
    """Difference intervals (t_a, t_b) and their integration index."""
    cycle = (NGROUPS + 1) * T_FRAME
    starts = np.arange(t_lo - cycle - phase, t_hi + cycle, cycle)
    j = np.arange(1, NGROUPS)
    ta = starts[:, None] + (j[None, :] + 1) * T_FRAME
    idx = np.repeat(np.arange(len(starts))[:, None], len(j), axis=1)
    keep = (ta >= t_lo) & (ta + T_FRAME <= t_hi)
    return ta[keep], ta[keep] + T_FRAME, idx[keep]


def exposure_mean(prof, speed, t0, ta, tb, n_sub=10):
    f = np.linspace(0, 1, n_sub + 1)
    tt = ta[:, None] + (tb - ta)[:, None] * f[None, :]
    w = np.full(n_sub + 1, 1.0 / n_sub)
    w[[0, -1]] *= 0.5
    return (prof(speed * (t0 - tt)) * w).sum(axis=1)


def block_inverse(strat, s, integ):
    """Sparse block-diagonal inverse covariance of the differences (samples ordered by integration)."""
    from scipy.sparse import block_diag
    blocks = []
    for k in np.unique(integ):
        sel = np.flatnonzero(integ == k)
        m = len(sel)
        C = np.diag(s[sel] + strat["npix"] * DARK_BG * T_FRAME + (FLAT * s[sel]) ** 2
                    + 2 * strat["npix"] * READ_VAR_PIX)
        if strat["gls"] and m > 1:
            off = -strat["npix"] * READ_VAR_PIX
            C += np.diag(np.full(m - 1, off), 1) + np.diag(np.full(m - 1, off), -1)
        blocks.append(np.linalg.inv(C))
    return block_diag(blocks, format="csr")


def quad(Cinv, a):
    return float(a @ (Cinv @ a))


def limb_metrics(strat, k_vega, speed_ms, prof, geo, F):
    s0 = frame_signal(strat, k_vega)
    half = 14 * F / speed_ms + 0.3
    dchi, sig = [], []
    for ph in np.linspace(0, (NGROUPS + 1) * T_FRAME, N_PHASE, endpoint=False):
        ta, tb, integ = readout(-half, half, ph)
        m = exposure_mean(prof, speed_ms, 0.0, ta, tb)
        blocks = block_inverse(strat, s0 * np.clip(m, 0, None), integ)
        dt = 1e-3
        J = (exposure_mean(prof, speed_ms, dt, ta, tb) - exposure_mean(prof, speed_ms, -dt, ta, tb)) / (2 * dt) * s0
        fisher = quad(blocks, J)
        sig.append(speed_ms / np.sqrt(fisher) / 1e3)
        def chi(sh):
            return quad(blocks, (m - exposure_mean(geo, speed_ms, sh, ta, tb)) * s0)
        scale = F / speed_ms
        grid = np.linspace(-scale, scale, 41)
        c = [chi(sh) for sh in grid]
        i = int(np.argmin(c))
        res = minimize_scalar(chi, bounds=(grid[max(i - 1, 0)], grid[min(i + 1, len(grid) - 1)]),
                              method="bounded", options={"xatol": 1e-4 * scale})
        dchi.append(min(res.fun, c[i]))
    return float(np.mean(dchi)), float(np.sqrt(np.mean(np.square(sig))))


def main():
    global READ_VAR_PIX, K_REF
    os.makedirs(OUT, exist_ok=True)
    cal = etc_calibration()
    READ_VAR_PIX = cal["read_var"]
    K_REF = cal["k_ref"]
    strats = strategies(cal)
    z = DIST_AU * AU
    band = NIRCamSetup("F200W", "SUB64P", 15.0).bandpass(TEFF, 12.0)
    F = float(fresnel_scale(band.mean, z))
    f_min = float(fresnel_scale(band.lam_min, z))

    occ = NIRCamSetup("F200W", "SUB64P", K_REF + 1.80)
    L = ["# Per-sample S/N (ETC-calibrated) and fringe detectability versus stellar K", "",
         "ETC runs (F200W, SUB64P, RAPID, 10 groups, K0 III, 2MASS Ks Vega, 0.15\" aperture):", "",
         "| Ks (Vega) | extracted flux (e-/s) | sigma (e-/s) | ramp S/N | implied read variance (e-^2/pix/read) |",
         "|---|---|---|---|---|"]
    for (k, flux, sig, _, _), rv in zip(cal["runs"], cal["read_var_each"]):
        L.append(f"| {k:g} | {flux:.0f} | {sig:.1f} | {flux / sig:.1f} | {rv:.0f} |")
    L += ["",
          f"Read noise per read {np.sqrt(READ_VAR_PIX):.1f} e-/pix (CDS {np.sqrt(2 * READ_VAR_PIX):.1f}; JDox"
          f" {SW.cds_read_noise}). Aperture holds {cal['flux_ap'] / cal['flux_img']:.0%} of the PSF image flux;"
          f" a {SMALL_AP_PIX:g}-pixel aperture holds {cal['small_frac']:.0%} in {cal['small_n']} pixels;"
          f" PSF weighting behaves like {strats['PSF']['npix']:.0f} read-noise pixels with all the flux.",
          f"occfringe.nircam predicts {occ.signal_per_sample / T_FRAME:.0f} e-/s in its 2-FWHM aperture for"
          f" Ks = {K_REF:g} (ETC 0.15\" aperture: {cal['flux_ap']:.0f}). Flat-field term {FLAT:g}. All K are Vega.", "",
         "## S/N of a single 50 ms difference (unocculted), versus K (Vega)", "",
         "| K | " + " | ".join(strats) + " |", "|---|" + "---|" * len(strats)]
    for k in (12.0, 12.5, 13.0, 13.5, 14.0, 14.5, 15.0, 15.5, 16.0):
        L.append(f"| {k:.2f} | " + " | ".join(f"{snr_difference(s, k):.1f}" for s in strats.values()) + " |")
    L += ["", "PSF+GLS uses the same electrons as PSF; its gain appears in the fringe and edge metrics below,"
          " not in the single-difference S/N.", ""]

    rows = []
    geo_cache = {}
    for r_uas in RADII_UAS:
        R = r_uas * UAS * z
        disk = None if R == 0 else StellarDisk.for_fresnel_scale(R, f_min, points_per_F=12, max_side=120)
        prof = knife_edge_profile(z, band, disk, window_F=14.0)
        geo = geometric_edge_profile(R) if R > 0 else geometric_edge_profile(1.0)
        geo_cache[r_uas] = (prof, geo)
        for name, st in strats.items():
            for v in SPEEDS:
                for k in K_GRID:
                    dchi, sig = limb_metrics(st, k, v * 1e3, prof, geo, F)
                    rows.append((name, r_uas, R, v, k, snr_difference(st, k), dchi, sig))
        print(f"radius {r_uas} uas done", flush=True)
    from astropy.table import Table
    tab = Table(rows=rows, names=["strategy", "radius_uas", "R_proj_m", "speed_kms", "K", "snr_diff",
                                  "dchi2_fringe", "sigma_edge_km"])
    tab.write(os.path.join(OUT, "snr_fringe_limits.csv"), overwrite=True)

    def k_limit(name, r, v, dchi_min=DCHI2_DETECT):
        s = tab[(tab["strategy"] == name) & (tab["radius_uas"] == r) & (tab["speed_kms"] == v)]
        ok = s["dchi2_fringe"] >= dchi_min
        if not ok.any():
            return "none"
        if ok.all():
            return f">{K_GRID[-1]:.1f}"
        k = np.asarray(s["K"]); d = np.log10(np.asarray(s["dchi2_fringe"]))
        return f"{np.interp(-np.log10(dchi_min), -d, k):.2f}"

    L += [f"## Faintest K (Vega) at which one limb's fringes are detected at dchi2 >= {DCHI2_DETECT:g} (5 sigma)", "",
          f"Straight limb, F200W only, 43 au (F = {F / 1e3:.2f} km). Projected radius = angular radius x"
          f" {UAS * z:.1f} m/uas.", ""]
    for name in strats:
        L += [f"### {name}", "", "| angular radius (uas) | R_proj (m) | " + " | ".join(f"v = {v:g} km/s" for v in SPEEDS)
              + " |", "|---|---|" + "---|" * len(SPEEDS)]
        for r in RADII_UAS:
            L.append(f"| {r:g} | {r * UAS * z:.0f} | " + " | ".join(k_limit(name, r, v) for v in SPEEDS) + " |")
        L.append("")

    L += ["## Limb position precision sigma_edge (km), 10 uas star", "",
          "| K | " + " | ".join(f"{n}, v={v:g}" for n in ("ETC ap", "PSF", "PSF+GLS") for v in (6.0, 11.0))
          + " |", "|---|" + "---|" * 6]
    for k in (13.0, 13.5, 14.0, 14.5, 15.0, 15.5, 16.0):
        vals = []
        for n in ("ETC ap", "PSF", "PSF+GLS"):
            for v in (6.0, 11.0):
                s = tab[(tab["strategy"] == n) & (tab["radius_uas"] == 10.0) & (tab["speed_kms"] == v)
                        & (np.abs(tab["K"] - k) < 1e-6)]
                vals.append(f"{s['sigma_edge_km'][0]:.2f} ({s['dchi2_fringe'][0]:.0f})")
        L.append(f"| {k:.1f} | " + " | ".join(vals) + " |")
    L += ["", "Entries: sigma_edge km (fringe dchi2)."]
    with open(os.path.join(OUT, "snr_fringe_limits.md"), "w") as f:
        f.write("\n".join(L) + "\n")
    print("\n".join(L))
    plot(tab, strats, geo_cache, F)


def plot(tab, strats, geo_cache, F):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(1, 3, figsize=(17, 5))
    kk = np.linspace(12, 16.5, 50)
    for name, st in strats.items():
        ax[0].plot(kk, [snr_difference(st, k) for k in kk], label=name)
    ax[0].set_yscale("log"); ax[0].set_xlabel("K (Vega)"); ax[0].set_ylabel("S/N per 50 ms difference")
    ax[0].grid(alpha=0.3); ax[0].legend(fontsize=8); ax[0].set_title("Single-difference S/N (F200W)")
    for name, ls in (("ETC ap", "--"), ("PSF", "-"), ("PSF+GLS", "-.")):
        for r, c in zip((5.0, 20.0, 45.0), ("C0", "C1", "C3")):
            s = tab[(tab["strategy"] == name) & (tab["radius_uas"] == r) & (tab["speed_kms"] == 6.0)]
            ax[1].plot(s["K"], s["dchi2_fringe"], ls=ls, c=c, label=f"{name}, {r:g} uas")
    ax[1].axhline(DCHI2_DETECT, c="k", lw=0.8); ax[1].set_yscale("log")
    ax[1].set_xlabel("K (Vega)"); ax[1].set_ylabel("fringe detection dchi2, one limb")
    ax[1].set_title("v = 6 km/s, 43 au"); ax[1].legend(fontsize=6, ncol=2); ax[1].grid(alpha=0.3)
    u = np.linspace(-6 * F, 3 * F, 800)
    for r, c in zip((5.0, 20.0, 45.0), ("C0", "C1", "C3")):
        prof, geo = geo_cache[r]
        ax[2].plot(u / 1e3, prof(u), c=c, label=f"{r:g} uas ({r * UAS * DIST_AU * AU:.0f} m)")
    ax[2].set_xlabel("distance from limb (km, lit side > 0)"); ax[2].set_ylabel("relative flux")
    ax[2].set_title("F200W straight-limb profile"); ax[2].legend(fontsize=8); ax[2].grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(os.path.join(OUT, "snr_fringe_limits.png"), dpi=130)


if __name__ == "__main__":
    main()
