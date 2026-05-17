#!/bin/bash
# launch_sima_hg38.sh
# Lanza c5.2xlarge Spot para remapeo hg38 + mapDamage
# Encaja con patrón GoodPractice.md del proyecto EastWestDM

set -euo pipefail

# Cargar config base (reutiliza infraestructura existente)
source "$(dirname "$0")/config_eastwest.env"

# Override de instancia — c5.2xlarge para BWA (CPU-bound, no RAM-bound)
INSTANCE_TYPE="c5.2xlarge"   # 8 vCPU, 16GB RAM, ~$0.07/h Spot
VOLUME_SIZE=300               # 300GB: FASTQs + hg38 ref + BAMs intermedios
JOB_NAME="sima-hg38-mapdamage"

echo "========================================="
echo "🚀 Sima hg38 remapeo + mapDamage"
echo "========================================="
echo "Instancia: ${INSTANCE_TYPE} (8 vCPU, 16GB RAM)"
echo "Precio:    ~\$0.07/h Spot eu-west-1"
echo "Tiempo:    ~6-8h estimado"
echo "Coste:     ~\$0.50-0.70 total"
echo "Bucket:    s3://${S3_BUCKET}/sima_hg38/"
echo "========================================="

# Verificar credenciales
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ ERROR: Credenciales AWS no configuradas"
    exit 1
fi

# Subir pipeline a S3 ANTES de lanzar la instancia
echo "📦 Subiendo pipeline a S3..."
PIPELINE_DIR="$(dirname "$0")/../pipeline/sima_hg38"
mkdir -p "$PIPELINE_DIR"

# Los archivos deben estar en ~/EastWestDM/pipeline/sima_hg38/
aws s3 cp "${PIPELINE_DIR}/Snakefile_sima_hg38" \
    s3://${S3_BUCKET}/sima_hg38/pipeline/Snakefile_sima_hg38 \
    --region ${AWS_REGION}
aws s3 cp "${PIPELINE_DIR}/config_sima_hg38.yaml" \
    s3://${S3_BUCKET}/sima_hg38/pipeline/config_sima_hg38.yaml \
    --region ${AWS_REGION}
echo "  Pipeline en S3 ✅"

# Codificar user_data
USER_DATA_B64=$(base64 -w 0 "$(dirname "$0")/user_data_sima_hg38.sh")

# Launch spec (patrón del proyecto)
cat > /tmp/launch_spec_hg38.json << SPEC
{
    "ImageId": "${UBUNTU_AMI}",
    "InstanceType": "${INSTANCE_TYPE}",
    "KeyName": "${KEY_NAME}",
    "SecurityGroupIds": ["${SG_ID}"],
    "IamInstanceProfile": {"Name": "${IAM_INSTANCE_PROFILE}"},
    "BlockDeviceMappings": [{
        "DeviceName": "/dev/sda1",
        "Ebs": {
            "VolumeSize": ${VOLUME_SIZE},
            "VolumeType": "gp3",
            "Throughput": 250,
            "DeleteOnTermination": true
        }
    }],
    "UserData": "${USER_DATA_B64}"
}
SPEC

echo "📡 Solicitando Spot Instance..."
SPOT_RESPONSE=$(aws ec2 request-spot-instances \
    --instance-count 1 \
    --type "one-time" \
    --instance-interruption-behavior "terminate" \
    --region "${AWS_REGION}" \
    --launch-specification file:///tmp/launch_spec_hg38.json)

SPOT_ID=$(echo "$SPOT_RESPONSE" | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['SpotInstanceRequests'][0]['SpotInstanceRequestId'])")

echo "✅ Spot Request ID: $SPOT_ID"
echo "$SPOT_ID" > "$(dirname "$0")/instance_id_sima_hg38.txt"

# Esperar a que se asigne instancia y añadir tags
echo "⏳ Esperando asignación de instancia..."
sleep 30

INSTANCE_ID=$(aws ec2 describe-spot-instance-requests \
    --spot-instance-request-ids "$SPOT_ID" \
    --region "${AWS_REGION}" \
    --query 'SpotInstanceRequests[0].InstanceId' \
    --output text 2>/dev/null || echo "None")

if [ "$INSTANCE_ID" != "None" ] && [ -n "$INSTANCE_ID" ]; then
    aws ec2 create-tags \
        --resources "$INSTANCE_ID" \
        --tags \
            Key=Name,Value=${JOB_NAME} \
            Key=Project,Value=EastWestDM \
            Key=Pipeline,Value=sima-hg38-mapdamage \
            Key=Date,Value=$(date +%Y-%m-%d) \
        --region "${AWS_REGION}"
    echo "$INSTANCE_ID" >> "$(dirname "$0")/instance_id_sima_hg38.txt"
    
    # Guardar IP cuando esté disponible
    sleep 20
    IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --region "${AWS_REGION}" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
    echo "$IP" > "$(dirname "$0")/ip_sima_hg38.txt"
    echo "Instance ID : $INSTANCE_ID"
    echo "IP pública  : $IP"
fi

echo ""
echo "📊 MONITOREO:"
echo "  # Estado del job:"
echo "  aws s3 ls s3://${S3_BUCKET}/sima_hg38/logs/ --region ${AWS_REGION} | tail -5"
echo ""
echo "  # Seguir log en tiempo real:"
echo "  watch -n 60 'aws s3 cp s3://${S3_BUCKET}/sima_hg38/logs/\$(aws s3 ls s3://${S3_BUCKET}/sima_hg38/logs/ --region ${AWS_REGION} | grep heartbeat | tail -1 | awk \"{print \$4}\") - --region ${AWS_REGION} | tail -30'"
echo ""
echo "  # Recuperar resultados cuando termine:"
echo "  aws s3 sync s3://${S3_BUCKET}/sima_hg38/results/ ./results_sima_hg38/ --region ${AWS_REGION}"
echo "  aws s3 cp s3://${S3_BUCKET}/sima_hg38/results/damage_summary.tsv . --region ${AWS_REGION}"
echo "  aws s3 cp s3://${S3_BUCKET}/sima_hg38/results/sima_hg38_loci.vcf.gz . --region ${AWS_REGION}"
echo ""
echo "========================================="
echo "✅ LANZAMIENTO COMPLETADO"
echo "========================================="

rm -f /tmp/launch_spec_hg38.json
