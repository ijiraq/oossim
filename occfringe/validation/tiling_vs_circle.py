#!/usr/bin/env python3
"""How far do rectangle tilings of a disk depart from the exact disk?

Compares, near ingress of a chord at b = 0.5 R, the exact circular-obstacle
pattern with (1) the hierarchical box tiling of fresnelT.c and (2) horizontal
strip tilings of several heights, first monochromatic with a point source, then
after NIRCam band and stellar-disk averaging.  Writes
results/tiling_vs_circle.{md,png}.
"""
import os
import sys

for _var in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "VECLIB_MAXIMUM_THREADS"):
    os.environ.setdefault(_var, "4")

import numpy as np  # noqa: E402

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from occfringe.constants import AU, UAS, fresnel_scale  # noqa: E402
from occfringe.fresnel import (circle_obstacle_intensity, legacy_ellipse_boxes,  # noqa: E402
                               obstacle_intensity)
from occfringe.nircam import NIRCamSetup  # noqa: E402
from occfringe.shapes import Outline, chord_profile  # noqa: E402
from occfringe.star import StellarDisk  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "results")


def main(R_km=20.0, dist_au=40.0, filt="F150W", star_uas=10.0, b_frac=0.5):
    z = dist_au * AU
    band = NIRCamSetup(filt, "SUB64P", 13.0).bandpass(5800.0, 10.0)
    F_min = float(fresnel_scale(band.lam_min, z))
    F_mono = float(fresnel_scale(1.5e-6, z))
    disk = StellarDisk.for_fresnel_scale(star_uas * UAS * z, F_min)
    R = R_km * 1e3
    b = b_frac * R
    L = np.sqrt(R * R - b * b)
    circle = Outline.circle(R)
    tilings = {"fresnelT.c boxes (order 5)": legacy_ellipse_boxes(R, 1.0, 5)}
    for k in (5, 20, 80):
        tilings[f"strips F/{k}"] = circle.strips(F_min / k)

    x_mono = -L + np.arange(-8.0, 8.0, 1.0 / 40.0) * F_mono
    mono = {"exact": circle_obstacle_intensity(R, np.hypot(x_mono, b), F_mono)}
    for name, rects in tilings.items():
        mono[name] = obstacle_intensity(rects, x_mono, b, F_mono)

    x_band = -L + np.arange(-8.0, 8.0, 1.0 / 40.0) * F_min
    smooth = {"exact": chord_profile(lambda X, Y, F: circle_obstacle_intensity(R, np.hypot(X, Y), F),
                                     x_band, b, z, band, disk)}
    for name, rects in tilings.items():
        print(f"  band average: {name} ({len(rects)} rectangles)", flush=True)
        smooth[name] = chord_profile(lambda X, Y, F, r=rects: obstacle_intensity(r, X, Y, F), x_band, b, z, band,
                                     disk)

    lines = ["# Rectangle tilings vs the exact disk", "",
             f"R = {R_km:g} km at {dist_au:g} AU, chord b = {b_frac:g} R, window +/- 8 F around ingress. "
             f"Monochromatic: 1.5 um point source (F = {F_mono:.0f} m). Smoothed: {filt} band "
             f"({band.lam.size} wavelengths) and a {star_uas:g} uas star (R* = {disk.radius:.0f} m, "
             f"F_min = {F_min:.0f} m).", "",
             "| tiling | rectangles | max abs diff, monochromatic | max abs diff, band + star | rms, band + star |",
             "|---|---|---|---|---|"]
    for name, rects in tilings.items():
        d = smooth[name] - smooth["exact"]
        lines.append(f"| {name} | {len(rects)} | {np.max(np.abs(mono[name] - mono['exact'])):.2e} | "
                     f"{np.max(np.abs(d)):.2e} | {np.sqrt(np.mean(d ** 2)):.1e} |")
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "tiling_vs_circle.md"), "w") as fh:
        fh.write("\n".join(lines) + "\n")
    print("\n".join(lines))

    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, axes = plt.subplots(2, 2, figsize=(11, 6.5), sharex="col", gridspec_kw=dict(height_ratios=[2, 1]))
    for col, (x, curves, F, title) in enumerate(((x_mono, mono, F_mono, "monochromatic point source"),
                                                 (x_band, smooth, F_min, f"{filt} band + {star_uas:g} uas star"))):
        u = -(x + L) / F
        for i, (name, I) in enumerate(curves.items()):
            style = dict(color="k", lw=1.6) if name == "exact" else dict(color=f"C{i}", lw=0.9)
            axes[0, col].plot(u, I, label=name, **style)
            if name != "exact":
                axes[1, col].plot(u, I - curves["exact"], color=f"C{i}", lw=0.9)
        axes[0, col].set_title(title, fontsize=10)
        axes[1, col].set_xlabel("distance outside the limb along the chord (F)")
        axes[1, col].axhline(0, color="k", lw=0.6)
    axes[0, 0].set_ylabel("intensity")
    axes[1, 0].set_ylabel("tiling - exact")
    axes[0, 0].legend(fontsize=7)
    fig.suptitle(f"R = {R_km:g} km disk at {dist_au:g} AU, chord b = {b_frac:g} R", fontsize=10)
    fig.tight_layout()
    fig.savefig(os.path.join(OUT, "tiling_vs_circle.png"), dpi=130)


if __name__ == "__main__":
    main()
