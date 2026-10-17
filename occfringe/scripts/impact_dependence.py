#!/usr/bin/env python3
"""Diameter recovery versus impact parameter for the 1.3:1 ellipse (K = 13.5 star).

Same configuration as nonsphere_limit.py (40 AU, SUB64P RAPID 10 groups,
F200W + F322W2 fitted jointly, D_eq = 40 km, albedo-range prior on D), but
with the chord at b = 0, 0.45 and 0.85 R_eq.  Each noise realisation is
fitted with the free-ellipse osculating-limb model and D_eq = 2 sqrt(ab) is
compared with the truth.

Writes results/impact/impact_dependence.{md,csv,png}.

    python scripts/impact_dependence.py [--n-real 48] [--jobs 14] [--replot]
"""
import argparse
import csv
import os
import pickle
import sys
import time
from multiprocessing import Pool

for _var in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS", "VECLIB_MAXIMUM_THREADS"):
    os.environ.setdefault(_var, "1")

import numpy as np  # noqa: E402

sys.path.insert(0, os.path.dirname(__file__))
import nonsphere_limit as NS  # noqa: E402
from nonsphere_limit import BANDS, DIST_AU, R_BOUNDS, R_EQ, STAR_UAS, TEFF, limbfit  # noqa: E402
from occfringe.constants import AU, UAS, fresnel_scale  # noqa: E402
from occfringe.nircam import NIRCamSetup  # noqa: E402
from occfringe.shapes import outline_profile  # noqa: E402
from occfringe.star import StellarDisk  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "results", "impact")
SHAPE = "ellipse 1.3:1"
AXIS_RATIO, THETA_DEG = NS.ELLIPSE_TRUTH[SHAPE]
IMPACTS = (0.0, 0.45, 0.85)
K_MAG = 13.5
SPEEDS = NS.SPEEDS
CHUNK = 8


def _outline():
    return next(o for o in NS.outlines() if o.name == SHAPE)


def _truth_task(args):
    b, band_name = args
    z = DIST_AU * AU
    band = NIRCamSetup(band_name, "SUB64P", 16.0).bandpass(TEFF, 10.0)
    disk = StellarDisk.for_fresnel_scale(STAR_UAS * UAS * z, float(fresnel_scale(band.lam_min, z)))
    t0 = time.time()
    p = outline_profile(_outline(), b * R_EQ, z, band, disk)
    print(f"  truth b={b} {band_name}: {time.time() - t0:.0f}s", flush=True)
    return p


def setup_state(path):
    with open(os.path.join(NS.OUT, "state.pkl"), "rb") as fh:
        base = pickle.load(fh)
    state = dict(libs=base["libs"], truth={}, outline=_outline())
    todo = []
    for b in IMPACTS:
        for bn in BANDS:
            if b == NS.IMPACT:
                state["truth"][(b, bn)] = base["truth"][(SHAPE, bn)]
            else:
                todo.append((b, bn))
    with Pool(len(todo)) as pool:
        for key, p in zip(todo, pool.map(_truth_task, todo)):
            state["truth"][key] = p
    with open(path, "wb") as fh:
        pickle.dump(state, fh)
    return state


def chord(state, b, speed, K, rng):
    sub = dict(libs=state["libs"], truth={(SHAPE, bn): state["truth"][(b, bn)] for bn in BANDS})
    return NS.make_chord(sub, SHAPE, speed, K, rng)


_STATE = None


def _init(path):
    global _STATE
    with open(path, "rb") as fh:
        _STATE = pickle.load(fh)


def run_task(args):
    b, speed, i0, n, seed = args
    rng = np.random.default_rng(seed)
    rows = []
    for i in range(i0, i0 + n):
        cd, clean, setups = chord(_STATE, b, speed, K_MAG, rng)
        p, c2, sR = limbfit.fit(cd, "ellipse", R_bounds=R_BOUNDS)
        rows.append(dict(impact=b, speed_kms=speed / 1e3, realisation=i, D_km=2 * p[0] / 1e3,
                         sigma_D_km=2 * sR / 1e3, axis_ratio=float(np.exp(p[1])),
                         theta_deg=float(np.degrees(p[2]) % 180.0), yc_km=p[3] / 1e3,
                         chi2=c2, dof=2 * cd.t_a.size, snr_F200W=1 / setups[0].sigma(1.0)))
    print(f"  b={b} v={speed / 1e3:g} [{i0}:{i0 + n}] done", flush=True)
    return rows


def truth_checks(state):
    """Noise-free fit and Fisher sigma_D at the true parameters for each impact."""
    out = {}
    for b in IMPACTS:
        rng = np.random.default_rng(0)
        cd, clean, _ = chord(state, b, SPEEDS[0], K_MAG, rng)
        p_true = np.array([R_EQ, np.log(AXIS_RATIO), np.radians(THETA_DEG), -b * R_EQ, 0.0, 1.0, 1.0])
        fisher = 2 * limbfit.sigma_R(cd, "ellipse", p_true, clean) / 1e3
        p, c2, _ = limbfit.fit(cd, "ellipse", data=clean, R_bounds=R_BOUNDS)
        lim = limbfit.ellipse_limbs(R_EQ, AXIS_RATIO, np.radians(THETA_DEG), 0.0, -b * R_EQ)
        out[b] = dict(fisher_D_km=fisher, noisefree_D_km=2 * p[0] / 1e3, noisefree_e=float(np.exp(p[1])),
                      chord_km=(lim[1].x - lim[0].x) / 1e3, rho_km=(lim[0].rho / 1e3, lim[1].rho / 1e3))
    return out


def summarise(rows):
    groups = {}
    for r in rows:
        groups.setdefault((r["impact"], r["speed_kms"]), []).append(r)
    summ = []
    for (b, v), g in sorted(groups.items()):
        err = np.array([x["D_km"] for x in g]) / (2 * R_EQ / 1e3) - 1.0
        e = np.array([x["axis_ratio"] for x in g])
        summ.append(dict(impact=b, speed_kms=v, n=len(g), bias=float(np.median(err)),
                         scatter=float(1.4826 * np.median(np.abs(err - np.median(err)))),
                         p68=float(np.percentile(np.abs(err), 68)), frac10=float(np.mean(np.abs(err) < 0.10)),
                         e_med=float(np.median(e)), e_p16=float(np.percentile(e, 16)),
                         e_p84=float(np.percentile(e, 84)),
                         sigma_D_med=float(np.median([x["sigma_D_km"] for x in g])),
                         chi2_dof=float(np.median([x["chi2"] / x["dof"] for x in g]))))
    return summ


def plot(state, rows, summ, path):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.gridspec import GridSpec

    D0 = 2 * R_EQ / 1e3
    colors = {b: f"C{k}" for k, b in enumerate(IMPACTS)}
    fig = plt.figure(figsize=(12, 8.2))
    gs = GridSpec(3, 3, figure=fig, height_ratios=[1.0, 1.1, 1.1], hspace=0.5, wspace=0.28)

    ax = fig.add_subplot(gs[0, 0])
    for p in state["outline"].polygons:
        pp = np.vstack([p, p[:1]]) / 1e3
        ax.fill(pp[:, 0], pp[:, 1], color="0.7", lw=0)
    for b in IMPACTS:
        ax.axhline(b * R_EQ / 1e3, color=colors[b], lw=1.2, label=f"b = {b:g} R")
    ax.set_xlim(-30, 30)
    ax.set_ylim(-25, 25)
    ax.set_aspect("equal")
    ax.set_title(f"{SHAPE} at {THETA_DEG:g} deg, D_eq = {D0:g} km", fontsize=9)
    ax.set_xlabel("km", fontsize=8)
    ax.legend(fontsize=7, loc="lower left")
    ax.tick_params(labelsize=7)

    # example light curves (F200W) with an ellipse fit, v = 6 km/s
    ax = fig.add_subplot(gs[0, 1:])
    rng = np.random.default_rng(11)
    for k, b in enumerate(IMPACTS):
        cd, clean, _ = chord(state, b, SPEEDS[0], K_MAG, rng)
        p, c2, _ = limbfit.fit(cd, "ellipse", R_bounds=R_BOUNDS)
        mod = cd.model(limbfit._limbs("ellipse", p), p[5:])[0]
        t = 0.5 * (cd.t_a + cd.t_b)
        off = 1.1 * (len(IMPACTS) - 1 - k)
        ax.errorbar(t, cd.data[0] + off, cd.sigma[0], fmt="o", ms=1.2, color="k", ecolor="0.7", elinewidth=0.4,
                    zorder=1)
        ax.plot(t, mod + off, colors[b], lw=1.1, zorder=2)
        ax.text(3.6, off + 0.35, f"b = {b:g}: D = {2 * p[0] / 1e3:.1f} km, e = {np.exp(p[1]):.2f}",
                fontsize=7, color=colors[b])
    ax.set_xlim(-4.5, 5.5)
    ax.set_xlabel("time [s]", fontsize=8)
    ax.set_ylabel("F200W flux (+ offset)", fontsize=8)
    ax.set_title(f"example realisations, K = {K_MAG:g}, v = {SPEEDS[0] / 1e3:g} km/s (ellipse fits, both bands)",
                 fontsize=9)
    ax.tick_params(labelsize=7)

    bins = np.linspace(-0.4, 0.4, 33)
    for j, v in enumerate(SPEEDS):
        ax = fig.add_subplot(gs[1, j])
        for b in IMPACTS:
            err = np.array([r["D_km"] for r in rows if r["impact"] == b and r["speed_kms"] == v / 1e3]) / D0 - 1
            s = next(s for s in summ if s["impact"] == b and s["speed_kms"] == v / 1e3)
            ax.hist(np.clip(err, bins[0], bins[-1]), bins, histtype="step", color=colors[b], lw=1.4,
                    label=f"b = {b:g}: 68% |err| = {s['p68']:.1%}")
        ax.axvspan(-0.1, 0.1, color="0.93", zorder=0)
        ax.set_xlabel(r"$D_{fit}/D_{eq} - 1$", fontsize=8)
        ax.set_title(f"v = {v / 1e3:g} km/s", fontsize=9)
        ax.legend(fontsize=7, loc="upper left")
        ax.tick_params(labelsize=7)
        if j == 0:
            ax.set_ylabel("realisations", fontsize=8)

    ax = fig.add_subplot(gs[1, 2])
    for j, (v, mk) in enumerate(zip(SPEEDS, ("o", "s"))):
        for b in IMPACTS:
            sel = [r for r in rows if r["impact"] == b and r["speed_kms"] == v / 1e3]
            ax.plot([r["axis_ratio"] + 0.0 for r in sel], [r["D_km"] / D0 - 1 for r in sel], mk, ms=2.5,
                    color=colors[b], alpha=0.6, mfc="none" if j else colors[b],
                    label=f"b = {b:g}" if j == 0 else None)
    ax.axvline(AXIS_RATIO, color="k", lw=0.7, ls=":")
    ax.axhline(0.0, color="k", lw=0.7, ls=":")
    ax.set_ylim(-0.5, 0.5)
    ax.set_xlabel("fitted axis ratio (filled 6, open 11 km/s)", fontsize=8)
    ax.set_ylabel(r"$D_{fit}/D_{eq} - 1$", fontsize=8)
    ax.legend(fontsize=7)
    ax.tick_params(labelsize=7)

    ax = fig.add_subplot(gs[2, :])
    ax.axis("off")
    hdr = ["b / R", "v (km/s)", "chord (km)", "bias", "scatter", "68% |err|", "within 10%", "fitted e (16-84%)",
           r"Fisher $\sigma_D/D$", r"$\chi^2$/dof"]
    cells = []
    for s in summ:
        cells.append([f"{s['impact']:g}", f"{s['speed_kms']:g}", f"{state['checks'][s['impact']]['chord_km']:.1f}",
                      f"{s['bias']:+.1%}", f"{s['scatter']:.1%}", f"{s['p68']:.1%}", f"{s['frac10']:.0%}",
                      f"{s['e_med']:.2f} ({s['e_p16']:.2f}-{s['e_p84']:.2f})",
                      f"{s['sigma_D_med'] / D0:.1%}", f"{s['chi2_dof']:.2f}"])
    tab = ax.table(cellText=cells, colLabels=hdr, loc="center", cellLoc="center")
    tab.auto_set_font_size(False)
    tab.set_fontsize(7.5)
    tab.auto_set_column_width(list(range(len(hdr))))
    tab.scale(1.0, 1.25)
    fig.savefig(path, dpi=150, bbox_inches="tight")


def _read_csv(path):
    with open(path) as fh:
        return [{k: float(v) for k, v in r.items()} for r in csv.DictReader(fh)]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--n-real", type=int, default=48)
    ap.add_argument("--jobs", type=int, default=os.cpu_count())
    ap.add_argument("--rebuild", action="store_true")
    ap.add_argument("--replot", action="store_true")
    args = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    state_path = os.path.join(OUT, "state.pkl")
    t0 = time.time()
    if args.rebuild or not os.path.exists(state_path):
        print("building truth profiles", flush=True)
        state = setup_state(state_path)
    else:
        with open(state_path, "rb") as fh:
            state = pickle.load(fh)
    if "checks" not in state:
        state["checks"] = truth_checks(state)
        with open(state_path, "wb") as fh:
            pickle.dump(state, fh)
    print(f"state ready ({time.time() - t0:.0f}s)", flush=True)
    csv_path = os.path.join(OUT, "impact_dependence.csv")

    if args.replot:
        rows = _read_csv(csv_path)
    else:
        tasks = [(b, v, i0, min(CHUNK, args.n_real - i0), 10000 * k + 1000 * j + 7 * i0 + 3)
                 for k, b in enumerate(IMPACTS) for j, v in enumerate(SPEEDS) for i0 in range(0, args.n_real, CHUNK)]
        with Pool(args.jobs, initializer=_init, initargs=(state_path,)) as pool:
            rows = [r for g in pool.imap_unordered(run_task, tasks) for r in g]
        with open(csv_path, "w", newline="") as fh:
            w = csv.DictWriter(fh, fieldnames=list(rows[0]))
            w.writeheader()
            w.writerows(rows)
        print(f"fits done ({time.time() - t0:.0f}s)", flush=True)
    summ = summarise(rows)

    D0 = 2 * R_EQ / 1e3
    n = int(max(r["realisation"] for r in rows)) + 1
    lines = [f"# D_eq recovery versus impact parameter: {SHAPE} ({THETA_DEG:g} deg), K = {K_MAG:g}", "",
             f"{DIST_AU:g} AU; D_eq = {D0:g} km; SUB64P RAPID 10 groups; F200W + F322W2 fitted jointly with the "
             f"free-ellipse osculating-limb model; D bounded to x/÷ {NS.D_PRIOR} of nominal; {n} noise realisations "
             f"per row. S/N per 50 ms F200W sample = {rows[0]['snr_F200W']:.0f}.", "",
             "## Geometry and noise-free checks (v = 6 km/s)", "",
             "| b / R | chord (km) | limb curvature radii (km) | Fisher sigma_D at truth (km) | "
             "noise-free fit D (km) | noise-free fit e |", "|---|---|---|---|---|---|"]
    for b, c in state["checks"].items():
        lines.append(f"| {b:g} | {c['chord_km']:.1f} | {c['rho_km'][0]:.1f}, {c['rho_km'][1]:.1f} | "
                     f"{c['fisher_D_km']:.2f} | {c['noisefree_D_km']:.2f} | {c['noisefree_e']:.3f} |")
    lines += ["", "## Noisy realisations", "",
              "| b / R | v (km/s) | bias | scatter (MAD) | 68% abs error | within 10% | fitted e median (16-84%) | "
              "median Fisher sigma_D (km) | chi2/dof |", "|---|---|---|---|---|---|---|---|---|"]
    for s in summ:
        lines.append(f"| {s['impact']:g} | {s['speed_kms']:g} | {s['bias']:+.3f} | {s['scatter']:.3f} | "
                     f"{s['p68']:.3f} | {s['frac10']:.0%} | {s['e_med']:.2f} ({s['e_p16']:.2f}-{s['e_p84']:.2f}) | "
                     f"{s['sigma_D_med']:.2f} | {s['chi2_dof']:.2f} |")
    a_km, b_km = R_EQ * np.sqrt(AXIS_RATIO) / 1e3, R_EQ / np.sqrt(AXIS_RATIO) / 1e3
    lines += ["", "## Notes", "",
              "- A central chord (b = 0) crosses two point-symmetric limbs with identical curvature, so nothing in "
              "the light curve distinguishes the ellipse from a circle whose diameter is about the chord length. "
              "The noise-free fit prefers a near-circle (e ~ 1.02) with a *lower* chi2 than the true ellipse "
              "(the difference is within the osculating-limb model systematic), so D_eq is biased toward the chord "
              f"length. Over all orientations a central chord of this body spans {2 * b_km:.1f}-{2 * a_km:.1f} km, "
              f"i.e. {2 * b_km / D0 - 1:+.0%} to {2 * a_km / D0 - 1:+.0%} in D; 30 deg gives +5%.",
              "- Off-centre chords hit limbs with different curvature radii and oblique crossing angles; the "
              "fringes measure both, which pins down the axis ratio (e = 1.30 +/- 0.03 at K = 13.5) and removes "
              "the bias. Grazing chords (b = 0.85) do slightly better than b = 0.45 despite a chord half as long.",
              "- Fisher sigma_D grows with b (shorter chord), but the realised error is dominated by the shape "
              "degeneracy, which shrinks with b."]
    with open(os.path.join(OUT, "impact_dependence.md"), "w") as fh:
        fh.write("\n".join(lines) + "\n")
    print("\n".join(lines))
    plot(state, rows, summ, os.path.join(OUT, "impact_dependence.png"))
    print(f"total {time.time() - t0:.0f}s")


if __name__ == "__main__":
    main()
