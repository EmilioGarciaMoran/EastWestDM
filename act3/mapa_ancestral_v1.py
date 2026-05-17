#!/usr/bin/env python3
# =============================================================
# MAPA MUNDIAL — Ancestral NCDN variant frequency
# chr1:35,565,741 — Global frequency distribution
# Mercator centrado en Atlántico (Canarias → Brasil)
# Figure 6 — EastWestDM manuscript v7.1
# =============================================================

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.lines import Line2D
import matplotlib.patheffects as pe
import geopandas as gpd
import warnings
warnings.filterwarnings("ignore")

# --- 1. DATOS POBLACIONALES ---------------------------------
populations = [
    # Deep-branching African — ancestral baseline
    {"name": "San",           "lat": -23.0,  "lon":  21.0,  "freq": 92,  "group": "Africa ancestral"},
    {"name": "Biaka",         "lat":   4.0,  "lon":  18.0,  "freq": 91,  "group": "Africa ancestral"},
    {"name": "Mbuti",         "lat":   0.0,  "lon":  25.0,  "freq": 83,  "group": "Africa ancestral"},
    {"name": "Yoruba",        "lat":   7.4,  "lon":   3.9,  "freq": 70,  "group": "Africa ancestral"},
    {"name": "ESN",           "lat":   6.5,  "lon":   3.3,  "freq": 69,  "group": "Africa ancestral"},
    {"name": "GWD",           "lat":  13.4,  "lon": -15.3,  "freq": 64,  "group": "Africa ancestral"},
    {"name": "LWK",           "lat":   0.5,  "lon":  35.3,  "freq": 65,  "group": "Africa ancestral"},
    # Cold-enriched
    {"name": "EAS",           "lat":  35.0,  "lon": 105.0,  "freq": 78,  "group": "Cold-enriched"},
    {"name": "Surui",         "lat": -11.0,  "lon": -61.5,  "freq": 100, "group": "Cold-enriched"},
    {"name": "Karitiana",     "lat": -10.2,  "lon": -62.8,  "freq": 100, "group": "Cold-enriched"},
    {"name": "Pima",          "lat":  27.0,  "lon":-110.0,  "freq": 77,  "group": "Cold-enriched"},
    {"name": "Maya",          "lat":  18.0,  "lon": -89.0,  "freq": 67,  "group": "Cold-enriched"},
    # Low admixture AMR
    {"name": "Peruvian",      "lat": -12.0,  "lon": -77.0,  "freq": 53,  "group": "Admixture AMR"},
    # Admixed AMR post-1521
    {"name": "Mexican",       "lat":  19.4,  "lon": -99.1,  "freq": 39,  "group": "Admixture AMR"},
    {"name": "AMR gnomAD",    "lat":  10.0,  "lon": -84.0,  "freq": 31,  "group": "Admixture AMR"},
    {"name": "Colombian",     "lat":   4.7,  "lon": -74.0,  "freq": 29,  "group": "Admixture AMR"},
    # African American — admixture dilution
    {"name": "ACB",           "lat":  13.1,  "lon": -59.6,  "freq": 73,  "group": "African admixed"},
    {"name": "ASW",           "lat":  33.7,  "lon": -84.4,  "freq": 49,  "group": "African admixed"},
    # European — Neolithic loss
    {"name": "NFE",           "lat":  50.0,  "lon":  10.0,  "freq":  3,  "group": "European loss"},
]

# --- 2. COLOR POR FRECUENCIA --------------------------------
def freq_to_color(freq):
    cmap = plt.cm.RdYlBu_r
    return cmap(freq / 100.0)

# --- 3. MAPA BASE -------------------------------------------
print("Loading world map...")
world = gpd.read_file(
    "https://naturalearth.s3.amazonaws.com/110m_cultural/"
    "ne_110m_admin_0_countries.zip"
)

# --- 4. FIGURA ----------------------------------------------
print("Rendering map...")
fig, ax = plt.subplots(figsize=(200/25.4, 120/25.4),
                       dpi=300, facecolor="white")
ax.set_facecolor("#D6EAF8")

world.plot(ax=ax, color="#F0EDE8", edgecolor="#BBBBBB",
           linewidth=0.25, zorder=1)

# --- 5. FLECHAS DE MIGRACIÓN --------------------------------
migrations = [
    {"start": (40.0,  9.0), "end": (84.0, 51.0),
     "color": "#2C2C2C", "lw": 2.5, "rad":  0.20, "ls": "solid"},
    {"start": (84.0, 51.0), "end": (-61.5, -11.0),
     "color": "#8B1A1A", "lw": 2.5, "rad": -0.35, "ls": "solid"},
    {"start": (40.0,  9.0), "end": (10.0,  50.0),
     "color": "#2980B9", "lw": 2.0, "rad":  0.15, "ls": "solid"},
    {"start": (-4.0, 40.0), "end": (-99.1, 19.4),
     "color": "#888888", "lw": 1.2, "rad":  0.20, "ls": "dashed"},
    {"start": (-5.0,  5.0), "end": (-59.6, 13.1),
     "color": "#888888", "lw": 1.2, "rad": -0.15, "ls": "dashed"},
]

for m in migrations:
    ax.annotate("",
        xy=m["end"], xytext=m["start"],
        xycoords="data", textcoords="data",
        arrowprops=dict(
            arrowstyle="-|>", color=m["color"],
            lw=m["lw"], mutation_scale=10,
            connectionstyle=f"arc3,rad={m['rad']}",
            linestyle=m["ls"]
        ),
        zorder=5
    )

# --- 6. PUNTOS DE POBLACIÓN ---------------------------------
offsets = {
    "San":        ( 4,  3), "Biaka":      (-7,  3), "Mbuti":      ( 5, -5),
    "Yoruba":     (-7,  3), "ESN":        ( 5, -5), "GWD":        (-7, -4),
    "LWK":        ( 5,  3), "EAS":        ( 5,  3), "Surui":      (-9, -4),
    "Karitiana":  ( 5,  4), "Pima":       (-9,  3), "Maya":       ( 5, -4),
    "Peruvian":   (-9,  3), "Mexican":    ( 5,  3), "AMR gnomAD": (-9, -4),
    "Colombian":  ( 5,  3), "ACB":        ( 5,  3), "ASW":        ( 5, -4),
    "NFE":        ( 5,  3),
}

for pop in populations:
    x, y   = pop["lon"], pop["lat"]
    freq   = pop["freq"]
    color  = freq_to_color(freq)
    size   = 25 + freq * 1.6

    ax.scatter(x, y, s=size, c=[color],
               edgecolors="white", linewidths=0.9,
               zorder=6, alpha=0.92)

    name  = pop["name"]
    dx, dy = offsets.get(name, (4, 3))

    ax.annotate(f"{name}\n{freq}%",
        xy=(x, y), xytext=(x+dx, y+dy),
        fontsize=5.5, ha="center", va="center",
        color="#1a1a1a", linespacing=1.2,
        bbox=dict(boxstyle="round,pad=0.2", facecolor="white",
                  edgecolor="#CCCCCC", alpha=0.88, linewidth=0.4),
        arrowprops=dict(arrowstyle="-", color="#999999",
                        linewidth=0.35, shrinkA=2, shrinkB=2),
        zorder=8
    )

# --- 7. EJES ------------------------------------------------
ax.set_xlim(-130, 150)
ax.set_ylim(-40, 75)
ax.set_xticks(range(-120, 141, 30))
ax.set_xticklabels(
    [f"{abs(x)}°{'W' if x<0 else 'E'}" for x in range(-120, 141, 30)],
    fontsize=6)
ax.set_yticks(range(-30, 71, 15))
ax.set_yticklabels(
    [f"{abs(y)}°{'S' if y<0 else 'N'}" for y in range(-30, 71, 15)],
    fontsize=6)
ax.tick_params(length=2, width=0.3, color="#999999", pad=2)
for sp in ax.spines.values():
    sp.set_linewidth(0.5); sp.set_edgecolor("#777777")

# --- 8. COLORBAR --------------------------------------------
from matplotlib.colorbar import ColorbarBase
from matplotlib.colors import Normalize
from mpl_toolkits.axes_grid1.inset_locator import inset_axes

ax_cb = inset_axes(ax, width="22%", height="3.5%",
                   loc="lower left",
                   bbox_to_anchor=(0.02, 0.06, 1, 1),
                   bbox_transform=ax.transAxes,
                   borderpad=0)
cmap = plt.cm.RdYlBu_r
cb = ColorbarBase(ax_cb, cmap=cmap, norm=Normalize(0, 100),
                  orientation="horizontal")
cb.set_label("Ancestral allele frequency (%)", fontsize=6, labelpad=3)
cb.ax.tick_params(labelsize=5.5)
cb.outline.set_linewidth(0.35)

# --- 9. LEYENDA FLECHAS ------------------------------------
legend_elements = [
    Line2D([0],[0], color="#2C2C2C", lw=2.0,
           label="Out-of-Africa (~70 ka)"),
    Line2D([0],[0], color="#8B1A1A", lw=2.0,
           label="Beringia cold enrichment (~15 ka)"),
    Line2D([0],[0], color="#2980B9", lw=1.8,
           label="Neolithic loss in Europe (~8–5 ka)"),
    Line2D([0],[0], color="#888888", lw=1.2, linestyle="dashed",
           label="Post-colonial admixture (1521–1850)"),
]
ax.legend(handles=legend_elements,
          loc="lower right", fontsize=5.5,
          framealpha=0.92, edgecolor="#CCCCCC",
          handlelength=2.2, borderpad=0.6,
          title="Migration / selection events",
          title_fontsize=6)

# --- 10. TITULO Y FUENTE -----------------------------------
ax.set_title(
    "Global frequency of ancestral metabolic variant  (NCDN  chr1:35,565,741)\n"
    "African ancestral baseline (~70%)  ·  Cold-environment enrichment (77–100%)  ·  "
    "European Neolithic loss (3%)",
    fontsize=8, pad=8, color="#222222"
)
ax.text(0.99, 0.01,
        "Source: HGDP + 1000 Genomes + gnomAD v3.1.2  |  EastWestDM v7.1",
        transform=ax.transAxes,
        ha="right", va="bottom", fontsize=5, color="#888888")

# --- 11. EXPORTAR ------------------------------------------
import os
out_dir = os.path.expanduser("~/EastWestDM/act3")
os.makedirs(out_dir, exist_ok=True)

for fmt, d in [("png", 300), ("pdf", 300)]:
    fname = os.path.join(out_dir, f"figure6_world_map_ancestral_freq.{fmt}")
    plt.savefig(fname, dpi=d, bbox_inches="tight", facecolor="white")
    print(f"  -> {fname}")

print("\nDone.")
