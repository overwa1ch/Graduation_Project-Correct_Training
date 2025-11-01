"""
MNS Consumer for processing job messages
Using aliyun-python-sdk-mns for MNS operations
"""
import json
import logging
import time
from typing import Callable, Dict, Any
from mns.mns_client import MNSClient
from mns.mns_request import SendMessageRequest, ReceiveMessageRequest, DeleteMessageRequest
from config import settings

logger = logging.getLogger(__name__)


class MNSConsumer:
    """Long-polling MNS consumer"""
    
    def __init__(self, queue_name: str, visibility_timeout: int):
        self.queue_name = queue_name
        self.visibility_timeout = visibility_timeout
        
        # MNS endpoint format: https://{accountId}.mns.{region}.aliyuncs.com
        mns_region = settings.aliyun_region.replace('oss-', '')  # oss-cn-hangzhou -> cn-hangzhou
        account_id = settings.aliyun_mns_account_id
        endpoint = f'https://{account_id}.mns.{mns_region}.aliyuncs.com'
        
        # Initialize MNS client
        self.mns_client = MNSClient(
            endpoint,
            settings.aliyun_access_key_id,
            settings.aliyun_secret_access_key
        )
        
        logger.info(f"Initialized MNS consumer for queue: {queue_name} at {endpoint}")
    
    def receive_message(self) -> Dict[str, Any] | None:
        """
        Receive a single message from MNS queue
        
        Returns:
            Message dict with 'MessageId', 'ReceiptHandle', 'MessageBody', or None if no message
        """
        try:
            req = ReceiveMessageRequest(
                wait_seconds=20,  # Long polling
                visibility_timeout=self.visibility_timeout
            )
            
            resp = self.mns_client.receive_message(self.queue_name, req)
            
            if resp and resp.message_body:
                return {
                    'MessageId': resp.message_id,
                    'ReceiptHandle': resp.receipt_handle,
                    'MessageBody': resp.message_body,
                }
            return None
        except Exception as e:
            error_msg = str(e)
            if 'MessageNotExist' in error_msg or '404' in error_msg:
                return None
            logger.error(f"Error receiving message: {e}")
            raise
    
    def delete_message(self, receipt_handle: str) -> None:
        """
        Delete message from queue using receipt handle
        
        Args:
            receipt_handle: Receipt handle from received message
        """
        try:
            req = DeleteMessageRequest(receipt_handle)
            self.mns_client.delete_message(self.queue_name, receipt_handle)
            logger.debug(f"Deleted message with receipt handle: {receipt_handle[:20]}...")
        except Exception as e:
            logger.error(f"Error deleting message: {e}")
            raise
    
    def poll(self, handler: Callable[[Dict[str, Any]], None]):
        """
        Long-poll MNS and process messages
        
        Args:
            handler: Function to process message body
        """
        logger.info("Starting MNS polling...")
        
        while True:
            try:
                message = self.receive_message()
                
                if message:
                    try:
                        logger.info(f"Received message: {message['MessageId']}")
                        body = json.loads(message['MessageBody'])
                        
                        # Process message
                        handler(body)
                        
                        # Delete message on success
                        self.delete_message(message['ReceiptHandle'])
                        logger.info(f"Successfully processed and deleted message: {message['MessageId']}")
                        
                    except Exception as e:
                        logger.error(f"Error processing message {message.get('MessageId')}: {e}", exc_info=True)
                        # Message will become visible again after visibility timeout
                        # and will be retried (up to maxReceiveCount before going to DLQ)
                else:
                    # No message received, continue polling
                    time.sleep(1)
                    
            except KeyboardInterrupt:
                logger.info("Received interrupt signal, stopping consumer...")
                break
            except Exception as e:
                logger.error(f"Error in polling loop: {e}", exc_info=True)
                # Continue polling even if there's an error
                time.sleep(5)
                continue

