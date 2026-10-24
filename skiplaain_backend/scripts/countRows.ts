import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function countRows() {
  const tables = [
    'partner',
    'customer',
    'barber',
    'service',
    'booking',
    'bookingService',
    'membership',
    'payment',
    'commissionLedger',
    'partnerPayout',
    'subscriptionPlan',
    'platformSettings',
    'otpVerification'
  ];

  console.log('\n📊 Row counts:\n');

  for (const table of tables) {
    // @ts-ignore
    const count = await prisma[table].count();
    console.log(`   ${table.padEnd(20)}: ${count}`);
  }

  console.log('');
  await prisma.$disconnect();
}

countRows();
