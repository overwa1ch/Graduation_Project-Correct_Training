"""
OSS client utilities for downloading and uploading files
"""
import oss2
import json
import logging
from typing import Any, Dict
from urllib.parse import urlparse
from config import settings

logger = logging.getLogger(__name__)

# Initialize OSS client
auth = oss2.Auth(settings.aliyun_access_key_id, settings.aliyun_secret_access_key)
# OSS endpoint format: https://oss-{region}.aliyuncs.com
oss_region = settings.aliyun_region.replace('oss-', '')  # oss-cn-hangzhou -> cn-hangzhou
endpoint = f'https://oss-{oss_region}.aliyuncs.com'
bucket = oss2.Bucket(auth, endpoint, settings.aliyun_oss_bucket)


def parse_oss_uri(oss_uri: str) -> tuple[str, str]:
    """
    Parse OSS URI and return (bucket, key)
    
    Supports formats:
    - oss://bucket/key
    - https://bucket.oss-region.aliyuncs.com/key
    
    Args:
        oss_uri: OSS URI string
        
    Returns:
        Tuple of (bucket, key)
    """
    if oss_uri.startswith('oss://'):
        # Format: oss://bucket/key
        parts = oss_uri[6:].split('/', 1)  # Remove 'oss://' prefix
        bucket_name = parts[0]
        key = parts[1] if len(parts) > 1 else ''
        return (bucket_name, key)
    elif oss_uri.startswith('https://'):
        # Format: https://bucket.oss-region.aliyuncs.com/key
        try:
            parsed = urlparse(oss_uri)
            # Extract bucket from hostname: bucket.oss-region.aliyuncs.com
            hostname = parsed.netloc
            if '.oss-' in hostname and '.aliyuncs.com' in hostname:
                bucket_name = hostname.split('.')[0]
                key = parsed.path.lstrip('/')
                return (bucket_name, key)
            else:
                raise ValueError(f"Invalid OSS HTTPS URI format: {oss_uri}")
        except Exception as e:
            raise ValueError(f"Failed to parse OSS URI {oss_uri}: {e}")
    else:
        raise ValueError(f"Invalid OSS URI format (must start with oss:// or https://): {oss_uri}")


def download_file(oss_uri: str, local_path: str) -> None:
    """
    Download file from OSS to local path
    
    Args:
        oss_uri: OSS URI in format oss://bucket/key or https://bucket.oss-region.aliyuncs.com/key
        local_path: Local file path to save to
    """
    bucket_name, key = parse_oss_uri(oss_uri)
    
    # If bucket doesn't match, use bucket-specific client
    if bucket_name != settings.aliyun_oss_bucket:
        bucket_client = oss2.Bucket(auth, endpoint, bucket_name)
    else:
        bucket_client = bucket
    
    logger.info(f"Downloading {oss_uri} to {local_path}")
    bucket_client.get_object_to_file(key, local_path)
    logger.info(f"Downloaded {oss_uri} successfully")


def upload_file(local_path: str, oss_uri: str, content_type: str = 'application/json') -> None:
    """
    Upload file from local path to OSS
    
    Args:
        local_path: Local file path to upload
        oss_uri: OSS URI in format oss://bucket/key or https://bucket.oss-region.aliyuncs.com/key
        content_type: MIME type of the file
    """
    bucket_name, key = parse_oss_uri(oss_uri)
    
    # If bucket doesn't match, use bucket-specific client
    if bucket_name != settings.aliyun_oss_bucket:
        bucket_client = oss2.Bucket(auth, endpoint, bucket_name)
    else:
        bucket_client = bucket
    
    logger.info(f"Uploading {local_path} to {oss_uri}")
    bucket_client.put_object_from_file(key, local_path, headers={'Content-Type': content_type})
    logger.info(f"Uploaded {local_path} successfully")


def upload_json(data: Dict[str, Any], oss_uri: str) -> None:
    """
    Upload JSON data directly to OSS
    
    Args:
        data: Dictionary to upload as JSON
        oss_uri: OSS URI in format oss://bucket/key or https://bucket.oss-region.aliyuncs.com/key
    """
    bucket_name, key = parse_oss_uri(oss_uri)
    
    # If bucket doesn't match, use bucket-specific client
    if bucket_name != settings.aliyun_oss_bucket:
        bucket_client = oss2.Bucket(auth, endpoint, bucket_name)
    else:
        bucket_client = bucket
    
    json_str = json.dumps(data, indent=2, ensure_ascii=False)
    
    logger.info(f"Uploading JSON data to {oss_uri}")
    bucket_client.put_object(
        key,
        json_str.encode('utf-8'),
        headers={'Content-Type': 'application/json; charset=utf-8'}
    )
    logger.info(f"Uploaded JSON data successfully")


def get_oss_key_from_uri(oss_uri: str) -> str:
    """
    Extract OSS key from OSS URI
    
    Args:
        oss_uri: OSS URI
        
    Returns:
        OSS key (path within bucket)
    """
    _, key = parse_oss_uri(oss_uri)
    return key

