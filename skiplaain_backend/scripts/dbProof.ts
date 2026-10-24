import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('\n══════════════════════════════');
  console.log('       DB PROOF REPORT');
  console.log('══════════════════════════════\n');

  // Row counts
  console.log('📊 ROW COUNTS:');
  const counts: Record<string, number> = {
    partners:          await prisma.partner.count(),
    customers:         await prisma.customer.count(),
    barbers:           await prisma.barber.count(),
    services:          await prisma.service.count(),
    bookings:          await prisma.booking.count(),
    bookingServices:   await prisma.bookingService.count(),
    memberships:       await prisma.membership.count(),
    payments:          await prisma.payment.count(),
    commissionLedger:  await prisma.commissionLedger.count(),
    partnerPayouts:    await prisma.partnerPayout.count(),
    subscriptionPlans: await prisma.subscriptionPlan.count(),
    platformSettings:  await prisma.platformSettings.count(),
    otpVerifications:  await prisma.otpVerification.count(),
  };
  Object.entries(counts).forEach(([t, n]) => console.log(`   ${t.padEnd(22)}: ${n}`));

  // Indexes
  console.log('\n📐 INDEXES (memberships, payments, commission_ledger, partner_payouts):');
  const indexes = await prisma.$queryRaw<any[]>`
    SELECT
      t.relname AS table_name,
      i.relname AS index_name,
      ix.indisunique AS is_unique,
      array_agg(a.attname ORDER BY array_position(ix.indkey, a.attnum)) AS columns
    FROM pg_class t
    JOIN pg_index ix ON t.oid = ix.indrelid
    JOIN pg_class i ON i.oid = ix.indexrelid
    JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(ix.indkey)
    WHERE t.relname IN ('memberships', 'payments', 'commission_ledger', 'partner_payouts')
      AND t.relkind = 'r'
    GROUP BY t.relname, i.relname, ix.indisunique
    ORDER BY t.relname, i.relname;
  `;
  indexes.forEach(ix => {
    const unique = ix.is_unique ? ' [UNIQUE]' : '';
    console.log(`   ${ix.table_name}.${ix.index_name}${unique}: (${ix.columns.join(', ')})`);
  });

  // Plans
  console.log('\n📋 SUBSCRIPTION PLANS (ORDER BY sort_order):');
  const plans = await prisma.subscriptionPlan.findMany({ orderBy: { sortOrder: 'asc' } });
  plans.forEach(p => {
    console.log(`   ${p.sortOrder}. ${p.name} | ${p.durationMonths}mo | ₹${p.pricePaise/100} | active=${p.isActive} | id=${p.id}`);
  });

  // Settings
  console.log('\n⚙️  PLATFORM SETTINGS:');
  const settings = await prisma.platformSettings.findUnique({ where: { id: 'default' } });
  if (settings) {
    console.log(`   commission=%${settings.commissionPercent} | payoutCycle=${settings.payoutCycleDays}d | minPayout=₹${settings.minPayoutPaise/100}`);
  }

  console.log('\n══════════════════════════════\n');
}

main()
  .then(() => prisma.$disconnect())
  .catch(e => { console.error(e); prisma.$disconnect(); process.exit(1); });
