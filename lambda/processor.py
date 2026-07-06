import json
import logging
from urllib.parse import unquote_plus
 
logger = logging.getLogger()
logger.setLevel(logging.INFO)
 
 
def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))
 
    processed_files = []
 
    for record in event.get("Records", []):
        bucket_name = record["s3"]["bucket"]["name"]
        object_key = unquote_plus(record["s3"]["object"]["key"])
 
        logger.info(
            "Processing transaction file: s3://%s/%s",
            bucket_name,
            object_key,
        )
 
        processed_files.append(
            {
                "bucket": bucket_name,
                "key": object_key,
                "status": "received",
            }
        )
 
    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "Transaction files received successfully",
                "processedFiles": processed_files,
            }
        ),
    }
