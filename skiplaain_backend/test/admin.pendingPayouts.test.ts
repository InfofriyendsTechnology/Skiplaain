import request from 'supertest';
import app from '../src/app';
import prisma from '../src/utils/prisma';

describe('Admin - Pending Payouts Summary', () => {
  let adminToken: string;

  beforeAll(async () => {
    // Login as admin
    await request(app).post('/api/auth/send-otp').send({ phone: '9999999999', purpose: 'login' });
    const loginRes = await request(app)
      .post('/api/auth/verify-otp')
      .send({ phone: '9999999999', otp: '111111', userType: 'admin' });
    adminToken = loginRes.body.data.token;
  });

  test('GET /api/admin/payouts/pending-summary - should return pending payouts per partner', async () => {
    const res = await request(app)
      .get('/api/admin/payouts/pending-summary')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);

    // Check structure of each summary item
    if (res.body.data.length > 0) {
      const summary = res.body.data[0];
      expect(summary).toHaveProperty('partnerId');
      expect(summary).toHaveProperty('salonName');
      expect(summary).toHaveProperty('pendingPaise');
      expect(summary).toHaveProperty('count');
      expect(summary).toHaveProperty('oldestEarnedAt');
      expect(summary).toHaveProperty('aboveMinPayout');
      expect(summary).toHaveProperty('payoutUpiId');
      expect(summary).toHaveProperty('payoutBankAccountNumber');
    }
  });
});
