"""JWST activation lead time vs yield of Roman-predicted TNO occultations.

A non-disruptive JWST ToO must be activated >= 14 days before the event, so the
hit probability that is realised is the one computed at activation, from the
Roman arc in hand at that moment, with both the object ephemeris and the JWST
ephemeris extrapolated to the event.  For each event epoch t and lead L:

    arc used     = [first Roman detection, min(last Roman detection, t - L)]
    requirement  = object already detected (min_days of Roman data) by t - L
    sigma_cross^2 = sigma_obj(arc, t - arc_end)^2 * (40 km / D)^4
                    + floor^2 + sigma_star^2 + (JWST rate * L)^2

sigma_obj is the linearised single-season orbit covariance of path_covariance.py.
"""
import os
import sys
import numpy as np
from astropy.table import Table
from astropy.time import Time
from scipy.interpolate import RegularGridInterpolator
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

sys.path.insert(0, os.path.dirname(__file__))
import gbtds_tno_rate as g
import path_covariance as pc

OUT = os.path.join(g.OUT, "lead_time")
PRIOR = (10.0, 0.15)
ARC = np.arange(2.0, 76.0, 1.0)
EXT = np.arange(0.0, 111.0, 1.0)
CONFIG_SETS = {
    "leads": [None, (2, 1.9), (5, 1.9), (7, 1.9), (10, 1.9), (14, 1.9), (21, 1.9), (5, 3.3), (14, 3.3)],
    # (lead, JWST km/d, threshold): activate and execute every passage with P >= threshold.
    # (lead, JWST km/d, refinement lead, threshold): activate on P >= threshold, withdraw before
    # execution unless the refined P >= 0.5.
    "withdraw": [None, (7, 1.9), (14, 1.9), (14, 1.9, 0.3), (14, 1.9, 0.2), (14, 3.3, 0.3),
                 (14, 1.9, 7, 0.3), (14, 1.9, 7, 0.2)],
    "adopted": [None, (14, 1.9, 0.25), (14, 3.3, 0.25)],
}
CONFIGS = CONFIG_SETS[os.environ.get("CONFIG_SET", "leads")]
SIG1_SCALE = float(os.environ.get("SIG1_SCALE", "1.0"))
TAG = os.environ.get("LEAD_TAG", "")


def make_sigtab(fp, cross, season):
    t_r0, t_r1 = sorted([cross[g.ROMAN_ELONG[0]], cross[g.ROMAN_ELONG[1]]])
    tab, s1 = pc.sigma_table(np.radians(fp["lam_c"]), np.radians(fp["beta_c"]), t_r0, t_r1, ARC, EXT, prior=PRIOR,
                              sigma1_scale=SIG1_SCALE)
    tab = np.where(np.isfinite(tab), tab, 1e6)
    logi = RegularGridInterpolator((ARC, EXT), np.log(np.clip(tab, 1e-3, 1e6)), bounds_error=False, fill_value=None)

    def f(T, ext):
        T = np.asarray(T, float)
        pts = np.stack([np.clip(T, ARC[0], ARC[-1]), np.clip(ext, EXT[0], EXT[-1])], axis=-1)
        s = np.exp(logi(pts))
        return np.where(T < ARC[0], 1e6, s)
    return f, tab, s1


def main():
    os.makedirs(OUT, exist_ok=True)
    args = g.parser().parse_args(sys.argv[1:])
    stars = Table.read(os.path.join(g.OUT, "gbtds_stars.csv"))
    fields = Table.read(os.path.join(g.OUT, "gbtds_fields.csv"))
    k_sat = stars.meta.get("k_sat_2groups", 12.3)
    area = float(fields["area_deg2"][fields["field"] == "ALL"][0])
    use = (stars["Ks"] < args.k_limit) & (stars["Ks"] > k_sat) & (stars["fringe_retained"] >= args.fringe_min)
    n_star = np.sum(use) / (area * 3600.0 ** 2)
    print(f"usable stars K < {args.k_limit}: {n_star:.4f} arcsec^-2", flush=True)

    fp = g.footprint_raster()
    crosses = g.season_times(np.radians(fp["lam_c"]), np.radians(fp["beta_c"]))
    args.sigtab, tabs = {}, {}
    for season in ("spring", "autumn"):
        f, tab, s1 = make_sigtab(fp, crosses[season], season)
        args.sigtab[season], tabs[season] = f, tab
        print(f"{season}: sigma_1 = {s1[0]:.1f} mas (F146 {s1[1]:.2f}) for D = 40 km", flush=True)
    np.savez(os.path.join(OUT, f"sigma_tables{TAG}.npz"), arc=ARC, ext=EXT, **tabs)
    args.act_leads = CONFIGS
    args.d_ref, args.sig_floor, args.sig_star = pc.D_REF, 3.0, 2.9

    df, scale = g.load_model(None if args.max_mb is None else args.max_mb * 1e6)
    lam_n21, lam_n32 = g.resonant_neptune_lon(df)
    g.MODEL_EPOCH_JD = g.epoch_from_neptune(0.5 * (lam_n21 + lam_n32))
    print(f"model {len(df)} objects, epoch {Time(g.MODEL_EPOCH_JD, format='jd').iso[:10]}", flush=True)

    res = {}
    for season in ("spring", "autumn"):
        tab, info = g.run_season(df, scale, fp, season, crosses[season], g.MODEL_EPOCH_JD, n_star, args)
        tab.write(os.path.join(OUT, f"objects_{season}{TAG}.csv"), overwrite=True)
        res[season] = tab
    report(res, tabs, n_star)


def report(res, tabs, n_star):
    L = [f"# Activation lead time vs yield (K < 13.5, per season pair){TAG}", "",
         f"Per-exposure astrometric error scale {SIG1_SCALE} x nominal.", "",
         "Config: lead L days, JWST cross-track ephemeris growth [km/day].  'baseline' is the"
         " proposal's earlier model (sigma0 = 20 km, 5-day detection-to-event, arc runs to the event).",
         " Withdraw configs: activate at lead L on P >= p_act, withdraw before execution unless the"
         " prediction refined at L_ref has P >= 0.5; 'cand' = executed visits, 'act' = activations.",
         "", "| config | sample | cand spring | cand autumn | cand total | act total | succ total | mean P |",
         "|---|---|---|---|---|---|---|---|"]
    for icfg, cfg in enumerate(CONFIGS):
        key = -1 if cfg is None else icfg
        if cfg is None:
            label = "baseline"
        elif len(cfg) == 2:
            label = f"L = {cfg[0]} d, JWST {cfg[1]} km/d"
        elif len(cfg) == 3:
            label = f"L = {cfg[0]} d, JWST {cfg[1]} km/d, P >= {cfg[2]}"
        else:
            label = f"L = {cfg[0]} d, JWST {cfg[1]} km/d, P_act >= {cfg[3]}, refine at {cfg[2]} d"
        for sname, dmin in (("D >= 40", 40.0), ("D >= 60", 60.0)):
            c, s, a = {}, {}, {}
            for season, tab in res.items():
                sel = (tab["config"] == key) & (tab["D_km"] >= dmin)
                m = g.summarise(tab, sel)
                c[season], s[season], a[season] = m["n_cand"], m["n_succ"], m.get("n_act", m["n_cand"])
            ct, st, at = sum(c.values()), sum(s.values()), sum(a.values())
            L.append(f"| {label} | {sname} | {c['spring']:.2f} | {c['autumn']:.2f} | {ct:.2f} | {at:.2f} |"
                     f" {st:.2f} | {st / ct if ct else 0:.2f} |")
    L += ["", "## sigma_obj(arc, extrapolation) for D = 40 km [km], spring / autumn", ""]
    for season, tab in tabs.items():
        L += [f"### {season}", "", "| arc (d) | +0 | +7 | +14 | +21 | +30 |", "|---|---|---|---|---|---|"]
        for a in (20, 29, 40, 48, 60, 70):
            i = int(np.flatnonzero(ARC == a)[0])
            L.append(f"| {a} | " + " | ".join(f"{tab[i, int(e)]:.0f}" for e in (0, 7, 14, 21, 30)) + " |")
        L.append("")
    with open(os.path.join(OUT, f"lead_time{TAG}.md"), "w") as fh:
        fh.write("\n".join(L) + "\n")
    print("\n".join(L))

    fig, ax = plt.subplots(1, 2, figsize=(10, 4))
    for a, col in ((29, "C3"), (48, "C1"), (70, "C0")):
        i = int(np.flatnonzero(ARC == a)[0])
        for D, ls in ((40, "-"), (80, "--")):
            s = np.sqrt((tabs["spring"][i] * (40 / D) ** 2) ** 2 + 3.0 ** 2 + 2.9 ** 2)
            ax[0].plot(EXT, s, ls, color=col, label=f"{a}-d arc, D = {D} km")
    ax[0].set(xlim=(0, 30), ylim=(0, 100), xlabel="days from last astrometry to event",
              ylabel="object cross-track 1-sigma (km)", title="spring season")
    ax[0].legend(fontsize=7)
    for rate, mk, ls in ((1.9, "o", "-"), (3.3, "s", "none")):
        for season, col in (("spring", "C0"), ("autumn", "C1"), ("both", "k")):
            xs, ys = [], []
            for icfg, cfg in enumerate(CONFIGS):
                if cfg is None or len(cfg) != 2 or cfg[1] != rate:
                    continue
                tot = 0.0
                for s in (("spring", "autumn") if season == "both" else (season,)):
                    tab = res[s]
                    tot += g.summarise(tab, (tab["config"] == icfg) & (tab["D_km"] >= 40))["n_succ"]
                xs.append(cfg[0])
                ys.append(tot)
            ax[1].plot(xs, ys, marker=mk, ls=ls, color=col,
                       label=f"{season}, JWST {rate} km/d" if rate == 1.9 or season == "both" else None)
    ax[1].axvline(14, color="0.6", lw=0.8, ls=":")
    ax[1].set(xlabel="activation lead (days)", ylabel="expected events, D >= 40 km, K < 13.5", ylim=(0, None))
    ax[1].legend(fontsize=7)
    fig.tight_layout()
    fig.savefig(os.path.join(OUT, f"lead_time{TAG}.png"), dpi=130)


if __name__ == "__main__":
    main()
