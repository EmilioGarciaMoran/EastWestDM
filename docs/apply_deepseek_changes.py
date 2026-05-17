#!/usr/bin/env python3
"""Apply DeepSeek's three structural changes to manuscript_v7_EastWest.qmd"""

import re

qmd_path = "/home/egarmo/EastWestDM/docs/manuscript_v7_EastWest.qmd"

with open(qmd_path, "r") as f:
    text = f.read()

# ── CHANGE 1: TITLE ──────────────────────────────────────────────────────────
old_title = """title: |
  Divergent Post-Out-of-Africa Metabolic Adaptations and a Miscalibrated Clinical Reference:
  The Evolutionary Basis of Global Type 2 Diabetes Disparities"""

new_title = """title: |
  Ancestral Metabolic Architecture Lost in European Neolithic Lineages
  Explains Global Type 2 Diabetes Disparities"""

text = text.replace(old_title, new_title)

# ── CHANGE 2: INTRODUCTION — add clinical hook at end of first paragraph ─────
old_intro_p1 = """The three population groups most poorly served by current clinical frameworks — EAS, AMR, and African-ancestry — thus share a common feature: systematic underperformance of risk models calibrated on European reference cohorts."""

new_intro_p1 = """The three population groups most poorly served by current clinical frameworks — EAS, AMR, and African-ancestry — thus share a common feature: systematic underperformance of risk models calibrated on European reference cohorts. This constitutes a systematic clinical bias: diagnostic thresholds, BMI cutoffs, and therapeutic guidelines calibrated on European-ancestry populations consistently underperform in EAS, AMR, and African-ancestry groups not because of differential disease biology, but because they measure the wrong metabolic baseline."""

text = text.replace(old_intro_p1, new_intro_p1)

# ── CHANGE 3: DISCUSSION — add AMA/EPMA framework at opening ────────────────
old_discussion_open = """### Two adaptive solutions of equivalent fitness

The metabolic architectures documented here represent independent evolutionary solutions of equivalent adaptive success — not differential pathology. The European lineage, beginning with pre-agricultural Neandertals in temperate environments and consolidated by the Neolithic transition, optimised for carbohydrate processing from plant-based substrates: ACACA lipogenesis, PPARGC1A thermogenesis, PPARγ adipogenesis calibrated for cereal-derived glucose. The Siberian and Beringian lineage optimised for maximal glycolytic efficiency under cold stress and caloric scarcity, with brain glucose supply as the inviolable constraint. The clinical problem arises not from the architectures themselves but from their encounter with a globally uniform food environment and a medical reference standard that, by historical accident, reflects only one of them."""

new_discussion_open = """### Two adaptive solutions of equivalent fitness

We propose a terminological framework that clarifies the evolutionary asymmetry documented here. The **Ancestral Metabolic Architecture (AMA)** — characterised by high NCDN variant frequency, LDHC suppression across peripheral tissues, enhanced anaerobic glycolytic flux, and preserved brain glucose priority — represents the metabolic baseline present in Africa prior to the Out-of-Africa dispersal and maintained in EAS, unadmixed Native American, and sub-Saharan African populations. The **European Post-Neolithic Metabolic Architecture (EPMA)** — characterised by near-complete loss of AMA variants (NCDN 3%), ACACA lipogenesis, and PPARGC1A thermogenesis — emerged in European lineages beginning with pre-agricultural Neandertals in temperate environments and was consolidated by the Neolithic agrarian transition. The clinical disparity arises not from AMA pathology but from the universal application of EPMA-calibrated diagnostic and therapeutic standards to populations in whom AMA predominates.

The AMA and EPMA represent independent evolutionary solutions of equivalent adaptive success — not differential pathology. The EPMA lineage optimised for carbohydrate processing from plant-based substrates: ACACA lipogenesis, PPARGC1A thermogenesis, PPARγ adipogenesis calibrated for cereal-derived glucose. The AMA lineage optimised for maximal glycolytic efficiency under cold stress and caloric scarcity, with brain glucose supply as the inviolable constraint in both cases. The clinical problem arises not from the architectures themselves but from their encounter with a globally uniform food environment and a medical reference standard that, by historical accident, reflects only the EPMA."""

text = text.replace(old_discussion_open, new_discussion_open)

# ── CHANGE 4: Replace Eastern/Western with AMA/EPMA where appropriate ────────
# Only in discussion — keep "Eastern variants" in Results (methodological)
replacements_discussion = [
    ("the ancestral metabolic architecture that Europeans specifically lost",
     "the AMA that Europeans specifically lost through EPMA selection"),
    ("the European low-frequency architecture",
     "the EPMA low-frequency architecture"),
    ("the ancestral African glycolytic architecture",
     "the AMA"),
    ("the Western metabolic architecture",
     "the EPMA"),
    ("the ancestral architecture",
     "the AMA"),
]

for old, new in replacements_discussion:
    text = text.replace(old, new)

# ── CHANGE 5: Update title in header/footer references ───────────────────────
text = text.replace(
    "Divergent Post-Out-of-Africa Metabolic Adaptations and a Miscalibrated Clinical Reference:",
    "Ancestral Metabolic Architecture Lost in European Neolithic Lineages:"
)
text = text.replace(
    "Divergent Post-Out-of-Africa Metabolic Adaptations and a Miscalibrated Clinical Reference",
    "Ancestral Metabolic Architecture and Global T2D Disparities"
)

# Write
with open(qmd_path, "w") as f:
    f.write(text)

print("Done — changes applied to manuscript_v7_EastWest.qmd")
print("\nChanges made:")
print("  1. Title updated to AMA/EPMA framing")
print("  2. Introduction: clinical hook added to first paragraph")
print("  3. Discussion: AMA/EPMA framework defined at opening")
print("  4. Key terminology updated to AMA/EPMA")
print("  5. Header references updated")
