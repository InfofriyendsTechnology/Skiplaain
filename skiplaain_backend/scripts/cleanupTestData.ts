import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function cleanupTestData() {
  try {
    console.log('\n🧹 Cleaning up test data...\n');

    // First, find all test partners and customers
    const testPartners = await prisma.partner.findMany({
      where: {
        OR: [
          { phone: { startsWith: '90000000' } },
          { ownerName: { startsWith: 'TEST_' } },
          { salonName: { startsWith: 'TEST_' } }
        ]
      },
      select: { id: true }
    });

    const testCustomers = await prisma.customer.findMany({
      where: {
        OR: [
          { phone: { startsWith: '90000000' } },
          { name: { startsWith: 'TEST_' } }
        ]
      },
      select: { id: true }
    });

    const partnerIds = testPartners.map(p => p.id);
    const customerIds = testCustomers.map(c => c.id);

    console.log(`Found ${partnerIds.length} test partners and ${customerIds.length} test customers\n`);

    // FK-safe deletion order
    const counts = {
      bookingServices: 0,
      bookings: 0,
      commissionLedger: 0,
      partnerPayouts: 0,
      memberships: 0,
      payments: 0,
      services: 0,
      barbers: 0,
      customers: 0,
      partners: 0,
      otps: 0
    };

    // Delete booking_services (via bookings cascade should handle this, but explicit is safer)
    const bookings = await prisma.booking.findMany({
      where: {
        OR: [
          { customerId: { in: customerIds } },
          { customerPhone: { startsWith: '90000000' } }
        ]
      },
      select: { id: true }
    });
    const bookingIds = bookings.map(b => b.id);
    
    counts.bookingServices = (await prisma.bookingService.deleteMany({
      where: { bookingId: { in: bookingIds } }
    })).count;

    // Delete bookings
    counts.bookings = (await prisma.booking.deleteMany({
      where: {
        OR: [
          { customerId: { in: customerIds } },
          { customerPhone: { startsWith: '90000000' } }
        ]
      }
    })).count;

    // Delete commission_ledger (must be before memberships)
    counts.commissionLedger = (await prisma.commissionLedger.deleteMany({
      where: { partnerId: { in: partnerIds } }
    })).count;

    // Delete partner_payouts
    counts.partnerPayouts = (await prisma.partnerPayout.deleteMany({
      where: { partnerId: { in: partnerIds } }
    })).count;

    // Delete memberships
    counts.memberships = (await prisma.membership.deleteMany({
      where: {
        OR: [
          { customerId: { in: customerIds } },
          { customerPhone: { startsWith: '90000000' } }
        ]
      }
    })).count;

    // Delete payments
    counts.payments = (await prisma.payment.deleteMany({
      where: { customerId: { in: customerIds } }
    })).count;

    // Delete services
    counts.services = (await prisma.service.deleteMany({
      where: { partnerId: { in: partnerIds } }
    })).count;

    // Delete barbers
    counts.barbers = (await prisma.barber.deleteMany({
      where: { partnerId: { in: partnerIds } }
    })).count;

    // Delete customers
    counts.customers = (await prisma.customer.deleteMany({
      where: {
        OR: [
          { phone: { startsWith: '90000000' } },
          { name: { startsWith: 'TEST_' } }
        ]
      }
    })).count;

    // Delete partners
    counts.partners = (await prisma.partner.deleteMany({
      where: {
        OR: [
          { phone: { startsWith: '90000000' } },
          { ownerName: { startsWith: 'TEST_' } },
          { salonName: { startsWith: 'TEST_' } }
        ]
      }
    })).count;

    // Delete OTPs
    counts.otps = (await prisma.otpVerification.deleteMany({
      where: { phone: { startsWith: '90000000' } }
    })).count;

    console.log('✅ Rows deleted per table:');
    Object.entries(counts).forEach(([table, count]) => {
      console.log(`   ${table.padEnd(20)}: ${count}`);
    });

    console.log('\n✅ Test data cleanup complete!\n');
  } catch (error) {
    console.error('❌ Cleanup error:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

cleanupTestData();
