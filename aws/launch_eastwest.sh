#!/bin/bash
# launch_eastwest.sh
# Lanza instancia AWS para East-West Diabetes Story — Acto 2
# Reutiliza infraestructura Sima (keypair, SG, AMI, IAM)
# GoodPractice.md compliant

set -e

# ==========================================================
# CARGAR CONFIG
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config_eastwest.env"

echo "============================================"
echo "East-West DM — Acto 2 — Launch"
echo "============================================"
echo "Instancia : $INSTANCE_TYPE"
echo "Region    : $AWS_REGION"
echo "Bucket    : s3://$S3_BUCKET/$S3_PREFIX/"
echo "============================================"

# Verificar credenciales
echo "Verificando credenciales AWS..."
aws sts get-caller-identity --region $AWS_REGION > /dev/null || {
    echo "ERROR: Credenciales AWS no validas"
    echo "Ejecuta: source ~/.aws/credentials o configura aws configure"
    exit 1
}
echo "  Credenciales OK"

# Verificar keypair
[ -f "$KEY_PATH" ] || {
    echo "ERROR: Keypair no encontrado en $KEY_PATH"
    exit 1
}
chmod 400 "$KEY_PATH"
echo "  Keypair OK"

# Verificar user_data
USER_DATA_SCRIPT="${SCRIPT_DIR}/user_data_bootstrap.sh"
[ -f "$USER_DATA_SCRIPT" ] || {
    echo "ERROR: user_data_bootstrap.sh no encontrado"
    exit 1
}
echo "  User data OK"

# ==========================================================
# CREAR PREFIJO S3 SI NO EXISTE
# ==========================================================
aws s3api put-object \
    --bucket $S3_BUCKET \
    --key "${S3_PREFIX}/" \
    --region $AWS_REGION > /dev/null 2>&1 || true

aws s3api put-object \
    --bucket $S3_BUCKET \
    --key "${S3_PREFIX}/results/" \
    --region $AWS_REGION > /dev/null 2>&1 || true

aws s3api put-object \
    --bucket $S3_BUCKET \
    --key "${S3_PREFIX}/logs/" \
    --region $AWS_REGION > /dev/null 2>&1 || true

echo "  Prefijo S3 eastwest/ creado"

# ==========================================================
# LANZAR INSTANCIA
# ==========================================================
echo ""
echo "Lanzando instancia $INSTANCE_TYPE..."

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $UBUNTU_AMI \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SG_ID \
    --iam-instance-profile Name=$IAM_INSTANCE_PROFILE \
    --user-data file://$USER_DATA_SCRIPT \
    --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":100,"VolumeType":"gp3","DeleteOnTermination":true}}]' \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=EastWestDM-Act2},{Key=Project,Value=EastWestDM},{Key=AutoShutdown,Value=true}]' \
    --instance-initiated-shutdown-behavior terminate \
    --region $AWS_REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo ""
echo "============================================"
echo "INSTANCIA LANZADA"
echo "============================================"
echo "Instance ID : $INSTANCE_ID"
echo "Tipo        : $INSTANCE_TYPE"

# Guardar ID
echo $INSTANCE_ID > "${SCRIPT_DIR}/instance_id_eastwest.txt"
echo "  ID guardado en instance_id_eastwest.txt"

# Esperar IP publica
echo ""
echo "Esperando IP publica (30s)..."
sleep 30

PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $AWS_REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text 2>/dev/null || echo "pendiente")

echo "IP publica  : $PUBLIC_IP"
echo $PUBLIC_IP > "${SCRIPT_DIR}/ip_eastwest.txt"

echo ""
echo "============================================"
echo "COMANDOS UTILES"
echo "============================================"
echo ""
echo "# Conectar por SSH:"
echo "ssh -i $KEY_PATH ubuntu@$PUBLIC_IP"
echo ""
echo "# Monitorizar logs en S3:"
echo "aws s3 ls s3://$S3_BUCKET/$S3_PREFIX/logs/ --region $AWS_REGION"
echo ""
echo "# Ver log actual:"
echo "aws s3 cp s3://$S3_BUCKET/$S3_PREFIX/logs/ . --recursive --region $AWS_REGION"
echo ""
echo "# Ver resultados cuando termine:"
echo "aws s3 ls s3://$S3_BUCKET/$S3_PREFIX/results/ --region $AWS_REGION"
echo ""
echo "# Descargar resultados:"
echo "aws s3 sync s3://$S3_BUCKET/$S3_PREFIX/results/ ~/EastWestDM/act2/ --region $AWS_REGION"
echo ""
echo "# Terminar instancia si hay problema:"
echo "aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $AWS_REGION"
echo ""
echo "============================================"
echo "Tiempo estimado: 8-12 horas"
echo "Coste estimado : ~4-6 USD (on-demand)"
echo "Auto-apagado   : SI — instancia termina sola"
echo "============================================"
