import { FastifyRequest, FastifyReply } from 'fastify';
import { JobsService } from './jobs.service';
import { prisma } from '../../lib/prisma';

const jobsService = new JobsService();

export async function triggerReinferJob(
  request: FastifyRequest<{ Params: { id: string } }>,
  reply: FastifyReply
) {
  try {
    const sessionId = request.params.id;

    // Verify user owns session
    const session = await prisma.session.findUnique({
      where: { id: sessionId },
    });

    if (!session) {
      return reply.code(404).send({
        error: { code: 'NOT_FOUND', message: 'Session not found' },
      });
    }

    if (session.userId !== request.userId) {
      return reply.code(403).send({
        error: { code: 'FORBIDDEN', message: 'Access denied' },
      });
    }

    // Trigger job
    const result = await jobsService.triggerReinferJob(sessionId);
    reply.code(201).send(result);
  } catch (error: any) {
    if (error.message.includes('not found') || error.message.includes('must be')) {
      reply.code(400).send({
        error: { code: 'INVALID_REQUEST', message: error.message },
      });
    } else {
      throw error;
    }
  }
}

export async function triggerAdviceJob(
  request: FastifyRequest<{ Params: { id: string } }>,
  reply: FastifyReply
) {
  try {
    const sessionId = request.params.id;

    // Verify user owns session
    const session = await prisma.session.findUnique({
      where: { id: sessionId },
    });

    if (!session) {
      return reply.code(404).send({
        error: { code: 'NOT_FOUND', message: 'Session not found' },
      });
    }

    if (session.userId !== request.userId) {
      return reply.code(403).send({
        error: { code: 'FORBIDDEN', message: 'Access denied' },
      });
    }

    // Trigger job
    const result = await jobsService.triggerAdviceJob(sessionId);
    reply.code(201).send(result);
  } catch (error: any) {
    if (error.message.includes('not found') || error.message.includes('required')) {
      reply.code(400).send({
        error: { code: 'INVALID_REQUEST', message: error.message },
      });
    } else {
      throw error;
    }
  }
}

export async function getJobStatus(
  request: FastifyRequest<{ Params: { id: string } }>,
  reply: FastifyReply
) {
  try {
    const jobId = request.params.id;
    const job = await jobsService.getJobStatus(jobId);

    // Get session to verify ownership
    const session = await prisma.session.findUnique({
      where: { id: job.session_id },
      select: { userId: true },
    });

    if (!session) {
      return reply.code(404).send({
        error: { code: 'NOT_FOUND', message: 'Session not found' },
      });
    }

    if (session.userId !== request.userId) {
      return reply.code(403).send({
        error: { code: 'FORBIDDEN', message: 'Access denied' },
      });
    }

    reply.send(job);
  } catch (error: any) {
    if (error.message === 'Job not found') {
      reply.code(404).send({
        error: { code: 'JOB_NOT_FOUND', message: error.message },
      });
    } else {
      throw error;
    }
  }
}

