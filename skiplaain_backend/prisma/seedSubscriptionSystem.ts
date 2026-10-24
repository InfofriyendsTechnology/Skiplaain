import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding subscription system...');

  // Seed Platform Settings (single row)
  const settings = await prisma.platformSettings.upsert({
    where: { id: 'default' },
    update: {},
    create: {
      id: 'default',
      commissionPercent: 10,
      payoutCycleDays: 14,
      minPayoutPaise: 0,
    },
  });
  console.log('✅ Platform settings created:', settings);

  // Seed Subscription Plans
  const planData = [
    {
      id: 'plan-3m',
      name: '3 Months VIP',
      durationMonths: 3,
      pricePaise: 3300, // ₹33
      isActive: true,
      sortOrder: 1,
    },
    {
      id: 'plan-6m',
      name: '6 Months VIP',
      durationMonths: 6,
      pricePaise: 6600, // ₹66
      isActive: true,
      sortOrder: 2,
    },
    {
      id: 'plan-12m',
      name: '12 Months VIP',
      durationMonths: 12,
      pricePaise: 9900, // ₹99
      isActive: true,
      sortOrder: 3,
    },
  ];

  for (const plan of planData) {
    const createdPlan = await prisma.subscriptionPlan.upsert({
      where: { id: plan.id },
      update: plan,
      create: plan,
    });
    console.log(`✅ Plan created: ${createdPlan.name} - ₹${createdPlan.pricePaise / 100}`);
  }

  // Migrate existing memberships to have pricePaise
  const existingMemberships = await prisma.membership.findMany({
    where: {
      pricePaise: 0, // Not yet migrated
    },
  });

  for (const membership of existingMemberships) {
    await prisma.membership.update({
      where: { id: membership.id },
      data: {
        pricePaise: membership.price * 100, // Convert Rs to paise
        commissionPercent: settings.commissionPercent,
        commissionPaise: Math.round((membership.price * 100 * settings.commissionPercent) / 100),
        startsAt: membership.activatedAt,
      },
    });
  }

  console.log(`✅ Migrated ${existingMemberships.length} existing memberships`);
  console.log('🎉 Subscription system seeded successfully!');
}

main()
  .catch((e) => {
    console.error('Error seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
