"""
Lambda ingestion function - course module 5 ("AWS Lambda"), code as given by
the course, lightly adapted so the Kinesis stream name and error-bucket name
come from environment variables (KINESIS_STREAM_NAME / ERROR_BUCKET_NAME)
instead of being hardcoded - those env vars are set by
terraform/modules/lambda/main.tf once you've written it, so this file and
your Terraform need to agree on those two names.

Flow: API Gateway hands this function the raw employee JSON array in
event['body']. Each record either:
  - is missing/blank employee_id  -> written to the S3 error bucket
  - has an employee_id            -> PutRecord onto the Kinesis Data Stream

Sample record shape (from the course):
  {
    "employee_id": "E001",
    "employee_name": "John Smith",
    "department": "Engineering",
    "designation": "Software Engineer",
    "salary": 95000,
    "joining_date": "2022-01-15",
    "city": "San Francisco",
    "state": "CA",
    "country": "USA"
  }
"""

import json
import os
import boto3
from datetime import datetime

streamname = os.environ.get("KINESIS_STREAM_NAME", "your_kinesis_stream_name")
errorbucketname = os.environ.get("ERROR_BUCKET_NAME", "your_error_handling_bucket_name")

# Initialize clients
s3_client = boto3.client("s3")
kinesis_client = boto3.client("kinesis")


def lambda_handler(event, context):

    try:
        # Assuming API Gateway passes JSON data in the event
        data = json.loads(event["body"])

        success_count = 0
        error_count = 0
        for record in data:

            # print the records
            print(record)
            # Set the current timestamp
            timestamp = datetime.now().strftime("%Y%m%d%H%M%S%f")
            # Check if 'employee_id' column not exists or is blank
            if "employee_id" not in record or record["employee_id"] in [None, ""]:

                # Include the timestamp in the object key
                object_key = f"error_{timestamp}.json"

                # Write record to S3 bucket for error handling
                s3_client.put_object(Bucket=errorbucketname, Key=object_key, Body=json.dumps(record))
                error_count += 1

            else:
                print("Writing to Amazon Kinesis stream")
                kinesis_client.put_record(StreamName=streamname, Data=json.dumps(record), PartitionKey="1")
                success_count += 1

        response = {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "message": "Data Processing Completed",
                    "success_records": success_count,
                    "error_records": error_count,
                }
            ),
            "headers": {"Content-Type": "application/json"},
        }
        return response

    except Exception as e:
        print(f"Error processing event: {e}")

        error_response = {
            "statusCode": 500,
            "body": json.dumps(f"Error processing event: {e}"),
            "headers": {"Content-Type": "application/json"},
        }
        return error_response
