import csv
import io
import json
import os
import urllib.parse
from decimal import Decimal
 
import boto3
 
 
s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")
 
table_name = os.environ["DYNAMODB_TABLE"]
table = dynamodb.Table(table_name)
 
 
def store_transaction(transaction):
    transaction["transaction_id"] = str(transaction["transaction_id"])
 
    if "amount" in transaction:
        transaction["amount"] = Decimal(str(transaction["amount"]))
 
    table.put_item(Item=transaction)
 
 
def process_s3_record(record):
    bucket_name = record["s3"]["bucket"]["name"]
    object_key = urllib.parse.unquote_plus(
        record["s3"]["object"]["key"]
    )
 
    print(f"Processing CSV file: s3://{bucket_name}/{object_key}")
 
    response = s3.get_object(
        Bucket=bucket_name,
        Key=object_key
    )
 
    csv_content = response["Body"].read().decode("utf-8")
    reader = csv.DictReader(io.StringIO(csv_content))
 
    processed_count = 0
 
    for row in reader:
        if not row.get("transaction_id"):
            raise ValueError(
                "CSV row is missing transaction_id"
            )
 
        store_transaction(row)
        processed_count += 1
 
    return {
        "file": object_key,
        "recordsProcessed": processed_count
    }
 
 
def lambda_handler(event, context):
    print("Received event:", json.dumps(event))
 
    # S3 upload path
    if event.get("Records"):
        processed_files = []
 
        for record in event["Records"]:
            if record.get("eventSource") == "aws:s3":
                result = process_s3_record(record)
                processed_files.append(result)
 
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "CSV transaction files processed successfully",
                "processedFiles": processed_files
            })
        }
 
    # Step Functions path
    if event.get("bucket") and event.get("key"):
        record = {
            "s3": {
                "bucket": {
                    "name": event["bucket"]
                },
                "object": {
                    "key": event["key"]
                }
            }
        }
 
        result = process_s3_record(record)
 
        return {
            "statusCode": 200,
            "message": "CSV transaction file processed successfully",
            "result": result
        }
 
    # API Gateway path
    body = event.get("body", event)
 
    if isinstance(body, str):
        body = json.loads(body)
 
    if not body.get("transaction_id"):
        return {
            "statusCode": 400,
            "body": json.dumps({
                "message": "transaction_id is required"
            })
        }
 
    store_transaction(body)
 
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Transaction stored successfully",
            "transaction_id": body["transaction_id"]
        })
    }
 
