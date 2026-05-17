#!/usr/bin/env python3
# =============================================================
# MAPA MUNDIAL — Ancestral NCDN variant frequency  v7
# Publication quality — Genome Medicine Figure 6
# Fixes v7:
#   - Beringia asiática recortada a 140°E
#   - Todos los bbox etiquetas facecolor="white" explícito
#   - Muescas colorbar en negro
#   - Etiqueta "Out-of-Africa ~70 ka" en Etiopía
#   - LWK offset corregido
#   - Mbuti bbox corregido
#   - Tamaño figura ligeramente mayor para respirar
#   - Etiqueta fuente completa
# =============================================================

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.colorbar import ColorbarBase
from matplotlib.colors import Normalize
import geopandas as gpd
import warnings
warnings.filterwarnings("ignore")

# --- 1. DATOS -----------------------------------------------
populations = [
    {"name": "San",        "lat": -25.0, "lon":  20.0, "freq": 92},
    {"name": "Biaka",      "lat":   3.0, "lon":  16.5, "freq": 91},
    {"name": "Mbuti",      "lat":   1.5, "lon":  27.5, "freq": 83},
    {"name": "Yoruba",     "lat":   7.4, "lon":   3.9, "freq": 70},
    {"name": "ESN",        "lat":   5.5, "lon":   6.8, "freq": 69},
    {"name": "GWD",        "lat":  13.4, "lon": -15.3, "freq": 64},
    {"name": "LWK",        "lat":  -1.0, "lon":  37.0, "freq": 65},
    {"name": "EAS",        "lat":  35.0, "lon": 108.0, "freq": 78},
    {"name": "Surui",      "lat": -11.5, "lon": -59.5, "freq": 100},
    {"name": "Karitiana",  "lat":  -8.0, "lon": -63.5, "freq": 100},
    {"name": "Pima",       "lat":  28.5, "lon":-109.0, "freq": 77},
    {"name": "Maya",       "lat":  17.0, "lon": -90.0, "freq": 67},
    {"name": "Peruvian",   "lat": -12.5, "lon": -76.0, "freq": 53},
    {"name": "Mexican",    "lat":  20.5, "lon": -99.5, "freq": 39},
    {"name": "AMR gnomAD", "lat":   8.0, "lon": -79.0, "freq": 31},
    {"name": "Colombian",  "lat":   5.5, "lon": -74.0, "freq": 29},
    {"name": "ACB",        "lat":  13.5, "lon": -59.6, "freq": 73},
    {"name": "ASW",        "lat":  34.5, "lon": -82.0, "freq": 49},
    {"name": "NFE",        "lat":  50.0, "lon":  10.0, "freq":  3},
]

cmap = plt.cm.RdYlBu_r
def fc(f): return cmap(f / 100.0)

# --- 2. FIGURA ----------------------------------------------
print("Loading world map...")
world = gpd.read_file(
    "https://naturalearth.s3.amazonaws.com/110m_cultural/"
    "ne_110m_admin_0_countries.zip"
)

FW, FH = 220/25.4, 132/25.4
print("Rendering...")
fig = plt.figure(figsize=(FW, FH), dpi=300, facecolor="white")
ax  = fig.add_axes([0.03, 0.06, 0.94, 0.88])
ax.set_facecolor("#D6EAF8")

# LÍMITES AL INICIO
ax.set_xlim(-128, 148)
ax.set_ylim(-38, 78)

world.plot(ax=ax, color="#F0EDE8", edgecolor="#BBBBBB",
           linewidth=0.22, zorder=1)

# --- 3. FLECHAS ---------------------------------------------

# Out-of-Africa → Siberia
ax.annotate("", xy=(84.7, 51.4), xytext=(38.0, 8.0),
    arrowprops=dict(arrowstyle="-|>", color="#2C2C2C", lw=2.2,
                    mutation_scale=11,
                    connectionstyle="arc3,rad=-0.22"), zorder=5)

# Out-of-Africa → Europa
ax.annotate("", xy=(12.0, 49.0), xytext=(38.0, 8.0),
    arrowprops=dict(arrowstyle="-|>", color="#2C2C2C", lw=2.2,
                    mutation_scale=11,
                    connectionstyle="arc3,rad=0.20"), zorder=5)

# Etiqueta Out-of-Africa en Etiopía
ax.annotate("Out-of-Africa\n~70 ka",
    xy=(38.0, 8.0), xytext=(52.0, 2.0),
    fontsize=5.5, ha="center", color="#2C2C2C",
    bbox=dict(boxstyle="round,pad=0.25", facecolor="white",
              edgecolor="#888888", alpha=0.92, linewidth=0.5),
    arrowprops=dict(arrowstyle="-", color="#888888", linewidth=0.5),
    zorder=9)

# Neolithic loss: Anatolia → Europa (azul)
ax.annotate("", xy=(5.0, 48.0), xytext=(33.0, 38.0),
    arrowprops=dict(arrowstyle="-|>", color="#2980B9", lw=2.0,
                    mutation_scale=10,
                    connectionstyle="arc3,rad=0.28"), zorder=5)

# BERINGIA — polilínea manual
# Asiática: max 140°E
bx_a = [84.7, 105.0, 125.0, 140.0]
by_a = [51.4,  57.0,  62.0,  65.0]
ax.plot(bx_a, by_a, color="#8B1A1A", lw=2.5, zorder=5,
        solid_capstyle="round", solid_joinstyle="round",
        clip_on=True)

# Americana: Beringia → Amazonia
bx_b = [-172.0, -160.0, -148.0, -125.0, -104.0, -78.0, -65.0]
by_b = [  66.5,   65.0,   62.0,   55.0,   33.0,   6.0,  -8.0]
ax.plot(bx_b, by_b, color="#8B1A1A", lw=2.5, zorder=5,
        solid_capstyle="round", solid_joinstyle="round",
        clip_on=True)

# Flecha terminal → Surui
ax.annotate("", xy=(-59.5, -11.5), xytext=(-65.0, -8.0),
    arrowprops=dict(arrowstyle="-|>", color="#8B1A1A",
                    lw=2.5, mutation_scale=11), zorder=5)

# Marcador + etiqueta Beringia
ax.plot(-168, 66.5, "^", markersize=7, color="#8B1A1A",
        markeredgecolor="white", markeredgewidth=0.8, zorder=8)
ax.annotate("Beringia\n~15 ka",
    xy=(-168, 66.5), xytext=(-148, 72),
    fontsize=5.5, ha="center", color="#8B1A1A",
    bbox=dict(boxstyle="round,pad=0.25", facecolor="white",
              edgecolor="#C0392B", alpha=0.92, linewidth=0.5),
    arrowprops=dict(arrowstyle="-", color="#C0392B", linewidth=0.5),
    zorder=9)

# Conquista española → México
ax.annotate("", xy=(-99.5, 20.5), xytext=(-6.0, 38.0),
    arrowprops=dict(arrowstyle="-|>", color="#888888", lw=1.2,
                    mutation_scale=8,
                    connectionstyle="arc3,rad=0.18",
                    linestyle="dashed"), zorder=5)

# Trata transatlántica → Caribe
ax.annotate("", xy=(-59.6, 13.5), xytext=(-6.0, 5.0),
    arrowprops=dict(arrowstyle="-|>", color="#888888", lw=1.2,
                    mutation_scale=8,
                    connectionstyle="arc3,rad=-0.10",
                    linestyle="dashed"), zorder=5)

# --- 4. PUNTOS Y ETIQUETAS ----------------------------------
offsets = {
    "San":        (  5.5, -5.5),
    "Biaka":      ( -7.5,  3.5),
    "Mbuti":      (  6.5,  4.0),
    "Yoruba":     ( -7.5,  4.0),
    "ESN":        (  5.5, -5.0),
    "GWD":        ( -7.5, -4.5),
    "LWK":        (  7.5,  3.5),
    "EAS":        (  6.5,  3.5),
    "Surui":      ( -8.0, -4.5),
    "Karitiana":  (  6.5,  4.5),
    "Pima":       ( -8.5,  3.5),
    "Maya":       (  6.5, -4.5),
    "Peruvian":   ( -8.5,  3.5),
    "Mexican":    (  6.5,  4.0),
    "AMR gnomAD": ( -9.5, -4.5),
    "Colombian":  (  6.5,  3.5),
    "ACB":        (  6.5,  3.5),
    "ASW":        (  6.5, -4.5),
    "NFE":        (  6.5,  3.5),
}

for pop in populations:
    x, y  = pop["lon"], pop["lat"]
    freq  = pop["freq"]
    size  = 28 + freq * 1.7

    ax.scatter(x, y, s=size, c=[fc(freq)],
               edgecolors="white", linewidths=0.9,
               zorder=7, alpha=0.93)

    dx, dy = offsets.get(pop["name"], (5, 3))
    ax.annotate(f"{pop['name']}\n{freq}%",
        xy=(x, y), xytext=(x+dx, y+dy),
        fontsize=5.2, ha="center", va="center",
        color="#1a1a1a", linespacing=1.25,
        bbox=dict(boxstyle="round,pad=0.22",
                  facecolor="white",        # SIEMPRE blanco
                  edgecolor="#CCCCCC",
                  alpha=0.92, linewidth=0.4),
        arrowprops=dict(arrowstyle="-", color="#AAAAAA",
                        linewidth=0.35, shrinkA=3, shrinkB=3),
        zorder=9)

# --- 5. EJES ------------------------------------------------
ax.set_xticks(range(-120, 141, 30))
ax.set_xticklabels(
    [f"{abs(x)}°{'W' if x<0 else 'E'}" for x in range(-120, 141, 30)],
    fontsize=6)
ax.set_yticks(range(-30, 71, 15))
ax.set_yticklabels(
    [f"{abs(y)}°{'S' if y<0 else 'N'}" for y in range(-30, 71, 15)],
    fontsize=6)
ax.tick_params(length=2.5, width=0.35, color="#999999", pad=2)
for sp in ax.spines.values():
    sp.set_linewidth(0.5); sp.set_edgecolor("#777777")

# --- 6. COLORBAR — fig.add_axes absoluto -------------------
ax_cb = fig.add_axes([0.055, 0.74, 0.20, 0.028])
cb = ColorbarBase(ax_cb, cmap=cmap, norm=Normalize(0, 100),
                  orientation="horizontal")
cb.set_label("Ancestral allele frequency (%)",
             fontsize=5.8, labelpad=3)
cb.ax.tick_params(labelsize=5.0, length=2, colors="#333333")
cb.outline.set_linewidth(0.5)
cb.outline.set_edgecolor("#999999")
ax_cb.patch.set_facecolor("white")
ax_cb.patch.set_alpha(1.0)
ax_cb.set_zorder(10)

# Muescas en NEGRO sobre el gradiente
for frac, lbl in [(0.03, "NFE\n3%"), (0.70, "AFR\n~70%"), (1.00, "100%")]:
    ax_cb.axvline(frac, color="#333333", linewidth=1.0, zorder=5)
    ax_cb.text(frac, 1.55, lbl,
               transform=ax_cb.transAxes,
               ha="center", va="bottom",
               fontsize=4.2, color="#333333", fontweight="500")

# --- 7. LEYENDA --------------------------------------------
legend_elements = [
    Line2D([0],[0], color="#2C2C2C", lw=2.0,
           label="Out-of-Africa (~70 ka)"),
    Line2D([0],[0], color="#8B1A1A", lw=2.0,
           label="Beringia cold enrichment (~15 ka)"),
    Line2D([0],[0], color="#2980B9", lw=1.8,
           label="Neolithic loss in Europe (~8–5 ka)"),
    Line2D([0],[0], color="#888888", lw=1.2,
           linestyle="dashed",
           label="Post-colonial admixture (1521–1850)"),
]
leg = ax.legend(handles=legend_elements,
          loc="lower right", fontsize=5.5,
          framealpha=0.95, edgecolor="#CCCCCC",
          handlelength=2.5, borderpad=0.8,
          title="Migration / selection events",
          title_fontsize=5.8)
leg.get_frame().set_linewidth(0.5)

# --- 8. TÍTULO Y FUENTE ------------------------------------
ax.set_title(
    "Global frequency of ancestral metabolic variant  "
    "(NCDN  chr1:35,565,741)\n"
    "African ancestral baseline (~70%)  ·  "
    "Cold-environment enrichment (77–100%)  ·  "
    "European Neolithic loss (3%)",
    fontsize=8.5, pad=10, color="#1a1a1a",
    fontfamily="DejaVu Sans")

ax.text(0.995, 0.005,
        "Source: HGDP + 1000 Genomes + gnomAD v3.1.2  |  "
        "EastWestDM v7.1  |  García-Morán 2026",
        transform=ax.transAxes,
        ha="right", va="bottom", fontsize=4.8, color="#999999")

# --- 9. EXPORTAR -------------------------------------------
import os
out = os.path.expanduser("~/EastWestDM/act3")
os.makedirs(out, exist_ok=True)
for fmt, d in [("png", 300), ("pdf", 300), ("tiff", 600)]:
    p = os.path.join(out, f"figure6_world_map_v7.{fmt}")
    kw = dict(dpi=d, bbox_inches="tight", facecolor="white")
    if fmt == "tiff":
        kw["pil_kwargs"] = {"compression": "tiff_lzw"}
    plt.savefig(p, **kw)
    print(f"  -> {p}")
print("\nDone.")
