import request from 'supertest';
import app from '../src/app';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

describe('PHASE 2: Admin Web Panel API Tests', () => {
  let adminToken: string;
  let testPartnerId: string;
  let testPlanId: string;
  
  beforeAll(async () => {
    // Clean test data
    await prisma.partnerPayout.deleteMany({ where: { partner: { phone: { startsWith: '90000' } } } });
    await prisma.commissionLedger.deleteMany({ where: { membership: { customer: { phone: { startsWith: '90000' } } } } });
    await prisma.membership.deleteMany({ where: { customer: { phone: { startsWith: '90000' } } } });
    await prisma.payment.deleteMany({ where: { customer: { phone: { startsWith: '90000' } } } });
    await prisma.service.deleteMany({ where: { partner: { phone: { startsWith: '90000' } } } });
    await prisma.barber.deleteMany({ where: { partner: { phone: { startsWith: '90000' } } } });
    await prisma.customer.deleteMany({ where: { phone: { startsWith: '90000' } } });
    await prisma.partner.deleteMany({ where: { phone: { startsWith: '90000' } } });
    await prisma.subscriptionPlan.deleteMany({ where: { name: { startsWith: 'TEST_' } } });
    await prisma.otpVerification.deleteMany({ where: { phone: { startsWith: '90000' } } });

    // Get admin token
    const sendOtpRes = await request(app).post('/api/auth/send-otp').send({ phone: '9999999999', userType: 'admin' });
    
    const verifyRes = await request(app).post('/api/auth/verify-otp').send({ phone: '9999999999', otp: '111111', userType: 'admin' });
    
    adminToken = verifyRes.body.data?.token || verifyRes.body.token;
    
    if (!adminToken || verifyRes.status !== 200) {
      console.error('❌ Admin token generation failed:', verifyRes.status, verifyRes.body);
      throw new Error('Failed to generate admin token');
    }

    // Create test partner
    const partner = await prisma.partner.create({
      data: {
        phone: '9000000001',
        salonName: 'TEST_Salon1',
        ownerName: 'TEST_Owner',
        address: 'Test Address',
        plansEnabled: true
      }
    });
    testPartnerId = partner.id;
  });

  afterAll(async () => {
    // Cleanup in FK-safe order
    await prisma.partnerPayout.deleteMany({ where: { partner: { phone: { startsWith: '90000' } } } });
    await prisma.commissionLedger.deleteMany({ where: { membership: { customer: { phone: { startsWith: '90000' } } } } });
    await prisma.membership.deleteMany({ where: { customer: { phone: { startsWith: '90000' } } } });
    await prisma.payment.deleteMany({ where: { customer: { phone: { startsWith: '90000' } } } });
    await prisma.service.deleteMany({ where: { partner: { phone: { startsWith: '90000' } } } });
    await prisma.barber.deleteMany({ where: { partner: { phone: { startsWith: '90000' } } } });
    await prisma.customer.deleteMany({ where: { phone: { startsWith: '90000' } } });
    await prisma.partner.deleteMany({ where: { phone: { startsWith: '90000' } } });
    await prisma.subscriptionPlan.deleteMany({ where: { name: { startsWith: 'TEST_' } } });
    await prisma.otpVerification.deleteMany({ where: { phone: { startsWith: '90000' } } });
  });

  // TEST 1: GET platform settings
  test('1. GET /admin/settings should return platform settings', async () => {
    const res = await request(app)
      .get('/api/admin/settings')
      .set('Authorization', `Bearer ${adminToken}`);
    
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('commissionPercent');
    expect(res.body.data).toHaveProperty('payoutCycleDays');
    expect(res.body.data).toHaveProperty('minPayoutPaise');
  });

  // TEST 2: UPDATE platform settings
  test('2. PUT /admin/settings should update settings', async () => {
    const res = await request(app)
      .put('/api/admin/settings')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        commissionPercent: 12.5,
        payoutCycleDays: 21,
        minPayoutPaise: 100000
      });
    
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.commissionPercent).toBe(12.5);
    expect(res.body.data.payoutCycleDays).toBe(21);
    expect(res.body.data.minPayoutPaise).toBe(100000);

    // Restore original values
    await request(app)
      .put('/api/admin/settings')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        commissionPercent: 10,
        payoutCycleDays: 14,
        minPayoutPaise: 0
      });
  });

  // TEST 3: GET subscription plans
  test('3. GET /admin/plans should return all plans', async () => {
    const res = await request(app)
      .get('/api/admin/plans')
      .set('Authorization', `Bearer ${adminToken}`);
    
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBeGreaterThanOrEqual(3); // At least 3 seeded plans
  });

  // TEST 4: CREATE subscription plan
  test('4. POST /admin/plans should create new plan', async () => {
    const res = await request(app)
      .post('/api/admin/plans')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'TEST_1Month',
        durationMonths: 1,
        pricePaise: 2000,
        sortOrder: 99
      });
    
    expect(res.status).toBe(201); // Created returns 201
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('id');
    expect(res.body.data.name).toBe('TEST_1Month');
    expect(res.body.data.pricePaise).toBe(2000);
    testPlanId = res.body.data.id;
  });

  // TEST 5: UPDATE subscription plan
  test('5. PUT /admin/plans/:id should update plan', async () => {
    const res = await request(app)
      .put(`/api/admin/plans/${testPlanId}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'TEST_1Month_Updated',
        pricePaise: 2500
      });
    
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('TEST_1Month_Updated');
    expect(res.body.data.pricePaise).toBe(2500);
  });

  // TEST 6: DELETE subscription plan (soft delete)
  test('6. DELETE /admin/plans/:id should soft delete plan', async () => {
    const res = await request(app)
      .delete(`/api/admin/plans/${testPlanId}`)
      .set('Authorization', `Bearer ${adminToken}`);
    
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    
    // Verify soft delete (isActive=false) OR hard delete (plan=null)
    const plan = await prisma.subscriptionPlan.findUnique({ where: { id: testPlanId } });
    
    // Test passes if either soft-deleted OR hard-deleted (no memberships)
    if (plan) {
      expect(plan.isActive).toBe(false); // Soft deleted
    } else {
      expect(plan).toBeNull(); // Hard deleted (no memberships existed)
    }
  });

  // TEST 7: UPDATE partner commission
  test('7. PUT /admin/partners/:id/commission should set custom commission', async () => {
    const res = await request(app)
      .put(`/api/admin/partners/${testPartnerId}/commission`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        commissionPercentOverride: 15
      });
    
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.commissionPercentOverride).toBe(15);

    // Test null (use default)
    const res2 = await request(app)
      .put(`/api/admin/partners/${testPartnerId}/commission`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        commissionPercentOverride: null
      });
    
    expect(res2.status).toBe(200);
    expect(res2.body.data.commissionPercentOverride).toBeNull();
  });

  // TEST 8: GET revenue (empty database)
  test('8. GET /admin/revenue should return revenue data', async () => {
    const res = await request(app)
      .get('/api/admin/revenue')
      .set('Authorization', `Bearer ${adminToken}`);
    
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('totalPlanSales');
    expect(res.body.data).toHaveProperty('commissionOwed');
    expect(res.body.data).toHaveProperty('commissionPaid');
    expect(res.body.data).toHaveProperty('platformNet');
    expect(res.body.data).toHaveProperty('bySalon');
    expect(Array.isArray(res.body.data.bySalon)).toBe(true);
  });

  // TEST 9: GET revenue with date range
  test('9. GET /admin/revenue with date range should filter', async () => {
    const from = '2026-01-01';
    const to = '2026-12-31';
    const res = await request(app)
      .get(`/api/admin/revenue?from=${from}&to=${to}`)
      .set('Authorization', `Bearer ${adminToken}`);
    
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('totalPlanSales');
  });

  // TEST 10: GENERATE payouts (no pending commissions)
  test('10. POST /admin/payouts/generate should generate payouts', async () => {
    const res = await request(app)
      .post('/api/admin/payouts/generate')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ force: false });
    
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
    // Response is array of generated payouts, length indicates count
  });

  // TEST 11: GET payouts
  test('11. GET /admin/payouts should return all payouts', async () => {
    const res = await request(app)
      .get('/api/admin/payouts')
      .set('Authorization', `Bearer ${adminToken}`);
    
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  // TEST 12: CREATE payment and test full flow
  test('12. Full flow: payment → commission → payout → mark paid', async () => {
    // Create customer
    const customer = await prisma.customer.create({
      data: {
        phone: '9000000002',
        name: 'TEST_Customer'
      }
    });

    // Get a real plan
    const plan = await prisma.subscriptionPlan.findFirst({ where: { isActive: true } });
    expect(plan).not.toBeNull();

    // Create payment
    const payment = await prisma.payment.create({
      data: {
        customerId: customer.id,
        partnerId: testPartnerId,
        planId: plan!.id,
        amountPaise: plan!.pricePaise,
        status: 'paid',
        razorpayOrderId: `order_TEST_${Date.now()}`,
        razorpayPaymentId: `pay_TEST_${Date.now()}`
      }
    });

    // Create membership
    const membership = await prisma.membership.create({
      data: {
        membershipId: `VIP-TEST-${Date.now()}`,
        customerId: customer.id,
        partnerId: testPartnerId,
        planId: plan!.id,
        paymentId: payment.id,
        salonName: 'TEST_Salon1',
        customerName: 'TEST_Customer',
        customerPhone: '9000000002',
        planName: plan!.name,
        price: plan!.pricePaise,
        pricePaise: plan!.pricePaise,
        durationMonths: plan!.durationMonths,
        commissionPercent: 10,
        commissionPaise: Math.floor(plan!.pricePaise * 0.1),
        status: 'active',
        startsAt: new Date(),
        activatedAt: new Date(),
        expiresAt: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000)
      }
    });

    // Create commission ledger
    const commissionAmount = Math.floor(plan!.pricePaise * 0.1);
    await prisma.commissionLedger.create({
      data: {
        membershipId: membership.id,
        paymentId: payment.id,
        partnerId: testPartnerId,
        grossPaise: plan!.pricePaise,
        commissionPercent: 10,
        commissionPaise: commissionAmount,
        status: 'pending'
      }
    });

    // Generate payout
    const genRes = await request(app)
      .post('/api/admin/payouts/generate')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ force: true });
    
    expect(genRes.status).toBe(200);
    expect(genRes.body.success).toBe(true);
    expect(Array.isArray(genRes.body.data)).toBe(true);
    expect(genRes.body.data.length).toBeGreaterThan(0);

    // Get payouts
    const getRes = await request(app)
      .get('/api/admin/payouts')
      .set('Authorization', `Bearer ${adminToken}`);
    
    expect(getRes.status).toBe(200);
    expect(getRes.body.success).toBe(true);
    const payouts = getRes.body.data;
    const testPayout = payouts.find((p: any) => p.partner.id === testPartnerId);
    expect(testPayout).toBeDefined();
    expect(testPayout.status).toBe('pending');

    // Mark as paid
    const markRes = await request(app)
      .post(`/api/admin/payouts/${testPayout.id}/mark-paid`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        paymentReference: 'UTR123456789',
        notes: 'Test payment'
      });
    
    expect(markRes.status).toBe(200);
    expect(markRes.body.success).toBe(true);
    expect(markRes.body.data.status).toBe('paid');
    expect(markRes.body.data.paymentReference).toBe('UTR123456789');
    expect(markRes.body.data.paidAt).toBeDefined();

    // Verify commission ledger updated
    const ledger = await prisma.commissionLedger.findFirst({
      where: { membershipId: membership.id }
    });
    expect(ledger?.status).toBe('paid');
  });

  // TEST 13: Unauthorized access
  test('13. Admin routes should reject requests without token', async () => {
    const res = await request(app).get('/api/admin/settings');
    expect(res.status).toBe(401);
  });

  // TEST 14: Non-admin phone should be rejected
  test('14. Non-admin phone should not access admin routes', async () => {
    // Send OTP for non-admin phone
    await request(app).post('/api/auth/send-otp').send({ phone: '9000000099', userType: 'admin' });
    const verifyRes = await request(app).post('/api/auth/verify-otp').send({ phone: '9000000099', otp: '111111', userType: 'admin' });
    
    // Should be rejected (403) during verify since phone not in ADMIN_PHONES
    expect(verifyRes.status).toBe(403);
  });
});
