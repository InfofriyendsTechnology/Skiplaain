import request from 'supertest';
import app from '../src/app';
import prisma from '../src/utils/prisma';

describe('Admin - Partner Status Validation', () => {
  let adminToken: string;
  let testPartnerId: string;

  beforeAll(async () => {
    // Login as admin
    await request(app).post('/api/auth/send-otp').send({ phone: '9999999999', purpose: 'login' });
    const loginRes = await request(app)
      .post('/api/auth/verify-otp')
      .send({ phone: '9999999999', otp: '111111', userType: 'admin' });
    adminToken = loginRes.body.data.token;

    // Create test partner
    const partner = await prisma.partner.create({
      data: {
        phone: '7777777772',
        ownerName: 'Test Status Owner',
        salonName: 'TEST_Status_Salon',
        address: 'Test Address',
        city: 'Test City',
        pincode: '123456',
        status: 'pending',
      },
    });
    testPartnerId = partner.id;
  });

  afterAll(async () => {
    if (testPartnerId) {
      await prisma.partner.delete({ where: { id: testPartnerId } });
    }
  });

  test('PATCH /partners/:id/status - should accept valid statuses', async () => {
    const validStatuses = ['pending', 'approved', 'blocked'];

    for (const status of validStatuses) {
      const res = await request(app)
        .patch(`/api/partners/${testPartnerId}/status`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ status });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe(status);
    }
  });

  test('PATCH /partners/:id/status - should reject invalid status with clear message', async () => {
    const res = await request(app)
      .patch(`/api/partners/${testPartnerId}/status`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ status: 'active' });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('Invalid status value');
    expect(res.body.message).toContain('pending');
    expect(res.body.message).toContain('approved');
    expect(res.body.message).toContain('blocked');
  });
});
