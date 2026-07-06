import json
import os
import urllib.parse
 
import boto3
 
 
s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")
 
table_name = os.environ["DYNAMODB_TABLE"]
table = dynamodb.Table(table_name)
 
 
def lambda_handler(event, context):
    print("Received event:", json.dumps(event))
 
    processed_files = []
 
    for record in event.get("Records", []):
        bucket_name = record["s3"]["bucket"]["name"]
        object_key = urllib.parse.unquote_plus(
            record["s3"]["object"]["key"]
        )
 
        print(f"Processing transaction file: s3://{bucket_name}/{object_key}")
 
        response = s3.get_object(
            Bucket=bucket_name,
            Key=object_key
        )
 
        transaction = json.loads(
            response["Body"].read().decode("utf-8")
        )
 
        table.put_item(Item=transaction)
 
        print(
            f"Transaction {transaction['transaction_id']} "
            "stored successfully in DynamoDB"
        )
 
        processed_files.append(object_key)
 
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Transaction files processed successfully",
            "processedFiles": processed_files
        })
    }
