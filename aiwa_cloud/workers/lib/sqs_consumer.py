"""
SQS Consumer for processing job messages
"""
import boto3
import json
import logging
from typing import Callable, Dict, Any
from config import settings

logger = logging.getLogger(__name__)


class SQSConsumer:
    """Long-polling SQS consumer"""
    
    def __init__(self, queue_url: str, visibility_timeout: int):
        self.sqs = boto3.client(
            'sqs',
            region_name=settings.aws_region,
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
        )
        self.queue_url = queue_url
        self.visibility_timeout = visibility_timeout
        logger.info(f"Initialized SQS consumer for queue: {queue_url}")
    
    def poll(self, handler: Callable[[Dict[str, Any]], None]):
        """
        Long-poll SQS and process messages
        
        Args:
            handler: Function to process message body
        """
        logger.info("Starting SQS polling...")
        
        while True:
            try:
                response = self.sqs.receive_message(
                    QueueUrl=self.queue_url,
                    MaxNumberOfMessages=1,
                    WaitTimeSeconds=20,  # Long polling
                    VisibilityTimeout=self.visibility_timeout,
                )
                
                if 'Messages' in response:
                    for message in response['Messages']:
                        try:
                            logger.info(f"Received message: {message['MessageId']}")
                            body = json.loads(message['Body'])
                            
                            # Process message
                            handler(body)
                            
                            # Delete message on success
                            self.sqs.delete_message(
                                QueueUrl=self.queue_url,
                                ReceiptHandle=message['ReceiptHandle']
                            )
                            logger.info(f"Successfully processed and deleted message: {message['MessageId']}")
                            
                        except Exception as e:
                            logger.error(f"Error processing message {message.get('MessageId')}: {e}", exc_info=True)
                            # Message will become visible again after visibility timeout
                            # and will be retried (up to maxReceiveCount before going to DLQ)
                            
            except KeyboardInterrupt:
                logger.info("Received interrupt signal, stopping consumer...")
                break
            except Exception as e:
                logger.error(f"Error in polling loop: {e}", exc_info=True)
                # Continue polling even if there's an error
                continue

