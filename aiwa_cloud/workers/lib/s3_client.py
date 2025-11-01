"""
S3 client utilities for downloading and uploading files
"""
import boto3
import json
import logging
from typing import Any, Dict
from config import settings

logger = logging.getLogger(__name__)

# Initialize S3 client
s3_client = boto3.client(
    's3',
    region_name=settings.aws_region,
    aws_access_key_id=settings.aws_access_key_id,
    aws_secret_access_key=settings.aws_secret_access_key,
)


def download_file(s3_uri: str, local_path: str) -> None:
    """
    Download file from S3 to local path
    
    Args:
        s3_uri: S3 URI in format s3://bucket/key
        local_path: Local file path to save to
    """
    # Parse S3 URI
    if not s3_uri.startswith('s3://'):
        raise ValueError(f"Invalid S3 URI: {s3_uri}")
    
    parts = s3_uri[5:].split('/', 1)
    bucket = parts[0]
    key = parts[1] if len(parts) > 1 else ''
    
    logger.info(f"Downloading {s3_uri} to {local_path}")
    s3_client.download_file(bucket, key, local_path)
    logger.info(f"Downloaded {s3_uri} successfully")


def upload_file(local_path: str, s3_uri: str, content_type: str = 'application/json') -> None:
    """
    Upload file from local path to S3
    
    Args:
        local_path: Local file path to upload
        s3_uri: S3 URI in format s3://bucket/key
        content_type: MIME type of the file
    """
    # Parse S3 URI
    if not s3_uri.startswith('s3://'):
        raise ValueError(f"Invalid S3 URI: {s3_uri}")
    
    parts = s3_uri[5:].split('/', 1)
    bucket = parts[0]
    key = parts[1] if len(parts) > 1 else ''
    
    logger.info(f"Uploading {local_path} to {s3_uri}")
    s3_client.upload_file(
        local_path,
        bucket,
        key,
        ExtraArgs={'ContentType': content_type}
    )
    logger.info(f"Uploaded {local_path} successfully")


def upload_json(data: Dict[str, Any], s3_uri: str) -> None:
    """
    Upload JSON data directly to S3
    
    Args:
        data: Dictionary to upload as JSON
        s3_uri: S3 URI in format s3://bucket/key
    """
    # Parse S3 URI
    if not s3_uri.startswith('s3://'):
        raise ValueError(f"Invalid S3 URI: {s3_uri}")
    
    parts = s3_uri[5:].split('/', 1)
    bucket = parts[0]
    key = parts[1] if len(parts) > 1 else ''
    
    logger.info(f"Uploading JSON data to {s3_uri}")
    s3_client.put_object(
        Bucket=bucket,
        Key=key,
        Body=json.dumps(data, indent=2),
        ContentType='application/json'
    )
    logger.info(f"Uploaded JSON data successfully")


def get_s3_key_from_uri(s3_uri: str) -> str:
    """Extract S3 key from S3 URI"""
    if not s3_uri.startswith('s3://'):
        raise ValueError(f"Invalid S3 URI: {s3_uri}")
    parts = s3_uri[5:].split('/', 1)
    return parts[1] if len(parts) > 1 else ''

