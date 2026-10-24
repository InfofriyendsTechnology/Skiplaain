import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL
    }
  }
});

async function main() {
  console.log('📊 PRODUCTION DATABASE QUERY (Read-Only)\n');

  // Row counts
  const partners = await prisma.partner.count();
  const customers = await prisma.customer.count();
  const bookings = await prisma.booking.count();
  const memberships = await prisma.membership.count();
  const plans = await prisma.subscriptionPlan.count();
  const settings = await prisma.platformSettings.count();
  const payments = await prisma.payment.count();
  const ledger = await prisma.commissionLedger.count();
  const payouts = await prisma.partnerPayout.count();

  console.log('ROW COUNTS:');
  console.log(`  partners: ${partners}`);
  console.log(`  customers: ${customers}`);
  console.log(`  bookings: ${bookings}`);
  console.log(`  memberships: ${memberships}`);
  console.log(`  subscription_plans: ${plans}`);
  console.log(`  platform_settings: ${settings}`);
  console.log(`  payments: ${payments}`);
  console.log(`  commission_ledger: ${ledger}`);
  console.log(`  partner_payouts: ${payouts}\n`);

  // Plans
  const allPlans = await prisma.subscriptionPlan.findMany({ orderBy: { sortOrder: 'asc' } });
  console.log('SUBSCRIPTION PLANS:');
  allPlans.forEach(p => console.log(`  ${p.name}: ${p.durationMonths} months, ${p.pricePaise} paise, sortOrder=${p.sortOrder}, active=${p.isActive}`));

  // Settings
  const platformSettings = await prisma.platformSettings.findUnique({ where: { id: 'default' } });
  console.log('\nPLATFORM SETTINGS:');
  if (platformSettings) {
    console.log(`  commissionPercent: ${platformSettings.commissionPercent}%`);
    console.log(`  payoutCycleDays: ${platformSettings.payoutCycleDays}`);
    console.log(`  minPayoutPaise: ${platformSettings.minPayoutPaise}`);
  }

  // Indexes
  const indexQuery = `
    SELECT tablename, indexname, indexdef 
    FROM pg_indexes 
    WHERE schemaname='public' 
    AND tablename IN ('memberships', 'payments', 'commission_ledger', 'partner_payouts')
    ORDER BY tablename, indexname;
  `;
  const indexes: any = await prisma.$queryRawUnsafe(indexQuery);
  console.log('\nINDEXES:');
  indexes.forEach((idx: any) => console.log(`  ${idx.tablename}.${idx.indexname}`));

  await prisma.$disconnect();
}

main().catch(console.error);
