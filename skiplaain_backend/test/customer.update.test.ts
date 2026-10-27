import request from 'supertest';
import app from '../src/app';
import prisma from '../src/utils/prisma';

describe('Customer Update Authorization', () => {
  let adminToken: string;
  let customerAToken: string;
  let customerBToken: string;
  let customerAPhone: string;
  let customerBPhone: string;

  beforeAll(async () => {
    // Login as admin
    await request(app).post('/api/auth/send-otp').send({ phone: '9999999999', purpose: 'login' });
    const adminRes = await request(app)
      .post('/api/auth/verify-otp')
      .send({ phone: '9999999999', otp: '111111', userType: 'admin' });
    adminToken = adminRes.body.data.token;

    // Create customer A
    customerAPhone = '8000000091';
    await prisma.customer.deleteMany({ where: { phone: customerAPhone } });
    await prisma.customer.create({
      data: { phone: customerAPhone, name: 'Customer A' },
    });
    await request(app).post('/api/auth/send-otp').send({ phone: customerAPhone, purpose: 'login' });
    const custARes = await request(app)
      .post('/api/auth/verify-otp')
      .send({ phone: customerAPhone, otp: '111111', userType: 'customer' });
    customerAToken = custARes.body.data.token;

    // Create customer B
    customerBPhone = '8000000092';
    await prisma.customer.deleteMany({ where: { phone: customerBPhone } });
    await prisma.customer.create({
      data: { phone: customerBPhone, name: 'Customer B' },
    });
    await request(app).post('/api/auth/send-otp').send({ phone: customerBPhone, purpose: 'login' });
    const custBRes = await request(app)
      .post('/api/auth/verify-otp')
      .send({ phone: customerBPhone, otp: '111111', userType: 'customer' });
    customerBToken = custBRes.body.data.token;
  });

  afterAll(async () => {
    await prisma.customer.deleteMany({ where: { phone: customerAPhone } });
    await prisma.customer.deleteMany({ where: { phone: customerBPhone } });
  });

  test('Customer A can update their own profile', async () => {
    const res = await request(app)
      .put(`/api/customers/${customerAPhone}`)
      .set('Authorization', `Bearer ${customerAToken}`)
      .send({ name: 'Customer A Updated' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  test('Customer A cannot update Customer B profile', async () => {
    const res = await request(app)
      .put(`/api/customers/${customerBPhone}`)
      .set('Authorization', `Bearer ${customerAToken}`)
      .send({ name: 'Hacked Name' });

    expect(res.status).toBe(403);
    expect(res.body.message).toContain('only update your own');
  });

  test('Admin can update any customer profile', async () => {
    const res = await request(app)
      .put(`/api/customers/${customerBPhone}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: 'Admin Updated B' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});
