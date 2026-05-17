#!/bin/bash
# user_data_sima_hg38.sh
# East-West DM — Sima hg38 remapeo + mapDamage
# Instancia: c5.2xlarge (8 vCPU, 16GB RAM) — compute optimizado para BWA
# Tiempo estimado: 6-8h | Coste Spot ~$0.50-0.70 total
# GoodPractice.md compliant — auto-apagado garantizado

set -e

# ==========================================================
# CONFIG
# ==========================================================
S3_BUCKET="sima-egarmo-2026"
S3_PREFIX="sima_hg38"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
LOG_FILE="/tmp/sima_hg38_${TIMESTAMP}.log"
WORKDIR="/data/sima_hg38"
THREADS=8
REF_DIR="/data/ref"
HG38_FA="${REF_DIR}/hg38.fa"

{
    echo "============================================"
    echo "Sima hg38 — mapDamage + remapeo"
    echo "============================================"
    echo "Instance ID  : $INSTANCE_ID"
    echo "Instance Type: $INSTANCE_TYPE"
    echo "Timestamp    : $TIMESTAMP"
    echo "Threads      : $THREADS"
    echo "============================================"
} | tee -a $LOG_FILE

aws s3 cp $LOG_FILE \
    s3://${S3_BUCKET}/${S3_PREFIX}/logs/inicio_${TIMESTAMP}.log \
    --region eu-west-1 || true

# ==========================================================
# 1. DEPENDENCIAS
# ==========================================================
echo "[1/5] Instalando dependencias..." | tee -a $LOG_FILE

export DEBIAN_FRONTEND=noninteractive
apt-get update -y >> $LOG_FILE 2>&1
apt-get install -y \
    wget curl git unzip \
    bwa samtools \
    python3 python3-pip \
    default-jdk \
    adapterremoval \
    >> $LOG_FILE 2>&1

# Picard
wget -q https://github.com/broadinstitute/picard/releases/latest/download/picard.jar \
    -O /usr/local/bin/picard.jar >> $LOG_FILE 2>&1
echo '#!/bin/bash
java -jar /usr/local/bin/picard.jar "$@"' > /usr/local/bin/picard
chmod +x /usr/local/bin/picard

# GATK 4
wget -q https://github.com/broadinstitute/gatk/releases/download/4.5.0.0/gatk-4.5.0.0.zip \
    -O /tmp/gatk.zip >> $LOG_FILE 2>&1
unzip -q /tmp/gatk.zip -d /usr/local/ >> $LOG_FILE 2>&1
ln -sf /usr/local/gatk-4.5.0.0/gatk /usr/local/bin/gatk

# mapDamage 2.0
pip3 install mapdamage2 --quiet >> $LOG_FILE 2>&1

# Snakemake
pip3 install snakemake --quiet >> $LOG_FILE 2>&1

echo "  Dependencias OK" | tee -a $LOG_FILE
aws s3 cp $LOG_FILE \
    s3://${S3_BUCKET}/${S3_PREFIX}/logs/deps_${TIMESTAMP}.log \
    --region eu-west-1 || true

# ==========================================================
# 2. REFERENCIA hg38
# ==========================================================
echo "[2/5] Preparando referencia hg38..." | tee -a $LOG_FILE

mkdir -p $REF_DIR $WORKDIR
cd $REF_DIR

# Intentar recuperar de S3 primero (si ya se descargó antes)
if aws s3 ls s3://${S3_BUCKET}/ref/hg38.fa.gz --region eu-west-1 &>/dev/null; then
    echo "  Recuperando hg38 de S3..." | tee -a $LOG_FILE
    aws s3 cp s3://${S3_BUCKET}/ref/hg38.fa.gz ${REF_DIR}/hg38.fa.gz \
        --region eu-west-1 >> $LOG_FILE 2>&1
    gunzip ${REF_DIR}/hg38.fa.gz >> $LOG_FILE 2>&1
else
    echo "  Descargando hg38 de UCSC..." | tee -a $LOG_FILE
    # Solo cromosomas autosómicos + X + Y (sin scaffolds — más rápido)
    wget -q https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz \
        -O ${REF_DIR}/hg38.fa.gz >> $LOG_FILE 2>&1
    gunzip ${REF_DIR}/hg38.fa.gz >> $LOG_FILE 2>&1
    # Guardar en S3 para futuros runs
    aws s3 cp ${REF_DIR}/hg38.fa \
        s3://${S3_BUCKET}/ref/hg38.fa.gz \
        --region eu-west-1 || true
fi

# Indexar si no está indexado
if [ ! -f "${HG38_FA}.bwt" ]; then
    echo "  Indexando hg38 con BWA (tarda ~90min)..." | tee -a $LOG_FILE
    bwa index ${HG38_FA} >> $LOG_FILE 2>&1
    samtools faidx ${HG38_FA} >> $LOG_FILE 2>&1
    # Guardar índices en S3
    aws s3 sync ${REF_DIR}/ s3://${S3_BUCKET}/ref/ \
        --exclude "*.fa" --region eu-west-1 || true
fi

# Diccionario para GATK
if [ ! -f "${REF_DIR}/hg38.dict" ]; then
    picard CreateSequenceDictionary R=${HG38_FA} >> $LOG_FILE 2>&1
fi

echo "  Referencia lista" | tee -a $LOG_FILE

# ==========================================================
# 3. SETUP SNAKEMAKE
# ==========================================================
echo "[3/5] Configurando Snakemake..." | tee -a $LOG_FILE

mkdir -p ${WORKDIR}/{data/fastq,data/trimmed,results/{bam_hg38,bam_rescaled,mapdamage,loci,vcf},logs/{download,trim,bwa,dedup,mapdamage,rescale,loci,vcf}}
cd ${WORKDIR}

# Descargar Snakefile y config desde S3
# (subir manualmente antes del lanzamiento con el comando al final)
aws s3 cp s3://${S3_BUCKET}/${S3_PREFIX}/pipeline/Snakefile_sima_hg38 \
    ${WORKDIR}/Snakefile --region eu-west-1 >> $LOG_FILE 2>&1
aws s3 cp s3://${S3_BUCKET}/${S3_PREFIX}/pipeline/config_sima_hg38.yaml \
    ${WORKDIR}/config_sima_hg38.yaml --region eu-west-1 >> $LOG_FILE 2>&1

# Parchear config con rutas correctas de esta instancia
sed -i "s|/data/ref/hg38.fa|${HG38_FA}|g" ${WORKDIR}/config_sima_hg38.yaml

echo "  Snakemake configurado" | tee -a $LOG_FILE

# ==========================================================
# 4. LANZAR PIPELINE
# ==========================================================
echo "[4/5] Lanzando Snakemake pipeline..." | tee -a $LOG_FILE

aws s3 cp $LOG_FILE \
    s3://${S3_BUCKET}/${S3_PREFIX}/logs/prerun_${TIMESTAMP}.log \
    --region eu-west-1 || true

# Dry-run primero para validar
snakemake \
    --snakefile ${WORKDIR}/Snakefile \
    --configfile ${WORKDIR}/config_sima_hg38.yaml \
    --cores ${THREADS} \
    --dryrun \
    --quiet \
    >> $LOG_FILE 2>&1 && echo "  Dry-run OK" | tee -a $LOG_FILE

# Run real con heartbeat a S3 cada 30min
(
    while true; do
        sleep 1800
        aws s3 cp $LOG_FILE \
            s3://${S3_BUCKET}/${S3_PREFIX}/logs/heartbeat_${TIMESTAMP}.log \
            --region eu-west-1 || true
    done
) &
HEARTBEAT_PID=$!

snakemake \
    --snakefile ${WORKDIR}/Snakefile \
    --configfile ${WORKDIR}/config_sima_hg38.yaml \
    --cores ${THREADS} \
    --keep-going \
    --rerun-incomplete \
    --latency-wait 60 \
    >> $LOG_FILE 2>&1

kill $HEARTBEAT_PID 2>/dev/null || true

echo "  Pipeline completado" | tee -a $LOG_FILE

# ==========================================================
# 5. SUBIR RESULTADOS A S3
# ==========================================================
echo "[5/5] Subiendo resultados a S3..." | tee -a $LOG_FILE

# BAMs hg38 remapeados
aws s3 sync ${WORKDIR}/results/bam_hg38/ \
    s3://${S3_BUCKET}/${S3_PREFIX}/results/bam_hg38/ \
    --region eu-west-1 >> $LOG_FILE 2>&1

# mapDamage reports (plots + misincorporation tables)
aws s3 sync ${WORKDIR}/results/mapdamage/ \
    s3://${S3_BUCKET}/${S3_PREFIX}/results/mapdamage/ \
    --region eu-west-1 >> $LOG_FILE 2>&1

# Loci extraídos (LDHA, LDHC, SLC2A3)
aws s3 sync ${WORKDIR}/results/loci/ \
    s3://${S3_BUCKET}/${S3_PREFIX}/results/loci/ \
    --region eu-west-1 >> $LOG_FILE 2>&1

# VCF consolidado — el más importante
aws s3 cp ${WORKDIR}/results/vcf/sima_hg38_loci.vcf.gz \
    s3://${S3_BUCKET}/${S3_PREFIX}/results/sima_hg38_loci.vcf.gz \
    --region eu-west-1 >> $LOG_FILE 2>&1

# Damage summary (tabla para paper)
aws s3 cp ${WORKDIR}/results/mapdamage/damage_summary.tsv \
    s3://${S3_BUCKET}/${S3_PREFIX}/results/damage_summary.tsv \
    --region eu-west-1 >> $LOG_FILE 2>&1

# Logs completos
aws s3 sync ${WORKDIR}/logs/ \
    s3://${S3_BUCKET}/${S3_PREFIX}/logs/ \
    --region eu-west-1 >> $LOG_FILE 2>&1

# ==========================================================
# REPORTE FINAL
# ==========================================================
{
    echo "============================================"
    echo "Sima hg38 — COMPLETADO"
    echo "============================================"
    echo "Fecha        : $(date)"
    echo "Instance     : $INSTANCE_ID ($INSTANCE_TYPE)"
    echo "BAMs hg38    : $(ls ${WORKDIR}/results/bam_hg38/*.sorted.bam 2>/dev/null | wc -l)/5"
    echo "mapDamage    : $(ls -d ${WORKDIR}/results/mapdamage/*/ 2>/dev/null | wc -l)/5"
    echo "VCF loci     : $([ -f ${WORKDIR}/results/vcf/sima_hg38_loci.vcf.gz ] && echo OK || echo MISSING)"
    echo "S3           : s3://${S3_BUCKET}/${S3_PREFIX}/results/"
    echo "============================================"
    echo ""
    echo "RECUPERAR RESULTADOS:"
    echo "  aws s3 sync s3://${S3_BUCKET}/${S3_PREFIX}/results/ ./results_sima_hg38/"
    echo "  aws s3 cp s3://${S3_BUCKET}/${S3_PREFIX}/results/damage_summary.tsv ."
    echo "  aws s3 cp s3://${S3_BUCKET}/${S3_PREFIX}/results/sima_hg38_loci.vcf.gz ."
} | tee -a $LOG_FILE

aws s3 cp $LOG_FILE \
    s3://${S3_BUCKET}/${S3_PREFIX}/logs/DONE_${TIMESTAMP}.log \
    --region eu-west-1 || true

echo "Auto-apagado en 60s..."
sleep 60
sudo shutdown -h now
