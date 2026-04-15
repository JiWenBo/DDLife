import Fastify from 'fastify';
import cors from '@fastify/cors';
import { healthRoutes } from './routes/health';
import { bookRoutes } from './routes/books';
import { readingRecordRoutes } from './routes/readingRecords';
import { statsRoutes } from './routes/stats';
import { aiRoutes } from './routes/ai';

export async function buildApp() {
  const app = Fastify({ logger: true });
  app.addContentTypeParser(
    ['application/json', 'application/*+json'],
    { parseAs: 'string' },
    (_request, body, done) => {
      const rawBody = typeof body === 'string' ? body : body.toString('utf8');
      if (rawBody.length === 0) {
        done(null, {});
        return;
      }
      try {
        done(null, JSON.parse(rawBody));
      } catch (error) {
        done(error as Error, undefined);
      }
    },
  );
  await app.register(cors, { origin: true });
  await app.register(healthRoutes);
  await app.register(bookRoutes);
  await app.register(readingRecordRoutes);
  await app.register(statsRoutes);
  await app.register(aiRoutes);
  return app;
}
