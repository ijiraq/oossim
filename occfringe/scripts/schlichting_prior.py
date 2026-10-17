#!/usr/bin/env python3
"""OSSOS++ distance prior for the two HST/FGS serendipitous occultations.

Schlichting et al. (2009, Nature 462, 895; 2012, ApJ 761, 150) fitted each
event's timescale F/v with a circular-orbit velocity to obtain its distance,
then the radius from the depth (R/F).  Here the OSSOS++ population is placed
on the sky around each event star at epochs spanning the archival FGS data,
every model object is given equal weight (orbit and size uncorrelated), and

* the geocentric-distance prior of objects at that sky position is reported;
* for each object, the distance a circular-orbit fit would return from the
  same timescale is computed, and the objects whose fitted distance lies in
  the published range give the true distance and radius behind that fit.

The HST orbital velocity (7.5 km/s, known at the event) is omitted; the
observer is Earth at the chosen solar elongation.

Writes results/schlichting/schlichting_prior.{md,png}.
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import gbtds_tno_rate as g  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "results", "schlichting")
V_EARTH = 29.78                     # km/s
EVENTS = {
    "2009": dict(ra=186.87872, dec=12.72469, fit=45.0, lo=41.0, hi=50.0, r_m=520.0, dr_m=60.0),
    "2012": dict(ra=64.74065, dec=28.13064, fit=35.0, lo=26.0, hi=44.0, r_m=530.0, dr_m=70.0),
}
EPOCHS = [f"{y}-01-01" for y in range(2000, 2012)]
BOX_LAT = 1.0                       # half-height of the sky box [deg]
BOX_LON = 4.0                       # half-width, great-circle degrees
ELONGATIONS = (180.0, 150.0, 120.0)


def ecl_of(ra, dec):
    ra, dec = np.radians(ra), np.radians(dec)
    v = g.icrs_to_ecl(np.array([np.cos(dec) * np.cos(ra), np.cos(dec) * np.sin(ra), np.sin(dec)]))
    return np.arctan2(v[1], v[0]) % (2 * np.pi), np.arcsin(v[2])


def earth_at(lam, beta, elong_deg, sign):
    """Circular-orbit Earth [au, km/s] placed so the field is at the given elongation (sign picks the side)."""
    u = np.array([np.cos(beta) * np.cos(lam), np.cos(beta) * np.sin(lam), np.sin(beta)])
    phis = np.radians(np.arange(0, 360, 0.05))
    re = np.stack([np.cos(phis), np.sin(phis), np.zeros_like(phis)])
    d = 40.0 * u[:, None] - re
    el = np.degrees(np.arccos(np.sum(-re * d, axis=0) / np.linalg.norm(d, axis=0)))
    w = (phis - lam + np.pi) % (2 * np.pi) - np.pi
    ok = (np.sign(w) == sign) | (elong_deg >= 179.9)
    k = np.argmin(np.where(ok, np.abs(el - elong_deg), 1e9))
    phi = phis[k]
    return re[:, k], V_EARTH * np.array([-np.sin(phi), np.cos(phi), 0.0])


def sky_speed(d, v_rel):
    dhat = d / np.linalg.norm(d, axis=0)
    vt = v_rel - np.sum(v_rel * dhat, axis=0) * dhat
    return np.linalg.norm(vt, axis=0)


def circular_timescale_curve(u, ro, vo, deltas):
    """sqrt(Delta)/v for a prograde circular orbit on the line of sight at geocentric distance Delta."""
    pos = ro[:, None] + deltas[None, :] * u[:, None]
    r = np.linalg.norm(pos, axis=0)
    vk = np.sqrt(g.K_GAUSS ** 2 / r) * g.AUD_TO_KMS
    zhat = np.array([0.0, 0.0, 1.0])
    t = np.cross(zhat, pos.T).T
    t /= np.linalg.norm(t, axis=0)
    v = sky_speed(deltas[None, :] * u[:, None], vk * t - vo[:, None])
    return np.sqrt(deltas) / v


def analyse(name, ev, df, epoch_jd):
    lam, beta = ev["lam"], ev["beta"]
    u = np.array([np.cos(beta) * np.cos(lam), np.cos(beta) * np.sin(lam), np.sin(beta)])
    pre = df.inc.values >= np.degrees(abs(beta)) - 3.0
    sub = df[pre]
    cls = sub.cls.astype(str).values
    out = {}
    deltas = np.geomspace(3.0, 400.0, 4000)
    for elong in ELONGATIONS:
        for sign in ((+1,) if elong >= 179.9 else (+1, -1)):
            ro, vo = earth_at(lam, beta, elong, sign)
            curve = circular_timescale_curve(u, ro, vo, deltas)
            bad = np.flatnonzero(np.diff(curve) <= 0)
            cmin = bad[-1] + 1 if len(bad) else 0
            D_true, D_fit, vrel, klass = [], [], [], []
            for ep in EPOCHS:
                r, v = g.propagate(sub, g.Time(ep).jd, epoch_jd)
                d = r - ro[:, None]
                delta = np.linalg.norm(d, axis=0)
                l = np.arctan2(d[1], d[0])
                b = np.arcsin(d[2] / delta)
                dl = ((l - lam + np.pi) % (2 * np.pi) - np.pi) * np.cos(beta)
                inbox = (np.abs(b - beta) < np.radians(BOX_LAT)) & (np.abs(dl) < np.radians(BOX_LON))
                if not inbox.any():
                    continue
                di = d[:, inbox]
                vi = v[:, inbox] * g.AUD_TO_KMS - vo[:, None]
                s = sky_speed(di, vi)
                tau = np.sqrt(delta[inbox]) / s
                D_fit.append(np.interp(tau, curve[cmin:], deltas[cmin:], left=np.nan, right=np.nan))
                D_true.append(delta[inbox])
                vrel.append(s)
                klass.append(cls[inbox])
            key = f"{elong:.0f}" + ("" if elong >= 179.9 else ("E" if sign > 0 else "W"))
            out[key] = dict(D_true=np.concatenate(D_true), D_fit=np.concatenate(D_fit),
                            v=np.concatenate(vrel), cls=np.concatenate(klass))
            print(f"  {name} elong {key}: {out[key]['D_true'].size} objects in box", flush=True)
    return out


def pct(x, w=None, q=(5, 16, 50, 84, 95)):
    x = np.asarray(x)
    ok = np.isfinite(x)
    x = x[ok]
    if w is None:
        return np.percentile(x, q)
    w = np.asarray(w)[ok]
    o = np.argsort(x)
    c = np.cumsum(w[o]) / w.sum()
    return np.interp(np.array(q) / 100.0, c, x[o])


def group(c):
    if c.startswith("Classical--Faint--cold") or "cold" in c.lower():
        return "cold classical"
    if c.startswith("Classical"):
        return "hot/other classical"
    if c.startswith("Resonant--3:2"):
        return "3:2 resonant"
    if c.startswith("Resonant"):
        return "other resonant"
    if c.startswith("Scattering"):
        return "scattering"
    if c.startswith("Detached"):
        return "detached"
    return c.split("--")[0]


def main():
    os.makedirs(OUT, exist_ok=True)
    df, _ = g.load_model()
    lam_n, _ = g.resonant_neptune_lon(df)
    epoch_jd = g.epoch_from_neptune(lam_n)
    print(f"model: {len(df)} objects; epoch JD {epoch_jd:.1f}", flush=True)
    hmax = df.groupby("cls", observed=True).H.max()
    print("H max by class (min, max):", float(hmax.min()), float(hmax.max()), flush=True)
    h_cut = float(hmax.min())
    df = df[df.H <= h_cut]

    results = {}
    for name, ev in EVENTS.items():
        ev["lam"], ev["beta"] = ecl_of(ev["ra"], ev["dec"])
        print(f"{name}: ecliptic ({np.degrees(ev['lam']):.2f}, {np.degrees(ev['beta']):.2f})", flush=True)
        results[name] = analyse(name, ev, df, epoch_jd)

    lines = ["# OSSOS++ distance prior for the HST/FGS occultation events", "",
             f"Model objects with H <= {h_cut:.2f} (common limit of all classes), equal weight per object "
             f"(orbit and size uncorrelated). Sky box {2 * BOX_LAT:g} x {2 * BOX_LON:g} deg around each event star, "
             f"pooled over epochs {EPOCHS[0][:4]}-{EPOCHS[-1][:4]} (event dates not published). Observer: Earth on a "
             "circular orbit at the stated solar elongation (E/W = either side of opposition); HST's orbital "
             "velocity is omitted. Two-body propagation from the model epoch.", "",
             "'Circular fit' is the distance a prograde circular-orbit fit returns from the same timescale "
             "sqrt(Delta)/v; the posterior rows keep the objects whose circular-fit distance lies inside the "
             "published range, and give their true distance and the radius implied for the published R "
             "(R scales as F, i.e. sqrt(Delta), at fixed depth).", ""]
    for name, ev in EVENTS.items():
        lines += [f"## {name} event: ecliptic ({np.degrees(ev['lam']):.1f}, {np.degrees(ev['beta']):+.1f}) deg; "
                  f"published {ev['fit']:g} au ({ev['lo']:g}-{ev['hi']:g}), R = {ev['r_m']:g} +/- {ev['dr_m']:g} m", "",
                  "| elongation | N in box | prior Delta 5/16/50/84/95% (au) | rate-weighted (x v) 16/50/84% | "
                  "N consistent with fit | true Delta 5/16/50/84/95% given fit | implied R 16/50/84% (m) |",
                  "|---|---|---|---|---|---|---|"]
        for key, r in results[name].items():
            p = pct(r["D_true"])
            pw = pct(r["D_true"], r["v"], q=(16, 50, 84))
            sel = (r["D_fit"] >= ev["lo"]) & (r["D_fit"] <= ev["hi"])
            if sel.sum() > 5:
                pt = pct(r["D_true"][sel])
                ratio = np.sqrt(r["D_true"][sel] / r["D_fit"][sel])
                pr = pct(ev["r_m"] * ratio, q=(16, 50, 84))
                post = "/".join(f"{x:.1f}" for x in pt)
                rr = "/".join(f"{x:.0f}" for x in pr)
            else:
                post, rr = "-", "-"
            lines.append(f"| {key} | {r['D_true'].size} | {'/'.join(f'{x:.1f}' for x in p)} | "
                         f"{'/'.join(f'{x:.1f}' for x in pw)} | {int(sel.sum())} | {post} | {rr} |")
        r = results[name]["180"]
        sel = (r["D_fit"] >= ev["lo"]) & (r["D_fit"] <= ev["hi"])
        groups = np.array([group(c) for c in r["cls"]])
        lines += ["", f"Population mix at opposition ({name}): all objects in box / those consistent with the fit", "",
                  "| population | prior fraction | fraction given fit | median true Delta given fit |",
                  "|---|---|---|---|"]
        for gname in sorted(set(groups)):
            m = groups == gname
            ms = m & sel
            med = f"{np.median(r['D_true'][ms]):.1f}" if ms.sum() > 3 else "-"
            lines.append(f"| {gname} | {m.mean():.3f} | {ms.sum() / max(sel.sum(), 1):.3f} | {med} |")
        err = np.abs(np.sqrt(r["D_true"][sel] / r["D_fit"][sel]) - 1)
        lines += ["", f"At opposition, |R_true/R_fit - 1| from the circular assumption alone: "
                  f"median {np.median(err):.3f}, 84th percentile {np.percentile(err, 84):.3f}, "
                  f"95th {np.percentile(err, 95):.3f}.", ""]
    with open(os.path.join(OUT, "schlichting_prior.md"), "w") as fh:
        fh.write("\n".join(lines) + "\n")
    print("\n".join(lines))
    plot(results)


def plot(results):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, axes = plt.subplots(1, 2, figsize=(10, 3.6))
    bins = np.linspace(20, 120, 101)
    for ax, (name, ev) in zip(axes, EVENTS.items()):
        r = results[name]["180"]
        sel = (r["D_fit"] >= ev["lo"]) & (r["D_fit"] <= ev["hi"])
        ax.hist(r["D_true"], bins, density=True, histtype="step", color="0.4", label="prior at event position")
        ax.hist(r["D_true"][sel], bins, density=True, histtype="stepfilled", alpha=0.5, color="C0",
                label="true distance | circular fit in published range")
        ax.axvspan(ev["lo"], ev["hi"], color="C3", alpha=0.12, label="published circular-orbit fit")
        ax.axvline(ev["fit"], color="C3", lw=1)
        ax.set_xlabel("geocentric distance (au)")
        ax.set_title(f"{name} event, $\\beta$ = {np.degrees(ev['beta']):+.1f}$^\\circ$ (opposition)", fontsize=10)
        ax.legend(fontsize=7, frameon=False)
    axes[0].set_ylabel("probability density")
    fig.tight_layout()
    fig.savefig(os.path.join(OUT, "schlichting_prior.png"), dpi=150)


if __name__ == "__main__":
    main()
