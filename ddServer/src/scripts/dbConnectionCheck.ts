import mysql from 'mysql2/promise';
import { env } from '../env';

async function main() {
  const connection = await mysql.createConnection({
    host: env.dbHost,
    port: env.dbPort,
    user: env.dbUser,
    password: env.dbPassword,
    database: env.dbName,
    connectTimeout: 8000,
  });

  const [rows] = await connection.query<mysql.RowDataPacket[]>(
    'SELECT DATABASE() AS currentDatabase, NOW() AS serverTime, VERSION() AS version'
  );
  await connection.end();

  const result = rows[0] ?? {};
  console.log(
    JSON.stringify(
      {
        ok: true,
        nodeEnv: env.nodeEnv,
        host: env.dbHost,
        port: env.dbPort,
        user: env.dbUser,
        dbName: env.dbName,
        currentDatabase: result.currentDatabase,
        serverTime: result.serverTime,
        version: result.version,
      },
      null,
      2
    )
  );
}

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(
    JSON.stringify(
      {
        ok: false,
        nodeEnv: env.nodeEnv,
        host: env.dbHost,
        port: env.dbPort,
        user: env.dbUser,
        dbName: env.dbName,
        error: message,
      },
      null,
      2
    )
  );
  process.exit(1);
});
