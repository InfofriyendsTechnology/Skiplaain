import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

describe('Smoke Test', () => {
  test('confirms test database connection', async () => {
    const dbUrl = process.env.DATABASE_URL || '';
    const match = dbUrl.match(/\/\/[^:]+@([^/]+)\/([^?]+)/);
    if (match) {
      const [, host, dbName] = match;
      console.log(`Test DB: ${host}/${dbName}`);
    }
    
    const result = await prisma.$queryRaw`SELECT current_database()`;
    expect(result).toBeDefined();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });
});
