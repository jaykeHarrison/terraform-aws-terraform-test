import json
import boto3
import os

# Initialize S3 client
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    # Get the bucket name, file name, and content from the event
    bucket_name = event['bucket_name']
    file_name = event['file_name']
    content = event['content']

    try:
        # Upload the content to S3
        s3_client.put_object(Bucket=bucket_name, Key=file_name, Body=content)
        
        return {
            'statusCode': 200,
            'body': json.dumps(f"File '{file_name}' created successfully in bucket '{bucket_name}'")
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error creating file: {str(e)}")
        }
