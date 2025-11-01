import { prisma } from '../../lib/prisma';
import { generatePresignedUploadUrl } from '../../lib/aliyun';
import { CONFIG } from '../../config';

export interface CreateSessionInput {
  clientSessionId: string;
  userId: string;
  template: string;
  strictness?: string;
  engine?: string;
  consent: 'keypoints' | 'video+keypoints';
}

export interface FinalizeSessionInput {
  sessionId: string;
  assets: Array<{
    type: string;
    sha256: string;
    size: number;
    contentType: string;
  }>;
}

export class SessionsService {
  // Create session and generate presigned URLs
  async createSession(input: CreateSessionInput) {
    // Create session in database
    const session = await prisma.session.create({
      data: {
        clientSessionId: input.clientSessionId,
        userId: input.userId,
        template: input.template,
        strictness: input.strictness || 'strict',
        engine: input.engine || 'MoveNet',
        status: 'local_only',
      },
    });

    // Generate S3 keys
    const baseKey = `users/${input.userId}/sessions/${session.id}`;
    const keypointsKey = `${baseKey}/keypoints.json`;
    const videoKey = `${baseKey}/video.mp4`;

    // Generate presigned URLs
    const keypointsUrl = await generatePresignedUploadUrl(
      keypointsKey,
      'application/json'
    );

    let videoUrl: string | null = null;
    if (input.consent === 'video+keypoints') {
      videoUrl = await generatePresignedUploadUrl(videoKey, 'video/mp4');
    }

    return {
      session_id: session.id,
      upload_policies: {
        keypoints_url: keypointsUrl,
        video_url: videoUrl,
      },
    };
  }

  // Finalize session - bind uploaded assets
  async finalizeSession(input: FinalizeSessionInput) {
    // Get session
    const session = await prisma.session.findUnique({
      where: { id: input.sessionId },
    });

    if (!session) {
      throw new Error('Session not found');
    }

    // Create asset records
    const baseUri = `oss://${CONFIG.aliyun.oss.bucket}/users/${session.userId}/sessions/${session.id}`;
    
    for (const asset of input.assets) {
      const filename = asset.type === 'keypoints' ? 'keypoints.json' :
                      asset.type === 'video' ? 'video.mp4' :
                      asset.type === 'result_local' ? 'result.json' : asset.type;
      
      await prisma.asset.create({
        data: {
          sessionId: input.sessionId,
          type: asset.type,
          uri: `${baseUri}/${filename}`,
          sha256: asset.sha256,
          size: BigInt(asset.size),
          contentType: asset.contentType,
        },
      });
    }

    // Update session status
    await prisma.session.update({
      where: { id: input.sessionId },
      data: { status: 'uploaded' },
    });

    return { success: true };
  }

  // Get session details
  async getSession(sessionId: string) {
    const session = await prisma.session.findUnique({
      where: { id: sessionId },
      include: {
        assets: true,
        jobs: true,
      },
    });

    if (!session) {
      throw new Error('Session not found');
    }

    return {
      session_id: session.id,
      client_session_id: session.clientSessionId,
      user_id: session.userId, // For ownership verification
      status: session.status,
      template: session.template,
      engine: session.engine,
      strictness: session.strictness,
      created_at: session.createdAt.toISOString(),
    };
  }

  // List user sessions
  async listUserSessions(userId: string, limit: number = 20) {
    const sessions = await prisma.session.findMany({
      where: {
        userId,
        deletedAt: null,
      },
      orderBy: {
        createdAt: 'desc',
      },
      take: limit,
    });

    return sessions.map(s => ({
      session_id: s.id,
      client_session_id: s.clientSessionId,
      status: s.status,
      template: s.template,
      created_at: s.createdAt.toISOString(),
    }));
  }

  // Delete session (soft delete)
  async deleteSession(sessionId: string) {
    await prisma.session.update({
      where: { id: sessionId },
      data: { deletedAt: new Date() },
    });

    return { success: true };
  }
}

