import { FastifyInstance } from 'fastify';
import { authMiddleware } from '../../middleware/auth.middleware';
import { getSessionResults } from './results.controller';

export async function resultsRoutes(fastify: FastifyInstance) {
  // GET /v1/sessions/:id/results
  fastify.get('/sessions/:id/results', {
    preHandler: authMiddleware,
  }, getSessionResults);
}

