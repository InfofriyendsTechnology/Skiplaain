import request from 'supertest';
import app from '../src/app';
import prisma from '../src/utils/prisma';
import jwt from 'jsonwebtoken';

describe('Customer Endpoints', () => {
  let customerToken: string;
  let adminToken: string;
  let testCustomerId: string;
  let testSalonId: string;

  beforeAll(async () => {
    // Create test customer
    const customer = await prisma.customer.create({
      data: {
        phone: '9000000099',
        name: 'Test Customer',
        email: 'customer@test.com',
      },
    });
    testCustomerId = customer.id;

    // Create test salon (approved)
    const salon = await prisma.partner.create({
      data: {
        phone: '9876543299',
        ownerName: 'Test Owner',
        salonName: 'Test Salon',
        address: '123 Test St',
        city: 'Mumbai',
        status: 'approved',
        plansEnabled: true,
      },
    });
    testSalonId = salon.id;

    // Add services to salon
    await prisma.service.createMany({
      data: [
        {
          partnerId: testSalonId,
          name: 'Haircut',
          price: 200,
          duration: 30,
          category: 'haircut',
          isActive: true,
        },
        {
          partnerId: testSalonId,
          name: 'Shave',
          price: 100,
          duration: 20,
          category: 'shave',
          isActive: true,
        },
      ],
    });

    // Add barbers
    await prisma.barber.createMany({
      data: [
        {
          partnerId: testSalonId,
          name: 'Barber One',
          specialty: 'Hair Styling',
          isAvailable: true,
        },
      ],
    });

    // Generate tokens
    customerToken = jwt.sign(
      { phone: '9000000099', type: 'customer', name: 'Test Customer' },
      process.env.JWT_SECRET || 'test-secret',
      { expiresIn: '30d' }
    );

    adminToken = jwt.sign(
      { phone: '9999999999', type: 'admin', name: 'Admin' },
      process.env.JWT_SECRET || 'test-secret',
      { expiresIn: '30d' }
    );
  });

  afterAll(async () => {
    // Cleanup
    await prisma.barber.deleteMany({ where: { partnerId: testSalonId } });
    await prisma.service.deleteMany({ where: { partnerId: testSalonId } });
    await prisma.partner.delete({ where: { id: testSalonId } });
    await prisma.customer.delete({ where: { id: testCustomerId } });
    await prisma.$disconnect();
  });

  describe('GET /api/salons', () => {
    it('should return approved salons for customer', async () => {
      const res = await request(app)
        .get('/api/salons')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThan(0);

      const salon = res.body.data[0];
      expect(salon).toHaveProperty('id');
      expect(salon).toHaveProperty('salonName');
      expect(salon).toHaveProperty('address');
      expect(salon).toHaveProperty('city');
      expect(salon).toHaveProperty('services');
      expect(salon).toHaveProperty('barbers');

      // Ensure no sensitive data
      expect(salon).not.toHaveProperty('phone');
      expect(salon).not.toHaveProperty('email');
      expect(salon).not.toHaveProperty('ownerName');
      expect(salon).not.toHaveProperty('totalEarnings');
      expect(salon).not.toHaveProperty('payoutUpiId');
    });

    it('should filter salons by city', async () => {
      const res = await request(app)
        .get('/api/salons?city=Mumbai')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('should search salons by name', async () => {
      const res = await request(app)
        .get('/api/salons?search=Test')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('should return 403 for non-customer', async () => {
      const res = await request(app)
        .get('/api/salons')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(403);
    });
  });

  describe('GET /api/salons/:id', () => {
    it('should return salon details for approved salon', async () => {
      const res = await request(app)
        .get(`/api/salons/${testSalonId}`)
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('id', testSalonId);
      expect(res.body.data).toHaveProperty('salonName', 'Test Salon');
      expect(res.body.data.services.length).toBeGreaterThan(0);
      expect(res.body.data.barbers.length).toBeGreaterThan(0);

      // Ensure no sensitive data
      expect(res.body.data).not.toHaveProperty('phone');
      expect(res.body.data).not.toHaveProperty('email');
    });

    it('should return 404 for non-existent salon', async () => {
      const res = await request(app)
        .get('/api/salons/non-existent-id')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.status).toBe(404);
    });
  });

  describe('GET /api/customers/me', () => {
    it('should return customer profile', async () => {
      const res = await request(app)
        .get('/api/customers/me')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('phone', '9000000099');
      expect(res.body.data).toHaveProperty('name', 'Test Customer');
      expect(res.body.data).toHaveProperty('email', 'customer@test.com');
    });

    it('should return 401 without token', async () => {
      const res = await request(app).get('/api/customers/me');

      expect(res.status).toBe(401);
    });
  });

  describe('PUT /api/customers/me', () => {
    it('should update customer profile', async () => {
      const res = await request(app)
        .put('/api/customers/me')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({
          name: 'Updated Name',
          email: 'updated@test.com',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('name', 'Updated Name');
      expect(res.body.data).toHaveProperty('email', 'updated@test.com');
    });
  });

  describe('GET /api/subscriptions/my', () => {
    it('should return customer subscriptions', async () => {
      const res = await request(app)
        .get('/api/subscriptions/my')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
    });
  });

  describe('Customer cannot access admin endpoints', () => {
    it('should return 403 for GET /api/partners', async () => {
      const res = await request(app)
        .get('/api/partners')
        .set('Authorization', `Bearer ${customerToken}`);

      expect(res.status).toBe(403);
    });
  });
});
