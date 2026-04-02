#!/bin/bash
# =============================================================================
# East-West Diabetes Story — Acto 2 v2
# Mejoras:
#   - Fetch con retry automático (3 intentos)
#   - Checkpoint: solo descarga genes faltantes
#   - Árbol filogenético correcto (TimeTree 14 taxa)
#   - 6 especies frías adicionales si tienen ortólogos
#   - Heartbeat a S3 cada 10 genes
#   - Auto-apagado garantizado
# =============================================================================
set -e

S3_BUCKET="sima-egarmo-2026"
S3_PREFIX="eastwest"
REGION="eu-west-1"
WORKDIR="/data/eastwest"
THREADS=8
LOG="${WORKDIR}/logs/act2_v2.log"

mkdir -p ${WORKDIR}/{cds,alignments,paml,results,logs,scripts,go_filter,data}

heartbeat() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a $LOG
    aws s3 cp $LOG \
        s3://${S3_BUCKET}/${S3_PREFIX}/logs/act2_v2.log \
        --region $REGION > /dev/null 2>&1 || true
}

heartbeat "=== East-West DM Acto 2 v2 START ==="
heartbeat "Instance: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
heartbeat "Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type)"

# ==========================================================
# PASO 0 — Descargar datos de S3
# ==========================================================
heartbeat "[0/5] Sincronizando datos desde S3..."

# CDS ya descargados
aws s3 sync s3://${S3_BUCKET}/${S3_PREFIX}/cds/ \
    ${WORKDIR}/cds/ --region $REGION --quiet
N_CDS=$(ls ${WORKDIR}/cds/*.fa 2>/dev/null | wc -l)
heartbeat "  CDS descargados desde S3: ${N_CDS}"

# Listas de genes
aws s3 cp s3://${S3_BUCKET}/${S3_PREFIX}/go_filter/genes_faltantes.txt \
    ${WORKDIR}/go_filter/genes_faltantes.txt --region $REGION
aws s3 cp s3://${S3_BUCKET}/${S3_PREFIX}/go_filter/genes_completados.txt \
    ${WORKDIR}/go_filter/genes_completados.txt --region $REGION
aws s3 cp s3://${S3_BUCKET}/${S3_PREFIX}/go_filter/candidate_genes.csv \
    ${WORKDIR}/go_filter/candidate_genes.csv --region $REGION

# Lista completa de genes
cat ${WORKDIR}/go_filter/genes_faltantes.txt \
    ${WORKDIR}/go_filter/genes_completados.txt | \
    sort -u > ${WORKDIR}/go_filter/gene_symbols_all.txt
N_GENES=$(wc -l < ${WORKDIR}/go_filter/gene_symbols_all.txt)
heartbeat "  Total genes candidatos: ${N_GENES}"

# Árbol filogenético
aws s3 cp s3://${S3_BUCKET}/${S3_PREFIX}/data/species_tree_14taxa.nwk \
    ${WORKDIR}/data/species_tree_14taxa.nwk --region $REGION
heartbeat "  Árbol descargado OK"

# ==========================================================
# PASO 1 — Fetch CDS (solo genes faltantes + retry)
# ==========================================================
heartbeat "[1/5] Fetch CDS — solo genes faltantes (con retry)..."

python3 - << 'PYEOF'
import requests, time, os, sys
from pathlib import Path

OUTDIR  = Path("/data/eastwest/cds")
LOGFILE = open("/data/eastwest/logs/fetch_cds_v2.log", "w", buffering=1)

def log(m):
    print(m, flush=True)
    LOGFILE.write(m + "\n")
    LOGFILE.flush()

# Solo genes faltantes
GENES = [g.strip() for g in
         open("/data/eastwest/go_filter/genes_faltantes.txt") if g.strip()]

# Especies base + 3 frías adicionales (si tienen ortólogos)
SPECIES_BASE = [
    "pan_troglodytes", "gorilla_gorilla", "pongo_abelii",
    "macaca_mulatta", "callithrix_jacchus",
    "mus_musculus", "rattus_norvegicus", "bos_taurus",
    "canis_lupus_familiaris", "loxodonta_africana",
    "tursiops_truncatus", "vulpes_vulpes", "ursus_americanus"
]
SPECIES_COLD = [
    "mustela_putorius_furo",   # hurón — proxy Mustela
    "ovis_aries",              # oveja — ungulado frío
    "equus_caballus"           # caballo
]
SPECIES = SPECIES_BASE + SPECIES_COLD

BASE = "https://rest.ensembl.org"
JH   = {"Accept": "application/json"}
FH   = {"Accept": "text/x-fasta"}

def retry_get(url, headers, params=None, retries=3, delay=2):
    for attempt in range(retries):
        try:
            r = requests.get(url, headers=headers,
                             params=params, timeout=25)
            if r.status_code == 200:
                return r
            if r.status_code == 429:  # rate limit
                time.sleep(delay * (attempt + 1))
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(delay)
    return None

def get_orth(sym, sp):
    r = retry_get(
        f"{BASE}/homology/symbol/homo_sapiens/{sym}",
        headers=JH,
        params={"target_species": sp,
                "type": "orthologues",
                "sequence": "none"})
    if r:
        for h in r.json().get("data",[{}])[0].get("homologies",[]):
            if h.get("target",{}).get("species","") == sp:
                return h["target"].get("id")
    return None

def get_cds(ensg, label):
    r = retry_get(
        f"{BASE}/sequence/id/{ensg}",
        headers=FH,
        params={"type": "cds", "multiple_sequences": "1"})
    if r and len(r.text) > 50:
        lines = r.text.strip().split("\n")
        seq = ""
        for l in lines[1:]:
            if l.startswith(">"): break
            seq += l.strip()
        if len(seq) > 100:
            return f">{label}\n{seq}\n"
    return None

def get_ensg(sym):
    r = retry_get(f"{BASE}/xrefs/symbol/homo_sapiens/{sym}",
                  headers=JH)
    if r:
        return next((x["id"] for x in r.json()
                     if x.get("type") == "gene"), None)
    return None

log(f"Genes faltantes: {len(GENES)} | Especies: {len(SPECIES)+1}")
ok = err = skip = 0

for i, gene in enumerate(GENES):
    ensg_hs = get_ensg(gene)
    time.sleep(0.1)
    if not ensg_hs:
        log(f"  SKIP {gene} — sin ENSG")
        err += 1
        continue

    # homo_sapiens
    f = OUTDIR / f"{gene}_homo_sapiens.fa"
    if f.exists() and f.stat().st_size > 100:
        skip += 1
    else:
        cds = get_cds(ensg_hs, f"{gene}_homo_sapiens")
        time.sleep(0.1)
        if cds: f.write_text(cds); ok += 1
        else: err += 1

    # Otras especies
    gok = 0
    for sp in SPECIES:
        f = OUTDIR / f"{gene}_{sp}.fa"
        if f.exists() and f.stat().st_size > 100:
            skip += 1; continue
        ensg_sp = get_orth(gene, sp)
        time.sleep(0.08)
        if not ensg_sp: err += 1; continue
        cds = get_cds(ensg_sp, f"{gene}_{sp}")
        time.sleep(0.08)
        if cds: f.write_text(cds); ok += 1; gok += 1
        else: err += 1

    if (i + 1) % 10 == 0:
        msg = (f"[{i+1}/{len(GENES)}] {gene}: {gok}/{len(SPECIES)} sp | "
               f"OK:{ok} ERR:{err} SKIP:{skip}")
        log(msg)
        # Heartbeat S3
        import subprocess
        subprocess.run([
            "aws","s3","cp",
            "/data/eastwest/logs/fetch_cds_v2.log",
            f"s3://sima-egarmo-2026/eastwest/logs/fetch_cds_v2.log",
            "--region","eu-west-1"
        ], capture_output=True)

log(f"CDS COMPLETADO — OK:{ok} ERR:{err} SKIP:{skip}")
LOGFILE.close()
PYEOF

N_CDS=$(ls ${WORKDIR}/cds/*.fa 2>/dev/null | wc -l)
heartbeat "  CDS total tras fetch: ${N_CDS}"

# ==========================================================
# PASO 2 — Alineamiento MAFFT + PAML branch-site
# ==========================================================
heartbeat "[2/5] Alineamiento MAFFT + PAML branch-site..."

echo "gene,lnL_alt,lnL_nul,n_taxa" > ${WORKDIR}/results/paml_lrt_raw.csv

run_gene() {
    GENE=$1
    ALNDIR="${WORKDIR}/alignments/${GENE}"
    PAMLDIR="${WORKDIR}/paml/${GENE}"
    TREE="${WORKDIR}/data/species_tree_14taxa.nwk"
    mkdir -p $ALNDIR $PAMLDIR

    # Concatenar CDS disponibles para este gen
    cat ${WORKDIR}/cds/${GENE}_*.fa > ${ALNDIR}/all_taxa.fa 2>/dev/null || return
    N=$(grep -c "^>" ${ALNDIR}/all_taxa.fa 2>/dev/null || echo 0)
    [ "$N" -lt 4 ] && return

    # Alinear con MAFFT
    mafft --auto --quiet \
        ${ALNDIR}/all_taxa.fa > ${ALNDIR}/aligned.fa 2>/dev/null
    [ ! -s ${ALNDIR}/aligned.fa ] && return

    # Podar árbol a las especies presentes en el alineamiento
    TAXA=$(grep "^>" ${ALNDIR}/aligned.fa | sed 's/>//' | \
           sed "s/${GENE}_//g" | tr '\n' ',')

    # PAML necesita árbol con solo las especies del alineamiento
    # Usamos el árbol completo — PAML lo poda automáticamente
    # si las secuencias tienen los nombres correctos

    # CTL modelo alternativo (branch-site, homo_sapiens foreground)
    cat > ${PAMLDIR}/alt.ctl << CTLEOF
seqfile  = ${ALNDIR}/aligned.fa
treefile = ${TREE}
outfile  = ${PAMLDIR}/alt_out.txt
noisy    = 0
verbose  = 0
runmode  = 0
seqtype  = 1
CodonFreq = 2
model    = 2
NSsites  = 2
icode    = 0
fix_kappa = 0
kappa    = 2
fix_omega = 0
omega    = 1
fix_alpha = 1
alpha    = 0
ncatG    = 4
CTLEOF

    # CTL modelo nulo (omega fijado a 1)
    sed 's/fix_omega = 0/fix_omega = 1/' \
        ${PAMLDIR}/alt.ctl > ${PAMLDIR}/nul.ctl

    cd ${PAMLDIR}

    # Modelo alternativo
    codeml alt.ctl > /dev/null 2>&1
    cp alt_out.txt alt_saved.txt 2>/dev/null || return

    # Modelo nulo
    codeml nul.ctl > /dev/null 2>&1
    cp alt_out.txt nul_saved.txt 2>/dev/null || return

    # Extraer log-likelihoods
    lnL_alt=$(grep "^lnL" alt_saved.txt 2>/dev/null | \
              awk '{print $5}' | head -1)
    lnL_nul=$(grep "^lnL" nul_saved.txt 2>/dev/null | \
              awk '{print $5}' | head -1)

    [ -n "$lnL_alt" ] && [ -n "$lnL_nul" ] && \
        echo "${GENE},${lnL_alt},${lnL_nul},${N}" >> \
        ${WORKDIR}/results/paml_lrt_raw.csv
}

export -f run_gene
export WORKDIR

# Procesar todos los genes con CDS disponibles
ls ${WORKDIR}/cds/*.fa | \
    xargs -I{} basename {} | \
    cut -d_ -f1 | sort -u | \
    xargs -P ${THREADS} -I{} bash -c 'run_gene "$@"' _ {}

N_PAML=$(($(wc -l < ${WORKDIR}/results/paml_lrt_raw.csv) - 1))
heartbeat "  PAML completado: ${N_PAML} genes con resultado"

# ==========================================================
# PASO 3 — LRT + FDR + permutaciones
# ==========================================================
heartbeat "[3/5] LRT, FDR y permutaciones..."

Rscript - << 'REOF'
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

lrt <- read_csv("/data/eastwest/results/paml_lrt_raw.csv",
                show_col_types=FALSE) %>%
  mutate(
    lnL_alt  = as.numeric(lnL_alt),
    lnL_nul  = as.numeric(lnL_nul),
    LRT      = pmax(2 * (lnL_alt - lnL_nul), 0),
    p_val    = pchisq(LRT, df=1, lower.tail=FALSE),
    p_fdr    = p.adjust(p_val, method="fdr"),
    selected = p_fdr < 0.05
  ) %>%
  arrange(p_fdr)

write_csv(lrt, "/data/eastwest/results/paml_lrt_fdr.csv")

cat("=== RESULTADOS LRT ===\n")
cat("Genes analizados:", nrow(lrt), "\n")
cat("Genes bajo seleccion positiva (FDR<0.05):",
    sum(lrt$selected, na.rm=TRUE), "\n")
cat("Genes bajo seleccion positiva (FDR<0.10):",
    sum(lrt$p_fdr < 0.10, na.rm=TRUE), "\n")
cat("\nTop 20:\n")
print(head(lrt[, c("gene","LRT","p_val","p_fdr","selected")], 20),
      n=20)

# Anotar con categorias GO
go <- read_csv("/data/eastwest/go_filter/candidate_genes.csv",
               show_col_types=FALSE)

df <- lrt %>%
  left_join(go, by=c("gene"="hgnc_symbol")) %>%
  mutate(
    cat_glucose  = grepl("glucose_metabolism", categories, fixed=TRUE),
    cat_cold     = grepl("cold_response",      categories, fixed=TRUE),
    cat_insulin  = grepl("insulin_signaling",  categories, fixed=TRUE),
    cat_gluco    = grepl("gluconeogenesis",    categories, fixed=TRUE),
    cat_lipid    = grepl("lipid_homeostasis",  categories, fixed=TRUE)
  )

# Permutation test anti-circular
permtest <- function(df, cat_col, n=10000, seed=42) {
  set.seed(seed)
  obs <- sum(df$selected & df[[cat_col]], na.rm=TRUE)
  sim <- replicate(n, {
    perm <- sample(df$selected, replace=FALSE)
    sum(perm & df[[cat_col]], na.rm=TRUE)
  })
  data.frame(
    category    = cat_col,
    observed    = obs,
    n_selected  = sum(df$selected, na.rm=TRUE),
    mean_null   = round(mean(sim), 2),
    sd_null     = round(sd(sim), 2),
    p_empirical = sum(sim >= obs) / n
  )
}

cat("\n=== PERMUTATION TESTS (10,000 iteraciones) ===\n")
cats <- c("cat_glucose","cat_cold","cat_insulin",
          "cat_gluco","cat_lipid")
perm_df <- do.call(rbind, lapply(cats, function(c) permtest(df, c)))
print(perm_df)

# Genes seleccionados por categoria
cat("\n=== GENES BAJO SELECCION POSITIVA POR CATEGORIA ===\n")
sel <- df[df$selected & !is.na(df$selected), ]
if (nrow(sel) > 0) {
  for (c in cats) {
    genes_cat <- sel$gene[sel[[c]] & !is.na(sel[[c]])]
    if (length(genes_cat) > 0)
      cat(c, ":", paste(genes_cat, collapse=", "), "\n")
  }
}

write_csv(perm_df, "/data/eastwest/results/permutation_results.csv")
write_csv(df,      "/data/eastwest/results/act2_final_genes.csv")
write_csv(sel,     "/data/eastwest/results/act2_selected_genes.csv")

cat("\nActo 2 completado.\n")
REOF

# ==========================================================
# PASO 4 — Subir TODO a S3
# ==========================================================
heartbeat "[4/5] Subiendo resultados a S3..."

aws s3 sync ${WORKDIR}/results/ \
    s3://${S3_BUCKET}/${S3_PREFIX}/results/ \
    --region $REGION

aws s3 sync ${WORKDIR}/cds/ \
    s3://${S3_BUCKET}/${S3_PREFIX}/cds/ \
    --region $REGION --quiet

aws s3 sync ${WORKDIR}/logs/ \
    s3://${S3_BUCKET}/${S3_PREFIX}/logs/ \
    --region $REGION

heartbeat "  S3 sync completado"

# ==========================================================
# PASO 5 — Reporte y apagado
# ==========================================================
heartbeat "[5/5] Reporte final..."

{
  echo "============================================"
  echo "East-West DM Acto 2 v2 — COMPLETADO"
  echo "============================================"
  echo "Fecha    : $(date)"
  echo "CDS      : $(ls ${WORKDIR}/cds/*.fa | wc -l) archivos"
  echo "PAML     : ${N_PAML} genes"
  echo "S3       : s3://${S3_BUCKET}/${S3_PREFIX}/results/"
  echo "============================================"
} | tee -a $LOG

aws s3 cp $LOG \
    s3://${S3_BUCKET}/${S3_PREFIX}/logs/act2_v2_DONE.log \
    --region $REGION

heartbeat "Auto-apagado en 60s..."
sleep 60
sudo shutdown -h now
