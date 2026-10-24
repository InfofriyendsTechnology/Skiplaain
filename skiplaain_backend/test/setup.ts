import dotenv from 'dotenv';
import path from 'path';

// Load .env
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const DATABASE_URL = process.env.DATABASE_URL;

if (!DATABASE_URL) {
  throw new Error('❌ FATAL: DATABASE_URL not set in .env');
}

// Extract host and database name for proof
const match = DATABASE_URL.match(/\/\/([^:]+)@([^/]+)\/([^?]+)/);
if (match) {
  const [, , host, dbName] = match;
  console.log(`\n🧪 Using database: ${host}/${dbName}\n`);
}
