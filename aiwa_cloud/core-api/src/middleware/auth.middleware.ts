// =============================================================================
// JWT 认证中间件（预留功能）
// =============================================================================
// 
// 说明：此中间件用于保护需要认证的 API 端点
// 当前状态：未使用（所有端点都是公开的）
// 
// 使用方法：
// 1. 在需要认证的路由中导入此中间件
// 2. 使用 fastify.addHook('preHandler', authMiddleware) 或
//    fastify.register(async (fastify) => {
//      fastify.addHook('preHandler', authMiddleware);
//      // 注册需要认证的路由
//    })
// 
// 示例：
// fastify.get('/protected', {
//   preHandler: authMiddleware
// }, async (request, reply) => {
//   // request.userId 已由中间件设置
//   return { userId: request.userId };
// })
// 
// =============================================================================

import { FastifyRequest, FastifyReply } from 'fastify';

// Extend FastifyRequest to include userId
declare module 'fastify' {
  interface FastifyRequest {
    userId?: string;
  }
}

export async function authMiddleware(
  request: FastifyRequest,
  reply: FastifyReply
) {
  try {
    // Extract Bearer token from Authorization header
    const authHeader = request.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return reply.code(401).send({
        error: {
          code: 'AUTH_INVALID',
          message: 'Missing or invalid authorization header',
        },
      });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    // Verify JWT
    const decoded = await request.server.jwt.verify(token);
    
    // Extract userId from token payload
    // Token structure: { sub: userId, email, type: 'access' }
    const userId = typeof decoded === 'object' && 'sub' in decoded ? decoded.sub as string : null;
    
    if (!userId) {
      return reply.code(401).send({
        error: {
          code: 'AUTH_INVALID',
          message: 'Invalid token payload',
        },
      });
    }

    // Attach userId to request
    request.userId = userId;
  } catch (error: any) {
    if (error.message.includes('expired')) {
      return reply.code(401).send({
        error: {
          code: 'AUTH_EXPIRED',
          message: 'Token has expired',
        },
      });
    }
    
    return reply.code(401).send({
      error: {
        code: 'AUTH_INVALID',
        message: 'Invalid token',
      },
    });
  }
}

