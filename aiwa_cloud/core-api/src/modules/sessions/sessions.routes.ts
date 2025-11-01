import { FastifyInstance } from 'fastify';
import { authMiddleware } from '../../middleware/auth.middleware';
import { createSession, finalizeSession, getSession, listUserSessions } from './sessions.controller';

export async function sessionsRoutes(fastify: FastifyInstance) {
  // POST /v1/sessions - Create session
  fastify.post('/', {
    preHandler: authMiddleware,
  }, createSession);

  // POST /v1/sessions/:id/finalize - Finalize session
  fastify.post('/:id/finalize', {
    preHandler: authMiddleware,
  }, finalizeSession);

  // GET /v1/sessions/:id - Get session
  fastify.get('/:id', {
    preHandler: authMiddleware,
  }, getSession);

  // GET /v1/sessions - List user sessions
  fastify.get('/', {
    preHandler: authMiddleware,
  }, listUserSessions);
}

