import OSS from 'ali-oss';
import PopCore from '@alicloud/pop-core';
import { CONFIG } from '../config';

// OSS Client
export const ossClient = new OSS({
  region: CONFIG.aliyun.region,
  accessKeyId: CONFIG.aliyun.accessKeyId,
  accessKeySecret: CONFIG.aliyun.secretAccessKey,
  bucket: CONFIG.aliyun.oss.bucket,
});

// MNS Client (using Alibaba Cloud POP Core SDK)
// MNS endpoint format: https://{accountId}.mns.{region}.aliyuncs.com
const mnsAccountId = CONFIG.aliyun.mns.accountId || '';
const mnsRegion = CONFIG.aliyun.region.replace('oss-', ''); // oss-cn-hangzhou -> cn-hangzhou
const mnsEndpoint = `https://${mnsAccountId}.mns.${mnsRegion}.aliyuncs.com`;

export const mnsClient = new PopCore({
  accessKeyId: CONFIG.aliyun.accessKeyId,
  accessKeySecret: CONFIG.aliyun.secretAccessKey,
  endpoint: mnsEndpoint,
  apiVersion: '2015-06-06',
});

// Generate presigned URL for upload
export async function generatePresignedUploadUrl(
  key: string,
  contentType: string,
  expiresIn: number = 900 // 15 minutes
): Promise<string> {
  const url = ossClient.signatureUrl(key, {
    method: 'PUT',
    expires: expiresIn,
    'Content-Type': contentType,
  });
  return url;
}

// Generate presigned URL for download
export async function generatePresignedDownloadUrl(
  key: string,
  expiresIn: number = 900 // 15 minutes
): Promise<string> {
  const url = ossClient.signatureUrl(key, {
    method: 'GET',
    expires: expiresIn,
  });
  return url;
}

// Extract key from OSS URI
export function extractKeyFromOssUri(uri: string): string {
  // Support both formats:
  // - oss://bucket/key
  // - https://bucket.oss-region.aliyuncs.com/key
  if (uri.startsWith('oss://')) {
    const parts = uri.substring(6).split('/', 2); // Remove 'oss://' prefix
    return parts.length > 1 ? parts[1] : '';
  } else if (uri.startsWith('https://')) {
    // Extract key from https://bucket.oss-region.aliyuncs.com/key
    const url = new URL(uri);
    return url.pathname.substring(1); // Remove leading '/'
  }
  throw new Error(`Invalid OSS URI format: ${uri}`);
}

// Send message to MNS queue
export async function sendMNSMessage(queueName: string, message: object): Promise<string> {
  const params = {
    QueueName: queueName,
    MessageBody: JSON.stringify(message),
    Priority: 8,
  };

  const requestOption = {
    method: 'POST',
  };

  try {
    const response = await mnsClient.request('SendMessage', params, requestOption);
    return response.MessageId || response.MessageId || 'unknown';
  } catch (error: any) {
    throw new Error(`Failed to send message to MNS queue ${queueName}: ${error.message}`);
  }
}

