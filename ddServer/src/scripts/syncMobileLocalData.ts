import fs from 'node:fs';
import path from 'node:path';
import { ensureUser, prisma } from '../lib/prisma';

type MobileBook = {
  id?: unknown;
  isbn?: unknown;
  title?: unknown;
  author?: unknown;
  coverUrl?: unknown;
  category?: unknown;
  seriesName?: unknown;
  volumeNumber?: unknown;
  edition?: unknown;
  audioPath?: unknown;
  audioUrl?: unknown;
  tags?: unknown;
  readCount?: unknown;
  lastReadAt?: unknown;
  createdAt?: unknown;
};

type MobileRecord = {
  id?: unknown;
  bookId?: unknown;
  readAt?: unknown;
  durationSeconds?: unknown;
  note?: unknown;
};

function getArg(name: string, fallback: string): string {
  const prefix = `--${name}=`;
  const hit = process.argv.find((arg) => arg.startsWith(prefix));
  if (!hit) return fallback;
  return hit.slice(prefix.length);
}

function toDate(value: unknown, fallback: Date): Date {
  if (typeof value !== 'string' || !value.trim()) return fallback;
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? fallback : d;
}

function toStringOrUndefined(value: unknown): string | undefined {
  if (typeof value !== 'string') return undefined;
  const v = value.trim();
  return v ? v : undefined;
}

function toIntOrUndefined(value: unknown): number | undefined {
  if (typeof value === 'number' && Number.isFinite(value)) return Math.trunc(value);
  if (typeof value === 'string' && value.trim()) {
    const n = Number(value);
    if (Number.isFinite(n)) return Math.trunc(n);
  }
  return undefined;
}

async function main() {
  const userId = getArg('user-id', 'mobile-sync-user');
  const booksPath = path.resolve(getArg('books', 'tmp/mobile_export/books.json'));
  const recordsPath = path.resolve(getArg('records', 'tmp/mobile_export/reading_records.json'));

  const booksRaw = JSON.parse(fs.readFileSync(booksPath, 'utf8')) as MobileBook[];
  const recordsRaw = JSON.parse(fs.readFileSync(recordsPath, 'utf8')) as MobileRecord[];

  if (!Array.isArray(booksRaw) || !Array.isArray(recordsRaw)) {
    throw new Error('books.json 或 reading_records.json 不是数组格式');
  }

  await ensureUser(userId);

  const validBookIds = new Set<string>();
  let upsertedBooks = 0;
  let skippedBooks = 0;

  for (const row of booksRaw) {
    const id = toStringOrUndefined(row.id);
    const title = toStringOrUndefined(row.title);
    if (!id || !title) {
      skippedBooks += 1;
      continue;
    }
    validBookIds.add(id);
    const createdAt = toDate(row.createdAt, new Date());
    const lastReadAt = typeof row.lastReadAt === 'string' ? toDate(row.lastReadAt, createdAt) : null;
    const tags = Array.isArray(row.tags) ? row.tags.filter((x): x is string => typeof x === 'string') : [];
    const readCount = toIntOrUndefined(row.readCount) ?? 0;
    const volumeNumber = toIntOrUndefined(row.volumeNumber);

    await prisma.book.upsert({
      where: { id },
      update: {
        userId,
        isbn: toStringOrUndefined(row.isbn) ?? '',
        title,
        author: toStringOrUndefined(row.author),
        coverUrl: toStringOrUndefined(row.coverUrl),
        category: toStringOrUndefined(row.category),
        seriesName: toStringOrUndefined(row.seriesName),
        volumeNumber,
        edition: toStringOrUndefined(row.edition),
        audioUrl: toStringOrUndefined(row.audioUrl) ?? toStringOrUndefined(row.audioPath),
        tags,
        readCount,
        lastReadAt,
        createdAt,
        deletedAt: null,
      },
      create: {
        id,
        userId,
        isbn: toStringOrUndefined(row.isbn) ?? '',
        title,
        author: toStringOrUndefined(row.author),
        coverUrl: toStringOrUndefined(row.coverUrl),
        category: toStringOrUndefined(row.category),
        seriesName: toStringOrUndefined(row.seriesName),
        volumeNumber,
        edition: toStringOrUndefined(row.edition),
        audioUrl: toStringOrUndefined(row.audioUrl) ?? toStringOrUndefined(row.audioPath),
        tags,
        readCount,
        lastReadAt,
        createdAt,
      },
    });
    upsertedBooks += 1;
  }

  let upsertedRecords = 0;
  let skippedRecords = 0;

  for (const row of recordsRaw) {
    const id = toStringOrUndefined(row.id);
    const bookId = toStringOrUndefined(row.bookId);
    if (!id || !bookId || !validBookIds.has(bookId)) {
      skippedRecords += 1;
      continue;
    }
    const readAt = toDate(row.readAt, new Date());
    await prisma.readingRecord.upsert({
      where: { id },
      update: {
        userId,
        bookId,
        readAt,
        durationSeconds: toIntOrUndefined(row.durationSeconds),
        note: toStringOrUndefined(row.note),
        deletedAt: null,
      },
      create: {
        id,
        userId,
        bookId,
        readAt,
        durationSeconds: toIntOrUndefined(row.durationSeconds),
        note: toStringOrUndefined(row.note),
      },
    });
    upsertedRecords += 1;
  }

  console.log(
    JSON.stringify(
      {
        ok: true,
        userId,
        booksPath,
        recordsPath,
        sourceBooks: booksRaw.length,
        sourceRecords: recordsRaw.length,
        upsertedBooks,
        skippedBooks,
        upsertedRecords,
        skippedRecords,
      },
      null,
      2
    )
  );
}

main()
  .catch((error: unknown) => {
    const message = error instanceof Error ? error.message : String(error);
    console.error(JSON.stringify({ ok: false, error: message }, null, 2));
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
