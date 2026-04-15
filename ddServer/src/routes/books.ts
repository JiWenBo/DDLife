import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { authGuard, AuthenticatedRequest } from '../plugins/auth';
import { ensureUser, prisma } from '../lib/prisma';
import { randomUUID } from 'node:crypto';

const createBookSchema = z.object({
  isbn: z.string().default(''),
  title: z.string().min(1),
  author: z.string().nullish(),
  coverUrl: z.string().nullish(),
  category: z.string().nullish(),
  seriesName: z.string().nullish(),
  volumeNumber: z.number().int().nullish(),
  edition: z.string().nullish(),
  audioUrl: z.string().nullish(),
  tags: z.array(z.string()).default([]),
});

const patchBookSchema = createBookSchema.partial();

function toBookDto(book: {
  id: string;
  userId: string;
  isbn: string;
  title: string;
  author: string | null;
  coverUrl: string | null;
  category: string | null;
  seriesName: string | null;
  volumeNumber: number | null;
  edition: string | null;
  audioUrl: string | null;
  tags: unknown;
  readCount: number;
  lastReadAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
}) {
  return {
    id: book.id,
    userId: book.userId,
    isbn: book.isbn,
    title: book.title,
    author: book.author ?? undefined,
    coverUrl: book.coverUrl ?? undefined,
    category: book.category ?? undefined,
    seriesName: book.seriesName ?? undefined,
    volumeNumber: book.volumeNumber ?? undefined,
    edition: book.edition ?? undefined,
    audioUrl: book.audioUrl ?? undefined,
    tags: Array.isArray(book.tags) ? (book.tags as string[]) : [],
    readCount: book.readCount,
    lastReadAt: book.lastReadAt?.toISOString(),
    createdAt: book.createdAt.toISOString(),
    updatedAt: book.updatedAt.toISOString(),
    deletedAt: book.deletedAt?.toISOString(),
  };
}

export async function bookRoutes(app: FastifyInstance) {
  app.get('/v1/books', { preHandler: authGuard }, async (request) => {
    const req = request as AuthenticatedRequest;
    const query = request.query as { q?: string; isbn?: string };
    await ensureUser(req.user.id);

    const q = query.q?.trim();
    const isbn = query.isbn?.trim();
    const baseWhere = { userId: req.user.id, deletedAt: null };
    const where = isbn
      ? { ...baseWhere, isbn }
      : q
        ? { ...baseWhere, OR: [{ title: { contains: q } }, { isbn: { contains: q } }, { seriesName: { contains: q } }] }
        : baseWhere;

    const books = await prisma.book.findMany({
      where: where as never,
      orderBy: { createdAt: 'desc' },
    });
    return {
      items: books.map(toBookDto),
    };
  });

  app.post('/v1/books', { preHandler: authGuard }, async (request, reply) => {
    const req = request as AuthenticatedRequest;
    const payload = createBookSchema.parse(request.body);
    await ensureUser(req.user.id);
    const created = await prisma.book.create({
      data: {
        id: randomUUID(),
        userId: req.user.id,
        isbn: payload.isbn,
        title: payload.title,
        author: payload.author,
        coverUrl: payload.coverUrl,
        category: payload.category,
        seriesName: payload.seriesName,
        volumeNumber: payload.volumeNumber,
        edition: payload.edition,
        audioUrl: payload.audioUrl,
        tags: payload.tags,
      },
    });
    reply.code(201);
    return toBookDto(created);
  });

  app.patch('/v1/books/:bookId', { preHandler: authGuard }, async (request, reply) => {
    const req = request as AuthenticatedRequest;
    const { bookId } = request.params as { bookId: string };
    const payload = patchBookSchema.parse(request.body);
    await ensureUser(req.user.id);
    const existing = await prisma.book.findFirst({
      where: { id: bookId, userId: req.user.id, deletedAt: null },
    });
    if (!existing) {
      reply.code(404);
      return { message: 'Book not found' };
    }
    const updated = await prisma.book.update({
      where: { id: bookId },
      data: {
        isbn: payload.isbn,
        title: payload.title,
        author: payload.author,
        coverUrl: payload.coverUrl,
        category: payload.category,
        seriesName: payload.seriesName,
        volumeNumber: payload.volumeNumber,
        edition: payload.edition,
        audioUrl: payload.audioUrl,
        tags: payload.tags,
      },
    });
    return toBookDto(updated);
  });

  app.delete('/v1/books/:bookId', { preHandler: authGuard }, async (request, reply) => {
    const req = request as AuthenticatedRequest;
    const { bookId } = request.params as { bookId: string };
    await ensureUser(req.user.id);
    const existing = await prisma.book.findFirst({
      where: { id: bookId, userId: req.user.id, deletedAt: null },
    });
    if (!existing) {
      reply.code(404);
      return { message: 'Book not found' };
    }
    await prisma.book.update({ where: { id: bookId }, data: { deletedAt: new Date() } });
    reply.code(204);
    return null;
  });
}
