import Fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import { CONFIG } from './config';
import { authRoutes } from './modules/auth/auth.routes';

const fastify = Fastify({
  logger: {
    level: CONFIG.nodeEnv === 'production' ? 'info' : 'debug',
  },
});

async function start() {
  try {
    // Register CORS
    await fastify.register(cors, {
      origin: CONFIG.cors.origin,
    });

    // Register JWT
    await fastify.register(jwt, {
      secret: CONFIG.jwt.accessSecret,
    });

    // Health check
    fastify.get('/health', async () => {
      return { 
        status: 'ok', 
        timestamp: new Date().toISOString(),
        service: 'aiwa-auth-api',
        version: '3.0.0'
      };
    });

    // Register routes (仅认证模块)
    await fastify.register(authRoutes, { prefix: '/v1/auth' });
    
    // 未来扩展：可在此添加其他路由模块
    // 例如：会话管理、文件上传、用户信息管理等

    // Error handler
    fastify.setErrorHandler((error, request, reply) => {
      fastify.log.error(error);
      
      const statusCode = error.statusCode || 500;
      const errorResponse = {
        error: {
          code: error.code || 'INTERNAL_ERROR',
          message: error.message || 'An unexpected error occurred',
          details: CONFIG.nodeEnv === 'development' ? error.stack : undefined,
        },
        request_id: request.id,
      };
      
      reply.status(statusCode).send(errorResponse);
    });

    // Start server
    // 使用 localhost 而不是 0.0.0.0 以避免 Windows 权限问题
    await fastify.listen({ port: CONFIG.port, host: 'localhost' });
    fastify.log.info(`🚀 AIWA Auth API listening on port ${CONFIG.port}`);
    fastify.log.info(`📝 Environment: ${CONFIG.nodeEnv}`);
    fastify.log.info(`🌐 Access at: http://localhost:${CONFIG.port}`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
}

start();

