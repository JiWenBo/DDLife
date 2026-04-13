import Fastify from 'fastify';
import cors from '@fastify/cors';
import { healthRoutes } from './routes/health';
import { bookRoutes } from './routes/books';
import { readingRecordRoutes } from './routes/readingRecords';
import { statsRoutes } from './routes/stats';
import { aiRoutes } from './routes/ai';

export async function buildApp() {
  const app = Fastify({ logger: true });
  await app.register(cors, { origin: true });
  await app.register(healthRoutes);
  await app.register(bookRoutes);
  await app.register(readingRecordRoutes);
  await app.register(statsRoutes);
  await app.register(aiRoutes);
  return app;
}
