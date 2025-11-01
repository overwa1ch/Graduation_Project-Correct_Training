import { FastifyRequest, FastifyReply } from 'fastify';
import { ResultsService } from './results.service';
import { prisma } from '../../lib/prisma';

const resultsService = new ResultsService();

export async function getSessionResults(
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

    // Get results
    const results = await resultsService.getSessionResults(sessionId);
    reply.send(results);
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

