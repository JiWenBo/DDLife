const fs = require('node:fs');

const nodeEnv = process.env.NODE_ENV || 'development';

function parseEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return {};
  const raw = fs.readFileSync(filePath, 'utf8');
  const result = {};
  for (const lineRaw of raw.split('\n')) {
    const line = lineRaw.trim();
    if (!line || line.startsWith('#')) continue;
    const idx = line.indexOf('=');
    if (idx <= 0) continue;
    const key = line.slice(0, idx).trim();
    let value = line.slice(idx + 1).trim();
    if (value.startsWith('export ')) value = value.slice('export '.length).trim();
    if (
      (value.startsWith('"') && value.endsWith('"') && value.length >= 2) ||
      (value.startsWith("'") && value.endsWith("'") && value.length >= 2)
    ) {
      value = value.slice(1, -1);
    }
    result[key] = value;
  }
  return result;
}

const baseEnv = parseEnvFile('.env');
const envEnv = parseEnvFile(`.env.${nodeEnv}`);
const merged = { ...baseEnv, ...envEnv, ...process.env };

const dbHost = merged.DB_HOST || '127.0.0.1';
const dbPort = merged.DB_PORT || '3306';
const dbUser = merged.DB_USER || '';
const dbPassword = merged.DB_PASSWORD || '';
const dbName = merged.DB_NAME || (nodeEnv === 'production' ? 'dd-prod' : 'dd-dev');

const dbPasswordEncoded = encodeURIComponent(dbPassword);
process.stdout.write(`mysql://${dbUser}:${dbPasswordEncoded}@${dbHost}:${dbPort}/${dbName}?connection_limit=10`);
