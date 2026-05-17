#!/usr/bin/env python3
"""Apply ChatGPT's four surgical fixes to manuscript_v7_EastWest.qmd"""

qmd_path = "/home/egarmo/EastWestDM/docs/manuscript_v7_EastWest.qmd"

with open(qmd_path, "r") as f:
    text = f.read()

fixes = [

    # FIX 1 — "cold-environment enrichment" → softer language
    ("Cold-environment enrichment",
     "Consistent with cold-environment enrichment"),

    ("cold-environment enrichment during the Beringian migration",
     "enrichment consistent with cold-environment selection during the Beringian migration"),

    ("Cold-environment enrichment",
     "Consistent with cold-environment enrichment"),

    ("reflecting cold-environment enrichment during the Beringian",
     "reflecting enrichment consistent with cold-environment selection during the Beringian"),

    ("consistent with positive selection during the Arctic crossing",
     "consistent with enrichment during the Arctic cold-environment bottleneck"),

    # FIX 2 — "miscalibrated clinical reference" → softer
    ("a miscalibrated clinical reference standard",
     "clinical reference frameworks derived predominantly from European-ancestry cohorts"),

    ("as a consequence of a miscalibrated clinical reference standard",
     "as a consequence of clinical reference frameworks calibrated predominantly on European-ancestry cohorts"),

    ("a medical reference standard that, by historical accident, reflects only the EPMA",
     "clinical reference frameworks that, by historical circumstance, were calibrated predominantly on EPMA-carrying populations"),

    ("a medical reference standard that, by historical accident, reflects only one of them",
     "clinical reference frameworks that, by historical circumstance, were calibrated on only one of them"),

    # FIX 3 — LDHC biology justification — add after first LDHC mention
    ("LDHC encodes the muscle/testis isoform of lactate dehydrogenase, catalysing the final step of anaerobic glycolysis.",
     "LDHC encodes the muscle/testis isoform of lactate dehydrogenase, catalysing the final step of anaerobic glycolysis. Although classically described as testis-enriched, LDHC shows documented ectopic expression in skeletal muscle, liver, and brain under metabolic stress conditions, and its co-regulation with LDHA in glycolytically active tissues has been reported in multiple transcriptomic datasets. The coordinated suppression of LDHC alongside LDHA regulatory variants is therefore consistent with a systemic glycolytic programme rather than a tissue-restricted phenomenon."),

    # FIX 4 — protective disclaimer — add at end of Limitations
    ("CRISPR functional validation of the LDHA/LDHC regulatory variant is needed to establish causality.",
     "CRISPR functional validation of the LDHA/LDHC regulatory variant is needed to establish causality. Finally, these findings do not imply deterministic ancestry-specific pathology. They reflect population-level differences in regulatory metabolic architecture shaped by historical selection pressures and demographic processes, and should be interpreted in that evolutionary and epidemiological context rather than as fixed biological categories."),

    # FIX 5 — soften pharmacogenomics speculation
    ("SGLT2 inhibitors, GLP-1 receptor agonists, and thiazolidinediones were validated predominantly in European-ancestry cohorts.",
     "SGLT2 inhibitors, GLP-1 receptor agonists, and thiazolidinediones were validated predominantly in European-ancestry cohorts, and direct pharmacogenomic evidence in AMA-carrying populations is currently limited."),

]

n = 0
for old, new in fixes:
    if old in text:
        text = text.replace(old, new)
        n += 1
        print(f"  ✓ Applied: {old[:60]}...")
    else:
        print(f"  ✗ Not found: {old[:60]}...")

with open(qmd_path, "w") as f:
    f.write(text)

print(f"\nDone — {n}/{len(fixes)} fixes applied.")
