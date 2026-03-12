import { FastifyRequest, FastifyReply } from 'fastify';
import { prisma } from '../../lib/prisma';
import { z } from 'zod';

const listUsersQuerySchema = z.object({
  search: z.string().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

const updateStatusSchema = z.object({
  status: z.enum(['active', 'inactive', 'suspended']),
});

export async function listUsers(
  request: FastifyRequest<{
    Querystring: { search?: string; page?: number; limit?: number };
  }>,
  reply: FastifyReply
) {
  try {
    const { search, page, limit } = listUsersQuerySchema.parse(request.query);
    const searchTerm = search?.trim();
    const isSqlite = process.env.DATABASE_URL?.startsWith('file:');

    const where = searchTerm
      ? isSqlite
        ? {
            OR: [
              { id: searchTerm },
              { email: { contains: searchTerm } },
              { name: { contains: searchTerm } },
            ],
          }
        : {
            OR: [
              { id: searchTerm },
              { email: { contains: searchTerm, mode: 'insensitive' as const } },
              { name: { contains: searchTerm, mode: 'insensitive' as const } },
            ],
          }
      : {};

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        select: {
          id: true,
          email: true,
          name: true,
          status: true,
          createdAt: true,
          lastLoginAt: true,
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.user.count({ where }),
    ]);

    reply.send({
      data: users,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      reply.code(400).send({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid query parameters',
          details: error.errors,
        },
      });
      return;
    }
    request.log?.error?.(error);
    reply.code(500).send({
      error: {
        code: 'INTERNAL_ERROR',
        message: error instanceof Error ? error.message : 'Unknown error',
        ...(process.env.NODE_ENV === 'development' && error instanceof Error && { stack: error.stack }),
      },
    });
    return;
  }
}

export async function updateUserStatus(
  request: FastifyRequest<{
    Params: { id: string };
    Body: { status?: string };
  }>,
  reply: FastifyReply
) {
  try {
    const { id } = request.params;
    const body = updateStatusSchema.parse(request.body);

    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) {
      reply.code(404).send({
        error: {
          code: 'USER_NOT_FOUND',
          message: 'User not found',
        },
      });
      return;
    }

    const updated = await prisma.user.update({
      where: { id },
      data: { status: body.status },
      select: {
        id: true,
        email: true,
        name: true,
        status: true,
        createdAt: true,
        lastLoginAt: true,
      },
    });

    reply.send({ data: updated });
  } catch (error) {
    if (error instanceof z.ZodError) {
      reply.code(400).send({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid request body',
          details: error.errors,
        },
      });
      return;
    }
    throw error;
  }
}
