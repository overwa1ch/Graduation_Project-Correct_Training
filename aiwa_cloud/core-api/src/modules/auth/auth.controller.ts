import { FastifyRequest, FastifyReply } from 'fastify';
import { AuthService } from './auth.service';
import { z } from 'zod';
import { CONFIG } from '../../config';

const authService = new AuthService();

// Validation schemas
const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

const refreshSchema = z.object({
  refresh_token: z.string(),
});

export async function register(
  request: FastifyRequest<{ Body: { email: string; password: string } }>,
  reply: FastifyReply
) {
  try {
    // Validate input
    const input = registerSchema.parse(request.body);

    // Register user
    const tokens = await authService.register(input);

    // Sign JWT access token
    const accessToken = request.server.jwt.sign(
      { sub: tokens.userId, email: tokens.email, type: 'access' },
      { expiresIn: CONFIG.jwt.accessExpiresIn }
    );

    reply.code(201).send({
      token: accessToken,
      refresh_token: tokens.refreshToken,
    });
  } catch (error: any) {
    if (error.message === 'User already exists') {
      reply.code(409).send({
        error: {
          code: 'USER_EXISTS',
          message: error.message,
        },
      });
    } else if (error instanceof z.ZodError) {
      reply.code(400).send({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid input',
          details: error.errors,
        },
      });
    } else {
      throw error;
    }
  }
}

export async function login(
  request: FastifyRequest<{ Body: { email: string; password: string } }>,
  reply: FastifyReply
) {
  try {
    // Validate input
    const input = loginSchema.parse(request.body);

    // Login user
    const tokens = await authService.login(input);

    // Sign JWT access token
    const accessToken = request.server.jwt.sign(
      { sub: tokens.userId, email: tokens.email, type: 'access' },
      { expiresIn: CONFIG.jwt.accessExpiresIn }
    );

    reply.send({
      token: accessToken,
      refresh_token: tokens.refreshToken,
    });
  } catch (error: any) {
    if (error.message === 'Invalid credentials' || error.message === 'Account is not active') {
      reply.code(401).send({
        error: {
          code: 'AUTH_INVALID',
          message: error.message,
        },
      });
    } else if (error instanceof z.ZodError) {
      reply.code(400).send({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid input',
          details: error.errors,
        },
      });
    } else {
      throw error;
    }
  }
}

export async function refresh(
  request: FastifyRequest<{ Body: { refresh_token: string } }>,
  reply: FastifyReply
) {
  try {
    // Validate input
    const input = refreshSchema.parse(request.body);

    // Refresh token
    const result = await authService.refresh(input.refresh_token);

    // Sign new access token
    const accessToken = request.server.jwt.sign(
      { sub: result.userId, email: result.email, type: 'access' },
      { expiresIn: CONFIG.jwt.accessExpiresIn }
    );

    reply.send({
      token: accessToken,
    });
  } catch (error: any) {
    if (error.message.includes('Invalid') || error.message.includes('expired')) {
      reply.code(401).send({
        error: {
          code: 'AUTH_EXPIRED',
          message: error.message,
        },
      });
    } else if (error instanceof z.ZodError) {
      reply.code(400).send({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid input',
          details: error.errors,
        },
      });
    } else {
      throw error;
    }
  }
}

