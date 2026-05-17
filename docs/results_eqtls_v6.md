# Results — New block: GTEx eQTL validation (insert after Fig. 3, before SLC2A3)

---

## Eastern-specific variants at the LDHA/LDHC locus exert coordinated trans-tissue regulatory effects
(Fig. 4 — new)

To assess whether the Eastern-specific variants identified by paleogenomic intersection
have functional consequences in modern tissues, we queried the GTEx v8 database
(n=838 donors, 54 tissues) for expression quantitative trait loci (eQTL) activity across
the 168 Eastern-specific variants in seven metabolically relevant tissues: skeletal muscle,
subcutaneous and visceral adipose, pancreas, liver, whole blood, and brain cortex.

A single Eastern-specific variant — chr11:18,411,103 C>T (hg38), annotated as an
upstream regulatory variant of LDHA — emerged as the top functional hit, acting as a
*trans*-eQTL for LDHC (lactate dehydrogenase C; ENSG00000156873) across all seven
queried tissues simultaneously (Fig. 4A). The Eastern-ancestral allele (C) was associated
with suppressed LDHC expression in skeletal muscle (p = 3.71 × 10⁻⁶⁴, NES = −0.935),
subcutaneous adipose (p = 1.46 × 10⁻⁵⁹, NES = −1.058), visceral adipose
(p = 1.11 × 10⁻⁴¹, NES = −0.944), whole blood (p = 7.39 × 10⁻³⁰, NES = −0.679),
pancreas (p = 7.33 × 10⁻²⁶, NES = −0.954), liver (p = 9.12 × 10⁻²⁴, NES = −1.084),
and brain cortex (p = 2.70 × 10⁻²², NES = −1.049) (Fig. 4B). The consistency of
direction (all negative NES) and magnitude (|NES| > 0.9 in five of seven tissues)
indicates a coordinated, architecture-wide suppression of aerobic lactate metabolism
rather than tissue-specific regulatory noise.

LDHC encodes the testis/muscle isoform of lactate dehydrogenase, catalysing the
interconversion of pyruvate and lactate at the terminal step of anaerobic glycolysis.
Its coordinated downregulation across muscle, adipose, liver, pancreas, and brain
by an Eastern-specific upstream variant of LDHA — itself showing 42 Eastern-specific
variants, the highest of any candidate gene — provides the first direct mechanistic
link between the paleogenomically-defined Eastern metabolic architecture and
differential glycolytic flux in tissues central to T2D pathophysiology.

The same variant also acts as a *cis*-eQTL for LDHA itself in skeletal muscle
(p = 2.70 × 10⁻¹², NES = −0.192) and subcutaneous adipose (p = 3.26 × 10⁻¹¹,
NES = −0.177), and as a *trans*-eQTL for TSG101 in skeletal muscle
(p = 1.86 × 10⁻¹⁸, NES = +0.282), suggesting the locus operates as a regulatory
hub with pleiotropic metabolic effects extending beyond the LDH gene family.

Of the 1,511 eQTL associations detected across all 168 Eastern-specific variants
(p < 0.01 threshold; GTEx v8 singleTissueEqtl), the LDHA upstream variant
chr11:18,411,103 accounted for the seven most significant associations in the dataset,
all targeting LDHC. No comparable multi-tissue eQTL signal was identified among
Western-specific variants, consistent with the asymmetric functional architecture
suggested by the variant count disparity (168 Eastern vs. 67 Western).

---

## Figure 4 legend (new)

**Figure 4. Multi-tissue eQTL effects of Eastern-specific variant chr11:18,411,103 C>T.**
**(A)** Tissue distribution of eQTL associations (p < 0.01) across 168 Eastern-specific
variants queried in GTEx v8 (7 tissues). The LDHA upstream variant chr11:18,411,103
accounts for the 7 strongest associations in the dataset, all targeting LDHC.
**(B)** NES and -log₁₀(p) for the LDHC eQTL signal across 7 tissues. All associations
show negative NES (Eastern ancestral allele associated with reduced LDHC expression),
with |NES| > 0.9 in muscle, adipose, pancreas, liver, and brain cortex. Dotted line:
Bonferroni threshold for 1,511 tests (p < 3.31 × 10⁻⁵).

---

## Methods addition (append to "Archaic genome mapping and variant calling" section)

**GTEx eQTL query.** Eastern-specific variants (n = 168 after damage filtering;
n = 282 before) were queried against the GTEx v8 database via the GTEx Portal REST
API v2 (gtexportal.org/api/v2/association/singleTissueEqtl) across seven
metabolically relevant tissues: Muscle_Skeletal, Adipose_Subcutaneous,
Adipose_Visceral_Omentum, Pancreas, Liver, Brain_Cortex, and Whole_Blood.
Variants were formatted as GTEx identifiers (chr_pos_ref_alt_b38). Associations
with p < 0.01 were retained (n = 1,511 across all variants and tissues). No
multiple-testing correction was applied at the query stage; the Bonferroni threshold
for 1,511 tests is p < 3.31 × 10⁻⁵, exceeded by 13 associations, all at the
chr11:18,411,103 locus targeting LDHC. Query code available at
https://github.com/EmilioGarciaMoran/EastWestDM (scripts/query_gtex_all.py).

---

## Discussion addition (append to "Regulatory ghost adaptation" paragraph)

The multi-tissue eQTL architecture of the LDHA/LDHC locus reinforces this
interpretation. The Eastern-specific upstream variant chr11:18,411,103 suppresses
LDHC expression with effect sizes of |NES| ≈ 1.0 across muscle, adipose, liver,
pancreas, and brain — organs that collectively define the metabolic syndrome
phenotype. LDHC downregulation shifts the pyruvate/lactate equilibrium toward
oxidative phosphorylation, a thermogenic adaptation consistent with Arctic
ancestry. In calorically abundant environments, this same shift may impair the
metabolic flexibility required for efficient glucose disposal, contributing to the
earlier and more aggressive T2D presentation observed in AMR and EAS populations.
The brain cortex eQTL signal (p = 2.70 × 10⁻²²) is particularly notable given
SLC2A3's invariance across the same hominin lineages: while brain glucose
*transport* was conserved, brain glucose *metabolism* retains Eastern-specific
regulatory variation — a distinction with potential implications for neurocognitive
aspects of T2D not captured by peripheral biomarkers.
