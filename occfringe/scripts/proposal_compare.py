#!/usr/bin/env python3
"""Compare occfringe with the JWST Cycle 6 proposal "Direct Diameters for TNOs from Roman-Predicted
Stellar Occultations" (APT file Roman_JWST_predicted_v4.aptx).

Figure 1 of the proposal was digitised from the PDF's vector paths into
results/proposal/figure1_digitized.json (markers, error bars, model curves).
This script recomputes those light curves with the proposal's stated
parameters, compares noise, saturation and fringe contrast, and repeats the
Fisher diameter precision for the proposal's trigger sizes.  Writes
results/proposal/proposal_compare.{md,png}.
"""
import json
import os
import sys

for _var in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS", "VECLIB_MAXIMUM_THREADS"):
    os.environ.setdefault(_var, "4")

import numpy as np  # noqa: E402
from scipy.optimize import least_squares  # noqa: E402

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from occfringe.bandpass import Bandpass  # noqa: E402
from occfringe.constants import AU, PC, R_SUN, UAS, fresnel_scale  # noqa: E402
from occfringe.diameter import Event, EventConfig, EventModel  # noqa: E402
from occfringe.edge import knife_edge_profile  # noqa: E402
from occfringe.lightcurve import exposure_average, radial_profile  # noqa: E402
from occfringe.nircam import NIRCamSetup, load_filter, saturation_mag  # noqa: E402
from occfringe.star import StellarDisk  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "results", "proposal")

# proposal parameters (Figure 1 caption, observing description, APT file)
DIST_AU = 40.0
IMPACT = 0.45
K_VEGA = 14.0
STAR_RSUN = 12.0
STAR_DIST_PC = 8000.0           # bulge giant; the proposal does not state a distance
TEFF = 4500.0                   # K giant; not stated in the proposal
SPEED_NOMINAL = 6.0e3           # implied by the quoted sample counts (D / v x 16.2 Hz)
T_FRAME = 0.05016
# Vega -> AB offsets for the NIRCam bands (Vega spectrum through each throughput curve)
VEGA_TO_AB = {"F200W": 1.70, "F322W2": 2.60}
K_MINUS_BAND = {"F200W": -0.10, "F322W2": 0.10}   # reddened K giant, Vega colours (assumed)


def band_ab(filt, k=K_VEGA):
    return k - K_MINUS_BAND[filt] + VEGA_TO_AB[filt]


def star_uas():
    return STAR_RSUN * R_SUN / (STAR_DIST_PC * PC) / UAS


def model_curve(D_km, filt, t, speed, t0=0.0, exposure=True, point_source=False):
    z = DIST_AU * AU
    setup = NIRCamSetup(filt, "SUB64P", band_ab(filt))
    band = setup.bandpass(TEFF, 12.0)
    F_min = float(fresnel_scale(band.lam_min, z))
    disk = StellarDisk.point() if point_source else StellarDisk.for_fresnel_scale(star_uas() * UAS * z, F_min)
    R = D_km * 500.0
    b = IMPACT * R
    r_max = np.hypot(speed * np.abs(t - t0).max() + 3 * F_min, b)
    prof = radial_profile(R, z, band, disk, r_out=np.arange(0.0, r_max, F_min / 40.0), left=0.0, right=1.0)

    def fn(tt):
        return prof(np.hypot(speed * (tt - t0), b))
    if not exposure:
        return fn(t)
    return exposure_average(fn, t - 0.5 * T_FRAME, t + 0.5 * T_FRAME, 8)


def first_fringe_contrast(filt, point_source=True):
    """Peak-to-trough of the first straight-edge fringe, band-averaged over monochromatic at the pivot."""
    z = DIST_AU * AU
    band = NIRCamSetup(filt, "SUB64P", 15.0).bandpass(TEFF, 12.0)
    F_min = float(fresnel_scale(band.lam_min, z))
    disk = None if point_source else StellarDisk.for_fresnel_scale(star_uas() * UAS * z, F_min)
    mono = Bandpass(np.array([band.mean]), np.array([1.0]))

    def p2t(bp):
        k = knife_edge_profile(z, bp, disk, window_F=12.0)
        u, I = k.x, k.I
        i_max = np.argmax(I)
        j = i_max + np.argmax((I[i_max + 1:-1] < I[i_max:-2]) & (I[i_max + 1:-1] <= I[i_max + 2:])) + 1
        return I[i_max] - I[j]
    return p2t(band) / p2t(mono), p2t(band)


def fisher_rows():
    rows = []
    for filt in ("F200W", "F322W2"):
        for D_km in (40.0, 80.0, 120.0):
            cfg = EventConfig(radius=D_km * 500.0, distance_au=DIST_AU, speed=SPEED_NOMINAL, impact=IMPACT * D_km * 500,
                              star_uas=star_uas(), filter=filt, mag_ab=band_ab(filt), teff=TEFF, flat_noise=0.0)
            model = EventModel(cfg)
            for v in (6.0e3, 11.0e3):
                ev = Event(model, v, cfg.impact, cfg.mag_ab, rng=np.random.default_rng(1), phase=0.0)
                jac = ev.jacobian("circle", ev.truth)
                cov = np.linalg.inv(jac.T @ jac)
                sR = np.sqrt(cov[0, 0] + cov[1, 1] + 2 * cov[0, 1])
                rows.append(dict(filter=filt, D_km=D_km, v_kms=v / 1e3, R_over_F=cfg.radius / model.F_mid,
                                 n_in_event=int(np.sum(np.abs(0.5 * (ev.t_a + ev.t_b)) < ev.truth[0] / v)),
                                 snr=ev.setup.summary()["snr_per_sample"], sigma_D_frac=sR / cfg.radius,
                                 sigma_chord_m=2 * np.sqrt(cov[0, 0]),
                                 sigma_D_frac_vprior=ev.fisher_sigma_R("circle", speed_prior=1e-4) / cfg.radius))
    return rows


def main():
    os.makedirs(OUT, exist_ok=True)
    fig1 = json.load(open(os.path.join(OUT, "figure1_digitized.json")))
    lines = ["# occfringe vs the Roman-predicted TNO occultation proposal", ""]

    # --- Figure 1 light curves ---------------------------------------------
    fits = {}
    for D in ("10", "20", "40"):
        ct = np.array(fig1[D]["curve_t"])
        cf = np.array(fig1[D]["curve_f"])
        o = np.argsort(ct)
        ct, cf = ct[o], cf[o]

        def resid(p, exposure=True):
            return model_curve(float(D), "F200W", ct, p[0] * 1e3, p[1], exposure=exposure) - cf
        best = {}
        for exposure in (True, False):
            r = least_squares(lambda p: resid(p, exposure), [SPEED_NOMINAL / 1e3, 0.0], x_scale=[0.1, 0.01])
            best[exposure] = (r.x, np.sqrt(np.mean(r.fun ** 2)), np.max(np.abs(r.fun)))
        nominal = resid([SPEED_NOMINAL / 1e3, 0.0])
        pt = model_curve(float(D), "F200W", ct, best[True][0][0] * 1e3, best[True][0][1], point_source=True) - cf
        fits[D] = dict(ct=ct, cf=cf, best=best, nominal=nominal, point=pt)
        print(f"D={D}: best v={best[True][0][0]:.3f} km/s rms={best[True][1]:.4f}", flush=True)

    lines += ["## Figure 1: digitised curves vs occfringe", "",
              f"Parameters: {DIST_AU:g} AU, chord at {IMPACT:g} R, F200W band for a {TEFF:g} K star, "
              f"{STAR_RSUN:g} R_sun at {STAR_DIST_PC / 1e3:g} kpc ({star_uas():.1f} uas radius, "
              f"{star_uas() * UAS * DIST_AU * AU:.0f} m at the occulter), exact circular-body diffraction, "
              "50 ms exposure averaging. Shadow speed and mid-time fitted to the proposal's model curve.", "",
              "| D (km) | best-fit v (km/s) | t0 (ms) | rms diff | max diff | rms diff, no exposure avg | "
              "rms diff at v = 6 km/s | rms diff, point-source star |", "|---|---|---|---|---|---|---|---|"]
    for D, f in fits.items():
        (v, t0), rms, mx = f["best"][True]
        lines.append(f"| {D} | {v:.3f} | {t0 * 1e3:.1f} | {rms:.4f} | {mx:.4f} | {f['best'][False][1]:.4f} | "
                     f"{np.sqrt(np.mean(f['nominal'] ** 2)):.4f} | {np.sqrt(np.mean(f['point'] ** 2)):.4f} |")

    # --- noise and saturation ---------------------------------------------
    s = NIRCamSetup("F200W", "SUB64P", band_ab("F200W"), flat_noise=0.0)
    s_lw = NIRCamSetup("F322W2", "SUB64P", band_ab("F322W2"), flat_noise=0.0)
    comps = s.noise_components(1.0)
    sig_fig = float(np.median(fig1["10"]["sigma"]))
    mag_for_36 = None
    for m in np.arange(13.0, 18.0, 0.01):
        if 1.0 / NIRCamSetup("F200W", "SUB64P", m, flat_noise=0.0, ngroups=10).sigma(1.0) < 36.0:
            mag_for_36 = m
            break
    sat10 = saturation_mag("F200W", "SUB64P", ngroups=10)
    lines += ["", "## Photometry", "",
              f"| quantity | proposal | occfringe |", "|---|---|---|",
              f"| F200W magnitude of the K = {K_VEGA:g} star | K = {K_VEGA:g} (Vega) | AB {band_ab('F200W'):.2f} "
              f"(assumed Vega-AB {VEGA_TO_AB['F200W']:.2f}, K - F200W = {K_MINUS_BAND['F200W']:+.2f}) |",
              f"| S/N per 50 ms sample, unocculted | 36 (sigma = {sig_fig:.4f} in Fig. 1) | "
              f"{1 / s.sigma(1.0):.1f} (shot {comps['shot']:.4f}, read {comps['read']:.4f}, "
              f"dark+bg {comps['background']:.5f}) |",
              f"| sigma in the shadow (flux 0) | same as unocculted ({sig_fig:.4f}) | {s.sigma(0.0):.4f} |",
              f"| AB giving S/N 36 per sample (F200W) | - | {mag_for_36:.2f} |",
              f"| F322W2 S/N per sample (AB {band_ab('F322W2'):.2f}) | not quoted | {1 / s_lw.sigma(1.0):.1f} |",
              f"| 10-group saturation (F200W, 80% well) | K = 12.3 | AB {sat10:.2f} = K {sat10 - VEGA_TO_AB['F200W'] + K_MINUS_BAND['F200W']:.2f} |",
              f"| sample times | uniform 1/16.2 s | 9 x 50.16 ms, then 100 ms reset gap |",
              f"| duty cycle | 81% | {s.duty_cycle:.1%} |"]

    # --- fringe contrast ------------------------------------------------------
    lines += ["", "## Fringe contrast (first straight-edge fringe, peak minus trough in units of the unocculted flux)",
              "", "The proposal's 59% for narrow F212N equals the monochromatic value (1.37 - 0.78 = 0.59), so this is "
              "taken to be its definition.", "",
              "| band | proposal | occfringe, point source | occfringe, 7 uas star | band / monochromatic |",
              "|---|---|---|---|---|"]
    for filt, quoted in (("F200W", "52%"), ("F322W2", "47%")):
        rp, cp = first_fringe_contrast(filt, True)
        _, cs = first_fringe_contrast(filt, False)
        lines.append(f"| {filt} | {quoted} | {cp:.0%} | {cs:.0%} | {rp:.0%} |")
    lam2, _ = load_filter("F200W")
    lam3, _ = load_filter("F322W2")
    from occfringe.nircam import filter_pivot
    ratio = np.sqrt(filter_pivot("F322W2") / filter_pivot("F200W"))
    lines.append(f"\nFringe scale F322W2 / F200W = sqrt(pivot ratio) = {ratio:.3f} (proposal: 27% coarser).")

    # --- Fisher ---------------------------------------------------------------
    rows = fisher_rows()
    lines += ["", "## Diameter precision for the trigger sizes (Fisher, circular body, impact marginalised)", "",
              f"K = {K_VEGA:g}, {star_uas():.1f} uas star, chord at {IMPACT:g} R, readout gaps included, no "
              "flat-field term (to match the proposal's photon + read noise). Proposal: sigma_D/D = 0.6-1.3% "
              "for D = 40-120 km, chord to ~70 m.", "",
              "| filter | D (km) | v (km/s) | R/F | samples in chord | S/N/sample | sigma_D/D (v exact) | "
              "sigma_D/D (v to 1e-4) | sigma chord (m) |", "|---|---|---|---|---|---|---|---|---|"]
    for r in rows:
        lines.append(f"| {r['filter']} | {r['D_km']:g} | {r['v_kms']:g} | {r['R_over_F']:.1f} | {r['n_in_event']} | "
                     f"{r['snr']:.1f} | {r['sigma_D_frac']:.2%} | {r['sigma_D_frac_vprior']:.2%} | "
                     f"{r['sigma_chord_m']:.0f} |")
    with open(os.path.join(OUT, "proposal_compare.md"), "w") as fh:
        fh.write("\n".join(lines) + "\n")
    print("\n".join(lines))

    # --- figure -----------------------------------------------------------------
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, axes = plt.subplots(2, 3, figsize=(13, 6.5), sharex="col", gridspec_kw=dict(height_ratios=[2.2, 1]))
    for k, (D, f) in enumerate(fits.items()):
        (v, t0), rms, _ = f["best"][True]
        ax, rax = axes[0, k], axes[1, k]
        td, fd, sd = (np.array(fig1[D][q]) for q in ("t", "f", "sigma"))
        ax.errorbar(td, fd, sd, fmt="D", ms=2.5, color="#b03060", elinewidth=0.6, alpha=0.7,
                    label="proposal: simulated points")
        ax.plot(f["ct"], f["cf"], color="#1f4fd8", lw=1.2, label="proposal: model curve")
        tt = np.linspace(-5.2, 5.2, 3000)
        ax.plot(tt, model_curve(float(D), "F200W", tt, v * 1e3, t0), "k--", lw=0.9,
                label=f"occfringe (v = {v:.2f} km/s)")
        ax.set_title(f"D = {D} km", fontsize=10)
        rax.plot(f["ct"], -f["best"][True][1] * 0 + (model_curve(float(D), "F200W", f["ct"], v * 1e3, t0) - f["cf"]),
                 "k", lw=0.9, label="occfringe - proposal")
        rax.plot(f["ct"], f["point"], color="C1", lw=0.7, label="same, point-source star")
        rax.fill_between([-5.2, 5.2], -sd[0], sd[0], color="0.9", zorder=0, label=r"proposal $\pm1\sigma$")
        rax.set_xlabel("time [s]")
        rax.set_ylim(-0.08, 0.08)
    axes[0, 0].set_ylabel("relative flux")
    axes[1, 0].set_ylabel("difference")
    axes[0, 0].legend(fontsize=7, loc="lower left")
    axes[1, 0].legend(fontsize=7, loc="lower left")
    fig.tight_layout()
    fig.savefig(os.path.join(OUT, "proposal_compare.png"), dpi=130)


if __name__ == "__main__":
    main()
