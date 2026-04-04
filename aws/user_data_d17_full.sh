#!/bin/bash
set -e -x

# Instalar herramientas necesarias
apt update
apt install -y awscli bwa samtools bcftools pigz htop at wget

# Crear directorios
mkdir -p /data/{logs,bams,ref,fastq}
chown -R ubuntu:ubuntu /data

# Descargar script de análisis desde S3
sudo -u ubuntu aws s3 cp s3://egarmo-genomes/d17/run_d17.sh /home/ubuntu/run_d17.sh
chmod +x /home/ubuntu/run_d17.sh

# Ejecutar con nohup y programar apagado en 6 horas
sudo -u ubuntu nohup /home/ubuntu/run_d17.sh > /home/ubuntu/run_d17.out 2>&1 &
echo "sudo shutdown -h now" | at now + 6 hours
