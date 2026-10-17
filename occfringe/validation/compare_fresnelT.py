"""Compare occfringe.legacy.fresnelT with the original cdiffracSim/fresnelT.c.

Builds fresnelT.c against a stub detection.h (no FFTW/GSL needed), runs both
codes on a small optical grid, and reports

* the maximum difference between the C output and the Python port with all
  legacy quirks on (should be at the 1e-8 print precision), and
* how much each quirk changes the profile when it is fixed.

Usage:  python validation/compare_fresnelT.py [--out validation/results]
"""

import argparse
import os
import shutil
import subprocess
import sys
import tempfile

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, ROOT)

from occfringe import legacy  # noqa: E402
from occfringe.bandpass import Bandpass  # noqa: E402
from occfringe.constants import fresnel_scale, distance_m  # noqa: E402
from occfringe.lightcurve import radial_profile  # noqa: E402
from occfringe.star import StellarDisk  # noqa: E402

C_SOURCE = os.path.join(ROOT, "..", "cdiffracSim", "fresnelT.c")

# (aa [m], T [K], params); spans R << F to R ~ few F, point source and resolved star
CASES = [
    (200.0, 5800.0, legacy.FresnelParams(5.5e-7, 5.5e-7, 1, 8000.0, 50.0, 1.0, 1, 40.0, 0.0, 1.0, 5)),
    (800.0, 5800.0, legacy.FresnelParams(5.0e-7, 7.0e-7, 5, 10000.0, 50.0, 300.0, 50, 40.0, 0.0, 1.0, 5)),
    (1500.0, 4000.0, legacy.FresnelParams(4.0e-7, 8.0e-7, 20, 12000.0, 50.0, 100.0, 30, 40.0, 0.0, 1.0, 5)),
    (3000.0, 9000.0, legacy.FresnelParams(4.0e-7, 8.0e-7, 20, 15000.0, 60.0, 800.0, 200, 40.0, 0.0, 1.0, 5)),
    (5000.0, 5800.0, legacy.FresnelParams(4.0e-7, 7.0e-7, 10, 20000.0, 100.0, 1.0, 1, 300.0, 0.0, 1.0, 5)),
    (1200.0, 5800.0, legacy.FresnelParams(4.0e-7, 7.0e-7, 10, 10000.0, 50.0, 200.0, 40, 40.0, 0.0, 2.0, 5)),
]


def build_fresnelT(build_dir):
    exe = os.path.join(build_dir, "fresnelT")
    src = os.path.join(build_dir, "fresnelT.c")
    shutil.copy(C_SOURCE, src)
    cmd = ["cc", "-O2", "-U_FORTIFY_SOURCE", "-D_FORTIFY_SOURCE=0", "-ftrivial-auto-var-init=zero",
           "-I", os.path.join(HERE, "stub"), "-o", exe, src, "-lm"]
    subprocess.run(cmd, check=True, stderr=subprocess.DEVNULL)
    return exe


def run_c(exe, aa, T, params, workdir):
    pfile = os.path.join(workdir, "params.fres")
    legacy.write_params(pfile, params)
    subprocess.run([exe, repr(aa), repr(T), pfile], cwd=workdir, check=True)
    return legacy.read_fres_file(os.path.join(workdir, legacy.fres_filename(aa, params.AU)))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default=os.path.join(HERE, "results"))
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)

    lines = ["| aa (m) | AU | R/F | R*/F | N_lam | C vs port | fix table | fix planck | fix interp | fix AU | all fixed |",
             "|---|---|---|---|---|---|---|---|---|---|---|"]
    worst = 0.0
    with tempfile.TemporaryDirectory() as tmp:
        exe = build_fresnelT(tmp)
        for aa, T, p in CASES:
            c = run_c(exe, aa, T, p, tmp)
            port = legacy.fresnelT(aa, T, p, legacy=True)
            d_port = float(np.max(np.abs(c.Idisk - port.Idisk)))
            worst = max(worst, d_port)
            quirk = [float(np.max(np.abs(legacy.fresnelT(aa, T, p, legacy=True, **{q: False}).Idisk - port.Idisk)))
                     for q in legacy.QUIRKS]
            d_all = float(np.max(np.abs(legacy.fresnelT(aa, T, p, legacy=False).Idisk - port.Idisk)))
            F = float(fresnel_scale(0.5 * (p.lambLo + p.lambHi), distance_m(p.AU)))
            lines.append(f"| {aa:g} | {p.AU:g} | {aa / F:.2f} | {p.RStarProj / F:.2f} | {p.nLambda} | {d_port:.1e} | "
                         + " | ".join(f"{v:.1e}" for v in quirk) + f" | {d_all:.1e} |")
            np.savetxt(os.path.join(args.out, f"compare_{int(aa):05d}_{int(p.AU):05d}.txt"),
                       np.column_stack([c.x, c.Idisk, port.Idisk, legacy.fresnelT(aa, T, p, legacy=False).Idisk]),
                       header="x_m Idisk_C Idisk_port_legacy Idisk_port_fixed", fmt="%.8g")

    tiling = ["| aa (m) | AU | R/F | R*/F | max abs(order-5 boxes - exact disk) |", "|---|---|---|---|---|"]
    for aa, T, p in CASES:
        if p.aspectRatio != 1.0 or p.offset != 0.0:
            continue
        fixed = legacy.fresnelT(aa, T, p, legacy=False)
        band = Bandpass.tophat(p.lambLo, p.lambHi, p.nLambda, T, weighting="photon")
        exact = radial_profile(aa, distance_m(p.AU), band, StellarDisk.legacy(p.RStarProj, p.Nptsrc), r_out=fixed.x)
        F = float(fresnel_scale(0.5 * (p.lambLo + p.lambHi), distance_m(p.AU)))
        tiling.append(f"| {aa:g} | {p.AU:g} | {aa / F:.2f} | {p.RStarProj / F:.2f} | "
                      f"{np.max(np.abs(fixed.Idisk - exact.I)):.1e} |")

    report = "\n".join([
        "# fresnelT.c vs occfringe.legacy.fresnelT",
        "",
        "Maximum |delta I_disk| over each profile. 'C vs port' compares the C binary with the Python port",
        "running every legacy quirk; the 'fix' columns show how far the profile moves when one quirk is",
        "corrected (table: exact Fresnel integrals; planck: photon-weighted Planck instead of the",
        "exp(x-1) Wien form; interp: correct linear interpolation in the stellar-disk average;",
        "AU: 1.496e11 m instead of 1.5e11 m).",
        "",
        *lines,
        "",
        f"Worst C vs port difference: {worst:.1e}",
        "",
        "## Rectangle tiling vs exact disk",
        "",
        "Same bandpass, stellar disk and sampling (all quirks fixed); the only difference is the",
        "occulter: fresnelT's order-5 rectangle mosaic versus the exact circular-disk solution",
        "(occfringe.fresnel.circle_obstacle_field).",
        "",
        *tiling,
    ])
    with open(os.path.join(args.out, "compare_fresnelT.md"), "w") as fh:
        fh.write(report + "\n")
    print(report)
    return 0 if worst < 1e-6 else 1


if __name__ == "__main__":
    sys.exit(main())
