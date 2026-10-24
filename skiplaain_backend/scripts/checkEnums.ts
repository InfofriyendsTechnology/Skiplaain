import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const result = await prisma.$queryRaw<any[]>`
    SELECT typname FROM pg_type WHERE typtype = 'e' ORDER BY typname;
  `;
  console.log('Enums in database:', result);
  
  // Try to query a payment
  const payments = await prisma.payment.findMany({ take: 1 });
  console.log('Sample payment:', payments[0]);
}

main()
  .then(() => prisma.$disconnect())
  .catch((e) => {
    console.error(e);
    prisma.$disconnect();
    process.exit(1);
  });
