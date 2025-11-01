import Fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import { CONFIG } from './config';
import { authRoutes } from './modules/auth/auth.routes';
// 注释掉不需要的路由模块（未来可扩展）
// import { sessionsRoutes } from './modules/sessions/sessions.routes';
// import { jobsRoutes } from './modules/jobs/jobs.routes';
// import { resultsRoutes } from './modules/results/results.routes';

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
        version: '1.0.0'
      };
    });

    // Register routes (仅认证模块)
    await fastify.register(authRoutes, { prefix: '/v1/auth' });
    
    // 未来扩展：会话管理、作业管理、结果查询
    // await fastify.register(sessionsRoutes, { prefix: '/v1/sessions' });
    // await fastify.register(jobsRoutes, { prefix: '/v1' });
    // await fastify.register(resultsRoutes, { prefix: '/v1' });

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
    await fastify.listen({ port: CONFIG.port, host: '0.0.0.0' });
    fastify.log.info(`🚀 AIWA Auth API listening on port ${CONFIG.port}`);
    fastify.log.info(`📝 Environment: ${CONFIG.nodeEnv}`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
}

start();

