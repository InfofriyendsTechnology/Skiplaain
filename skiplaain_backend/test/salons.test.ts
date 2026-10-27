import request from 'supertest';
import app from '../src/app';
import prisma from '../src/utils/prisma';

describe('Salon Endpoints', () => {
  let customerToken: string;
  let testPartnerId: string;

  beforeAll(async () => {
    // Create test partner
    const partner = await prisma.partner.create({
      data: {
        phone: '9000000101',
        ownerName: 'TEST_Salon_Owner',
        salonName: 'TEST_Elite_Salon',
        address: 'TEST_Address',
        city: 'Mumbai',
        status: 'approved',
        plansEnabled: true,
      },
    });
    testPartnerId = partner.id;

    // Create test customer and get token
    const otpRes = await request(app)
      .post('/api/auth/send-otp')
      .send({ phone: '9000000102', purpose: 'login' });

    const verifyRes = await request(app)
      .post('/api/auth/verify-otp')
      .send({
        phone: '9000000102',
        otp: '111111',
        userType: 'customer',
        name: 'TEST_Customer',
      });

    customerToken = verifyRes.body.data.token;
  });

  afterAll(async () => {
    // Cleanup
    await prisma.customer.deleteMany({ where: { phone: { startsWith: '900000010' } } });
    await prisma.partner.deleteMany({ where: { phone: { startsWith: '900000010' } } });
  });

  describe('GET /api/salons', () => {
    it('should return approved salons for authenticated customer', async () => {
      const res = await request(app)
        .get('/api/salons')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      
      const salon = res.body.data.find((s: any) => s.id === testPartnerId);
      expect(salon).toBeDefined();
      expect(salon.salonName).toBe('TEST_Elite_Salon');
    });

    it('should filter by search query', async () => {
      const res = await request(app)
        .get('/api/salons?search=Elite')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.some((s: any) => s.salonName.includes('Elite'))).toBe(true);
    });

    it('should require authentication', async () => {
      const res = await request(app).get('/api/salons');
      expect(res.status).toBe(401);
    });
  });

  describe('GET /api/salons/:id', () => {
    it('should return salon details by ID', async () => {
      const res = await request(app)
        .get(`/api/salons/${testPartnerId}`)
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.id).toBe(testPartnerId);
      expect(res.body.data.salonName).toBe('TEST_Elite_Salon');
      expect(res.body.data.plansEnabled).toBe(true);
    });

    it('should return 404 for non-existent salon', async () => {
      const res = await request(app)
        .get('/api/salons/nonexistent-id')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.status).toBe(404);
    });

    it('should require authentication', async () => {
      const res = await request(app).get(`/api/salons/${testPartnerId}`);
      expect(res.status).toBe(401);
    });
  });
});
