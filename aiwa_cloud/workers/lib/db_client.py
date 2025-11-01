"""
Database client for updating job and session status
"""
import psycopg2
import logging
from typing import Optional
from config import settings

logger = logging.getLogger(__name__)


def get_db_connection():
    """Get database connection"""
    return psycopg2.connect(settings.database_url)


def update_job_status(
    job_id: str,
    status: str,
    error_code: Optional[str] = None
) -> None:
    """
    Update job status in database
    
    Args:
        job_id: Job ID
        status: New status (queued, running, succeeded, failed, cancelled)
        error_code: Optional error code if failed
    """
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            if status in ['succeeded', 'failed']:
                cur.execute(
                    """
                    UPDATE jobs 
                    SET status = %s, error_code = %s, finished_at = NOW(), updated_at = NOW()
                    WHERE id = %s
                    """,
                    (status, error_code, job_id)
                )
            else:
                cur.execute(
                    """
                    UPDATE jobs 
                    SET status = %s, updated_at = NOW()
                    WHERE id = %s
                    """,
                    (status, job_id)
                )
            conn.commit()
            logger.info(f"Updated job {job_id} status to {status}")
    finally:
        conn.close()


def update_session_status(session_id: str, status: str) -> None:
    """
    Update session status in database
    
    Args:
        session_id: Session ID
        status: New status (local_only, uploaded, processing, ready, failed, cancelled)
    """
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                UPDATE sessions 
                SET status = %s, updated_at = NOW()
                WHERE id = %s
                """,
                (status, session_id)
            )
            conn.commit()
            logger.info(f"Updated session {session_id} status to {status}")
    finally:
        conn.close()


def create_asset(
    session_id: str,
    asset_type: str,
    uri: str,
    size: int,
    content_type: str,
    sha256: Optional[str] = None
) -> str:
    """
    Create asset record in database
    
    Args:
        session_id: Session ID
        asset_type: Asset type (result_cloud, advice, etc.)
        uri: S3 URI
        size: File size in bytes
        content_type: MIME type
        sha256: Optional SHA256 hash
        
    Returns:
        Asset ID
    """
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO assets (session_id, type, uri, size, content_type, sha256)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id
                """,
                (session_id, asset_type, uri, size, content_type, sha256)
            )
            asset_id = cur.fetchone()[0]
            conn.commit()
            logger.info(f"Created asset {asset_id} for session {session_id}")
            return asset_id
    finally:
        conn.close()

