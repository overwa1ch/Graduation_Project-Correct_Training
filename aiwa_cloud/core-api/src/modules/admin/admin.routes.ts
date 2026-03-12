import { FastifyInstance } from 'fastify';
import { requireAdminKey } from './admin.middleware';
import { listUsers, updateUserStatus } from './admin.controller';

export async function adminRoutes(fastify: FastifyInstance) {
  fastify.addHook('preHandler', requireAdminKey);

  fastify.get('/users', listUsers);
  fastify.patch('/users/:id/status', updateUserStatus);
}
