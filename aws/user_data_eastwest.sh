#!/bin/bash
# user_data_eastwest.sh
# East-West Diabetes Story — Acto 2
# Pipeline: filtro GO -> descarga CDS Ensembl -> PAML branch-site -> permutaciones
# Instancia: r6i.2xlarge (8 vCPU, 64GB RAM)
# Tiempo estimado: 8-12 horas | Coste estimado: ~$4-6
# GoodPractice.md compliant — auto-apagado garantizado

set -e

# ==========================================================
# CONFIGURACION
# ==========================================================
S3_BUCKET="sima-egarmo-2026"
S3_PREFIX="eastwest"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
LOG_FILE="/tmp/eastwest_act2_${TIMESTAMP}.log"
WORKDIR="/data/eastwest"
THREADS=8

# GO terms para filtro ciego (sin hipotesis sobre genes especificos)
# Eje EQ: transporte glucosa, metabolismo energetico cerebral
# Eje frio: respuesta a temperatura, termogenesis, homeostasis metabolica
GO_TERMS="GO:0006006,GO:0015758,GO:0009409,GO:0042542,GO:0006094,GO:0070328,GO:0001659,GO:0006099,GO:0045444"

# ==========================================================
# HEARTBEAT INICIAL
# ==========================================================
{
    echo "============================================"
    echo "East-West Diabetes Story — Acto 2"
    echo "============================================"
    echo "Instance ID  : $INSTANCE_ID"
    echo "Instance Type: $INSTANCE_TYPE"
    echo "Timestamp    : $TIMESTAMP"
    echo "Threads      : $THREADS"
    echo "GO terms     : $GO_TERMS"
    echo "============================================"
} | tee -a $LOG_FILE

aws s3 cp $LOG_FILE s3://${S3_BUCKET}/${S3_PREFIX}/logs/act2_${TIMESTAMP}_inicio.log \
    --region eu-west-1 || true

# ==========================================================
# 1. INSTALAR DEPENDENCIAS
# ==========================================================
echo "[1/6] Instalando dependencias..." | tee -a $LOG_FILE

export DEBIAN_FRONTEND=noninteractive
apt-get update -y >> $LOG_FILE 2>&1
apt-get install -y \
    wget curl git \
    r-base r-base-dev \
    python3 python3-pip \
    muscle mafft \
    >> $LOG_FILE 2>&1

# PAML
wget -q https://github.com/abacus-gene/paml/releases/download/v4.10.7/paml-4.10.7-linux-X86_64.tgz \
    -O /tmp/paml.tgz >> $LOG_FILE 2>&1
tar -xzf /tmp/paml.tgz -C /usr/local/bin/ --strip-components=2 \
    paml-4.10.7/bin/codeml >> $LOG_FILE 2>&1
chmod +x /usr/local/bin/codeml

# R packages
Rscript -e "
install.packages(c('BiocManager','dplyr','readr','ggplot2','patchwork'),
                 repos='https://cloud.r-project.org', quiet=TRUE)
BiocManager::install(c('biomaRt','clusterProfiler','org.Hs.eg.db',
                        'GO.db','AnnotationDbi'), ask=FALSE, quiet=TRUE)
" >> $LOG_FILE 2>&1

echo "  Dependencias OK" | tee -a $LOG_FILE
aws s3 cp $LOG_FILE s3://${S3_BUCKET}/${S3_PREFIX}/logs/act2_${TIMESTAMP}_deps.log \
    --region eu-west-1 || true

# ==========================================================
# 2. ESTRUCTURA DE DIRECTORIOS
# ==========================================================
echo "[2/6] Creando estructura..." | tee -a $LOG_FILE

mkdir -p ${WORKDIR}/{go_filter,cds,alignments,paml,results,logs}
cd ${WORKDIR}

# ==========================================================
# 3. FILTRO GO CIEGO — obtener genes candidatos
# ==========================================================
echo "[3/6] Filtro GO amplio (ciego)..." | tee -a $LOG_FILE

cat > ${WORKDIR}/go_filter/get_go_genes.R << 'REOF'
library(biomaRt)
library(dplyr)
library(readr)

# Conectar a Ensembl
mart <- useMart("ensembl", dataset = "hsapiens_gene_ensembl")

# GO terms — filtro amplio sin hipotesis sobre genes especificos
# Eje EQ: glucosa/energia cerebral
# Eje frio: temperatura/termogenesis
go_terms <- c(
  "GO:0006006",  # glucose metabolic process
  "GO:0015758",  # glucose transport
  "GO:0009409",  # response to cold
  "GO:0042542",  # response to hydrogen peroxide
  "GO:0006094",  # gluconeogenesis
  "GO:0070328",  # triglyceride homeostasis
  "GO:0001659",  # temperature homeostasis
  "GO:0006099",  # tricarboxylic acid cycle
  "GO:0045444"   # fat cell differentiation
)

cat("Consultando biomaRt para", length(go_terms), "GO terms...\n")

genes <- getBM(
  attributes = c("ensembl_gene_id", "hgnc_symbol",
                 "go_id", "name_1006",
                 "chromosome_name", "start_position", "end_position"),
  filters    = "go",
  values     = go_terms,
  mart       = mart
)

cat("Genes encontrados (con duplicados):", nrow(genes), "\n")

# Tabla de genes unicos con todos sus GO terms
genes_unique <- genes %>%
  group_by(ensembl_gene_id, hgnc_symbol,
           chromosome_name, start_position, end_position) %>%
  summarise(
    go_terms    = paste(unique(go_id),       collapse = ";"),
    go_names    = paste(unique(name_1006),   collapse = ";"),
    n_go_terms  = n_distinct(go_id),
    .groups = "drop"
  ) %>%
  filter(hgnc_symbol != "") %>%
  arrange(desc(n_go_terms))

cat("Genes unicos con simbolo HGNC:", nrow(genes_unique), "\n")
cat("Top 10 por numero de GO terms:\n")
print(head(genes_unique[, c("hgnc_symbol","n_go_terms","go_names")], 10))

write_csv(genes_unique, "/data/eastwest/go_filter/candidate_genes.csv")
write_csv(genes,        "/data/eastwest/go_filter/candidate_genes_raw.csv")

# Lista plana de simbolos para descarga CDS
writeLines(genes_unique$hgnc_symbol,
           "/data/eastwest/go_filter/gene_symbols.txt")

cat("\nGuardado: candidate_genes.csv\n")
cat("Total candidatos:", nrow(genes_unique), "\n")
REOF

Rscript ${WORKDIR}/go_filter/get_go_genes.R 2>&1 | tee -a $LOG_FILE

N_GENES=$(wc -l < ${WORKDIR}/go_filter/gene_symbols.txt)
echo "  Genes candidatos: $N_GENES" | tee -a $LOG_FILE

aws s3 cp ${WORKDIR}/go_filter/candidate_genes.csv \
    s3://${S3_BUCKET}/${S3_PREFIX}/results/candidate_genes.csv \
    --region eu-west-1 || true
aws s3 cp $LOG_FILE \
    s3://${S3_BUCKET}/${S3_PREFIX}/logs/act2_${TIMESTAMP}_gofilter.log \
    --region eu-west-1 || true

# ==========================================================
# 4. DESCARGAR CDS DESDE ENSEMBL (paralelo, 8 threads)
# ==========================================================
echo "[4/6] Descargando CDS desde Ensembl..." | tee -a $LOG_FILE

# Especies del arbol — mismas que en el Acto 1 con CDS disponibles en Ensembl
SPECIES=(
  "homo_sapiens"
  "pan_troglodytes"
  "gorilla_gorilla"
  "pongo_abelii"
  "macaca_mulatta"
  "callithrix_jacchus"
  "mus_musculus"
  "rattus_norvegicus"
  "bos_taurus"
  "canis_lupus_familiaris"
  "loxodonta_africana"
  "tursiops_truncatus"
  "vulpes_vulpes"
  "ursus_americanus"
)

cat > ${WORKDIR}/scripts/fetch_cds.py << 'PYEOF'
#!/usr/bin/env python3
"""
Descarga CDS desde Ensembl REST API para lista de genes y especies.
Output: cds/{GENE}_{SPECIES}.fa
"""
import requests, time, os, sys
from pathlib import Path

OUTDIR   = Path("/data/eastwest/cds")
GENE_FILE = "/data/eastwest/go_filter/gene_symbols.txt"
SPECIES  = sys.argv[1:]
BASE_URL = "https://rest.ensembl.org"
HEADERS  = {"Content-Type": "application/json"}

genes = [g.strip() for g in open(GENE_FILE) if g.strip()]
print(f"Genes a descargar: {len(genes)} x {len(SPECIES)} especies")

ok = err = skip = 0
for gene in genes:
    for sp in SPECIES:
        outfile = OUTDIR / f"{gene}_{sp}.fa"
        if outfile.exists() and outfile.stat().st_size > 100:
            skip += 1
            continue
        url = f"{BASE_URL}/sequence/id/{gene}?type=cds;species={sp}"
        try:
            r = requests.get(url, headers={**HEADERS, "Accept":"text/x-fasta"},
                             timeout=30)
            if r.status_code == 200:
                outfile.write_text(f">{gene}_{sp}\n{r.text.split(chr(10),1)[1]}")
                ok += 1
            else:
                err += 1
            time.sleep(0.1)   # respetar rate limit Ensembl
        except Exception as e:
            err += 1
    if (ok + err) % 100 == 0:
        print(f"  OK:{ok} ERR:{err} SKIP:{skip}")

print(f"Completado — OK:{ok} ERR:{err} SKIP:{skip}")
PYEOF

chmod +x ${WORKDIR}/scripts/fetch_cds.py

# Dividir especies en 2 grupos para paralelizar
python3 ${WORKDIR}/scripts/fetch_cds.py \
    homo_sapiens pan_troglodytes gorilla_gorilla pongo_abelii \
    macaca_mulatta callithrix_jacchus mus_musculus \
    >> $LOG_FILE 2>&1 &

python3 ${WORKDIR}/scripts/fetch_cds.py \
    rattus_norvegicus bos_taurus canis_lupus_familiaris \
    loxodonta_africana tursiops_truncatus vulpes_vulpes ursus_americanus \
    >> $LOG_FILE 2>&1 &

wait
echo "  Descarga CDS completada" | tee -a $LOG_FILE
N_CDS=$(ls ${WORKDIR}/cds/*.fa 2>/dev/null | wc -l)
echo "  Archivos CDS descargados: $N_CDS" | tee -a $LOG_FILE

aws s3 cp $LOG_FILE \
    s3://${S3_BUCKET}/${S3_PREFIX}/logs/act2_${TIMESTAMP}_cds.log \
    --region eu-west-1 || true

# ==========================================================
# 5. ALINEAMIENTO + PAML BRANCH-SITE
# ==========================================================
echo "[5/6] Alineamiento y PAML branch-site..." | tee -a $LOG_FILE

cat > ${WORKDIR}/scripts/run_paml_gene.sh << 'SHELLEOF'
#!/bin/bash
# Alinea y corre PAML branch-site para un gen
# Uso: run_paml_gene.sh GENE_SYMBOL
GENE=$1
WORKDIR="/data/eastwest"
CDS_DIR="${WORKDIR}/cds"
ALN_DIR="${WORKDIR}/alignments"
PAML_DIR="${WORKDIR}/paml"

mkdir -p ${ALN_DIR}/${GENE} ${PAML_DIR}/${GENE}

# Concatenar CDS disponibles para este gen
cat ${CDS_DIR}/${GENE}_*.fa > ${ALN_DIR}/${GENE}/all_taxa.fa 2>/dev/null || exit 0
N_SEQ=$(grep -c "^>" ${ALN_DIR}/${GENE}/all_taxa.fa 2>/dev/null || echo 0)
[ "$N_SEQ" -lt 4 ] && exit 0   # minimo 4 taxa

# Alineamiento con MAFFT
mafft --auto --quiet \
    ${ALN_DIR}/${GENE}/all_taxa.fa > ${ALN_DIR}/${GENE}/aligned.fa 2>/dev/null

# Control de tree para PAML (branch-site: homo_sapiens como foreground)
cat > ${PAML_DIR}/${GENE}/tree.nwk << 'TEOF'
((homo_sapiens #1, (pan_troglodytes, gorilla_gorilla, pongo_abelii)),
 (macaca_mulatta, callithrix_jacchus),
 ((mus_musculus, rattus_norvegicus),
  (bos_taurus, (tursiops_truncatus, loxodonta_africana)),
  (canis_lupus_familiaris, (vulpes_vulpes, ursus_americanus))));
TEOF

# CTL para branch-site model
cat > ${PAML_DIR}/${GENE}/branch_site.ctl << CTLEOF
seqfile  = ${ALN_DIR}/${GENE}/aligned.fa
treefile = ${PAML_DIR}/${GENE}/tree.nwk
outfile  = ${PAML_DIR}/${GENE}/branch_site_out.txt
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
Malpha   = 0
ncatG    = 4
CTLEOF

# Modelo alternativo (branch-site)
cd ${PAML_DIR}/${GENE}
codeml branch_site.ctl >> /tmp/paml_${GENE}.log 2>&1

# Modelo nulo (fix_omega=1, omega=1)
sed 's/fix_omega = 0/fix_omega = 1/' branch_site.ctl > null.ctl
sed -i 's/^omega    = 1/omega    = 1/' null.ctl
cp branch_site_out.txt alt_out.txt
codeml null.ctl >> /tmp/paml_${GENE}.log 2>&1
cp branch_site_out.txt null_out.txt

# Extraer log-likelihoods y calcular LRT
lnL_alt=$(grep "^lnL" alt_out.txt  2>/dev/null | awk '{print $5}' | head -1)
lnL_nul=$(grep "^lnL" null_out.txt 2>/dev/null | awk '{print $5}' | head -1)

if [ ! -z "$lnL_alt" ] && [ ! -z "$lnL_nul" ]; then
    echo "${GENE},${lnL_alt},${lnL_nul},${N_SEQ}" >> \
        ${WORKDIR}/results/paml_lrt_raw.csv
fi
SHELLEOF

chmod +x ${WORKDIR}/scripts/run_paml_gene.sh

# Inicializar CSV de resultados
echo "gene,lnL_alt,lnL_nul,n_taxa" > ${WORKDIR}/results/paml_lrt_raw.csv

# Correr PAML en paralelo (xargs con 8 jobs)
cat ${WORKDIR}/go_filter/gene_symbols.txt | \
    xargs -P $THREADS -I{} bash ${WORKDIR}/scripts/run_paml_gene.sh {} \
    2>> $LOG_FILE

echo "  PAML completado" | tee -a $LOG_FILE
N_PAML=$(wc -l < ${WORKDIR}/results/paml_lrt_raw.csv)
echo "  Genes con resultado PAML: $((N_PAML - 1))" | tee -a $LOG_FILE

aws s3 cp $LOG_FILE \
    s3://${S3_BUCKET}/${S3_PREFIX}/logs/act2_${TIMESTAMP}_paml.log \
    --region eu-west-1 || true

# ==========================================================
# 6. ANÁLISIS ESTADÍSTICO Y PERMUTACIONES
# ==========================================================
echo "[6/6] LRT, FDR y permutaciones..." | tee -a $LOG_FILE

cat > ${WORKDIR}/scripts/analyze_lrt.R << 'REOF'
library(dplyr)
library(readr)

# Cargar resultados PAML
lrt_raw <- read_csv("/data/eastwest/results/paml_lrt_raw.csv",
                    show_col_types = FALSE)

cat("Genes con resultado PAML:", nrow(lrt_raw), "\n")

# LRT = 2 * (lnL_alt - lnL_nul) ~ chi2(df=1) bajo H0
lrt_raw <- lrt_raw %>%
  mutate(
    lnL_alt  = as.numeric(lnL_alt),
    lnL_nul  = as.numeric(lnL_nul),
    LRT      = 2 * (lnL_alt - lnL_nul),
    LRT      = pmax(LRT, 0),    # LRT negativo = modelo nulo preferido
    p_val    = pchisq(LRT, df = 1, lower.tail = FALSE),
    p_fdr    = p.adjust(p_val, method = "fdr"),
    selected = p_fdr < 0.05
  ) %>%
  arrange(p_fdr)

write_csv(lrt_raw, "/data/eastwest/results/paml_lrt_fdr.csv")

cat("Genes bajo seleccion positiva (FDR<0.05):", sum(lrt_raw$selected), "\n")
cat("Top 20:\n")
print(head(lrt_raw[, c("gene","LRT","p_val","p_fdr","selected")], 20))

# ==========================================================
# PERMUTACION ANTI-CIRCULAR (10,000 iteraciones)
# ==========================================================
# Cargar anotacion GO de candidatos
go_annot <- read_csv("/data/eastwest/go_filter/candidate_genes.csv",
                     show_col_types = FALSE)

# Merge con resultados PAML
df <- lrt_raw %>%
  left_join(go_annot %>% select(hgnc_symbol, go_terms, go_names),
            by = c("gene" = "hgnc_symbol"))

# Definir categorias funcionales a priori (GO standard, no hipotesis propias)
df <- df %>%
  mutate(
    cat_glucose = grepl("GO:0006006|GO:0015758|GO:0006094", go_terms),
    cat_cold    = grepl("GO:0009409|GO:0001659", go_terms),
    cat_energy  = grepl("GO:0006099|GO:0042542", go_terms)
  )

# Funcion de permutacion
permtest <- function(df, cat_col, n_perm = 10000, seed = 42) {
  set.seed(seed)
  obs <- sum(df$selected & df[[cat_col]], na.rm = TRUE)
  n_sel <- sum(df$selected, na.rm = TRUE)

  sim <- replicate(n_perm, {
    perm <- sample(df$selected, replace = FALSE)
    sum(perm & df[[cat_col]], na.rm = TRUE)
  })

  p_emp <- sum(sim >= obs) / n_perm
  list(observed = obs, n_selected = n_sel,
       mean_null = mean(sim), sd_null = sd(sim),
       p_empirical = p_emp)
}

cat("\n=== PERMUTATION TESTS (10,000 iteraciones) ===\n")
cats <- c("cat_glucose", "cat_cold", "cat_energy")
perm_results <- lapply(cats, function(cat) {
  res <- permtest(df, cat)
  cat(sprintf("%-15s | obs=%d | null=%.1f+/-%.1f | p_emp=%.4f\n",
              cat, res$observed, res$mean_null, res$sd_null, res$p_empirical))
  data.frame(category = cat,
             observed = res$observed,
             n_selected = res$n_selected,
             mean_null = res$mean_null,
             sd_null = res$sd_null,
             p_empirical = res$p_empirical)
})

perm_df <- do.call(rbind, perm_results)
write_csv(perm_df, "/data/eastwest/results/permutation_results.csv")

# Resultado final
write_csv(df, "/data/eastwest/results/act2_final_genes.csv")
cat("\nActo 2 completado.\n")
REOF

Rscript ${WORKDIR}/scripts/analyze_lrt.R 2>&1 | tee -a $LOG_FILE

# ==========================================================
# SUBIR RESULTADOS A S3
# ==========================================================
echo "Subiendo resultados a S3..." | tee -a $LOG_FILE

for f in ${WORKDIR}/results/*.csv; do
    aws s3 cp $f \
        s3://${S3_BUCKET}/${S3_PREFIX}/results/$(basename $f) \
        --region eu-west-1 || true
done

aws s3 cp $LOG_FILE \
    s3://${S3_BUCKET}/${S3_PREFIX}/logs/act2_${TIMESTAMP}_final.log \
    --region eu-west-1 || true

# ==========================================================
# REPORTE FINAL
# ==========================================================
{
    echo "============================================"
    echo "East-West DM Acto 2 — COMPLETADO"
    echo "============================================"
    echo "Fecha        : $(date)"
    echo "Instance     : $INSTANCE_ID ($INSTANCE_TYPE)"
    echo "Genes GO     : $N_GENES candidatos"
    echo "CDS files    : $N_CDS"
    echo "PAML results : $((N_PAML - 1)) genes"
    echo "S3           : s3://${S3_BUCKET}/${S3_PREFIX}/results/"
    echo "============================================"
} | tee -a $LOG_FILE

aws s3 cp $LOG_FILE \
    s3://${S3_BUCKET}/${S3_PREFIX}/logs/act2_${TIMESTAMP}_DONE.log \
    --region eu-west-1 || true

echo "Esperando 60s para asegurar subidas S3..."
sleep 60

echo "Auto-apagado en 10s..."
sleep 10
sudo shutdown -h now
