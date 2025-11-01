import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { SQSClient, SendMessageCommand } from '@aws-sdk/client-sqs';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { CONFIG } from '../config';

// S3 Client
export const s3Client = new S3Client({
  region: CONFIG.aws.region,
  credentials: {
    accessKeyId: CONFIG.aws.accessKeyId,
    secretAccessKey: CONFIG.aws.secretAccessKey,
  },
});

// SQS Client
export const sqsClient = new SQSClient({
  region: CONFIG.aws.region,
  credentials: {
    accessKeyId: CONFIG.aws.accessKeyId,
    secretAccessKey: CONFIG.aws.secretAccessKey,
  },
});

// Generate presigned URL for upload
export async function generatePresignedUploadUrl(
  key: string,
  contentType: string
): Promise<string> {
  const command = new PutObjectCommand({
    Bucket: CONFIG.aws.s3.bucket,
    Key: key,
    ContentType: contentType,
  });

  return getSignedUrl(s3Client, command, {
    expiresIn: CONFIG.aws.s3.presignedUrlExpiration,
  });
}

// Generate presigned URL for download
export async function generatePresignedDownloadUrl(key: string): Promise<string> {
  const command = new GetObjectCommand({
    Bucket: CONFIG.aws.s3.bucket,
    Key: key,
  });

  return getSignedUrl(s3Client, command, {
    expiresIn: CONFIG.aws.s3.presignedUrlExpiration,
  });
}

// Send message to SQS queue
export async function sendSQSMessage(queueUrl: string, message: object): Promise<string> {
  const command = new SendMessageCommand({
    QueueUrl: queueUrl,
    MessageBody: JSON.stringify(message),
  });

  const response = await sqsClient.send(command);
  return response.MessageId!;
}

