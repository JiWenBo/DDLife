import { FastifyInstance } from 'fastify';
import { authGuard, AuthenticatedRequest } from '../plugins/auth';
import { ensureUser, prisma } from '../lib/prisma';

export async function statsRoutes(app: FastifyInstance) {
  app.get('/v1/stats/summary', { preHandler: authGuard }, async (request) => {
    const req = request as AuthenticatedRequest;
    await ensureUser(req.user.id);

    const total = await prisma.readingRecord.count({
      where: { userId: req.user.id, deletedAt: null },
    });

    const now = new Date();
    const monthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1, 0, 0, 0, 0));
    const monthEnd = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1, 0, 0, 0, 0));
    const thisMonth = await prisma.readingRecord.count({
      where: { userId: req.user.id, deletedAt: null, readAt: { gte: monthStart, lt: monthEnd } },
    });

    const rows = (await prisma.$queryRaw`
      SELECT DISTINCT DATE(read_at) AS d
      FROM reading_records
      WHERE user_id = ${req.user.id} AND deleted_at IS NULL
      ORDER BY d DESC
      LIMIT 400
    `) as Array<{ d: unknown }>;

    const days = rows
      .map((r: { d: unknown }) =>
        r.d instanceof Date ? r.d.toISOString().slice(0, 10) : String(r.d).slice(0, 10)
      )
      .filter((d: string) => /^\d{4}-\d{2}-\d{2}$/.test(d));

    const daySet = new Set(days);
    let streak = 0;
    let cursor = new Date();
    for (;;) {
      const key = cursor.toISOString().slice(0, 10);
      if (!daySet.has(key)) break;
      streak += 1;
      cursor = new Date(cursor.getTime() - 24 * 3600 * 1000);
    }

    return { total, thisMonth, streak, checkinDays: days };
  });
}
