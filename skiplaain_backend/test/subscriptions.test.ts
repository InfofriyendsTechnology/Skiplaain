import request from 'supertest';
import app from '../src/app';
import prisma from '../src/utils/prisma';

describe('Subscription Endpoints', () => {
  let customerToken: string;
  let testPartnerId: string;
  let testPlanId: string;
  let testMembershipId: string;
  let testCustomerId: string;

  beforeAll(async () => {
    // Create test partner with plan
    const partner = await prisma.partner.create({
      data: {
        phone: '9000000201',
        ownerName: 'TEST_Sub_Owner',
        salonName: 'TEST_Sub_Salon',
        address: 'TEST_Address',
        city: 'Delhi',
        status: 'approved',
        plansEnabled: true,
      },
    });
    testPartnerId = partner.id;

    const plan = await prisma.subscriptionPlan.create({
      data: {
        name: 'TEST_3_Month',
        durationMonths: 3,
        pricePaise: 9900,
        isActive: true,
      },
    });
    testPlanId = plan.id;

    // Create customer and get token
    const verifyRes = await request(app)
      .post('/api/auth/verify-otp')
      .send({
        phone: '9000000202',
        otp: '111111',
        userType: 'customer',
        name: 'TEST_Sub_Customer',
      });

    customerToken = verifyRes.body.data.token;
    const customer = await prisma.customer.findUnique({ where: { phone: '9000000202' } });
    testCustomerId = customer!.id;

    // Create test membership
    const membership = await prisma.membership.create({
      data: {
        membershipId: 'VIP-TEST-001',
        customerId: testCustomerId,
        partnerId: testPartnerId,
        planId: testPlanId,
        salonName: 'TEST_Sub_Salon',
        customerName: 'TEST_Sub_Customer',
        customerPhone: '9000000202',
        planName: 'TEST_3_Month',
        price: 99,
        pricePaise: 9900,
        durationMonths: 3,
        commissionPercent: 10,
        commissionPaise: 990,
        startsAt: new Date(),
        activatedAt: new Date(),
        expiresAt: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
      },
    });
    testMembershipId = membership.id;
  });

  afterAll(async () => {
    await prisma.membership.deleteMany({ where: { customerPhone: { startsWith: '900000020' } } });
    await prisma.customer.deleteMany({ where: { phone: { startsWith: '900000020' } } });
    await prisma.partner.deleteMany({ where: { phone: { startsWith: '900000020' } } });
    await prisma.subscriptionPlan.deleteMany({ where: { name: { startsWith: 'TEST_' } } });
  });

  describe('GET /api/subscriptions/my', () => {
    it('should return customer subscriptions', async () => {
      const res = await request(app)
        .get('/api/subscriptions/my')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      
      const sub = res.body.data.find((s: any) => s.id === testMembershipId);
      expect(sub).toBeDefined();
      expect(sub.salonName).toBe('TEST_Sub_Salon');
      expect(sub.planName).toBe('TEST_3_Month');
    });

    it('should require authentication', async () => {
      const res = await request(app).get('/api/subscriptions/my');
      expect(res.status).toBe(401);
    });
  });

  describe('GET /api/subscriptions/status', () => {
    it('should return subscription status for salon', async () => {
      const res = await request(app)
        .get(`/api/subscriptions/status?salonId=${testPartnerId}`)
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.hasActivePlan).toBe(true);
      expect(res.body.data.plansEnabled).toBe(true);
    });

    it('should return plansEnabled false when salon disables plans', async () => {
      await prisma.partner.update({
        where: { id: testPartnerId },
        data: { plansEnabled: false },
      });

      const res = await request(app)
        .get(`/api/subscriptions/status?salonId=${testPartnerId}`)
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.plansEnabled).toBe(false);

      // Restore
      await prisma.partner.update({
        where: { id: testPartnerId },
        data: { plansEnabled: true },
      });
    });

    it('should require salonId query param', async () => {
      const res = await request(app)
        .get('/api/subscriptions/status')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.status).toBe(400);
    });
  });
});
