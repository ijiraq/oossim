#!/usr/bin/env python3
"""How faint can the star be and still give a 10% diameter for a non-spherical 40 km TNO?

Proposal configuration (Roman_JWST_predicted_v4.aptx): NIRCam SUB64P, RAPID,
10 groups, F200W and F322W2 recorded simultaneously; 40 AU; 12 R_sun bulge
giant; chord at 0.45 R_eq.  True light curves come from strip tilings of each
outline; each noise realisation is fitted with a sphere and with an ellipse
(osculating-circle limb model, occfringe.limbfit) in both bands jointly.  The
area-equivalent diameter D_eq = 2 sqrt(a b) is compared with the truth.

Writes results/nonsphere/nonsphere_limit.{md,csv,png}.

    python scripts/nonsphere_limit.py [--n-real 24] [--jobs 16]
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

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from occfringe import limbfit  # noqa: E402
from occfringe.constants import AU, PC, R_SUN, UAS, fresnel_scale  # noqa: E402
from occfringe.lightcurve import exposure_average, n_substeps  # noqa: E402
from occfringe.nircam import NIRCamSetup  # noqa: E402
from occfringe.shapes import Outline, outline_profile  # noqa: E402
from occfringe.star import StellarDisk  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "results", "nonsphere")
DIST_AU = 40.0
R_EQ = 20e3
IMPACT = 0.45
TEFF = 4500.0
STAR_UAS = 12.0 * R_SUN / (8000.0 * PC) / UAS
BANDS = ("F200W", "F322W2")
K_TO_AB = {"F200W": 1.80, "F322W2": 2.50}     # AB = K(Vega) + offset, reddened K giant (assumed)
BASELINE = 5.0                                 # s of unocculted data either side
MAGS = (12.5, 13.5, 14.5, 15.5, 16.5, 17.5)
SPEEDS = (6e3, 11e3)
# Roman H with albedo 0.03-0.20 brackets D to a factor sqrt(0.20/0.03) = 2.6, i.e. x/÷ 1.63 about nominal.
D_PRIOR = 1.63
R_BOUNDS = (R_EQ / D_PRIOR, R_EQ * D_PRIOR)
CHUNK = 8


def outlines():
    return [
        Outline.circle(R_EQ, name="sphere"),
        Outline.ellipse(np.sqrt(1.3), 1 / np.sqrt(1.3), angle=np.radians(30.0), name="ellipse 1.3:1").scaled_to_radius(R_EQ),
        Outline.ellipse(np.sqrt(2.0), 1 / np.sqrt(2.0), angle=np.radians(60.0), name="ellipse 2:1").scaled_to_radius(R_EQ),
        Outline.contact_binary(angle=np.radians(20.0), name="contact binary (Arrokoth-like)").scaled_to_radius(R_EQ),
        Outline.rough_circle(R_EQ, 0.03 * R_EQ, seed=2, name="rough sphere (3% rms)"),
    ]


ELLIPSE_TRUTH = {"sphere": (1.0, 0.0), "ellipse 1.3:1": (1.3, 30.0), "ellipse 2:1": (2.0, 60.0)}


def setup_state(path):
    z = DIST_AU * AU
    state = dict(libs={}, truth={}, shapes=outlines())
    for band_name in BANDS:
        band = NIRCamSetup(band_name, "SUB64P", 16.0).bandpass(TEFF, 10.0)
        F_min = float(fresnel_scale(band.lam_min, z))
        disk = StellarDisk.for_fresnel_scale(STAR_UAS * UAS * z, F_min)
        state["libs"][band_name] = (band, disk)
    tasks = [(o, band_name) for o in state["shapes"] for band_name in BANDS]
    with Pool(min(len(tasks), os.cpu_count())) as pool:
        profs = pool.map(_truth_task, [(o, state["libs"][bn]) for o, bn in tasks])
        libs = pool.map(_lib_task, [state["libs"][bn] for bn in BANDS])
    for (o, bn), p in zip(tasks, profs):
        state["truth"][(o.name, bn)] = p
    state["libs"] = dict(zip(BANDS, libs))
    with open(path, "wb") as fh:
        pickle.dump(state, fh)
    return state


def _truth_task(args):
    o, (band, disk) = args
    t0 = time.time()
    p = outline_profile(o, IMPACT * R_EQ, DIST_AU * AU, band, disk)
    print(f"  truth {o.name}: {time.time() - t0:.0f}s", flush=True)
    return p


def _lib_task(args):
    band, disk = args
    return limbfit.LimbLibrary(DIST_AU * AU, band, disk, rho_min=5e3)


_STATE = None


def _init(path):
    global _STATE
    with open(path, "rb") as fh:
        _STATE = pickle.load(fh)


def make_chord(state, shape_name, speed, K, rng):
    libs = [state["libs"][b] for b in BANDS]
    profs = [state["truth"][(shape_name, b)] for b in BANDS]
    x_lo = min(p.x.min() for p in profs)
    x_hi = max(p.x.max() for p in profs)
    setups = [NIRCamSetup(b, "SUB64P", K + K_TO_AB[b], ngroups=10) for b in BANDS]
    cycle = 11 * setups[0].t_frame
    t_a, t_b = setups[0].sample_intervals(x_lo / speed - BASELINE, x_hi / speed + BASELINE,
                                          phase=rng.uniform(0.0, cycle))
    n_sub = n_substeps(speed, setups[0].t_frame, libs[0].F_min)
    clean = [exposure_average(lambda t, p=p: p(speed * t), t_a, t_b, n_sub) for p in profs]
    sigma = [s.sigma(c) for s, c in zip(setups, clean)]
    data = [c + s * rng.standard_normal(c.size) for c, s in zip(clean, sigma)]
    return limbfit.ChordData(libs, t_a, t_b, speed, sigma, data=data, n_sub=n_sub), clean, setups


def run_task(args):
    shape_name, speed, K, i0, n_real, seed = args
    rng = np.random.default_rng(seed)
    rows = []
    for i in range(i0, i0 + n_real):
        cd, clean, setups = make_chord(_STATE, shape_name, speed, K, rng)
        row = dict(shape=shape_name, speed_kms=speed / 1e3, K=K, realisation=i, n_samples=cd.t_a.size,
                   snr_F200W=1 / setups[0].sigma(1.0), snr_F322W2=1 / setups[1].sigma(1.0))
        for model in ("sphere", "ellipse"):
            p, c2, sR = limbfit.fit(cd, model, R_bounds=R_BOUNDS)
            row[f"{model}_D_km"] = 2 * p[0] / 1e3
            row[f"{model}_sigma_D_km"] = 2 * sR / 1e3
            row[f"{model}_chi2"] = c2
            if model == "ellipse":
                row["ellipse_axis_ratio"] = float(np.exp(p[1]))
                row["ellipse_theta_deg"] = float(np.degrees(p[2]) % 180.0)
        row["dof"] = 2 * cd.t_a.size
        rows.append(row)
    print(f"  {shape_name:32s} v={speed / 1e3:g} K={K} [{i0}:{i0 + n_real}]: done", flush=True)
    return rows


def model_mismatch(state):
    """chi^2 of the ellipse model at the true ellipse parameters against the tiled truth (noise-free, K=12.5)."""
    out = {}
    rng = np.random.default_rng(0)
    for name, (e, th) in ELLIPSE_TRUTH.items():
        cd, clean, _ = make_chord(state, name, 6e3, 12.5, rng)
        p = np.array([R_EQ, np.log(e), np.radians(th), -IMPACT * R_EQ, 0.0, 1.0, 1.0])
        r = limbfit.residuals(cd, "ellipse", p, clean)
        fisher = limbfit.sigma_R(cd, "ellipse", p, clean)
        out[name] = (float(np.sum(r ** 2)), cd.t_a.size * 2, 2 * fisher / 1e3)
    return out


def summarise(rows):
    groups = {}
    for r in rows:
        groups.setdefault((r["shape"], r["speed_kms"], r["K"]), []).append(r)
    summ = []
    for (shape, v, K), g in sorted(groups.items()):
        s = dict(shape=shape, speed_kms=v, K=K, n=len(g), snr_F200W=g[0]["snr_F200W"])
        for m in ("sphere", "ellipse"):
            err = np.array([x[f"{m}_D_km"] for x in g]) / (2 * R_EQ / 1e3) - 1.0
            s[f"{m}_bias"] = float(np.median(err))
            s[f"{m}_scatter"] = float(1.4826 * np.median(np.abs(err - np.median(err))))
            s[f"{m}_rms"] = float(np.sqrt(np.mean(err ** 2)))
            s[f"{m}_p68"] = float(np.percentile(np.abs(err), 68))
            s[f"{m}_frac10"] = float(np.mean(np.abs(err) < 0.10))
            s[f"{m}_chi2_dof"] = float(np.median([x[f"{m}_chi2"] / x["dof"] for x in g]))
        summ.append(s)
    return summ


def limiting_K(summ, shape, v, key="ellipse_p68", thresh=0.10):
    pts = sorted((s["K"], s[key]) for s in summ if s["shape"] == shape and s["speed_kms"] == v)
    for (k1, e1), (k2, e2) in zip(pts[:-1], pts[1:]):
        if e1 <= thresh < e2:
            return k1 + (k2 - k1) * (np.log(thresh) - np.log(e1)) / (np.log(e2) - np.log(e1))
    return None if pts[0][1] > thresh else f">{pts[-1][0]}"


def plot(state, summ, rows, path):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.gridspec import GridSpec

    shapes = state["shapes"]
    fig = plt.figure(figsize=(12, 7.8))
    gs = GridSpec(3, 5, figure=fig, height_ratios=[0.9, 1.3, 1.6], hspace=0.55, wspace=0.35)
    for k, o in enumerate(shapes):
        ax = fig.add_subplot(gs[0, k])
        for p in o.polygons:
            pp = np.vstack([p, p[:1]]) / 1e3
            ax.fill(pp[:, 0], pp[:, 1], color="0.65", lw=0)
        ax.axhline(IMPACT * R_EQ / 1e3, color="C3", lw=1)
        ax.set_xlim(-32, 32)
        ax.set_ylim(-28, 28)
        ax.set_aspect("equal")
        ax.set_title(o.name.replace(" (Arrokoth-like)", "\n(Arrokoth-like)"), fontsize=8)
        ax.tick_params(labelsize=7)
        if k == 0:
            ax.set_ylabel("km", fontsize=8)

    # example: contact binary at K = 14.5, v = 6 km/s
    rng = np.random.default_rng(5)
    name = shapes[3].name
    cd, clean, _ = make_chord(state, name, 6e3, 14.5, rng)
    fits = {m: limbfit.fit(cd, m, R_bounds=R_BOUNDS) for m in ("sphere", "ellipse")}
    t = 0.5 * (cd.t_a + cd.t_b)
    ax = fig.add_subplot(gs[1, :3])
    off = {"F200W": 0.0, "F322W2": 0.9}
    for bi, bname in enumerate(BANDS):
        ax.errorbar(t, cd.data[bi] + off[bname], cd.sigma[bi], fmt="o", ms=1.5, color="k", ecolor="0.6",
                    elinewidth=0.5, alpha=0.8, zorder=1)
        for m, c in (("sphere", "C1"), ("ellipse", "C0")):
            p = fits[m][0]
            mod = cd.model(limbfit._limbs(m, p), p[limbfit.n_shape(m):])[bi]
            ax.plot(t, mod + off[bname], c, lw=1, zorder=2,
                    label=(f"{m} fit: D = {2 * p[0] / 1e3:.1f} km" if bi == 0 else None))
        ax.text(-5.3, 1.12 + off[bname], bname, fontsize=8)
    ax.set_xlim(-5.5, 6.5)
    ax.set_xlabel("time [s]", fontsize=8)
    ax.set_ylabel("relative flux (+ offset)", fontsize=8)
    ax.set_title(f"{name}, D_eq = 40 km, K = 14.5, v = 6 km/s, chord at 0.45 R", fontsize=9)
    ax.legend(fontsize=7, loc="lower left")
    ax.tick_params(labelsize=7)

    ax = fig.add_subplot(gs[1, 3:])
    for m, c in (("sphere", "C1"), ("ellipse", "C0")):
        p = fits[m][0]
        mods = cd.model(limbfit._limbs(m, p), p[limbfit.n_shape(m):])
        for bi, bname in enumerate(BANDS):
            ax.plot(t, clean[bi] - mods[bi] + 0.25 * bi, c, lw=0.8)
    for bi in range(2):
        ax.fill_between(t, -cd.sigma[bi] + 0.25 * bi, cd.sigma[bi] + 0.25 * bi, color="0.88", zorder=0)
    ax.set_xlim(-5.5, 6.5)
    ax.set_title("truth - fit (noise-free); grey = 1 sigma per sample", fontsize=8)
    ax.set_xlabel("time [s]", fontsize=8)
    ax.tick_params(labelsize=7)

    for j, v in enumerate(SPEEDS):
        ax = fig.add_subplot(gs[2, j * 2:(j * 2) + 2] if j == 0 else gs[2, 2:4])
        for k, o in enumerate(shapes):
            pts = sorted((s["K"], s["ellipse_p68"], s["sphere_p68"]) for s in summ
                         if s["shape"] == o.name and s["speed_kms"] == v / 1e3)
            K = [p[0] for p in pts]
            ax.plot(K, [p[1] for p in pts], "o-", color=f"C{k}", ms=3, lw=1.2, label=o.name)
            ax.plot(K, [p[2] for p in pts], "x--", color=f"C{k}", ms=3, lw=0.8)
        ax.axhline(0.10, color="k", lw=0.8)
        ax.axhspan(0.25, 1.0, color="0.92", zorder=0)
        ax.text(12.4, 0.5, "prior-limited (albedo 0.03-0.20)", fontsize=6, color="0.4")
        ax.axvline(14.0, color="0.5", lw=0.6, ls=":")
        ax.set_yscale("log")
        ax.set_ylim(3e-3, 1.0)
        ax.set_xlabel("K (Vega) of the occulted star", fontsize=8)
        ax.set_title(f"v = {v / 1e3:g} km/s", fontsize=9)
        ax.tick_params(labelsize=7)
        if j == 0:
            ax.set_ylabel(r"68th pct $|D_{fit}/D_{eq} - 1|$", fontsize=8)
    ax.legend(fontsize=6, loc="upper left", title="solid: ellipse fit, dashed: sphere fit", title_fontsize=6)
    ax = fig.add_subplot(gs[2, 4])
    ax.axis("off")
    snr = {s["K"]: s["snr_F200W"] for s in summ if s["shape"] == shapes[0].name and s["speed_kms"] == 6.0}
    ax.text(0.0, 1.0, "F200W S/N per 50 ms sample\n(this model; proposal quotes\n36 at K = 14)\n\n" +
            "\n".join(f"K = {k:g}: {v:.0f}" for k, v in sorted(snr.items())), fontsize=7, va="top")
    fig.savefig(path, dpi=150, bbox_inches="tight")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--n-real", type=int, default=24)
    ap.add_argument("--jobs", type=int, default=os.cpu_count())
    ap.add_argument("--rebuild", action="store_true", help="recompute truth profiles and libraries")
    ap.add_argument("--replot", action="store_true", help="only redraw the figure from the existing csv")
    args = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    state_path = os.path.join(OUT, "state.pkl")
    t0 = time.time()
    if args.rebuild or not os.path.exists(state_path):
        print("building truth profiles and limb libraries", flush=True)
        state = setup_state(state_path)
    else:
        with open(state_path, "rb") as fh:
            state = pickle.load(fh)
    print(f"state ready ({time.time() - t0:.0f}s)", flush=True)
    if args.replot:
        with open(os.path.join(OUT, "nonsphere_limit.csv")) as fh:
            rows = [{k: (v if k == "shape" else float(v)) for k, v in r.items()} for r in csv.DictReader(fh)]
        plot(state, summarise(rows), rows, os.path.join(OUT, "nonsphere_limit.png"))
        return

    mism = model_mismatch(state)
    tasks = [(o.name, v, K, i0, min(CHUNK, args.n_real - i0), 100000 * i + 1000 * j + int(10 * K) + 7 * i0)
             for i, o in enumerate(state["shapes"]) for j, v in enumerate(SPEEDS) for K in MAGS[::-1]
             for i0 in range(0, args.n_real, CHUNK)]
    with Pool(args.jobs, initializer=_init, initargs=(state_path,)) as pool:
        rows = [r for g in pool.imap_unordered(run_task, tasks) for r in g]
    print(f"fits done ({time.time() - t0:.0f}s)", flush=True)

    with open(os.path.join(OUT, "nonsphere_limit.csv"), "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    summ = summarise(rows)

    lines = ["# Diameter of a non-spherical 40 km TNO from one NIRCam chord", "",
             f"{DIST_AU:g} AU; area-equivalent D = {2 * R_EQ / 1e3:g} km; chord at {IMPACT:g} R_eq; "
             f"{STAR_UAS:.1f} uas, {TEFF:g} K star; SUB64P RAPID 10 groups; F200W + F322W2 fitted jointly "
             f"(AB = K + {K_TO_AB['F200W']:.2f} / K + {K_TO_AB['F322W2']:.2f}); {BASELINE:g} s baseline each side; "
             f"flat-field term 1e-3; speed and distance known; {args.n_real} noise realisations per cell. "
             f"Fitted D is bounded to x/÷ {D_PRIOR} of nominal (Roman H with albedo 0.03-0.20), so an "
             f"uninformative chord scatters across that range rather than running away.", "",
             "Error metric: 68th percentile of |D_fit / D_eq - 1| over realisations (includes bias). "
             "Ellipse fit: area-equivalent radius, axis ratio (1-3), orientation, centre; sphere fit: radius, "
             "impact, centre.", "",
             "## Ellipse-model validation (noise-free, K = 12.5, v = 6 km/s)", "",
             "| shape | chi2 of osculating-ellipse model at true parameters vs tiled truth | N samples | "
             "Fisher sigma_D (km) at K = 12.5 |", "|---|---|---|---|"]
    for name, (c2, n, sD) in mism.items():
        lines.append(f"| {name} | {c2:.1f} | {n} | {sD:.2f} |")
    lines += ["", "## Limiting magnitude for a 10% diameter (68% of realisations within 10%)", "",
              "| shape | v = 6 km/s, ellipse fit | v = 11 km/s, ellipse fit | v = 6 km/s, sphere fit | "
              "v = 11 km/s, sphere fit |", "|---|---|---|---|---|"]
    for o in state["shapes"]:
        cells = []
        for key in ("ellipse_p68", "sphere_p68"):
            for v in SPEEDS:
                k = limiting_K(summ, o.name, v / 1e3, key)
                cells.append("never" if k is None else (k if isinstance(k, str) else f"K = {k:.1f}"))
        lines.append(f"| {o.name} | {cells[0]} | {cells[1]} | {cells[2]} | {cells[3]} |")
    lines += ["", "## All cells", "",
              "| shape | v (km/s) | K | S/N F200W | ellipse bias | ellipse scatter | ellipse 68% | "
              "ellipse frac<10% | ellipse chi2/dof | sphere bias | sphere 68% | sphere chi2/dof |",
              "|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for s in summ:
        lines.append(f"| {s['shape']} | {s['speed_kms']:g} | {s['K']:g} | {s['snr_F200W']:.0f} | "
                     f"{s['ellipse_bias']:+.3f} | {s['ellipse_scatter']:.3f} | {s['ellipse_p68']:.3f} | "
                     f"{s['ellipse_frac10']:.0%} | {s['ellipse_chi2_dof']:.2f} | {s['sphere_bias']:+.3f} | "
                     f"{s['sphere_p68']:.3f} | {s['sphere_chi2_dof']:.2f} |")
    with open(os.path.join(OUT, "nonsphere_limit.md"), "w") as fh:
        fh.write("\n".join(lines) + "\n")
    print("\n".join(lines[:40]))
    plot(state, summ, rows, os.path.join(OUT, "nonsphere_limit.png"))
    print(f"total {time.time() - t0:.0f}s")


if __name__ == "__main__":
    main()
