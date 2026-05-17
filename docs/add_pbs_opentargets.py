#!/usr/bin/env python3
"""Add PBS results and Open Targets molQTL data to manuscript .tex"""

import re

tex_path = "/home/egarmo/EastWestDM/docs/manuscript_v7_EastWest.tex"

with open(tex_path, "r") as f:
    text = f.read()

# ── ADD PBS TO RESULTS SECTION ───────────────────────────────
old_gwas = """\\subsection{Global frequency distribution: an ancestral variant with asymmetric selective history}"""

new_pbs_section = """\\subsection{Population Branch Statistics support directional selection on the European lineage}

Population Branch Statistics (PBS) were calculated at the NCDN locus using the Hudson Fst estimator with three populations: AMA (EAS as unadmixed reference), EPMA (NFE), and AFR as outgroup. PBS\\textsubscript{EPMA} = 0.953 substantially exceeded PBS\\textsubscript{AMA} = 0.364, with the AFR outgroup showing the expected near-zero value (PBS\\textsubscript{AFR} = −0.257). The supporting Fst values were: Fst(AMA/EPMA) = 0.732, Fst(AMA/AFR) = 0.102, Fst(EPMA/AFR) = 0.501. This pattern is consistent with directional selection on the European lineage rather than positive selection in cold-adapted AMA populations, supporting the hypothesis that EPMA represents a derived metabolic architecture shaped by Neolithic counter-selection rather than a neutral drift event.

\\subsection{Global frequency distribution: an ancestral variant with asymmetric selective history}"""

text = text.replace(old_gwas, new_pbs_section)

# ── ADD OPEN TARGETS DATA TO eQTL SECTION ───────────────────
old_eqtl_end = """The brain cortex eQTL"""

new_eqtl_end = """Independent fine-mapping in Open Targets Genetics confirmed 11\\textunderscore{}18411103\\textunderscore{}C\\textunderscore{}T as a cis-eQTL credible set variant for LDHC and LDHA across 13 independent molQTL studies (SuSiE fine-mapping), including amygdala (\\textit{p} = 1.95 × 10\\textsuperscript{−18}), skin, induced pluripotent stem cells, ascending aorta, frontal cortex, sigmoid colon, cerebellum, and omental fat pad, with consistent fine-mapping confidence across all tissues. This constitutes independent replication of the LDHC/LDHA cis-regulatory signal across GTEx v8 (7 tissues), eQTLGen (\\textit{n} = 31,684), and Open Targets molQTL (13 studies).

The brain cortex eQTL"""

text = text.replace(old_eqtl_end, new_eqtl_end)

# ── ADD PBS TO METHODS ───────────────────────────────────────
old_methods_end = """\\subsection{Statistical analysis and figure generation}"""

new_pbs_methods = """\\subsection{Population Branch Statistics}

Population Branch Statistics were calculated using the Hudson Fst estimator with three populations: AMA (represented by EAS gnomAD, \\textit{n} = 5,174), EPMA (represented by NFE gnomAD, \\textit{n} = 67,976), and AFR gnomAD as outgroup (\\textit{n} = 41,322). Hudson Fst was computed as: Fst = (\\textit{p}\\textsubscript{1} − \\textit{p}\\textsubscript{2})\\textsuperscript{2} − \\textit{p}\\textsubscript{1}(1−\\textit{p}\\textsubscript{1})/(\\textit{n}\\textsubscript{1}−1) − \\textit{p}\\textsubscript{2}(1−\\textit{p}\\textsubscript{2})/(\\textit{n}\\textsubscript{2}−1) / [\\textit{p}\\textsubscript{1}(1−\\textit{p}\\textsubscript{2}) + \\textit{p}\\textsubscript{2}(1−\\textit{p}\\textsubscript{1})]. T-statistics were computed as T = −log(1 − Fst) and PBS as PBS\\textsubscript{A} = (T\\textsubscript{AB} + T\\textsubscript{AC} − T\\textsubscript{BC})/2. Analysis was performed in R v4.5.2; code available at \\url{https://github.com/EmilioGarciaMoran/EastWestDM}.

\\subsection{Statistical analysis and figure generation}"""

text = text.replace(old_methods_end, new_pbs_methods)

# ── FIX trans-eQTL → cis-eQTL (final check) ─────────────────
text = text.replace("trans-eQTL", "cis-eQTL")
text = text.replace("trans-eQTL", "cis-eQTL")

with open(tex_path, "w") as f:
    f.write(text)

print("Done — PBS + Open Targets + cis-eQTL fix applied to .tex")
print("Now run: lualatex manuscript_v7_EastWest.tex (twice)")
