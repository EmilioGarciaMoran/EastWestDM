#!/bin/bash
set -e
aws s3 cp s3://egarmo-genomes/d17/run_d17.sh /home/ubuntu/run_d17.sh
chmod +x /home/ubuntu/run_d17.sh
nohup /home/ubuntu/run_d17.sh > /home/ubuntu/run_d17.out 2>&1 &
echo "sudo shutdown -h now" | at now + 6 hours
