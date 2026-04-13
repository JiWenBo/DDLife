import dotenv from 'dotenv';

const nodeEnv = process.env.NODE_ENV ?? 'development';
const envFilePath = `.env.${nodeEnv}`;
dotenv.config({ override: true });
dotenv.config({ path: envFilePath, override: true });

const dbHost = process.env.DB_HOST ?? '127.0.0.1';
const dbPort = Number(process.env.DB_PORT ?? 3306);
const dbUser = process.env.DB_USER ?? '';
const dbPassword = process.env.DB_PASSWORD ?? '';
const dbName = process.env.DB_NAME ?? (nodeEnv === 'production' ? 'dd-prod' : 'dd-dev');

const dbPasswordEncoded = encodeURIComponent(dbPassword);
const databaseUrl =
  process.env.DATABASE_URL ??
  `mysql://${dbUser}:${dbPasswordEncoded}@${dbHost}:${dbPort}/${dbName}?connection_limit=10`;

process.env.DATABASE_URL = databaseUrl;

export const env = {
  nodeEnv,
  port: Number(process.env.PORT ?? 3000),
  openAiApiKey: process.env.OPENAI_API_KEY ?? '',
  dbHost,
  dbPort,
  dbUser,
  dbPassword,
  dbName,
  databaseUrl,
};
