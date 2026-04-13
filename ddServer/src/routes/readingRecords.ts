import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { authGuard, AuthenticatedRequest } from '../plugins/auth';
import { ensureUser, prisma } from '../lib/prisma';
import { randomUUID } from 'node:crypto';
import type { Prisma } from '@prisma/client';

const createReadingRecordSchema = z.object({
  bookId: z.string().min(1),
  readAt: z.string().datetime().optional(),
  durationSeconds: z.number().int().positive().optional(),
  note: z.string().optional(),
});

function toRecordDto(record: {
  id: string;
  userId: string;
  bookId: string;
  readAt: Date;
  durationSeconds: number | null;
  note: string | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
  book?: {
    id: string;
    title: string;
    coverUrl: string | null;
  } | null;
}) {
  return {
    id: record.id,
    userId: record.userId,
    bookId: record.bookId,
    readAt: record.readAt.toISOString(),
    durationSeconds: record.durationSeconds ?? undefined,
    note: record.note ?? undefined,
    createdAt: record.createdAt.toISOString(),
    updatedAt: record.updatedAt.toISOString(),
    deletedAt: record.deletedAt?.toISOString(),
    book: record.book
      ? {
          id: record.book.id,
          title: record.book.title,
          coverUrl: record.book.coverUrl ?? undefined,
        }
      : undefined,
  };
}

export async function readingRecordRoutes(app: FastifyInstance) {
  app.get('/v1/reading-records', { preHandler: authGuard }, async (request) => {
    const req = request as AuthenticatedRequest;
    const query = request.query as { from?: string; to?: string; date?: string; includeBook?: string };
    await ensureUser(req.user.id);

    const baseWhere = { userId: req.user.id, deletedAt: null };

    let where: unknown = baseWhere;
    if (query.date) {
      const start = new Date(`${query.date}T00:00:00.000Z`);
      const end = new Date(start.getTime() + 24 * 3600 * 1000);
      where = { ...baseWhere, readAt: { gte: start, lt: end } };
    } else {
      const from = query.from ? new Date(query.from) : undefined;
      const to = query.to ? new Date(query.to) : undefined;
      if (from || to) {
        where = { ...baseWhere, readAt: { gte: from, lte: to } };
      }
    }

    const include = query.includeBook === 'true' ? { book: { select: { id: true, title: true, coverUrl: true } } } : undefined;

    const records = await prisma.readingRecord.findMany({
      where: where as never,
      orderBy: { readAt: 'desc' },
      include: include as never,
    });
    return {
      items: records.map(toRecordDto),
    };
  });

  app.post('/v1/reading-records', { preHandler: authGuard }, async (request, reply) => {
    const req = request as AuthenticatedRequest;
    const payload = createReadingRecordSchema.parse(request.body);
    await ensureUser(req.user.id);
    const readAt = payload.readAt ? new Date(payload.readAt) : new Date();

    const book = await prisma.book.findFirst({
      where: { id: payload.bookId, userId: req.user.id, deletedAt: null },
    });
    if (!book) {
      reply.code(404);
      return { message: 'Book not found' };
    }

    const created = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      const record = await tx.readingRecord.create({
        data: {
          id: randomUUID(),
          userId: req.user.id,
          bookId: payload.bookId,
          readAt,
          durationSeconds: payload.durationSeconds,
          note: payload.note,
        },
      });
      await tx.book.update({
        where: { id: payload.bookId },
        data: { readCount: { increment: 1 }, lastReadAt: readAt },
      });
      return record;
    });
    reply.code(201);
    return toRecordDto(created);
  });

  app.delete('/v1/reading-records/:recordId', { preHandler: authGuard }, async (request, reply) => {
    const req = request as AuthenticatedRequest;
    const { recordId } = request.params as { recordId: string };
    await ensureUser(req.user.id);
    const existing = await prisma.readingRecord.findFirst({
      where: { id: recordId, userId: req.user.id, deletedAt: null },
    });
    if (!existing) {
      reply.code(404);
      return { message: 'Record not found' };
    }
    await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      await tx.readingRecord.update({ where: { id: recordId }, data: { deletedAt: new Date() } });
      const agg = await tx.readingRecord.aggregate({
        where: { userId: req.user.id, bookId: existing.bookId, deletedAt: null },
        _count: { _all: true },
        _max: { readAt: true },
      });
      await tx.book.update({
        where: { id: existing.bookId },
        data: { readCount: agg._count._all, lastReadAt: agg._max.readAt ?? null },
      });
    });
    reply.code(204);
    return null;
  });
}
