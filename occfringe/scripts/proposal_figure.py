"""Proposal Figure 1: a simulated occultation light curve, shape-marginalised
diameter recovery versus the ETC-calibrated stellar magnitude, and the Cycle 6
event forecast versus the stellar magnitude limit.

The recovery simulations (results/nonsphere/nonsphere_limit.csv) were run
with the occfringe noise model; each simulated magnitude is re-labelled by
the K at which ETC-calibrated 2-pixel-aperture photometry
(results/snr/snr_fringe_limits.csv) delivers the same per-sample F200W S/N.
The example light curve reuses the recovery simulation's truth profiles and
noise model (results/nonsphere/state.pkl).
"""

import pickle
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "results"
OUT = RES / "proposal" / "overleaf" / "roman_targeting"
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "scripts"))

SHAPES = [
    ("sphere", "sphere"),
    ("ellipse 1.3:1", "ellipse 1.3:1"),
    ("contact binary (Arrokoth-like)", "bilobate"),
    ("rough sphere (3% rms)", "rough limb"),
]

EXAMPLE_SHAPE = "contact binary (Arrokoth-like)"
EXAMPLE_K_SIM = 13.5          # occfringe-model magnitude with S/N 36, i.e. K = 14.0 on the ETC scale
EXAMPLE_SPEED = 8e3
EXAMPLE_SEED = 11

# Spring + autumn, D >= 40 km, 12.3 < K, non-disruptive activation 14 d before the event at
# P >= 0.25, JWST ephemeris 1.9 km/d; from results/gbtds/lead_time/lead_time*.md.
K_LIM = np.array([12.5, 13.0, 13.5, 14.0, 14.5])
DENSITY = np.array([0.0012, 0.0064, 0.0172, 0.0284, 0.0391])
CAND_135 = 2.8
SUCC_135 = 1.3
SUCC_PRELAUNCH = 0.85          # events with the pre-launch 3.3 km/d JWST ephemeris, relative
K_EXTRAP = 15.0
DENSITY_EXTRAP = 0.0498


def k_equiv():
    s = pd.read_csv(RES / "snr" / "snr_fringe_limits.csv")
    s = s[(s.strategy == "r=2pix ap") & (s.radius_uas == 0) & (s.speed_kms == 6)]
    k, lsnr = s.K.to_numpy(), np.log10(s.snr_diff.to_numpy())
    slope = (lsnr[-1] - lsnr[-5]) / (k[-1] - k[-5])

    def f(snr):
        ls = np.log10(snr)
        out = np.interp(-ls, -lsnr, k)
        faint = ls < lsnr[-1]
        out[faint] = k[-1] + (ls[faint] - lsnr[-1]) / slope
        bright = ls > lsnr[0]
        out[bright] = k[0] + (ls[bright] - lsnr[0]) / slope
        return out

    return f


def recovery_table():
    d = pd.read_csv(RES / "nonsphere" / "nonsphere_limit.csv")
    d["err_ell"] = np.abs(d.ellipse_D_km / 40.0 - 1)
    d["err_sph"] = np.abs(d.sphere_D_km / 40.0 - 1)
    g = d.groupby(["shape", "speed_kms", "K"])
    t = g.agg(snr=("snr_F200W", "first"),
              ell=("err_ell", lambda x: np.percentile(x, 68)),
              sph=("err_sph", lambda x: np.percentile(x, 68))).reset_index()
    t["K_etc"] = k_equiv()(t.snr.to_numpy())
    return t


def example_panel(ax):
    import nonsphere_limit as ns
    from occfringe import limbfit

    with open(RES / "nonsphere" / "state.pkl", "rb") as fh:
        state = pickle.load(fh)
    rng = np.random.default_rng(EXAMPLE_SEED)
    cd, clean, _ = ns.make_chord(state, EXAMPLE_SHAPE, EXAMPLE_SPEED, EXAMPLE_K_SIM, rng)
    fits = {m: limbfit.fit(cd, m, R_bounds=ns.R_BOUNDS) for m in ("sphere", "ellipse")}
    t = 0.5 * (cd.t_a + cd.t_b)
    t = t - 0.5 * (t.min() + t.max())
    off = (0.0, 1.35)
    for bi, bname in enumerate(ns.BANDS):
        ax.plot(t, cd.data[bi] + off[bi], "o", ms=1.6, color="0.25", zorder=1)
        for m, c, lw in (("sphere", "C1", 0.9), ("ellipse", "C0", 1.2)):
            p = fits[m][0]
            mod = cd.model(limbfit._limbs(m, p), p[limbfit.n_shape(m):])[bi]
            lab = None
            if bi == 0:
                lab = (f"free-ellipse fit, $D_A$ = {2 * p[0] / 1e3:.1f} km" if m == "ellipse"
                       else f"circle fit, $D$ = {2 * p[0] / 1e3:.1f} km")
            ax.plot(t, mod + off[bi], color=c, lw=lw, zorder=2, label=lab)
        ax.text(-6.3, 1.12 + off[bi], bname, fontsize=8)
    ax.set_xlim(-6.5, 6.5)
    ax.set_ylim(-0.8, 2.75)
    ax.set_xlabel("time from mid-event (s)")
    ax.set_ylabel("relative flux (+ offset)")
    ax.set_title(r"simulated event: bilobate, $D_A=40$ km, $K=14$, $v=8$ km s$^{-1}$",
                 fontsize=9)
    ax.legend(fontsize=6.5, loc="lower center", frameon=False, borderaxespad=0.2)

    ins = ax.inset_axes([0.38, 0.36, 0.24, 0.24])
    o = next(s for s in state["shapes"] if s.name == EXAMPLE_SHAPE)
    for poly in o.polygons:
        pp = np.vstack([poly, poly[:1]]) / 1e3
        ins.fill(pp[:, 0], pp[:, 1], color="0.6", lw=0)
    ins.axhline(ns.IMPACT * ns.R_EQ / 1e3, color="C3", lw=0.8)
    ins.set_xlim(-32, 32)
    ins.set_ylim(-26, 26)
    ins.set_aspect("equal")
    ins.axis("off")
    return {m: 2 * fits[m][0][0] / 1e3 for m in fits}


def recovery_panel(ax, t):
    colours = plt.cm.viridis(np.linspace(0, 0.85, len(SHAPES)))
    for (name, label), c in zip(SHAPES, colours):
        for v, ls in ((6.0, "-"), (11.0, "--")):
            s = t[(t["shape"] == name) & (t.speed_kms == v)].sort_values("K_etc")
            ax.plot(s.K_etc, 100 * s.ell, ls, marker="o", color=c, ms=2.5, lw=1.2,
                    label=label if v == 6.0 else None)
    s = t[(t["shape"] == EXAMPLE_SHAPE) & (t.speed_kms == 6.0)].sort_values("K_etc")
    ax.plot(s.K_etc, 100 * s.sph, ":", color="C1", lw=1.2, label="bilobate, circle fit")
    ax.plot([], [], "k-", lw=1, label=r"6 km s$^{-1}$")
    ax.plot([], [], "k--", lw=1, label=r"11 km s$^{-1}$")
    ax.axhline(10, color="0.4", lw=0.8, ls=":")
    ax.set_yscale("log")
    ax.set_ylim(1.5, 70)
    ax.set_yticks([2, 5, 10, 20, 50])
    ax.set_yticklabels(["2", "5", "10", "20", "50"])
    ax.minorticks_off()
    ax.set_xlim(12.8, 17.2)
    ax.set_xlabel(r"$K$ (Vega) of occulted star")
    ax.set_ylabel(r"68th pct. $|\Delta D_A/D_A|$ (%)")
    ax.set_title(r"$D_A$ recovery, free-ellipse fit", fontsize=9)
    ax.grid(alpha=0.25, which="both")
    ax.legend(fontsize=6, loc="lower right", frameon=False, ncol=2, columnspacing=0.8,
              handlelength=1.8)


def forecast_panel(ax):
    scale = DENSITY / DENSITY[2]
    ax.plot(K_LIM, CAND_135 * scale, "o-", color="C0", ms=4,
            label="candidates, $P\\geq0.25$ at 14 d")
    ax.plot(K_LIM, SUCC_135 * scale, "s-", color="C3", ms=4, label="expected occultations")
    se = DENSITY_EXTRAP / DENSITY[2]
    kk = np.append(K_LIM, K_EXTRAP)
    ss = SUCC_135 * np.append(scale, se)
    ax.fill_between(kk, ss * SUCC_PRELAUNCH, ss, color="C3", alpha=0.15, lw=0,
                    label="pre-launch JWST ephemeris")
    ax.plot([14.5, K_EXTRAP], [CAND_135 * scale[-1], CAND_135 * se], "o--", color="C0",
            ms=4, mfc="none")
    ax.plot([14.5, K_EXTRAP], [SUCC_135 * scale[-1], SUCC_135 * se], "s--", color="C3",
            ms=4, mfc="none")
    ax.axhline(9, color="0.4", lw=0.8, ls=":")
    ax.text(12.55, 9.2, "nine requested activations", fontsize=7, color="0.3")
    ax.set_xlabel(r"faint limit $K$ of usable stars")
    ax.set_ylabel(r"number per Cycle 6 (two seasons)")
    ax.set_title(r"forecast, $D\geq40$ km", fontsize=9)
    ax.set_ylim(0, 10.5)
    ax.grid(alpha=0.25)
    ax.legend(fontsize=7, loc="center left", frameon=False)


def main():
    t = recovery_table()
    fig, axes = plt.subplots(1, 3, figsize=(10.5, 3.3),
                             gridspec_kw=dict(width_ratios=[1.45, 1, 0.95]))
    d = example_panel(axes[0])
    recovery_panel(axes[1], t)
    forecast_panel(axes[2])
    fig.tight_layout(w_pad=1.0)
    for ext in ("pdf", "png"):
        fig.savefig(OUT / f"fig_recovery_forecast.{ext}", dpi=200)
    print("example fits (km):", d)
    print(t[t.speed_kms.isin([6.0, 11.0]) & (t.K == 13.5)][["shape", "speed_kms", "K_etc", "ell", "sph"]]
          .to_string())


if __name__ == "__main__":
    main()
