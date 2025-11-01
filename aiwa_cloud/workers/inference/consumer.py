"""
REINFER Worker Consumer
Processes REINFER jobs from SQS queue
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
from lib.db_client import update_job_status, update_session_status, create_asset
from inference.pipeline import ReinferPipeline

# Configure logging
logging.basicConfig(
    level=settings.log_level,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def handle_reinfer_job(message: dict):
    """
    Process REINFER job from MNS
    
    Message format:
    {
        "job_id": "...",
        "session_id": "...",
        "type": "REINFER",
        "assets": {
            "keypoints": "oss://bucket/path/keypoints.json",
            "video": "oss://..." or null,
            "result_local": "oss://..." or null
        },
        "attempt": 1
    }
    """
    job_id = message['job_id']
    session_id = message['session_id']
    assets = message['assets']
    
    logger.info(f"Processing REINFER job {job_id} for session {session_id}")
    
    try:
        # Update job status to running
        update_job_status(job_id, 'running')
        
        # Download assets from OSS
        with tempfile.TemporaryDirectory() as tmpdir:
            keypoints_path = os.path.join(tmpdir, 'keypoints.json')
            logger.info(f"Downloading keypoints from {assets['keypoints']}")
            download_file(assets['keypoints'], keypoints_path)
            
            video_path = None
            if assets.get('video'):
                video_path = os.path.join(tmpdir, 'video.mp4')
                logger.info(f"Downloading video from {assets['video']}")
                download_file(assets['video'], video_path)
            
            result_local_path = None
            if assets.get('result_local'):
                result_local_path = os.path.join(tmpdir, 'result_local.json')
                logger.info(f"Downloading result_local from {assets['result_local']}")
                download_file(assets['result_local'], result_local_path)
            
            # Run pipeline
            logger.info("Running REINFER pipeline")
            pipeline = ReinferPipeline(
                model_path=settings.rtmpose_model_path,
                use_gpu=True
            )
            result = pipeline.process(keypoints_path, video_path, result_local_path)
            
            # Upload result_cloud.json to OSS
            # Construct OSS URI: same directory as keypoints, but result_cloud.json
            keypoints_key = get_oss_key_from_uri(assets['keypoints'])
            result_key = keypoints_key.replace('keypoints.json', 'result_cloud.json')
            result_uri = f"oss://{settings.aliyun_oss_bucket}/{result_key}"
            
            logger.info(f"Uploading result_cloud to {result_uri}")
            upload_json(result, result_uri)
            
            # Create asset record in database
            result_json_str = json.dumps(result, indent=2)
            result_size = len(result_json_str.encode('utf-8'))
            
            create_asset(
                session_id=session_id,
                asset_type='result_cloud',
                uri=result_uri,
                size=result_size,
                content_type='application/json'
            )
            
            # Update job status to succeeded
            update_job_status(job_id, 'succeeded')
            
            # Update session status to ready
            update_session_status(session_id, 'ready')
            
            logger.info(f"Successfully processed job {job_id}")
            
    except Exception as e:
        logger.error(f"Error processing job {job_id}: {e}", exc_info=True)
        
        # Determine error code
        error_code = 'PROCESSING_ERROR'
        if 'timeout' in str(e).lower():
            error_code = 'JOB_TIMEOUT'
        elif 'memory' in str(e).lower():
            error_code = 'OUT_OF_MEMORY'
        
        # Update job status to failed
        update_job_status(job_id, 'failed', error_code=error_code)
        update_session_status(session_id, 'failed')
        
        # Re-raise to let MNS handle retry logic
        raise


def main():
    """Main entry point for REINFER worker"""
    logger.info("Starting REINFER worker")
    logger.info(f"Queue name: {settings.aliyun_mns_reinfer_queue_name}")
    logger.info(f"Model path: {settings.rtmpose_model_path}")
    logger.info(f"Visibility timeout: {settings.reinfer_visibility_timeout}s")
    
    consumer = MNSConsumer(
        queue_name=settings.aliyun_mns_reinfer_queue_name,
        visibility_timeout=settings.reinfer_visibility_timeout
    )
    
    logger.info("Worker ready, starting to poll for messages...")
    consumer.poll(handle_reinfer_job)


if __name__ == '__main__':
    main()

