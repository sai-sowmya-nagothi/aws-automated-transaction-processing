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
 
 
def main():
    bucket = os.environ["S3_BUCKET"]
    key = urllib.parse.unquote_plus(os.environ["S3_KEY"])
 
    print(f"ECS processing CSV file: s3://{bucket}/{key}")
 
    response = s3.get_object(Bucket=bucket, Key=key)
    csv_content = response["Body"].read().decode("utf-8")
    reader = csv.DictReader(io.StringIO(csv_content))
 
    processed_count = 0
 
    for row in reader:
        if not row.get("transaction_id"):
            raise ValueError("CSV row is missing transaction_id")
 
        row["transaction_id"] = str(row["transaction_id"])
 
        if "amount" in row and row["amount"]:
            row["amount"] = Decimal(str(row["amount"]))
 
        table.put_item(Item=row)
        processed_count += 1
 
    print(json.dumps({
        "status": "SUCCESS",
        "file": key,
        "recordsProcessed": processed_count
    }))
 
 
if __name__ == "__main__":
    main()
