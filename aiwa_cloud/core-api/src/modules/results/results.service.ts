import { prisma } from '../../lib/prisma';
import { generatePresignedDownloadUrl, extractKeyFromOssUri } from '../../lib/aliyun';

export class ResultsService {
  async getSessionResults(sessionId: string) {
    // Get all assets for session
    const session = await prisma.session.findUnique({
      where: { id: sessionId },
      include: { assets: true },
    });

    if (!session) {
      throw new Error('Session not found');
    }

    // Find result assets
    const resultLocal = session.assets.find(a => a.type === 'result_local');
    const resultCloud = session.assets.find(a => a.type === 'result_cloud');
    const advice = session.assets.find(a => a.type === 'advice');

    // Generate presigned download URLs for existing assets
    const results = {
      local: resultLocal ? {
        type: 'result_local',
        uri: resultLocal.uri,
        download_url: await this.getDownloadUrl(resultLocal.uri),
      } : null,
      cloud: resultCloud ? {
        type: 'result_cloud',
        uri: resultCloud.uri,
        download_url: await this.getDownloadUrl(resultCloud.uri),
      } : null,
      advice: advice ? {
        type: 'advice',
        uri: advice.uri,
        download_url: await this.getDownloadUrl(advice.uri),
      } : null,
    };

    return results;
  }

  private async getDownloadUrl(ossUri: string): Promise<string> {
    // Extract key from OSS URI: oss://bucket/key or https://bucket.oss-region.aliyuncs.com/key
    const key = extractKeyFromOssUri(ossUri);
    return generatePresignedDownloadUrl(key);
  }
}

