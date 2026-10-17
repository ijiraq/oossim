#!/usr/bin/env python3
"""Fringes from non-circular occulters, and what a circular-limb fit makes of them.

Each outline (circle, ellipse, rough limbs, Arrokoth-like contact binaries) is
scaled to the same area-equivalent radius, tiled with fine strips, and its
band/star-averaged chord profile turned into a simulated NIRCam light curve.
The circular-limb, straight-edge and geometric models of occfringe.diameter are
then fitted.  Writes results/shapes/shape_fringes.{md,png}.

    python scripts/shape_fringes.py [--radius-km 20] [--filter F150W] [--impact 0.3]
"""
import argparse
import os
import sys
import time
from multiprocessing import Pool

for _var in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS", "VECLIB_MAXIMUM_THREADS"):
    os.environ.setdefault(_var, "1")

import numpy as np  # noqa: E402

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from occfringe.diameter import MODELS, Event, EventConfig, EventModel  # noqa: E402
from occfringe.nircam import saturation_mag  # noqa: E402
from occfringe.shapes import Outline, outline_profile  # noqa: E402


def outlines(R):
    return [
        Outline.circle(R, name="circle"),
        Outline.ellipse(1.0, 0.7, angle=np.radians(30.0), name="ellipse 1.4:1, 30 deg").scaled_to_radius(R),
        Outline.rough_circle(R, 0.01 * R, seed=2, name="rough limb, rms 1% R"),
        Outline.rough_circle(R, 0.03 * R, seed=2, name="rough limb, rms 3% R"),
        Outline.contact_binary(angle=0.0, name="contact binary, long axis along track").scaled_to_radius(R),
        Outline.contact_binary(angle=np.radians(60.0), name="contact binary, 60 deg").scaled_to_radius(R),
    ]


def profile_task(args):
    outline, b, cfg = args
    t0 = time.time()
    model = EventModel(cfg)
    prof = outline_profile(outline, b, cfg.z, model.band, model.disk, window_F=cfg.window_F)
    print(f"  {outline.name}: {time.time() - t0:.0f}s", flush=True)
    return prof


def analyse(outline, prof, model, speed, b, mag, seed):
    cfg = model.cfg
    ev = Event(model, speed, b, mag, rng=np.random.default_rng(seed), truth_profile=prof)
    iv = outline.intervals(b)
    x_in, x_out = iv.min(), iv.max()
    L = 0.5 * (x_out - x_in)
    ev.truth = np.array([L, max(cfg.radius - L, 0.0), 0.5 * (x_in + x_out) / speed, 1.0])
    row = dict(shape=outline.name, R_eq_km=cfg.radius / 1e3, chord_km=2 * L / 1e3, n_intervals=len(iv),
               n_samples=ev.t_a.size, dof=ev.t_a.size - 4)
    fits = {}
    for m in MODELS:
        theta, chi2, sR = ev.fit(m)
        theta_clean, chi2_clean, _ = ev.fit(m, data=ev.clean)
        fits[m] = theta
        fits[f"{m}_noiseless"] = theta_clean
        row.update({f"{m}_R_km": (theta[0] + theta[1]) / 1e3, f"{m}_sigma_R_km": sR / 1e3, f"{m}_chi2": chi2,
                    f"{m}_chi2_noiseless": chi2_clean})
    return row, ev, fits


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--radius-km", type=float, default=20.0, help="area-equivalent radius")
    ap.add_argument("--distance-au", type=float, default=40.0)
    ap.add_argument("--filter", default="F150W")
    ap.add_argument("--star-uas", type=float, default=10.0)
    ap.add_argument("--impact", type=float, default=0.3, help="chord offset / R_eq")
    ap.add_argument("--speed-kms", type=float, default=10.0)
    ap.add_argument("--dmag", type=float, default=2.0, help="magnitudes fainter than SUB64P saturation")
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "..", "results", "shapes"))
    args = ap.parse_args()

    R = args.radius_km * 1e3
    b = args.impact * R
    speed = args.speed_kms * 1e3
    mag = saturation_mag(args.filter, "SUB64P") + args.dmag
    cfg = EventConfig(radius=R, distance_au=args.distance_au, speed=speed, impact=b, star_uas=args.star_uas,
                      filter=args.filter, mag_ab=mag)
    shapes = outlines(R)
    print(f"{len(shapes)} outlines, R_eq = {args.radius_km:g} km, b = {args.impact:g} R_eq", flush=True)
    with Pool(min(args.jobs, len(shapes))) as pool:
        profiles = pool.map(profile_task, [(o, b, cfg) for o in shapes])

    model = EventModel(cfg)
    results = [analyse(o, p, model, speed, b, mag, seed=10 + i) for i, (o, p) in enumerate(zip(shapes, profiles))]
    os.makedirs(args.out, exist_ok=True)

    lines = ["# Fringes from non-circular occulters", "",
             f"Area-equivalent radius {args.radius_km:g} km at {args.distance_au:g} AU "
             f"(R_eq/F = {R / model.F_mid:.1f}), {args.filter} SUB64P, AB {mag:.1f} "
             f"(saturation + {args.dmag:g}), {args.star_uas:g} uas star, v = {args.speed_kms:g} km/s, "
             f"chord at y = {args.impact:g} R_eq. Profiles from strip tilings (F/40) of each outline; "
             "fits use the circular-limb (library within +/-35% of R_eq), straight-edge and geometric models.", "",
             "`chi2/dof` is for one noisy realisation; `noiseless chi2` is the misfit to the noise-free light curve "
             "(the systematic part: > ~10 means the model is detectably wrong).", "",
             "| shape | chord (km) | circle R (km) | circle chi2/dof | circle noiseless chi2 | knife R (km) | "
             "knife noiseless chi2 | geometric noiseless chi2 |", "|---|---|---|---|---|---|---|---|"]
    for row, _, _ in results:
        lines.append(f"| {row['shape']} | {row['chord_km']:.2f} | {row['circle_R_km']:.2f} +/- "
                     f"{row['circle_sigma_R_km']:.2f} | {row['circle_chi2'] / row['dof']:.2f} | "
                     f"{row['circle_chi2_noiseless']:.1f} | {row['knife_R_km']:.2f} +/- {row['knife_sigma_R_km']:.2f} | "
                     f"{row['knife_chi2_noiseless']:.1f} | {row['geometric_chi2_noiseless']:.0f} |")
    with open(os.path.join(args.out, "shape_fringes.md"), "w") as fh:
        fh.write("\n".join(lines) + "\n")
    print("\n".join(lines))

    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    n = len(results)
    fig, axes = plt.subplots(4, n, figsize=(3.3 * n, 10.5), gridspec_kw=dict(height_ratios=[1.3, 1.5, 1.5, 1]))
    win = 8 * model.F_mid / speed
    for k, ((row, ev, fits), outline) in enumerate(zip(results, shapes)):
        ax = axes[0, k]
        for p in outline.polygons:
            pp = np.vstack([p, p[:1]]) / 1e3
            ax.fill(pp[:, 0], pp[:, 1], color="0.7", lw=0)
        ax.axhline(b / 1e3, color="C3", lw=1)
        ax.set_aspect("equal")
        ax.set_title(row["shape"], fontsize=8)
        ax.set_xlabel("x (km)", fontsize=8)
        t = 0.5 * (ev.t_a + ev.t_b)
        th = fits["circle"]
        edges = (th[2] - th[0] / speed, th[2] + th[0] / speed)
        for j, te in enumerate(edges):
            ax = axes[1 + j, k]
            sel = np.abs(t - te) < win
            tt = np.linspace(t[sel].min(), t[sel].max(), 1500)
            ax.errorbar(t[sel], ev.data[sel], ev.sigma[sel], fmt="o", ms=1.5, color="k", ecolor="0.5",
                        elinewidth=0.6, capsize=1, label="simulated")
            ax.plot(tt, np.interp(tt, t, ev.clean), color="0.4", lw=0.8, label="true (shape)")
            for m, c in (("circle", "C0"), ("knife", "C1")):
                ax.plot(tt, model.flux(m, fits[m], tt, tt, speed, 1), c, lw=0.9, label=f"{m} fit")
            ax.set_title("ingress" if j == 0 else "egress", fontsize=8)
            thc = fits["circle_noiseless"]
            tec = thc[2] + (1 if j else -1) * thc[0] / speed
            selc = np.abs(t - tec) < win
            axes[3, k].plot((t[selc] - tec) * speed / model.F_mid, ev.clean[selc] - ev.predict("circle", thc)[selc],
                            color=f"C{2 + j}", lw=0.9, label="ingress" if j == 0 else "egress")
        rax = axes[3, k]
        rax.fill_between([-8, 8], -np.median(ev.sigma), np.median(ev.sigma), color="0.88", label=r"$\pm1\sigma$",
                         zorder=0)
        rax.set_xlabel("t v / F from fitted edge", fontsize=8)
        rax.set_title(f"true - circle fit (noise-free); $\\chi^2$ = {row['circle_chi2_noiseless']:.0f}", fontsize=8)
    axes[1, 0].set_ylabel("relative flux")
    axes[2, 0].set_ylabel("relative flux")
    axes[3, 0].set_ylabel("true - circle fit")
    axes[1, 0].legend(fontsize=6)
    axes[3, 0].legend(fontsize=6)
    fig.suptitle(f"R_eq = {args.radius_km:g} km, {args.distance_au:g} AU, {args.filter}, AB {mag:.1f}, "
                 f"{args.star_uas:g} uas star, chord y = {args.impact:g} R_eq", fontsize=10)
    fig.tight_layout()
    fig.savefig(os.path.join(args.out, "shape_fringes.png"), dpi=120)
    print(f"wrote {os.path.abspath(args.out)}")


if __name__ == "__main__":
    main()
