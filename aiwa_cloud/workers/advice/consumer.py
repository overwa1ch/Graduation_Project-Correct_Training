"""
ADVICE Worker Consumer
Processes ADVICE jobs from SQS queue
"""
import sys
import os
import json
import tempfile
import logging

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import settings
from lib.mns_consumer import MNSConsumer
from lib.oss_client import download_file, upload_json, get_oss_key_from_uri
from lib.db_client import update_job_status, create_asset
from advice.generator import generate_advice_from_file

# Configure logging
logging.basicConfig(
    level=settings.log_level,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def handle_advice_job(message: dict):
    """
    Process ADVICE job from MNS
    
    Message format:
    {
        "job_id": "...",
        "session_id": "...",
        "type": "ADVICE",
        "assets": {
            "result_cloud": "oss://..." or null,
            "result_local": "oss://..." or null
        },
        "attempt": 1
    }
    """
    job_id = message['job_id']
    session_id = message['session_id']
    assets = message['assets']
    
    logger.info(f"Processing ADVICE job {job_id} for session {session_id}")
    
    try:
        # Update job status to running
        update_job_status(job_id, 'running')
        
        # Determine which result to use (prefer result_cloud)
        result_uri = assets.get('result_cloud') or assets.get('result_local')
        if not result_uri:
            raise ValueError("No result asset found (result_cloud or result_local required)")
        
        logger.info(f"Using result from {result_uri}")
        
        # Download result from OSS
        with tempfile.TemporaryDirectory() as tmpdir:
            result_path = os.path.join(tmpdir, 'result.json')
            logger.info(f"Downloading result from {result_uri}")
            download_file(result_uri, result_path)
            
            # Load result to get template
            with open(result_path, 'r') as f:
                result_data = json.load(f)
            
            template = result_data.get('meta', {}).get('template', 'squat')
            
            # Generate advice
            logger.info(f"Generating advice for template '{template}'")
            advice = generate_advice_from_file(result_path, template)
            
            # Upload advice.json to OSS
            # Construct OSS URI: same directory as result, but advice.json
            result_key = get_oss_key_from_uri(result_uri)
            advice_key = result_key.replace('result_cloud.json', 'advice.json').replace('result_local.json', 'advice.json')
            advice_uri = f"oss://{settings.aliyun_oss_bucket}/{advice_key}"
            
            logger.info(f"Uploading advice to {advice_uri}")
            upload_json(advice, advice_uri)
            
            # Create asset record in database
            advice_json_str = json.dumps(advice, indent=2)
            advice_size = len(advice_json_str.encode('utf-8'))
            
            create_asset(
                session_id=session_id,
                asset_type='advice',
                uri=advice_uri,
                size=advice_size,
                content_type='application/json'
            )
            
            # Update job status to succeeded
            update_job_status(job_id, 'succeeded')
            
            logger.info(f"Successfully processed job {job_id}")
            
    except Exception as e:
        logger.error(f"Error processing job {job_id}: {e}", exc_info=True)
        
        # Determine error code
        error_code = 'PROCESSING_ERROR'
        if 'not found' in str(e).lower():
            error_code = 'ASSET_NOT_FOUND'
        
        # Update job status to failed
        update_job_status(job_id, 'failed', error_code=error_code)
        
        # Re-raise to let MNS handle retry logic
        raise


def main():
    """Main entry point for ADVICE worker"""
    logger.info("Starting ADVICE worker")
    logger.info(f"Queue name: {settings.aliyun_mns_advice_queue_name}")
    logger.info(f"Visibility timeout: {settings.advice_visibility_timeout}s")
    
    consumer = MNSConsumer(
        queue_name=settings.aliyun_mns_advice_queue_name,
        visibility_timeout=settings.advice_visibility_timeout
    )
    
    logger.info("Worker ready, starting to poll for messages...")
    consumer.poll(handle_advice_job)


if __name__ == '__main__':
    main()

