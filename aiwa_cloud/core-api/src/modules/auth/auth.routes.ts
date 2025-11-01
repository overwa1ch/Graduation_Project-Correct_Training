import { FastifyInstance } from 'fastify';
import { register, login, refresh } from './auth.controller';

export async function authRoutes(fastify: FastifyInstance) {
  // POST /v1/auth/register
  fastify.post('/register', register);

  // POST /v1/auth/login
  fastify.post('/login', login);

  // POST /v1/auth/refresh
  fastify.post('/refresh', refresh);
}

