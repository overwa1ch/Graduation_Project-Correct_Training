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

