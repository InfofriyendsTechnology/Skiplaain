import request from 'supertest';
import app from '../src/app';
import prisma from '../src/utils/prisma';

describe('Admin - Delete Operations', () => {
  let adminToken: string;
  let testBookingId: string;
  let testCustomerPhone: string;
  let testPartnerId: string;
  let testCustomerId: string;

  beforeAll(async () => {
    // Login as admin
    await request(app).post('/api/auth/send-otp').send({ phone: '9999999999', purpose: 'login' });
    const loginRes = await request(app)
      .post('/api/auth/verify-otp')
      .send({ phone: '9999999999', otp: '111111', userType: 'admin' });
    adminToken = loginRes.body.data.token;

    // Clean up any leftover test data first
    await prisma.partner.deleteMany({ where: { phone: '7777777771' } }).catch(() => {});
    await prisma.customer.deleteMany({ where: { phone: '8888888881' } }).catch(() => {});

    // Create test partner
    const partner = await prisma.partner.create({
      data: {
        phone: '7777777771',
        ownerName: 'Test Delete Owner',
        salonName: 'TEST_Delete_Salon',
        address: 'Test Address',
        city: 'Test City',
        pincode: '123456',
        status: 'approved',
      },
    });
    testPartnerId = partner.id;

    // Create test customer
    testCustomerPhone = '8888888881';
    const customer = await prisma.customer.create({
      data: {
        phone: testCustomerPhone,
        name: 'TEST_Delete_Customer',
      },
    });
    testCustomerId = customer.id;

    // Create test booking
    const booking = await prisma.booking.create({
      data: {
        bookingId: 'TEST-DELETE-001',
        partnerId: testPartnerId,
        customerId: testCustomerId,
        customerName: 'TEST_Delete_Customer',
        customerPhone: testCustomerPhone,
        salonName: 'TEST_Delete_Salon',
        salonPhone: '7777777771',
        salonAddress: 'Test Address',
        totalAmount: 100,
        bookingDate: '2024-12-01',
        timeSlot: '10:00',
        status: 'confirmed',
      },
    });
    testBookingId = booking.id;
  });

  afterAll(async () => {
    // Clean up test data - delete in proper order to avoid FK constraints
    if (testBookingId) {
      await prisma.bookingService.deleteMany({ where: { bookingId: testBookingId } }).catch(() => {});
      await prisma.booking.deleteMany({ where: { id: testBookingId } }).catch(() => {});
    }
    if (testCustomerId) {
      // Delete related memberships and their ledger entries first
      await prisma.commissionLedger.deleteMany({
        where: { membership: { customerId: testCustomerId } }
      }).catch(() => {});
      await prisma.membership.deleteMany({ where: { customerId: testCustomerId } }).catch(() => {});
      await prisma.payment.deleteMany({ where: { customerId: testCustomerId } }).catch(() => {});
      await prisma.customer.deleteMany({ where: { phone: testCustomerPhone } }).catch(() => {});
    }
    if (testPartnerId) {
      // Delete related memberships and ledger entries for this partner
      await prisma.commissionLedger.deleteMany({
        where: { partnerId: testPartnerId }
      }).catch(() => {});
      await prisma.membership.deleteMany({ where: { partnerId: testPartnerId } }).catch(() => {});
      await prisma.payment.deleteMany({ where: { partnerId: testPartnerId } }).catch(() => {});
      await prisma.service.deleteMany({ where: { partnerId: testPartnerId } }).catch(() => {});
      await prisma.barber.deleteMany({ where: { partnerId: testPartnerId } }).catch(() => {});
      await prisma.partner.delete({ where: { id: testPartnerId } }).catch(() => {});
    }
  });

  test('DELETE /api/bookings/:id - should delete booking', async () => {
    const res = await request(app)
      .delete(`/api/bookings/${testBookingId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  test('DELETE /api/customers/:phone - should delete customer with no financial records', async () => {
    // This customer has only a booking (which was already deleted by previous test), no memberships/payments
    const res = await request(app)
      .delete(`/api/customers/${testCustomerPhone}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  test('DELETE /api/customers/:phone - should return 409 for customer with membership', async () => {
    // Create customer with active membership
    const customer2 = await prisma.customer.create({
      data: {
        phone: '8888888882',
        name: 'TEST_Customer_With_Membership',
      },
    });

    // Create active membership
    await prisma.membership.create({
      data: {
        membershipId: 'TEST-MEM-001',
        partnerId: testPartnerId,
        customerId: customer2.id,
        salonName: 'TEST_Delete_Salon',
        customerName: 'TEST_Customer_With_Membership',
        customerPhone: '8888888882',
        planName: 'Test Plan',
        price: 1000,
        pricePaise: 100000,
        durationMonths: 3,
        commissionPercent: 10,
        commissionPaise: 10000,
        status: 'active',
        activatedAt: new Date(),
        expiresAt: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
        startsAt: new Date(),
      },
    });

    const res = await request(app)
      .delete(`/api/customers/${customer2.phone}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(409);
    expect(res.body.message).toContain('Cannot delete customer with existing records');
    expect(res.body.message).toContain('membership');

    // Clean up test data directly (test suite cleanup)
    await prisma.commissionLedger.deleteMany({
      where: { membership: { customerId: customer2.id } }
    });
    await prisma.membership.deleteMany({ where: { customerId: customer2.id } });
    await prisma.customer.delete({ where: { id: customer2.id } });
  });
});
