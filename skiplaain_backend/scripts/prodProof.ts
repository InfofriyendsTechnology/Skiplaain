import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function proof() {
  console.log('\n=== ROW COUNTS ===');
  const tables = ['partners', 'customers', 'bookings', 'memberships', 'payments', 'commission_ledger', 'partner_payouts', 'subscription_plans', 'platform_settings'];
  for (const t of tables) {
    const count: any = await prisma.$queryRawUnsafe(`SELECT COUNT(*) FROM ${t}`);
    console.log(`${t}: ${count[0].count}`);
  }

  console.log('\n=== INDEXES ===');
  const indexes: any = await prisma.$queryRaw`SELECT tablename, indexname FROM pg_indexes WHERE schemaname='public' AND tablename IN ('memberships', 'payments', 'commission_ledger', 'partner_payouts') ORDER BY tablename, indexname`;
  indexes.forEach((i: any) => console.log(`${i.tablename}.${i.indexname}`));

  console.log('\n=== SUBSCRIPTION_PLANS ===');
  const plans = await prisma.subscriptionPlan.findMany({ orderBy: { sortOrder: 'asc' } });
  plans.forEach(p => console.log(`${p.id}: ${p.name}, ${p.durationMonths}mo, ${p.pricePaise}p`));

  console.log('\n=== PLATFORM_SETTINGS ===');
  const settings = await prisma.platformSettings.findUnique({ where: { id: 'default' } });
  console.log(`commission: ${settings?.commissionPercent}%, cycle: ${settings?.payoutCycleDays}d, min: ${settings?.minPayoutPaise}p`);

  await prisma.$disconnect();
}

proof();
