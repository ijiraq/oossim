#!/usr/bin/env python3
"""Catalogue of occultation target stars inside the Roman GBTDS footprint.

The footprint is the ROTAC (2025) overguide layout: five contiguous WFI
pointings at b = -1.2 deg plus the Galactic Centre pointing, each built from
the 18 WFI detector apertures in the Roman SIAF (pysiaf) at V3 PA = 90 deg.

Photometry comes from the real near-infrared surveys of these fields rather
than a synthetic Galaxy model:
    2MASS PSC (II/246)      for K < K_SPLIT (VVV saturates brighter than this)
    VIRAC / VVV (II/364)    for Ks >= K_SPLIT
Reddening per star is taken from the VVVEXMAP high-resolution E(J-Ks) map
(Surot et al. 2020, J/A+A/644/A140); the VizieR copy has no nodes at
l < -0.3 deg, so there the median J-Ks of bulge giants in 2 arcmin cells,
zero-pointed against Surot where both exist, is used instead.  E(J-Ks) is
capped so that no star is dereddened to
bluer than (J-Ks)_0 = JK0_MIN (foreground disk stars sit in front of most of
the dust).  Angular diameters use the V-K surface-brightness relation of
Kervella et al. (2004), with (V-K)_0 from the (J-K)_0 giant sequence of
Bessell & Brett (1988).  For each star the projected radius at the occulter
distance and the retained F200W first-fringe contrast (occfringe knife-edge
model, relative to a point source) are recorded.

Writes results/gbtds/gbtds_stars.csv, gbtds_fields.csv, gbtds_stars.md and
gbtds_stars.png.  Raw VizieR queries are cached in results/gbtds/cache.
"""
import os
import sys

import numpy as np
from astropy.coordinates import SkyCoord
from astropy.table import Table, vstack, unique
import astropy.units as u
from matplotlib.path import Path

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from occfringe.constants import AU, UAS, fresnel_scale  # noqa: E402
from occfringe.edge import knife_edge_profile  # noqa: E402
from occfringe.nircam import NIRCamSetup, saturation_mag  # noqa: E402
from occfringe.star import StellarDisk  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "results", "gbtds")
CACHE = os.path.join(OUT, "cache")

FIELDS_LB = [(-0.417948, -1.200), (-0.008974, -1.200), (0.400000, -1.200),
             (0.808974, -1.200), (1.217948, -1.200), (0.000000, -0.125)]
FIELD_NAMES = ["GBTDS-1", "GBTDS-2", "GBTDS-3", "GBTDS-4", "GBTDS-5", "GBTDS-GC"]
V3PA = 90.0

K_FAINT = 14.5            # catalogue depth (Vega Ks)
K_SPLIT = 11.5            # 2MASS brighter than this, VIRAC fainter
TILE_RADIUS = 0.15        # deg, cone radius of each VizieR query
TILE_STEP = 0.20          # deg, spacing of query centres

A_KS_PER_EJK = 0.428      # Alonso-Garcia et al. (2017), VVV bulge
E_HK_PER_EJK = 0.388      # same law: A_Ks/E(H-Ks) = 1.104
JK0_MIN = 0.45            # bluest intrinsic colour allowed when dereddening
GIANT_CELL_ARCMIN = 2.0   # cell size of the giant-colour reddening estimate where Surot has no nodes
VK0_DEFAULT = 3.0         # K3 III, used when neither J nor H is available

# Bessell & Brett (1988) giant sequence: (J-K)_0 -> (V-K)_0
BB88_JK = np.array([0.45, 0.58, 0.63, 0.68, 0.73, 0.79, 0.86, 0.93, 0.96, 0.99, 1.03, 1.08, 1.13, 1.22])
BB88_VK = np.array([1.60, 2.16, 2.31, 2.50, 2.70, 3.00, 3.26, 3.60, 3.85, 4.05, 4.30, 4.64, 5.10, 5.96])
BB88_HK = np.array([0.06, 0.10, 0.12, 0.13, 0.14, 0.15, 0.17, 0.19, 0.20, 0.21, 0.22, 0.24, 0.27, 0.32])

# occultation geometry used for the compactness figure of merit
DIST_AU = 43.0
FILTER = "F200W"
SUBARRAY = "SUB64P"
TEFF = 4500.0
K_MINUS_F200W = -0.10     # reddened K giant, Vega (as in proposal_compare.py)
VEGA_TO_AB_F200W = 1.70


def wfi_polygons():
    """[(field, detector, ra[4], dec[4])] for the 6 x 18 WFI detectors."""
    import pysiaf
    from pysiaf.utils import rotations
    siaf = pysiaf.Siaf("Roman")
    cen = siaf["WFI_CEN"]
    polys = []
    for name, (l, b) in zip(FIELD_NAMES, FIELDS_LB):
        c = SkyCoord(l=l * u.deg, b=b * u.deg, frame="galactic").icrs
        att = rotations.attitude(cen.V2Ref, cen.V3Ref, c.ra.deg, c.dec.deg, V3PA)
        for i in range(1, 19):
            v2, v3 = siaf[f"WFI{i:02d}_FULL"].corners("tel")
            ra, dec = rotations.pointing(att, v2, v3)
            polys.append((name, i, np.asarray(ra), np.asarray(dec)))
    return polys


def tangent(ra, dec, ra0, dec0):
    """Gnomonic projection [deg] about (ra0, dec0)."""
    ra, dec, ra0, dec0 = (np.radians(np.asarray(x, dtype=float)) for x in (ra, dec, ra0, dec0))
    cosc = np.sin(dec0) * np.sin(dec) + np.cos(dec0) * np.cos(dec) * np.cos(ra - ra0)
    x = np.cos(dec) * np.sin(ra - ra0) / cosc
    y = (np.cos(dec0) * np.sin(dec) - np.sin(dec0) * np.cos(dec) * np.cos(ra - ra0)) / cosc
    return np.degrees(x), np.degrees(y)


def polygon_area_deg2(x, y):
    return 0.5 * abs(np.dot(x, np.roll(y, 1)) - np.dot(y, np.roll(x, 1)))


def assign_detectors(ra, dec, polys):
    """Field name and detector number for each position ('' / 0 outside the footprint)."""
    field = np.full(len(ra), "", dtype="U10")
    det = np.zeros(len(ra), dtype=int)
    for name, i, pra, pdec in polys:
        ra0, dec0 = pra.mean(), pdec.mean()
        px, py = tangent(pra, pdec, ra0, dec0)
        near = np.hypot((ra - ra0) * np.cos(np.radians(dec0)), dec - dec0) < 0.2
        if not near.any():
            continue
        x, y = tangent(ra[near], dec[near], ra0, dec0)
        inside = Path(np.column_stack([px, py])).contains_points(np.column_stack([x, y]))
        idx = np.flatnonzero(near)[inside]
        field[idx] = name
        det[idx] = i
    return field, det


def query_tiles(polys):
    """Query centres (galactic) on a grid covering every detector polygon."""
    centres = []
    for (l0, b0) in FIELDS_LB:
        for dl in np.arange(-0.35, 0.35 + 1e-9, TILE_STEP):
            for db in np.arange(-0.5, 0.5 + 1e-9, TILE_STEP):
                centres.append((l0 + dl, b0 + db))
    centres = np.array(centres)
    g = SkyCoord(l=centres[:, 0] * u.deg, b=centres[:, 1] * u.deg, frame="galactic").icrs
    field, _ = assign_detectors(g.ra.deg, g.dec.deg, polys)
    # keep tiles whose cone touches the footprint: test the centre and 8 points on the rim
    keep = field != ""
    for ang in np.radians(np.arange(0, 360, 45)):
        gl = centres[:, 0] + TILE_RADIUS * np.cos(ang)
        gb = centres[:, 1] + TILE_RADIUS * np.sin(ang)
        r = SkyCoord(l=gl * u.deg, b=gb * u.deg, frame="galactic").icrs
        keep |= assign_detectors(r.ra.deg, r.dec.deg, polys)[0] != ""
    return centres[keep]


def cached_query(catalog, columns, filters, centres, tag):
    from astroquery.vizier import Vizier
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, f"{tag}.ecsv")
    if os.path.exists(path):
        return Table.read(path)
    v = Vizier(columns=columns, column_filters=filters, row_limit=-1, timeout=600)
    parts = []
    for n, (l, b) in enumerate(centres):
        c = SkyCoord(l=l * u.deg, b=b * u.deg, frame="galactic")
        for attempt in range(3):
            try:
                res = v.query_region(c, radius=TILE_RADIUS * u.deg, catalog=catalog)
                break
            except Exception as exc:  # network hiccups
                print(f"  retry {tag} tile {n}: {exc}", flush=True)
        else:
            raise RuntimeError(f"VizieR query failed for {tag} tile {n}")
        if len(res):
            parts.append(res[0])
        print(f"  {tag}: tile {n + 1}/{len(centres)} rows {len(res[0]) if len(res) else 0}", flush=True)
    t = vstack(parts, metadata_conflicts="silent")
    t.write(path, overwrite=True)
    return t


def fetch(polys):
    centres = query_tiles(polys)
    print(f"{len(centres)} query tiles of radius {TILE_RADIUS} deg", flush=True)
    virac = cached_query("II/364/virac", ["srcid", "RA_ICRS", "DE_ICRS", "Ksmag", "Jmag", "Hmag", "flgrel"],
                         {"Ksmag": f"<{K_FAINT}"}, centres, "virac")
    tmass = cached_query("II/246/out", ["2MASS", "RAJ2000", "DEJ2000", "Jmag", "Hmag", "Kmag", "Qflg"],
                         {"Kmag": f"<{K_SPLIT + 0.5}"}, centres, "tmass")
    ejk = cached_query("J/A+A/644/A140/ejkmap", ["GLON", "GLAT", "E(J-Ks)", "e_E(J-Ks)"], {}, centres, "surot")
    virac = unique(virac, keys="srcid")
    tmass = unique(tmass, keys="2MASS")
    ejk = unique(ejk, keys=["GLON", "GLAT"])
    return virac, tmass, ejk


def merge(virac, tmass):
    """2MASS for K < K_SPLIT, VIRAC for Ks >= K_SPLIT, removing VIRAC counterparts of bright 2MASS stars."""
    def col(t, name):
        return np.ma.filled(np.ma.asarray(t[name], dtype=float), np.nan)
    br = tmass[col(tmass, "Kmag") < K_SPLIT]
    fa = virac[col(virac, "Ksmag") >= K_SPLIT]
    c_br = SkyCoord(col(br, "RAJ2000"), col(br, "DEJ2000"), unit="deg")
    c_fa = SkyCoord(col(fa, "RA_ICRS"), col(fa, "DE_ICRS"), unit="deg")
    _, d, _ = c_fa.match_to_catalog_sky(c_br)
    # a saturated VVV counterpart of a bright 2MASS star can report a faint Ks
    fa = fa[~((d.arcsec < 1.0) & (col(fa, "Ksmag") < K_SPLIT + 1.0))]
    rows = {
        "ra": np.concatenate([col(br, "RAJ2000"), col(fa, "RA_ICRS")]),
        "dec": np.concatenate([col(br, "DEJ2000"), col(fa, "DE_ICRS")]),
        "J": np.concatenate([col(br, "Jmag"), col(fa, "Jmag")]),
        "H": np.concatenate([col(br, "Hmag"), col(fa, "Hmag")]),
        "Ks": np.concatenate([col(br, "Kmag"), col(fa, "Ksmag")]),
        "source": np.array(["2MASS"] * len(br) + ["VIRAC"] * len(fa)),
        "id": np.array([str(x) for x in br["2MASS"]] + [str(x) for x in fa["srcid"]]),
    }
    return Table(rows)


def attach_reddening(cat, ejk):
    g = SkyCoord(cat["ra"], cat["dec"], unit="deg").galactic
    m = SkyCoord(l=np.asarray(ejk["GLON"], float) * u.deg, b=np.asarray(ejk["GLAT"], float) * u.deg,
                 frame="galactic")
    idx, sep, _ = g.match_to_catalog_sky(m)
    e_map = np.asarray(ejk["E(J-Ks)"], float)[idx]
    e_map[sep.arcmin > 3.0] = np.nan
    cat["l"] = g.l.wrap_at(180 * u.deg).deg
    cat["b"] = g.b.deg
    e_giant = giant_colour_reddening(cat)
    calib = np.isfinite(e_map) & np.isfinite(e_giant)
    offset = np.median(e_map[calib] - e_giant[calib])
    scatter = 1.4826 * np.median(np.abs(e_map[calib] - e_giant[calib] - offset))
    missing = ~np.isfinite(e_map)
    e_map[missing] = e_giant[missing] + offset
    cat.meta.update(dict(ejk_giant_offset=float(offset), ejk_giant_scatter=float(scatter),
                         ejk_from_giants_fraction=float(np.mean(missing))))
    print(f"giant-colour reddening: offset {offset:.3f}, scatter vs Surot {scatter:.3f},"
          f" used for {np.mean(missing):.1%} of stars")
    cat["EJK_map"] = e_map
    jk = cat["J"] - cat["Ks"]
    hk = cat["H"] - cat["Ks"]
    e_star = np.where(np.isfinite(jk), np.minimum(e_map, jk - JK0_MIN),
                      np.minimum(e_map, (hk - 0.06) / E_HK_PER_EJK))
    e_star = np.where(np.isfinite(e_star), np.clip(e_star, 0.0, None), e_map)
    cat["EJK"] = e_star
    cat["A_Ks"] = A_KS_PER_EJK * e_star
    cat["Ks0"] = cat["Ks"] - cat["A_Ks"]
    jk0 = jk - e_star
    hk0 = hk - E_HK_PER_EJK * e_star
    vk0 = np.where(np.isfinite(jk0), np.interp(jk0, BB88_JK, BB88_VK),
                   np.where(np.isfinite(hk0), np.interp(hk0, BB88_HK, BB88_VK), VK0_DEFAULT))
    cat["JK0"] = jk0
    cat["VK0"] = vk0
    return cat


def giant_colour_reddening(cat, cell_arcmin=GIANT_CELL_ARCMIN):
    """Median J-Ks of bulge giants per cell (red clump and RGB, 12 < Ks < 14.5), zero point to be calibrated."""
    jk = np.asarray(cat["J"] - cat["Ks"], float)
    ks = np.asarray(cat["Ks"], float)
    l, b = np.asarray(cat["l"]), np.asarray(cat["b"])
    cell = cell_arcmin / 60.0
    il = np.floor(l / cell).astype(int)
    ib = np.floor(b / cell).astype(int)
    key = il * 100000 + ib
    giants = (ks > 12.0) & (ks < 14.5) & np.isfinite(jk) & (jk > 0.5)
    out = np.full(len(cat), np.nan)
    uk, inv = np.unique(key, return_inverse=True)
    med = np.full(len(uk), np.nan)
    order = np.argsort(inv[giants])
    gi = inv[giants][order]
    gv = jk[giants][order]
    bounds = np.searchsorted(gi, np.arange(len(uk) + 1))
    for k in range(len(uk)):
        seg = gv[bounds[k]:bounds[k + 1]]
        if len(seg) >= 20:
            med[k] = np.median(seg)
    out[:] = med[inv]
    return out


def angular_diameter_uas(ks0, vk0):
    """Limb-darkened angular diameter [micro-arcsec], Kervella et al. (2004) V-K relation."""
    return 1e3 * 10 ** (0.0755 * vk0 + 0.5170 - 0.2 * ks0)


def contrast_table(radii_m):
    """F200W first-fringe peak-to-trough relative to a point source, versus projected stellar radius."""
    z = DIST_AU * AU
    band = NIRCamSetup(FILTER, SUBARRAY, 15.0).bandpass(TEFF, 12.0)
    f_min = float(fresnel_scale(band.lam_min, z))

    def p2t(disk):
        k = knife_edge_profile(z, band, disk, window_F=12.0)
        i_max = np.argmax(k.I)
        tail = k.I[i_max:]
        j = i_max + np.argmax((tail[1:-1] < tail[:-2]) & (tail[1:-1] <= tail[2:])) + 1
        return k.I[i_max] - k.I[j]
    c0 = p2t(None)
    out = []
    for r in radii_m:
        disk = None if r <= 0 else StellarDisk.for_fresnel_scale(r, f_min, points_per_F=12, max_side=120)
        out.append(p2t(disk) / c0)
    return np.array(out), c0, float(fresnel_scale(band.mean, z))


def main():
    os.makedirs(OUT, exist_ok=True)
    polys = wfi_polygons()
    areas = {}
    for name, i, pra, pdec in polys:
        x, y = tangent(pra, pdec, pra.mean(), pdec.mean())
        areas[name] = areas.get(name, 0.0) + polygon_area_deg2(x, y)
    virac, tmass, ejk = fetch(polys)
    cat = merge(virac, tmass)
    cat["field"], cat["detector"] = assign_detectors(np.asarray(cat["ra"]), np.asarray(cat["dec"]), polys)
    cat = cat[cat["field"] != ""]
    cat = attach_reddening(cat, ejk)

    cat["theta_LD_uas"] = angular_diameter_uas(cat["Ks0"], cat["VK0"])
    z = DIST_AU * AU
    cat["R_proj_m"] = 0.5 * cat["theta_LD_uas"] * UAS * z

    radii = np.concatenate([[0.0], np.geomspace(20.0, 3000.0, 22)])
    ratio, c0, F_mean = contrast_table(radii)
    cat["fringe_retained"] = np.interp(cat["R_proj_m"], radii, ratio)
    cat["F200W_AB"] = cat["Ks"] - K_MINUS_F200W + VEGA_TO_AB_F200W

    k_sat2 = saturation_mag(FILTER, SUBARRAY, ngroups=2) - VEGA_TO_AB_F200W + K_MINUS_F200W
    k_sat10 = saturation_mag(FILTER, SUBARRAY, ngroups=10) - VEGA_TO_AB_F200W + K_MINUS_F200W
    cat.meta.update(dict(dist_au=DIST_AU, fresnel_F200W_m=F_mean, k_sat_2groups=k_sat2, k_sat_10groups=k_sat10))
    for c in ("J", "H", "Ks", "EJK_map", "EJK", "A_Ks", "Ks0", "JK0", "VK0", "F200W_AB"):
        cat[c].info.format = ".3f"
    for c in ("theta_LD_uas", "R_proj_m", "fringe_retained"):
        cat[c].info.format = ".3f"
    cat.sort("Ks")
    cat.write(os.path.join(OUT, "gbtds_stars.csv"), overwrite=True)
    Table({"radius_m": radii, "fringe_retained": ratio}).write(os.path.join(OUT, "fringe_vs_radius.csv"),
                                                              overwrite=True)

    # per-field summary
    k_lims = (12.5, 13.0, 13.5, 14.0, 14.5)
    rows = []
    for name in FIELD_NAMES:
        s = cat[cat["field"] == name]
        a_as2 = areas[name] * 3600.0 ** 2
        row = {"field": name, "l": FIELDS_LB[FIELD_NAMES.index(name)][0],
               "b": FIELDS_LB[FIELD_NAMES.index(name)][1], "area_deg2": areas[name],
               "median_EJK": np.nanmedian(s["EJK_map"])}
        for kl in k_lims:
            use = (s["Ks"] < kl) & (s["Ks"] > k_sat2) & (s["fringe_retained"] >= 0.7)
            row[f"n_K<{kl}"] = int(np.sum(s["Ks"] < kl))
            row[f"dens_use_K<{kl}"] = np.sum(use) / a_as2
        rows.append(row)
    ft = Table(rows)
    tot = {"field": "ALL", "l": np.nan, "b": np.nan, "area_deg2": sum(areas.values()),
           "median_EJK": np.nanmedian(cat["EJK_map"])}
    for kl in k_lims:
        use = (cat["Ks"] < kl) & (cat["Ks"] > k_sat2) & (cat["fringe_retained"] >= 0.7)
        tot[f"n_K<{kl}"] = int(np.sum(cat["Ks"] < kl))
        tot[f"dens_use_K<{kl}"] = np.sum(use) / (tot["area_deg2"] * 3600.0 ** 2)
    ft.add_row(tot)
    ft.write(os.path.join(OUT, "gbtds_fields.csv"), overwrite=True)
    write_report(cat, ft, radii, ratio, c0, F_mean, k_sat2, k_sat10, k_lims)
    plot(cat, radii, ratio, k_sat2, F_mean)


def write_report(cat, ft, radii, ratio, c0, F_mean, k_sat2, k_sat10, k_lims):
    L = ["# Occultation target stars in the Roman GBTDS footprint", "",
         f"Footprint: ROTAC overguide layout, 6 pointings x 18 WFI detectors (pysiaf, V3PA = {V3PA:.0f}),"
         f" total {ft['area_deg2'][-1]:.3f} deg^2.",
         f"Photometry: 2MASS for K < {K_SPLIT}, VIRAC/VVV for Ks >= {K_SPLIT}; reddening from Surot et al. (2020)"
         f" with A_Ks = {A_KS_PER_EJK} E(J-Ks), dereddened colours capped at (J-Ks)_0 >= {JK0_MIN}.",
         "Angular diameters: Kervella et al. (2004) V-K surface-brightness relation, (V-K)_0 from the"
         " Bessell & Brett (1988) giant sequence.", "",
         f"Occulter distance {DIST_AU} au: F200W Fresnel scale {F_mean / 1e3:.2f} km;"
         f" 1 uas projects to {UAS * DIST_AU * AU:.1f} m.",
         f"F200W {SUBARRAY} saturation (80% well): K = {k_sat2:.2f} with 2 groups, K = {k_sat10:.2f} with 10 groups.",
         "Usable = brighter than the K limit, fainter than the 2-group saturation limit, and projected disk"
         " retaining >= 70% of the point-source first-fringe contrast.", "",
         "## Fringe contrast versus projected stellar radius (F200W, knife edge, 43 au)", "",
         "| R_proj (m) | angular radius (uas) | retained contrast |", "|---|---|---|"]
    for r, c in zip(radii, ratio):
        if r == 0 or r in radii[1::3]:
            L.append(f"| {r:.0f} | {r / (UAS * DIST_AU * AU):.1f} | {c:.2f} |")
    L += ["", f"Point-source first-fringe contrast: {c0:.3f}.", "", "## Per-field counts and usable densities", "",
          "| field | area (deg^2) | median E(J-Ks) | " + " | ".join(f"N(K<{k})" for k in k_lims) + " | "
          + " | ".join(f"usable K<{k} (arcsec^-2)" for k in k_lims) + " |",
          "|" + "---|" * (3 + 2 * len(k_lims))]
    for r in ft:
        L.append(f"| {r['field']} | {r['area_deg2']:.3f} | {r['median_EJK']:.2f} | "
                 + " | ".join(str(r[f'n_K<{k}']) for k in k_lims) + " | "
                 + " | ".join(f"{r[f'dens_use_K<{k}']:.4f}" for k in k_lims) + " |")
    use = (cat["Ks"] < 13.5) & (cat["Ks"] > k_sat2)
    q = np.nanpercentile(cat["theta_LD_uas"][use], [5, 50, 95]) / 2
    L += ["", f"Angular radius of K_sat < K < 13.5 stars: 5/50/95 percentiles {q[0]:.1f} / {q[1]:.1f} / {q[2]:.1f} uas"
          f" ({q[0] * UAS * DIST_AU * AU:.0f} / {q[1] * UAS * DIST_AU * AU:.0f} / {q[2] * UAS * DIST_AU * AU:.0f} m"
          " at 43 au).",
          f"Fraction of those failing the 70% fringe cut: {np.mean(cat['fringe_retained'][use] < 0.7):.3f}."]
    with open(os.path.join(OUT, "gbtds_stars.md"), "w") as f:
        f.write("\n".join(L) + "\n")
    print("\n".join(L))


def plot(cat, radii, ratio, k_sat2, F_mean):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(2, 2, figsize=(12, 9))
    a = ax[0, 0]
    bright = cat["Ks"] < 13.5
    a.scatter(cat["l"][bright], cat["b"][bright], s=0.05, c=cat["EJK_map"][bright], cmap="viridis_r")
    a.set_xlabel("l (deg)"); a.set_ylabel("b (deg)"); a.invert_xaxis()
    a.set_title("K < 13.5 stars in the GBTDS footprint (colour: E(J-Ks))"); a.set_aspect("equal")
    a = ax[0, 1]
    bins = np.arange(6, 14.55, 0.1)
    for name in FIELD_NAMES:
        s = cat["Ks"][cat["field"] == name]
        a.hist(s, bins, histtype="step", label=name)
    a.axvline(k_sat2, ls=":", c="k"); a.axvline(13.5, ls="--", c="k")
    a.set_yscale("log"); a.set_xlabel("Ks (Vega)"); a.set_ylabel("stars / 0.1 mag"); a.legend(fontsize=8)
    a = ax[1, 0]
    a.scatter(cat["Ks"], cat["theta_LD_uas"] / 2, s=0.05, alpha=0.3)
    a.set_yscale("log"); a.set_xlabel("Ks (Vega)"); a.set_ylabel("angular radius (uas)")
    a.axvline(13.5, ls="--", c="k"); a.axvline(k_sat2, ls=":", c="k")
    r70 = np.interp(0.7, ratio[::-1], radii[::-1])
    a.axhline(r70 / (UAS * DIST_AU * AU), c="r", ls="--", label="70% fringe contrast at 43 au")
    a.legend(fontsize=8)
    a = ax[1, 1]
    a.plot(radii / F_mean, ratio, "o-")
    a.set_xscale("symlog", linthresh=0.01); a.set_xlabel("projected stellar radius / F (F200W, 43 au)")
    a.set_ylabel("first-fringe contrast / point source"); a.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(os.path.join(OUT, "gbtds_stars.png"), dpi=130)


if __name__ == "__main__":
    main()
