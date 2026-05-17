#!/usr/bin/env python3
# =============================================================
# MAPA MUNDIAL — Ancestral NCDN variant frequency  v2
# chr1:35,565,741 — Global frequency distribution
# Correcciones v2:
#   - Flecha Beringia por el Ártico (rad alto)
#   - Out-of-Africa desde Etiopía real
#   - Surui/Karitiana separados
#   - Colorbar dentro del mapa arriba izquierda
#   - Offsets mejorados sin solapamientos
#   - Punto Siberia/Denisova añadido
# =============================================================

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.colorbar import ColorbarBase
from matplotlib.colors import Normalize
from mpl_toolkits.axes_grid1.inset_locator import inset_axes
import geopandas as gpd
import warnings
warnings.filterwarnings("ignore")

# --- 1. DATOS POBLACIONALES ---------------------------------
populations = [
    # Deep-branching African — ancestral baseline
    {"name": "San",        "lat": -25.0, "lon":  20.0, "freq": 92},
    {"name": "Biaka",      "lat":   3.0, "lon":  16.5, "freq": 91},
    {"name": "Mbuti",      "lat":   1.5, "lon":  27.5, "freq": 83},
    {"name": "Yoruba",     "lat":   7.4, "lon":   3.9, "freq": 70},
    {"name": "ESN",        "lat":   5.5, "lon":   6.8, "freq": 69},
    {"name": "GWD",        "lat":  13.4, "lon": -15.3, "freq": 64},
    {"name": "LWK",        "lat":  -1.0, "lon":  37.0, "freq": 65},
    # Cold-enriched — EAS + Nativo americano
    {"name": "EAS",        "lat":  35.0, "lon": 108.0, "freq": 78},
    {"name": "Siberia\n(Denisova)", "lat": 51.4, "lon":  84.7, "freq": 78},
    {"name": "Surui",      "lat": -11.5, "lon": -59.5, "freq": 100},
    {"name": "Karitiana",  "lat":  -9.0, "lon": -63.5, "freq": 100},
    {"name": "Pima",       "lat":  28.5, "lon":-109.0, "freq": 77},
    {"name": "Maya",       "lat":  17.0, "lon": -90.0, "freq": 67},
    # AMR — gradiente admixture
    {"name": "Peruvian",   "lat": -12.5, "lon": -76.0, "freq": 53},
    {"name": "Mexican",    "lat":  20.0, "lon": -99.5, "freq": 39},
    {"name": "AMR\ngnomAD","lat":   8.0, "lon": -80.0, "freq": 31},
    {"name": "Colombian",  "lat":   5.5, "lon": -75.0, "freq": 29},
    # African American — admixture dilution
    {"name": "ACB",        "lat":  13.1, "lon": -59.6, "freq": 73},
    {"name": "ASW",        "lat":  34.5, "lon": -82.0, "freq": 49},
    # European — Neolithic loss
    {"name": "NFE",        "lat":  50.0, "lon":  10.0, "freq":  3},
]

# --- 2. COLOR POR FRECUENCIA --------------------------------
cmap = plt.cm.RdYlBu_r
def freq_color(f): return cmap(f / 100.0)

# --- 3. MAPA BASE -------------------------------------------
print("Loading world map...")
world = gpd.read_file(
    "https://naturalearth.s3.amazonaws.com/110m_cultural/"
    "ne_110m_admin_0_countries.zip"
)

# --- 4. FIGURA ----------------------------------------------
print("Rendering...")
fig, ax = plt.subplots(figsize=(210/25.4, 125/25.4),
                       dpi=300, facecolor="white")
ax.set_facecolor("#D6EAF8")
world.plot(ax=ax, color="#F0EDE8", edgecolor="#BBBBBB",
           linewidth=0.22, zorder=1)

# --- 5. FLECHAS DE MIGRACIÓN --------------------------------
# Out-of-Africa: Etiopía → Siberia (arco suave por Arabia)
ax.annotate("", xy=(84.7, 51.4), xytext=(38.0, 8.0),
    arrowprops=dict(arrowstyle="-|>", color="#2C2C2C", lw=2.2,
                    mutation_scale=10,
                    connectionstyle="arc3,rad=-0.25"), zorder=5)

# Out-of-Africa: Etiopía → Europa (arco norte)
ax.annotate("", xy=(10.0, 50.0), xytext=(38.0, 8.0),
    arrowprops=dict(arrowstyle="-|>", color="#2C2C2C", lw=2.2,
                    mutation_scale=10,
                    connectionstyle="arc3,rad=0.18"), zorder=5)

# Beringia: Siberia → Américas — arco por el Ártico
# Dividimos en dos segmentos para forzar paso ártico
ax.annotate("", xy=(-150.0, 65.0), xytext=(84.7, 51.4),
    arrowprops=dict(arrowstyle="-", color="#8B1A1A", lw=2.5,
                    mutation_scale=10,
                    connectionstyle="arc3,rad=-0.45"), zorder=5)
ax.annotate("", xy=(-59.5, -11.5), xytext=(-150.0, 65.0),
    arrowprops=dict(arrowstyle="-|>", color="#8B1A1A", lw=2.5,
                    mutation_scale=10,
                    connectionstyle="arc3,rad=-0.30"), zorder=5)

# Neolithic loss: Anatolia → Europa (flecha azul)
ax.annotate("", xy=(10.0, 50.0), xytext=(33.0, 38.0),
    arrowprops=dict(arrowstyle="-|>", color="#2980B9", lw=2.2,
                    mutation_scale=10,
                    connectionstyle="arc3,rad=0.20"), zorder=5)

# Conquista española → México (gris punteado)
ax.annotate("", xy=(-99.5, 20.0), xytext=(-5.0, 40.0),
    arrowprops=dict(arrowstyle="-|>", color="#999999", lw=1.2,
                    mutation_scale=8,
                    connectionstyle="arc3,rad=0.22",
                    linestyle="dashed"), zorder=5)

# Trata transatlántica → Caribe (gris punteado)
ax.annotate("", xy=(-59.6, 13.1), xytext=(-5.0, 5.0),
    arrowprops=dict(arrowstyle="-|>", color="#999999", lw=1.2,
                    mutation_scale=8,
                    connectionstyle="arc3,rad=-0.12",
                    linestyle="dashed"), zorder=5)

# --- 6. PUNTOS Y ETIQUETAS ----------------------------------
# Offsets (dx, dy) en grados para cada población
offsets = {
    "San":            (  5.0, -5.0),
    "Biaka":          ( -7.0,  3.5),
    "Mbuti":          (  5.0,  3.5),
    "Yoruba":         ( -7.0,  3.5),
    "ESN":            (  5.5, -4.5),
    "GWD":            ( -7.0, -4.0),
    "LWK":            (  5.5,  3.5),
    "EAS":            (  6.0,  3.5),
    "Siberia\n(Denisova)": ( 6.0, -5.0),
    "Surui":          ( -8.0, -4.5),
    "Karitiana":      (  5.5,  4.0),
    "Pima":           ( -8.0,  3.5),
    "Maya":           (  5.5, -4.5),
    "Peruvian":       ( -8.5,  3.5),
    "Mexican":        (  5.5,  3.5),
    "AMR\ngnomAD":    ( -9.0, -4.5),
    "Colombian":      (  5.5,  3.5),
    "ACB":            (  5.5,  3.5),
    "ASW":            (  5.5, -4.5),
    "NFE":            (  5.5,  3.5),
}

for pop in populations:
    x, y  = pop["lon"], pop["lat"]
    freq  = pop["freq"]
    color = freq_color(freq)
    size  = 30 + freq * 1.7

    ax.scatter(x, y, s=size, c=[color],
               edgecolors="white", linewidths=0.9,
               zorder=7, alpha=0.93)

    name = pop["name"]
    dx, dy = offsets.get(name, (5, 3))

    ax.annotate(f"{name}\n{freq}%",
        xy=(x, y), xytext=(x + dx, y + dy),
        fontsize=5.2, ha="center", va="center",
        color="#1a1a1a", linespacing=1.25,
        bbox=dict(boxstyle="round,pad=0.22",
                  facecolor="white", edgecolor="#CCCCCC",
                  alpha=0.90, linewidth=0.4),
        arrowprops=dict(arrowstyle="-", color="#AAAAAA",
                        linewidth=0.35, shrinkA=3, shrinkB=3),
        zorder=9)

# --- 7. MARCADOR BERINGIA ----------------------------------
ax.plot(-168, 65.5, "^", markersize=7,
        color="#8B1A1A", markeredgecolor="white",
        markeredgewidth=0.7, zorder=8)
ax.annotate("Beringia\n~15 ka",
    xy=(-168, 65.5), xytext=(-155, 59),
    fontsize=5.2, ha="center", color="#8B1A1A",
    bbox=dict(boxstyle="round,pad=0.2", facecolor="white",
              edgecolor="#C0392B", alpha=0.88, linewidth=0.5),
    arrowprops=dict(arrowstyle="-", color="#C0392B",
                    linewidth=0.5), zorder=9)

# --- 8. EJES ------------------------------------------------
ax.set_xlim(-130, 150)
ax.set_ylim(-40, 78)
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

# --- 9. COLORBAR — arriba izquierda dentro del mapa --------
ax_cb = inset_axes(ax, width="20%", height="3%",
                   loc="upper left",
                   bbox_to_anchor=(0.02, -0.04, 1, 1),
                   bbox_transform=ax.transAxes,
                   borderpad=0)
cb = ColorbarBase(ax_cb, cmap=cmap, norm=Normalize(0, 100),
                  orientation="horizontal")
cb.set_label("Ancestral allele frequency (%)",
             fontsize=5.8, labelpad=3)
cb.ax.tick_params(labelsize=5.2)
cb.outline.set_linewidth(0.35)

# Muescas de referencia
for val, lbl in [(3, "NFE\n3%"), (70, "AFR\n~70%"), (100, "Surui\n100%")]:
    ax_cb.axvline(val, color="white", linewidth=1.0, zorder=5)
    ax_cb.text(val/100, -0.8, lbl,
               transform=ax_cb.transAxes,
               ha="center", va="top", fontsize=4.5, color="#444")

# --- 10. LEYENDA FLECHAS -----------------------------------
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

# --- 11. TÍTULO --------------------------------------------
ax.set_title(
    "Global frequency of ancestral metabolic variant  "
    "(NCDN  chr1:35,565,741)\n"
    "African ancestral baseline (~70%)  ·  "
    "Cold-environment enrichment (77–100%)  ·  "
    "European Neolithic loss (3%)",
    fontsize=8.5, pad=9, color="#1a1a1a",
    fontweight="normal"
)
ax.text(0.995, 0.008,
        "Source: HGDP + 1000 Genomes + gnomAD v3.1.2  |  EastWestDM v7.1",
        transform=ax.transAxes,
        ha="right", va="bottom", fontsize=4.8, color="#999999")

# --- 12. EXPORTAR ------------------------------------------
import os
out = os.path.expanduser("~/EastWestDM/act3")
os.makedirs(out, exist_ok=True)

for fmt, d in [("png", 300), ("pdf", 300)]:
    p = os.path.join(out, f"figure6_world_map_v2.{fmt}")
    plt.savefig(p, dpi=d, bbox_inches="tight", facecolor="white")
    print(f"  -> {p}")

print("\nDone.")
