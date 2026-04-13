export type Book = {
  id: string;
  userId: string;
  isbn: string;
  title: string;
  author?: string;
  coverUrl?: string;
  category?: string;
  seriesName?: string;
  volumeNumber?: number;
  edition?: string;
  audioUrl?: string;
  tags: string[];
  readCount: number;
  lastReadAt?: string;
  createdAt: string;
  updatedAt: string;
  deletedAt?: string;
};

export type ReadingRecord = {
  id: string;
  userId: string;
  bookId: string;
  readAt: string;
  durationSeconds?: number;
  note?: string;
  createdAt: string;
  updatedAt: string;
  deletedAt?: string;
};
