import request from 'supertest';
import app from '../src/app';
import prisma from '../src/utils/prisma';

describe('Admin - Barber Operations', () => {
  let adminToken: string;
  let testPartnerId: string;
  let testBarberId: string;

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
        phone: '7777777770',
        ownerName: 'Test Barber Owner',
        salonName: 'TEST_Barber_Salon',
        address: 'Test Address',
        city: 'Test City',
        pincode: '123456',
        email: 'test_barber@test.com',
        status: 'approved',
      },
    });
    testPartnerId = partner.id;
  });

  afterAll(async () => {
    // Clean up test data
    if (testPartnerId) {
      await prisma.barber.deleteMany({ where: { partnerId: testPartnerId } });
      await prisma.partner.delete({ where: { id: testPartnerId } });
    }
  });

  test('POST /api/partners/:id/barbers - should add barber', async () => {
    const res = await request(app)
      .post(`/api/partners/${testPartnerId}/barbers`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'TEST_Barber_1',
        phone: '8888888880',
        specialty: 'Haircut',
        isAvailable: true,
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('TEST_Barber_1');
    testBarberId = res.body.data.id;
  });

  test('DELETE /api/partners/:id/barbers/:barberId - should delete barber', async () => {
    const res = await request(app)
      .delete(`/api/partners/${testPartnerId}/barbers/${testBarberId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  test('DELETE /api/partners/:id/barbers - should clear all barbers', async () => {
    // Add two test barbers
    await request(app)
      .post(`/api/partners/${testPartnerId}/barbers`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: 'TEST_Barber_2' });
    await request(app)
      .post(`/api/partners/${testPartnerId}/barbers`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: 'TEST_Barber_3' });

    const res = await request(app)
      .delete(`/api/partners/${testPartnerId}/barbers`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.count).toBe(2);
  });
});
