#!/usr/bin/env python3
"""Radius-precision grid for JWST/NIRCam observations of TNO occultation limbs.

For every (distance, radius, filter, stellar size) a curvature library is built
once and shared by all (speed, impact, magnitude) cases.  Writes a CSV table,
a markdown summary and diagnostic plots to --out.

    python scripts/run_diameter_grid.py [--grid quick|coarse|full] --jobs 16
"""
import argparse
import csv
import itertools
import os
import sys
import time
from multiprocessing import Pool

for _var in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS", "VECLIB_MAXIMUM_THREADS"):
    os.environ.setdefault(_var, "1")

import numpy as np  # noqa: E402

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from occfringe.diameter import EventConfig, EventModel, run_case  # noqa: E402
from occfringe.nircam import saturation_mag  # noqa: E402

FULL = dict(distance_au=[30, 40, 50], radius_km=[5, 10, 20, 50, 100, 300], speed_kms=[10, 25],
            impact=[0.0, 0.5, 0.9], filter=["F150W", "F200W", "F356W", "F444W"],
            star_uas=[1, 10, 30, 100], dmag=[0.5, 2.0, 4.0, 6.0, 8.0])
QUICK = dict(distance_au=[40], radius_km=[10, 50, 200], speed_kms=[10],
             impact=[0.0, 0.5], filter=["F150W", "F356W"], star_uas=[10, 30], dmag=[2.0])
# hand-picked (distance AU, radius km, filter, star uas) libraries spanning R/F ~ 2-150 and R*/F ~ 0.01-1
COARSE = dict(groups=[(40, 5, "F150W", 10), (40, 10, "F200W", 1), (40, 10, "F444W", 30),
                      (40, 20, "F356W", 10), (40, 50, "F150W", 30), (40, 50, "F444W", 100),
                      (40, 100, "F200W", 10), (40, 100, "F356W", 1), (40, 300, "F150W", 100),
                      (40, 300, "F444W", 10)],
              speed_kms=[10], impact=[0.0, 0.5, 0.9], dmag=[2.0, 4.0, 6.0])
GRIDS = dict(quick=QUICK, coarse=COARSE, full=FULL)

SUBARRAY = "SUB64P"
THRESHOLD = 0.10


def run_group(args):
    (dist, rkm, filt, star), grid, seed, speed_prior, flat_noise = args
    t0 = time.time()
    msat = saturation_mag(filt, SUBARRAY)
    cfg = EventConfig(radius=rkm * 1e3, distance_au=dist, speed=grid["speed_kms"][0] * 1e3, impact=0.0,
                      star_uas=star, filter=filt, subarray=SUBARRAY, mag_ab=msat + 2, flat_noise=flat_noise)
    rows = []
    try:
        model = EventModel(cfg)
    except Exception as exc:  # keep the grid running; report the failure
        return [dict(distance_au=dist, radius=rkm * 1e3, filter=filt, star_uas=star, error=repr(exc))]
    rng = np.random.default_rng(seed)
    for v, b, dm in itertools.product(grid["speed_kms"], grid["impact"], grid["dmag"]):
        try:
            row = run_case(model, v * 1e3, b * rkm * 1e3, msat + dm, rng=rng, speed_prior=speed_prior)
        except Exception as exc:
            row = dict(distance_au=dist, radius=rkm * 1e3, filter=filt, star_uas=star, speed=v * 1e3,
                       impact=b * rkm * 1e3, mag_ab=msat + dm, error=repr(exc))
        row.update(radius_km=rkm, speed_kms=v, impact_frac=b, dmag_sat=dm, m_sat=msat)
        rows.append(row)
    print(f"  D={dist} R={rkm}km {filt} R*={star}uas: {len(rows)} cases, {time.time() - t0:.1f}s", flush=True)
    return rows


def write_csv(rows, path):
    keys = []
    for r in rows:
        keys += [k for k in r if k not in keys]
    with open(path, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=keys)
        w.writeheader()
        w.writerows(rows)


def _fmt(x):
    if x is None or not np.isfinite(x):
        return "inf"
    return f"{x:.3g}"


def summarise(rows, path, grid, speed_prior):
    ok = [r for r in rows if "error" not in r and r.get("n_samples", 0) > 0]
    err = [r for r in rows if "error" in r]
    lines = ["# Radius precision from NIRCam limb diffraction", "",
             f"Subarray {SUBARRAY}; magnitudes are m_sat(ngroups=2) + dmag; threshold sigma_R/R = {THRESHOLD:.0%}.",
             f"Cases: {len(rows)} ({len(ok)} fitted, {len(err)} errors).", "",
             "Columns: `circle` = Fisher sigma_R/R with the exact circular-limb model (speed known); "
             f"`circle+v` = same with a {speed_prior:.1%} shadow-speed prior; `knife` = straight-edge "
             "fringes only (no curvature); `chord` = no fringes (geometric edge smoothed by star and "
             "exposure); `knife bias` = median (R_knife - R)/sigma of the straight-edge fit; "
             "`dchi2 knife` = median expected chi^2 penalty of the straight-edge model. "
             "Values are medians over speed, impact and magnitude.", ""]

    hdr = "| D (AU) | R (km) | filter | R* (uas) | R/F | R*/F | circle | circle+v | knife | chord | knife bias | dchi2 knife | frac < 10% |"
    lines += ["## Median over speed, impact and magnitude", "", hdr, "|" + "---|" * (hdr.count("|") - 1)]
    groups = {}
    for r in ok:
        groups.setdefault((r["distance_au"], r["radius_km"], r["filter"], r["star_uas"]), []).append(r)
    for key in sorted(groups):
        g = groups[key]
        med = lambda k: float(np.median([x[k] for x in g]))  # noqa: E731
        frac_ok = np.mean([x["frac_sigma_R_fisher_vprior"] < THRESHOLD for x in g])
        lines.append(f"| {key[0]} | {key[1]} | {key[2]} | {key[3]} | {med('R_over_F'):.1f} | "
                     f"{med('Rstar_over_F'):.2f} | {_fmt(med('frac_sigma_R_fisher'))} | "
                     f"{_fmt(med('frac_sigma_R_fisher_vprior'))} | {_fmt(med('frac_knife_sigma_R_fisher'))} | "
                     f"{_fmt(med('frac_geometric_sigma_R_fisher'))} | {med('knife_bias_sigma'):.2g} | "
                     f"{med('dchi2_knife_expected'):.3g} | {frac_ok:.0%} |")

    for title, fields in (("magnitude offset from saturation", ("filter", "dmag_sat")),
                          ("impact parameter (b/R)", ("impact_frac",)),
                          ("impact parameter and magnitude offset", ("impact_frac", "dmag_sat"))):
        head = " | ".join(fields)
        lines += ["", f"## By {title}", "",
                  f"| {head} | mag range | median circle | median circle+v | median knife | median chord | "
                  "frac(circle+v < 10%) | frac(chord < 10%) |",
                  "|" + "---|" * (len(fields) + 7)]
        groups = {}
        for r in ok:
            groups.setdefault(tuple(r[f] for f in fields), []).append(r)
        for key in sorted(groups):
            g = groups[key]
            med = lambda k: float(np.median([x[k] for x in g]))  # noqa: E731
            mags = [x["mag_ab"] for x in g]
            lines.append(f"| {' | '.join(str(k) for k in key)} | {min(mags):.1f}-{max(mags):.1f} | "
                         f"{_fmt(med('frac_sigma_R_fisher'))} | {_fmt(med('frac_sigma_R_fisher_vprior'))} | "
                         f"{_fmt(med('frac_knife_sigma_R_fisher'))} | {_fmt(med('frac_geometric_sigma_R_fisher'))} | "
                         f"{np.mean([x['frac_sigma_R_fisher_vprior'] < THRESHOLD for x in g]):.0%} | "
                         f"{np.mean([x['frac_geometric_sigma_R_fisher'] < THRESHOLD for x in g]):.0%} |")

    edge = sum(bool(r.get("circle_at_library_edge")) for r in ok)
    lines += ["", f"Circular fits at the edge of the curvature library: {edge} of {len(ok)}."]
    if err:
        lines += ["", "## Errors", ""] + [f"- {r.get('distance_au')} AU, R={r.get('radius')}, {r.get('filter')}, "
                                          f"R*={r.get('star_uas')}: {r['error']}" for r in err[:20]]
    with open(path, "w") as fh:
        fh.write("\n".join(lines) + "\n")


def plots(rows, out, example):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    ok = [r for r in rows if "error" not in r and r.get("n_samples", 0) > 0]

    fig, axes = plt.subplots(1, len({r["filter"] for r in ok}), figsize=(4.2 * len({r["filter"] for r in ok}), 3.8),
                             sharey=True, squeeze=False)
    for ax, filt in zip(axes[0], sorted({r["filter"] for r in ok})):
        for key, style in (("frac_sigma_R_fisher", "o-"), ("frac_sigma_R_fisher_vprior", "s--"),
                           ("frac_knife_sigma_R_fisher", "^:"), ("frac_geometric_sigma_R_fisher", "x-.")):
            sel = [r for r in ok if r["filter"] == filt]
            radii = sorted({r["radius_km"] for r in sel})
            med = [np.median([r[key] for r in sel if r["radius_km"] == R]) for R in radii]
            ax.plot(radii, med, style, label=key.replace("frac_", "").replace("_sigma_R_fisher", "")
                    .replace("sigma_R_fisher", "circle").replace("circle_vprior", "circle+v") or "circle")
        ax.axhline(THRESHOLD, color="k", lw=0.8)
        ax.set_xscale("log")
        ax.set_yscale("log")
        ax.set_title(filt)
        ax.set_xlabel("R (km)")
    axes[0][0].set_ylabel(r"median $\sigma_R/R$")
    axes[0][0].legend(fontsize=7)
    fig.tight_layout()
    fig.savefig(os.path.join(out, "sigmaR_vs_R.png"), dpi=130)
    plt.close(fig)

    fig, ax = plt.subplots(figsize=(5, 3.8))
    for filt in sorted({r["filter"] for r in ok}):
        sel = [r for r in ok if r["filter"] == filt]
        ax.scatter([r["R_over_F"] for r in sel], [r["curvature_signal"] for r in sel], s=10, label=filt)
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_xlabel("R / F")
    ax.set_ylabel("max |I_circle - I_knife|")
    ax.legend(fontsize=7)
    fig.tight_layout()
    fig.savefig(os.path.join(out, "curvature_signal.png"), dpi=130)
    plt.close(fig)

    if example is not None:
        example_plots(plt, out, *example)


def example_plots(plt, out, model, speed, impact, mags):
    """Simulated ingress/egress with per-sample error bars, residuals, and the noise budget."""
    from occfringe.diameter import Event

    cfg = model.cfg
    events = [Event(model, speed, impact, m, rng=np.random.default_rng(3)) for m in mags]
    fig, axes = plt.subplots(2, 2 * len(mags), figsize=(4.2 * 2 * len(mags), 6.2),
                             gridspec_kw=dict(height_ratios=[2.2, 1]), sharex="col")
    for k, (ev, mag) in enumerate(zip(events, mags)):
        t = 0.5 * (ev.t_a + ev.t_b)
        L = ev.truth[0]
        for j, sgn in enumerate((-1, 1)):
            ax, rax = axes[0, 2 * k + j], axes[1, 2 * k + j]
            edge = sgn * L / speed
            win = np.abs(t - edge) < 10 * model.F_mid / speed
            tt = np.linspace(t[win].min(), t[win].max(), 2000)
            smooth = {m: model.flux(m, ev.truth, tt, tt, speed, 1) for m in ("circle", "knife", "geometric")}
            for m, c in (("geometric", "C2"), ("knife", "C1"), ("circle", "C0")):
                ax.plot(tt, smooth[m], c, lw=1, label=m, zorder=1)
            ax.errorbar(t[win], ev.data[win], ev.sigma[win], fmt="o", ms=2, color="k", ecolor="0.35",
                        elinewidth=0.8, capsize=1.5, label=r"simulated $\pm1\sigma$", zorder=2)
            geo = model.flux("geometric", ev.truth, ev.t_a[win], ev.t_b[win], speed, ev.n_sub)
            rax.errorbar(t[win], ev.data[win] - geo, ev.sigma[win], fmt="o", ms=2, color="k", ecolor="0.35",
                         elinewidth=0.8, capsize=1.5, label="data - geometric", zorder=2)
            rax.plot(tt, smooth["knife"] - smooth["geometric"], "C1", lw=1, label="knife - geometric", zorder=1)
            rax.plot(tt, smooth["circle"] - smooth["geometric"], "C0", lw=0.8, ls="--", label="circle - geometric",
                     zorder=1)
            rax.axhline(0, color="C2", lw=0.8)
            rax.set_xlabel("t (s)")
            ax.set_title(f"{'ingress' if sgn < 0 else 'egress'}, AB {mag:.1f} "
                         f"(median $\\sigma$ = {np.median(ev.sigma[win]):.2%})", fontsize=9)
        axes[0, 2 * k].set_ylabel("relative flux")
        axes[1, 2 * k].set_ylabel("flux - geometric")
    axes[0, 0].legend(fontsize=7, loc="center left")
    axes[1, 0].legend(fontsize=7, loc="lower left")
    fig.suptitle(f"R={cfg.radius / 1e3:g} km, {cfg.distance_au} AU, {cfg.filter} {cfg.subarray}, "
                 f"R*={cfg.star_uas} uas, v={speed / 1e3:g} km/s, b={impact / cfg.radius:.1f}R; errors: shot + read "
                 f"+ dark/background + flat-field {cfg.flat_noise:.1e}", fontsize=9)
    fig.tight_layout()
    fig.savefig(os.path.join(out, "example_lightcurve.png"), dpi=130)
    plt.close(fig)

    f = np.linspace(0.0, 1.4, 200)
    fig, axes = plt.subplots(1, len(mags), figsize=(4.5 * len(mags), 3.6), sharey=True, squeeze=False)
    for ax, ev, mag in zip(axes[0], events, mags):
        comps = ev.setup.noise_components(f)
        for name, c in comps.items():
            ax.plot(f, c, label=name)
        ax.plot(f, ev.setup.sigma(f), "k", lw=1.5, label="total")
        ax.set_yscale("log")
        ax.set_xlabel("relative flux")
        ax.set_title(f"{cfg.filter} {cfg.subarray}, AB {mag:.1f}, ngroups={ev.setup.ngroups}", fontsize=9)
    axes[0][0].set_ylabel(r"$\sigma$ per sample (fraction of unocculted flux)")
    axes[0][0].legend(fontsize=7)
    fig.tight_layout()
    fig.savefig(os.path.join(out, "noise_budget.png"), dpi=130)
    plt.close(fig)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--grid", choices=sorted(GRIDS), default="coarse",
                    help="quick: smoke test; coarse: 10 libraries at 40 AU for development; full: proposal grid")
    ap.add_argument("--jobs", type=int, default=os.cpu_count())
    ap.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "..", "results", "diameter"))
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--speed-prior", type=float, default=0.01, help="fractional shadow-speed uncertainty")
    ap.add_argument("--flat-noise", type=float, default=1e-3,
                    help="fractional flat-field/jitter error per sample")
    args = ap.parse_args()

    grid = GRIDS[args.grid]
    os.makedirs(args.out, exist_ok=True)
    keys = grid.get("groups") or list(itertools.product(grid["distance_au"], grid["radius_km"], grid["filter"],
                                                        grid["star_uas"]))
    tasks = [(k, grid, args.seed + i, args.speed_prior, args.flat_noise) for i, k in enumerate(keys)]
    print(f"{len(keys)} libraries, {len(keys) * len(grid['speed_kms']) * len(grid['impact']) * len(grid['dmag'])} "
          f"cases on {args.jobs} processes", flush=True)
    t0 = time.time()
    with Pool(args.jobs) as pool:
        rows = [r for group in pool.imap_unordered(run_group, tasks) for r in group]
    print(f"grid done in {time.time() - t0:.0f}s", flush=True)

    write_csv(rows, os.path.join(args.out, f"diameter_{args.grid}.csv"))
    summarise(rows, os.path.join(args.out, f"diameter_{args.grid}.md"), grid, args.speed_prior)

    rkm, filt, star = 50, "F150W", 10
    msat = saturation_mag(filt, SUBARRAY)
    cfg = EventConfig(radius=rkm * 1e3, distance_au=40, speed=10e3, impact=0.5 * rkm * 1e3, star_uas=star,
                      filter=filt, subarray=SUBARRAY, mag_ab=msat + 2, flat_noise=args.flat_noise)
    plots(rows, args.out, (EventModel(cfg), 10e3, 0.5 * rkm * 1e3, [msat + 2, msat + 6]))
    print(f"wrote results to {os.path.abspath(args.out)}")


if __name__ == "__main__":
    main()
