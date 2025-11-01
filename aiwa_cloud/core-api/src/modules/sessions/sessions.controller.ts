import { FastifyRequest, FastifyReply } from 'fastify';
import { SessionsService } from './sessions.service';
import { z } from 'zod';

const sessionsService = new SessionsService();

// Validation schemas
const createSessionSchema = z.object({
  client_session_id: z.string(),
  template: z.enum(['squat']),
  strictness: z.enum(['strict', 'relaxed']).optional(),
  engine: z.enum(['MoveNet', 'MLKit', 'Auto']).optional(),
  consent: z.enum(['keypoints', 'video+keypoints']),
});

const finalizeSessionSchema = z.object({
  assets: z.array(z.object({
    type: z.string(),
    sha256: z.string(),
    size: z.number(),
    content_type: z.string(),
  })),
});

export async function createSession(
  request: FastifyRequest<{ Body: any }>,
  reply: FastifyReply
) {
  try {
    // Validate input
    const input = createSessionSchema.parse(request.body);
    
    // Get userId from auth middleware
    if (!request.userId) {
      return reply.code(401).send({
        error: { code: 'AUTH_REQUIRED', message: 'Authentication required' },
      });
    }

    // Create session
    const result = await sessionsService.createSession({
      clientSessionId: input.client_session_id,
      userId: request.userId,
      template: input.template,
      strictness: input.strictness,
      engine: input.engine,
      consent: input.consent,
    });

    reply.code(201).send(result);
  } catch (error: any) {
    if (error instanceof z.ZodError) {
      reply.code(400).send({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid input',
          details: error.errors,
        },
      });
    } else {
      throw error;
    }
  }
}

export async function finalizeSession(
  request: FastifyRequest<{ Params: { id: string }; Body: any }>,
  reply: FastifyReply
) {
  try {
    // Validate input
    const input = finalizeSessionSchema.parse(request.body);
    const sessionId = request.params.id;

    // Verify user owns session
    const session = await sessionsService.getSession(sessionId);
    if (session.user_id !== request.userId) {
      return reply.code(403).send({
        error: { code: 'FORBIDDEN', message: 'Access denied' },
      });
    }

    // Finalize session
    await sessionsService.finalizeSession({
      sessionId,
      assets: input.assets.map(a => ({
        type: a.type,
        sha256: a.sha256,
        size: a.size,
        contentType: a.content_type,
      })),
    });

    reply.send({ success: true });
  } catch (error: any) {
    if (error.message === 'Session not found') {
      reply.code(404).send({
        error: { code: 'NOT_FOUND', message: error.message },
      });
    } else if (error instanceof z.ZodError) {
      reply.code(400).send({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid input',
          details: error.errors,
        },
      });
    } else {
      throw error;
    }
  }
}

export async function getSession(
  request: FastifyRequest<{ Params: { id: string } }>,
  reply: FastifyReply
) {
  try {
    const sessionId = request.params.id;
    const session = await sessionsService.getSession(sessionId);

    // Verify user owns session
    if (session.user_id !== request.userId) {
      return reply.code(403).send({
        error: { code: 'FORBIDDEN', message: 'Access denied' },
      });
    }

    reply.send(session);
  } catch (error: any) {
    if (error.message === 'Session not found') {
      reply.code(404).send({
        error: { code: 'NOT_FOUND', message: error.message },
      });
    } else {
      throw error;
    }
  }
}

export async function listUserSessions(
  request: FastifyRequest<{ Querystring: { limit?: string } }>,
  reply: FastifyReply
) {
  try {
    if (!request.userId) {
      return reply.code(401).send({
        error: { code: 'AUTH_REQUIRED', message: 'Authentication required' },
      });
    }

    const limit = request.query.limit ? parseInt(request.query.limit, 10) : 20;
    const sessions = await sessionsService.listUserSessions(request.userId, limit);

    reply.send({ sessions });
  } catch (error) {
    throw error;
  }
}

