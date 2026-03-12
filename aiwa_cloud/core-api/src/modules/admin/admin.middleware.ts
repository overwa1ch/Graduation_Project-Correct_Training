import { FastifyRequest, FastifyReply } from 'fastify';
import { CONFIG } from '../../config';

/**
 * 校验 Admin API 请求：X-Admin-Key 或 Authorization: Bearer <ADMIN_API_KEY>
 */
export async function requireAdminKey(
  request: FastifyRequest,
  reply: FastifyReply
): Promise<void> {
  if (!CONFIG.adminApiKey || CONFIG.adminApiKey.length < 16) {
    reply.code(503).send({
      error: {
        code: 'ADMIN_API_DISABLED',
        message: 'Admin API is not configured',
      },
    });
    return;
  }

  const adminKey =
    request.headers['x-admin-key'] ||
    (request.headers.authorization?.startsWith('Bearer ')
      ? request.headers.authorization.slice(7)
      : null);

  if (!adminKey || adminKey !== CONFIG.adminApiKey) {
    reply.code(401).send({
      error: {
        code: 'ADMIN_UNAUTHORIZED',
        message: 'Invalid or missing admin API key',
      },
    });
    return;
  }
}
