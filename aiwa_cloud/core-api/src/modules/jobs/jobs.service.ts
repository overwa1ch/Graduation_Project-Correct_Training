import { prisma } from '../../lib/prisma';
import { sendMNSMessage } from '../../lib/aliyun';
import { CONFIG } from '../../config';

export class JobsService {
  // Trigger REINFER job
  async triggerReinferJob(sessionId: string) {
    // 1. Verify session exists and status = "uploaded"
    const session = await prisma.session.findUnique({
      where: { id: sessionId },
      include: { assets: true },
    });

    if (!session) {
      throw new Error('Session not found');
    }

    if (session.status !== 'uploaded') {
      throw new Error(`Session must be in 'uploaded' status, current: ${session.status}`);
    }

    // 2. Get session assets
    const keypointsAsset = session.assets.find(a => a.type === 'keypoints');
    if (!keypointsAsset) {
      throw new Error('Keypoints asset not found');
    }

    const videoAsset = session.assets.find(a => a.type === 'video');
    const resultLocalAsset = session.assets.find(a => a.type === 'result_local');

    // 3. Create job record
    const job = await prisma.job.create({
      data: {
        sessionId,
        type: 'REINFER',
        status: 'queued',
      },
    });

    // 4. Build SQS message
    const message = {
      job_id: job.id,
      session_id: sessionId,
      type: 'REINFER',
      assets: {
        keypoints: keypointsAsset.uri,
        video: videoAsset?.uri || null,
        result_local: resultLocalAsset?.uri || null,
      },
      attempt: 1,
    };

    // 5. Send to MNS
    await sendMNSMessage(CONFIG.aliyun.mns.reinferQueueName, message);

    // 6. Update session status to "processing"
    await prisma.session.update({
      where: { id: sessionId },
      data: { status: 'processing' },
    });

    // 7. Return job_id
    return { job_id: job.id };
  }

  // Trigger ADVICE job
  async triggerAdviceJob(sessionId: string) {
    // 1. Verify session exists
    const session = await prisma.session.findUnique({
      where: { id: sessionId },
      include: { assets: true },
    });

    if (!session) {
      throw new Error('Session not found');
    }

    // 2. Require result_cloud or result_local asset
    const resultCloudAsset = session.assets.find(a => a.type === 'result_cloud');
    const resultLocalAsset = session.assets.find(a => a.type === 'result_local');

    if (!resultCloudAsset && !resultLocalAsset) {
      throw new Error('No result asset found (result_cloud or result_local required)');
    }

    // 3. Create job record
    const job = await prisma.job.create({
      data: {
        sessionId,
        type: 'ADVICE',
        status: 'queued',
      },
    });

    // 4. Build SQS message
    const message = {
      job_id: job.id,
      session_id: sessionId,
      type: 'ADVICE',
      assets: {
        result_cloud: resultCloudAsset?.uri || null,
        result_local: resultLocalAsset?.uri || null,
      },
      attempt: 1,
    };

    // 5. Send to MNS
    await sendMNSMessage(CONFIG.aliyun.mns.adviceQueueName, message);

    // 6. Return job_id
    return { job_id: job.id };
  }

  // Get job status
  async getJobStatus(jobId: string) {
    const job = await prisma.job.findUnique({
      where: { id: jobId },
      include: {
        session: {
          include: {
            assets: true,
          },
        },
      },
    });

    if (!job) {
      throw new Error('Job not found');
    }

    // Find result asset if job succeeded
    let resultAsset = null;
    if (job.status === 'succeeded') {
      const assetType = job.type === 'REINFER' ? 'result_cloud' : 'advice';
      const asset = job.session.assets.find(a => a.type === assetType);
      if (asset) {
        resultAsset = {
          type: asset.type,
          uri: asset.uri,
        };
      }
    }

    return {
      job_id: job.id,
      session_id: job.sessionId,
      type: job.type,
      status: job.status,
      error_code: job.errorCode,
      result_asset: resultAsset,
      created_at: job.createdAt.toISOString(),
      finished_at: job.finishedAt?.toISOString() || null,
    };
  }

  // Update job status (called by worker)
  async updateJobStatus(jobId: string, status: string, errorCode?: string) {
    const job = await prisma.job.findUnique({
      where: { id: jobId },
    });

    if (!job) {
      throw new Error('Job not found');
    }

    // Update job
    await prisma.job.update({
      where: { id: jobId },
      data: {
        status,
        errorCode,
        finishedAt: status === 'succeeded' || status === 'failed' ? new Date() : undefined,
      },
    });

    // Update session status based on job result
    if (status === 'succeeded') {
      // Check if all jobs for this session are succeeded
      const allJobs = await prisma.job.findMany({
        where: { sessionId: job.sessionId },
      });

      const allSucceeded = allJobs.every(j => j.status === 'succeeded');
      if (allSucceeded) {
        await prisma.session.update({
          where: { id: job.sessionId },
          data: { status: 'ready' },
        });
      }
    } else if (status === 'failed') {
      await prisma.session.update({
        where: { id: job.sessionId },
        data: { status: 'failed' },
      });
    }

    return { success: true };
  }
}

