/**
 * 阿里云 OSS 客户端（预留功能 - 当前未实现）
 * 
 * ⚠️ 注意：此文件为预留接口，当前版本（v3.0）仅提供认证功能，不需要文件存储。
 * 
 * 未来扩展时使用：
 * 1. 设置环境变量 USE_ALIYUN_OSS=true
 * 2. 安装依赖: npm install ali-oss
 * 3. 配置环境变量: ALIYUN_ACCESS_KEY_ID, ALIYUN_SECRET_ACCESS_KEY, ALIYUN_OSS_BUCKET
 * 4. 实现下面的函数（取消注释并完成实现）
 * 
 * 当前状态：所有函数仅抛出错误，需要完整实现才能使用
 */

import { CONFIG } from '../config';

/**
 * 生成预签名上传 URL（未来实现）
 * @param key 对象存储键（文件路径）
 * @param contentType 文件类型
 * @returns 预签名 URL
 */
export async function generatePresignedUploadUrl(
  _key: string,
  _contentType: string
): Promise<string> {
  if (!CONFIG.aliyun.enabled) {
    throw new Error('Aliyun OSS is not enabled. Set USE_ALIYUN_OSS=true in .env');
  }

  // 未来实现：使用 ali-oss SDK
  // const OSS = require('ali-oss');
  // const client = new OSS({
  //   region: CONFIG.aliyun.region,
  //   accessKeyId: CONFIG.aliyun.accessKeyId,
  //   accessKeySecret: CONFIG.aliyun.secretAccessKey,
  //   bucket: CONFIG.aliyun.oss.bucket,
  // });
  // 
  // const url = client.signatureUrl(key, {
  //   method: 'PUT',
  //   expires: CONFIG.aliyun.oss.presignedUrlExpiration,
  //   'Content-Type': contentType,
  // });
  // 
  // return url;

  throw new Error('OSS functionality not implemented yet');
}

/**
 * 生成预签名下载 URL（未来实现）
 * @param key 对象存储键（文件路径）
 * @returns 预签名 URL
 */
export async function generatePresignedDownloadUrl(_key: string): Promise<string> {
  if (!CONFIG.aliyun.enabled) {
    throw new Error('Aliyun OSS is not enabled. Set USE_ALIYUN_OSS=true in .env');
  }

  // 未来实现：使用 ali-oss SDK
  // const OSS = require('ali-oss');
  // const client = new OSS({
  //   region: CONFIG.aliyun.region,
  //   accessKeyId: CONFIG.aliyun.accessKeyId,
  //   accessKeySecret: CONFIG.aliyun.secretAccessKey,
  //   bucket: CONFIG.aliyun.oss.bucket,
  // });
  // 
  // const url = client.signatureUrl(key, {
  //   method: 'GET',
  //   expires: CONFIG.aliyun.oss.presignedUrlExpiration,
  // });
  // 
  // return url;

  throw new Error('OSS functionality not implemented yet');
}

/**
 * 上传文件到 OSS（未来实现）
 * @param key 对象存储键（文件路径）
 * @param data 文件数据
 * @returns OSS URL
 */
export async function uploadFile(_key: string, _data: Buffer): Promise<string> {
  if (!CONFIG.aliyun.enabled) {
    throw new Error('Aliyun OSS is not enabled. Set USE_ALIYUN_OSS=true in .env');
  }

  // 未来实现：使用 ali-oss SDK
  // const OSS = require('ali-oss');
  // const client = new OSS({
  //   region: CONFIG.aliyun.region,
  //   accessKeyId: CONFIG.aliyun.accessKeyId,
  //   accessKeySecret: CONFIG.aliyun.secretAccessKey,
  //   bucket: CONFIG.aliyun.oss.bucket,
  // });
  // 
  // const result = await client.put(key, data);
  // return result.url;

  throw new Error('OSS functionality not implemented yet');
}

/**
 * 删除文件（未来实现）
 * @param key 对象存储键（文件路径）
 */
export async function deleteFile(_key: string): Promise<void> {
  if (!CONFIG.aliyun.enabled) {
    throw new Error('Aliyun OSS is not enabled. Set USE_ALIYUN_OSS=true in .env');
  }

  // 未来实现：使用 ali-oss SDK
  // const OSS = require('ali-oss');
  // const client = new OSS({
  //   region: CONFIG.aliyun.region,
  //   accessKeyId: CONFIG.aliyun.accessKeyId,
  //   accessKeySecret: CONFIG.aliyun.secretAccessKey,
  //   bucket: CONFIG.aliyun.oss.bucket,
  // });
  // 
  // await client.delete(key);

  throw new Error('OSS functionality not implemented yet');
}

/**
 * 扩展示例：存储用户头像
 * 
 * 用法：
 * ```typescript
 * import { uploadFile } from '../lib/aliyun-oss';
 * 
 * // 在用户注册/更新时上传头像
 * const avatarKey = `users/${userId}/avatar.jpg`;
 * const avatarUrl = await uploadFile(avatarKey, avatarBuffer);
 * 
 * // 更新数据库
 * await prisma.user.update({
 *   where: { id: userId },
 *   data: { avatar: avatarUrl },
 * });
 * ```
 */


