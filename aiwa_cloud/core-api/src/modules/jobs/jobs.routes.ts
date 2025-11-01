import { FastifyInstance } from 'fastify';
import { authMiddleware } from '../../middleware/auth.middleware';
import { triggerReinferJob, triggerAdviceJob, getJobStatus } from './jobs.controller';

export async function jobsRoutes(fastify: FastifyInstance) {
  // POST /v1/sessions/:id/jobs/reinfer
  fastify.post('/sessions/:id/jobs/reinfer', {
    preHandler: authMiddleware,
  }, triggerReinferJob);

  // POST /v1/sessions/:id/jobs/advice
  fastify.post('/sessions/:id/jobs/advice', {
    preHandler: authMiddleware,
  }, triggerAdviceJob);

  // GET /v1/jobs/:id
  fastify.get('/:id', {
    preHandler: authMiddleware,
  }, getJobStatus);
}

