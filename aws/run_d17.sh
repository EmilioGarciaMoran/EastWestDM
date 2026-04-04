cd ~/EastWestDM/aws
# Crear el script (si no lo tienes ya)
cat > run_d17.sh << 'EOF'
#!/bin/bash
set -e

S3_BUCKET="egarmo-genomes"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/data/logs/d17_${TIMESTAMP}.log"

mkdir -p /data/{logs,bams,ref,fastq}

echo "[$(date)] Iniciando D17 pipeline" | tee -a $LOG_FILE
aws s3 cp $LOG_FILE s3://${S3_BUCKET}/d17/logs/start_${TIMESTAMP}.log

cd /data

# Referencia hg38
if [ ! -f ref/hg38.fa ]; then
    wget -O ref/hg38.fa.gz https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
    gunzip ref/hg38.fa.gz
    bwa index ref/hg38.fa
    samtools faidx ref/hg38.fa
fi

# Descargar FASTQ de D17 (ERR16782339)
cd fastq
wget -c ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR167/ERR16782339/ERR16782339.fastq.gz
cd ..

# Mapeo con bwa
bwa mem -t $(nproc) -k 17 -T 30 ref/hg38.fa fastq/ERR16782339.fastq.gz | \
    samtools view -bS -q 20 > bams/D17_raw.bam
samtools sort bams/D17_raw.bam -o bams/D17_sorted.bam
samtools index bams/D17_sorted.bam

# Crear BED de genes
cat > genes.bed << 'EOF'
chr15	72410127	72434999	PKM
chr11	18403920	18421489	LDHA
chr12	48506319	48540967	PFKM
chr2	31808841	31984936	PPARGC1A
chr4	155365149	155423755	TRPA1
chr3	143864741	143877800	SLC2A3
chr16	28603147	28622294	ADIPOQ
chr6	16235526	16282945	PGM1
chr1	35535999	35570376	UGP2
chr17	47198964	47252179	ACACA
EOF

# Extraer regiones
samtools view -b -L genes.bed bams/D17_sorted.bam > bams/D17_subset.bam
samtools index bams/D17_subset.bam

# Llamar variantes
bcftools mpileup -f ref/hg38.fa -R genes.bed bams/D17_subset.bam | \
    bcftools call -mv -o bams/D17_variants.vcf

# Subir resultados a S3
aws s3 cp bams/D17_variants.vcf s3://${S3_BUCKET}/d17/results/D17_variants_${TIMESTAMP}.vcf
aws s3 cp bams/D17_subset.bam s3://${S3_BUCKET}/d17/results/D17_subset_${TIMESTAMP}.bam
aws s3 cp bams/D17_subset.bam.bai s3://${S3_BUCKET}/d17/results/D17_subset_${TIMESTAMP}.bam.bai

echo "[$(date)] Pipeline completado" | tee -a $LOG_FILE
aws s3 cp $LOG_FILE s3://${S3_BUCKET}/d17/logs/complete_${TIMESTAMP}.log

sleep 60
sudo shutdown -h now
