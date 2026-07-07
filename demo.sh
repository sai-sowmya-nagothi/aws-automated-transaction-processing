#!/bin/bash
 
set -e
 
REGION="us-east-1"
BUCKET="aws-transaction-files-265145884274"
CSV_FILE="test-transactions.csv"
LOG_GROUP="/ecs/transaction-processor"
 
TIMESTAMP=$(date +%s)
S3_KEY="workflow-test-${TIMESTAMP}.csv"
 
echo "========================================"
echo " AWS Transaction Workflow Test"
echo "========================================"
 
if [ ! -f "$CSV_FILE" ]; then
    echo "ERROR: $CSV_FILE not found."
    echo "Run this script from the project root."
    exit 1
fi
 
echo
echo "[1/4] Uploading CSV to S3..."
 
aws s3 cp "$CSV_FILE" "s3://${BUCKET}/${S3_KEY}" \
    --region "$REGION"
 
echo
echo "[2/4] CSV uploaded successfully."
echo "S3 object: s3://${BUCKET}/${S3_KEY}"
 
echo
echo "[3/4] Waiting for EventBridge, Step Functions, and ECS..."
sleep 45
 
echo
echo "[4/4] Showing ECS processing logs..."
 
aws logs tail "$LOG_GROUP" \
    --since 5m \
    --region "$REGION"
 
echo
echo "========================================"
echo " Workflow test completed"
echo "========================================"
