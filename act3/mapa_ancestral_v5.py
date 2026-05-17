#!/usr/bin/env python3
# =============================================================
# MAPA MUNDIAL — Ancestral NCDN variant frequency  v5
# Correcciones v5:
#   - Colorbar con fondo blanco via patch (no set_facecolor)
#   - xlim al inicio antes de cualquier plot
#   - Beringia asiática recortada a 143°E
#   - Colorbar muescas corregidas
# =============================================================

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.colorbar import ColorbarBase
from matplotlib.colors import Normalize
from matplotlib.patches import FancyBboxPatch
from mpl_toolkits.axes_grid1.inset_locator import inset_axes
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

# --- 2. FIGURA Y LÍMITES ------------------------------------
print("Loading world map...")
world = gpd.read_file(
    "https://naturalearth.s3.amazonaws.com/110m_cultural/"
    "ne_110m_admin_0_countries.zip"
)

print("Rendering...")
fig, ax = plt.subplots(figsize=(210/25.4, 125/25.4),
                       dpi=300, facecolor="white")
ax.set_facecolor("#D6EAF8")

# LÍMITES AL INICIO — antes de cualquier plot
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

# Neolithic loss: Anatolia → Europa Occidental (azul)
ax.annotate("", xy=(5.0, 48.0), xytext=(33.0, 38.0),
    arrowprops=dict(arrowstyle="-|>", color="#2980B9", lw=2.0,
                    mutation_scale=10,
                    connectionstyle="arc3,rad=0.28"), zorder=5)

# BERINGIA — polilínea manual
# Segmento asiático: Siberia → Chukotka (max 143°E)
bx_a = [84.7, 108.0, 128.0, 143.0]
by_a = [51.4,  57.0,  62.5,  65.5]
ax.plot(bx_a, by_a, color="#8B1A1A", lw=2.5, zorder=5,
        solid_capstyle="round", solid_joinstyle="round",
        clip_on=True)

# Segmento americano: Beringia → Amazonia
bx_b = [-172.0, -160.0, -148.0, -125.0, -104.0, -78.0, -65.0]
by_b = [  66.5,   65.0,   62.0,   55.0,   33.0,   6.0,  -8.0]
ax.plot(bx_b, by_b, color="#8B1A1A", lw=2.5, zorder=5,
        solid_capstyle="round", solid_joinstyle="round",
        clip_on=True)

# Flecha terminal → Surui
ax.annotate("", xy=(-59.5, -11.5), xytext=(-65.0, -8.0),
    arrowprops=dict(arrowstyle="-|>", color="#8B1A1A",
                    lw=2.5, mutation_scale=11), zorder=5)

# Etiqueta Beringia
ax.plot(-168, 66.5, "^", markersize=7, color="#8B1A1A",
        markeredgecolor="white", markeredgewidth=0.8, zorder=8)
ax.annotate("Beringia\n~15 ka",
    xy=(-168, 66.5), xytext=(-148, 72),
    fontsize=5.5, ha="center", color="#8B1A1A",
    bbox=dict(boxstyle="round,pad=0.25", facecolor="white",
              edgecolor="#C0392B", alpha=0.90, linewidth=0.5),
    arrowprops=dict(arrowstyle="-", color="#C0392B", linewidth=0.5),
    zorder=9)

# Conquista española → México
ax.annotate("", xy=(-99.5, 20.5), xytext=(-6.0, 38.0),
    arrowprops=dict(arrowstyle="-|>", color="#999999", lw=1.2,
                    mutation_scale=8,
                    connectionstyle="arc3,rad=0.18",
                    linestyle="dashed"), zorder=5)

# Trata transatlántica → Caribe
ax.annotate("", xy=(-59.6, 13.5), xytext=(-6.0, 5.0),
    arrowprops=dict(arrowstyle="-|>", color="#999999", lw=1.2,
                    mutation_scale=8,
                    connectionstyle="arc3,rad=-0.10",
                    linestyle="dashed"), zorder=5)

# --- 4. PUNTOS Y ETIQUETAS ----------------------------------
offsets = {
    "San":        (  5.5, -5.5),
    "Biaka":      ( -7.5,  3.5),
    "Mbuti":      (  6.0,  4.0),
    "Yoruba":     ( -7.5,  4.0),
    "ESN":        (  6.0, -4.5),
    "GWD":        ( -7.5, -4.5),
    "LWK":        (  6.0,  3.5),
    "EAS":        (  6.5,  3.5),
    "Surui":      ( -8.0, -4.5),
    "Karitiana":  (  6.5,  4.0),
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
    color = fc(freq)
    size  = 28 + freq * 1.7

    ax.scatter(x, y, s=size, c=[color],
               edgecolors="white", linewidths=0.9,
               zorder=7, alpha=0.93)

    dx, dy = offsets.get(pop["name"], (5, 3))
    ax.annotate(f"{pop['name']}\n{freq}%",
        xy=(x, y), xytext=(x + dx, y + dy),
        fontsize=5.2, ha="center", va="center",
        color="#1a1a1a", linespacing=1.25,
        bbox=dict(boxstyle="round,pad=0.22",
                  facecolor="white", edgecolor="#CCCCCC",
                  alpha=0.90, linewidth=0.4),
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

# --- 6. COLORBAR — fondo via patch, arriba izquierda -------
# Parche blanco de fondo sobre Canadá
ax.add_patch(FancyBboxPatch(
    (-127, 58), 42, 16,
    boxstyle="round,pad=0.5",
    facecolor="white", edgecolor="#CCCCCC",
    linewidth=0.5, zorder=6, alpha=0.93,
    transform=ax.transData
))

ax_cb = inset_axes(ax, width="24%", height="3.8%",
                   loc="upper left",
                   bbox_to_anchor=(0.015, -0.015, 1, 1),
                   bbox_transform=ax.transAxes,
                   borderpad=0)

cb = ColorbarBase(ax_cb, cmap=cmap, norm=Normalize(0, 100),
                  orientation="horizontal")
cb.set_label("Ancestral allele frequency (%)",
             fontsize=5.8, labelpad=3)
cb.ax.tick_params(labelsize=5.0, length=2)
cb.outline.set_linewidth(0.4)
cb.outline.set_edgecolor("#AAAAAA")

# Muescas de referencia
for frac, lbl in [(0.03, "NFE 3%"), (0.70, "AFR ~70%"), (1.00, "100%")]:
    ax_cb.axvline(frac, color="white", linewidth=0.9, zorder=5)
    ax_cb.text(frac, 1.5, lbl,
               transform=ax_cb.transAxes,
               ha="center", va="bottom",
               fontsize=4.2, color="#555555")

# --- 7. LEYENDA --------------------------------------------
legend_elements = [
    Line2D([0],[0], color="#2C2C2C", lw=2.0,
           label="Out-of-Africa (~70 ka)"),
    Line2D([0],[0], color="#8B1A1A", lw=2.0,
           label="Beringia cold enrichment (~15 ka)"),
    Line2D([0],[0], color="#2980B9", lw=1.8,
           label="Neolithic loss in Europe (~8–5 ka)"),
    Line2D([0],[0], color="#999999", lw=1.2,
           linestyle="dashed",
           label="Post-colonial admixture (1521–1850)"),
]
ax.legend(handles=legend_elements,
          loc="lower right", fontsize=5.5,
          framealpha=0.93, edgecolor="#CCCCCC",
          handlelength=2.5, borderpad=0.7,
          title="Migration / selection events",
          title_fontsize=5.8)

# --- 8. TÍTULO Y FUENTE ------------------------------------
ax.set_title(
    "Global frequency of ancestral metabolic variant  "
    "(NCDN  chr1:35,565,741)\n"
    "African ancestral baseline (~70%)  ·  "
    "Cold-environment enrichment (77–100%)  ·  "
    "European Neolithic loss (3%)",
    fontsize=8.5, pad=9, color="#1a1a1a")
ax.text(0.995, 0.005,
        "Source: HGDP + 1000 Genomes + gnomAD v3.1.2  |  EastWestDM v7.1",
        transform=ax.transAxes,
        ha="right", va="bottom", fontsize=4.8, color="#999999")

# --- 9. EXPORTAR -------------------------------------------
import os
out = os.path.expanduser("~/EastWestDM/act3")
os.makedirs(out, exist_ok=True)
for fmt, d in [("png", 300), ("pdf", 300)]:
    p = os.path.join(out, f"figure6_world_map_v5.{fmt}")
    plt.savefig(p, dpi=d, bbox_inches="tight", facecolor="white")
    print(f"  -> {p}")
print("Done.")
