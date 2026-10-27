import axios from 'axios';

const API_BASE = process.env.VITE_API_URL || 'http://localhost:61026/api';
const ADMIN_PHONE = '9999999999'; // From ADMIN_PHONES env
const DEV_OTP = '111111';

let adminToken = '';
let testPartnerId = '';
let testBarberId = '';
let testBookingId = '';
let testCustomerPhone = '';

const api = axios.create({
  baseURL: API_BASE,
  headers: { 'Content-Type': 'application/json' },
  timeout: 10000,
});

// Helper to log response
function logResponse(method, path, status, data) {
  console.log(`\n${method.padEnd(7)} ${path}`);
  console.log(`Status: ${status}`);
  if (data && typeof data === 'object') {
    if (Array.isArray(data)) {
      console.log(`Response: Array with ${data.length} items`);
      if (data.length > 0) {
        console.log(`First item keys: ${Object.keys(data[0]).join(', ')}`);
      }
    } else {
      console.log(`Response keys: ${Object.keys(data).join(', ')}`);
      // Show nested structure for revenue
      if (data.bySalon) {
        console.log(`  bySalon[0] keys: ${data.bySalon[0] ? Object.keys(data.bySalon[0]).join(', ') : 'empty'}`);
      }
    }
  }
}

async function loginAsAdmin() {
  console.log('=== ADMIN LOGIN ===');
  
  // Send OTP
  const otpRes = await api.post('/auth/send-otp', {
    phone: ADMIN_PHONE,
    purpose: 'login',
  });
  logResponse('POST', '/auth/send-otp', otpRes.status, otpRes.data);

  // Verify OTP
  const verifyRes = await api.post('/auth/verify-otp', {
    phone: ADMIN_PHONE,
    otp: DEV_OTP,
    userType: 'admin',
  });
  logResponse('POST', '/auth/verify-otp', verifyRes.status, verifyRes.data);

  adminToken = verifyRes.data.data.token;
  api.defaults.headers.Authorization = `Bearer ${adminToken}`;
  console.log(`\nAdmin token obtained: ${adminToken.substring(0, 20)}...`);
}

async function testReadEndpoints() {
  console.log('\n\n=== READ ENDPOINTS ===');

  // GET /admin/settings
  const settings = await api.get('/admin/settings');
  logResponse('GET', '/admin/settings', settings.status, settings.data.data);

  // GET /admin/plans
  const plans = await api.get('/admin/plans');
  logResponse('GET', '/admin/plans', plans.status, plans.data.data);

  // GET /admin/revenue
  const revenue = await api.get('/admin/revenue?from=2024-01-01&to=2024-12-31');
  logResponse('GET', '/admin/revenue?from=2024-01-01&to=2024-12-31', revenue.status, revenue.data.data);

  // GET /admin/payouts
  const payouts = await api.get('/admin/payouts');
  logResponse('GET', '/admin/payouts', payouts.status, payouts.data.data);

  // GET /partners
  const partners = await api.get('/partners');
  logResponse('GET', '/partners', partners.status, partners.data.data);

  // GET /customers
  const customers = await api.get('/customers');
  logResponse('GET', '/customers', customers.status, customers.data.data);

  // GET /bookings
  const bookings = await api.get('/bookings');
  logResponse('GET', '/bookings', bookings.status, bookings.data.data);

  // GET /memberships
  const memberships = await api.get('/memberships');
  logResponse('GET', '/memberships', memberships.status, memberships.data.data);
}

async function testWriteEndpoints() {
  console.log('\n\n=== WRITE/DELETE ENDPOINTS (with test data) ===');

  // Create TEST partner using POST /partners
  console.log('\n--- Creating TEST partner ---');
  try {
    const partnerRes = await axios.post(`${API_BASE}/partners`, {
      phone: '7777777772',
      ownerName: 'Test Owner',
      salonName: 'TEST_Contract_Salon',
      category: 'Unisex',
      address: 'Test Address',
      city: 'Test City',
      pincode: '123456',
      email: 'test_contract2@test.com',
      openingTime: '09:00',
      closingTime: '21:00',
      weeklyOff: 'Monday',
    });
    testPartnerId = partnerRes.data.data.id;
    console.log(`Created test partner ID: ${testPartnerId}`);

    // PATCH /partners/:id/status
    const statusRes = await api.patch(`/partners/${testPartnerId}/status`, { status: 'blocked' });
    logResponse('PATCH', `/partners/${testPartnerId}/status`, statusRes.status, statusRes.data.data);

    // Restore to active
    await api.patch(`/partners/${testPartnerId}/status`, { status: 'active' });

    // PUT /admin/partners/:id/commission
    const commissionRes = await api.put(`/admin/partners/${testPartnerId}/commission`, {
      commissionPercentOverride: 15,
    });
    logResponse('PUT', `/admin/partners/${testPartnerId}/commission`, commissionRes.status, commissionRes.data.data);

  } catch (err) {
    console.error(`Partner operations failed: ${err.response?.status || 'ERROR'}: ${err.response?.data?.message || err.message}`);
  }

  // Test barber operations (endpoints may not exist)
  console.log('\n--- Testing barber endpoints ---');
  try {
    if (testPartnerId) {
      const barberRes = await api.post(`/partners/${testPartnerId}/barbers`, {
        name: 'TEST_Barber',
        workingDays: ['Tue', 'Wed', 'Thu'],
      });
      testBarberId = barberRes.data.data.id;
      logResponse('POST', `/partners/${testPartnerId}/barbers`, barberRes.status, barberRes.data.data);
      
      // DELETE single barber
      const delBarberRes = await api.delete(`/partners/${testPartnerId}/barbers/${testBarberId}`);
      logResponse('DELETE', `/partners/${testPartnerId}/barbers/${testBarberId}`, delBarberRes.status, delBarberRes.data);
      
      // Test bulk barber delete
      const delAllBarbersRes = await api.delete(`/partners/${testPartnerId}/barbers`);
      logResponse('DELETE', `/partners/${testPartnerId}/barbers`, delAllBarbersRes.status, delAllBarbersRes.data);
    }
  } catch (err) {
    console.log(`Barber endpoints => ${err.response?.status || 'ERROR'}: ${err.response?.data?.message || err.message}`);
  }

  // Test DELETE /bookings/:id
  console.log('\n--- Testing DELETE /bookings/:id ---');
  try {
    const delBookingRes = await api.delete('/bookings/test-booking-id');
    logResponse('DELETE', '/bookings/:id', delBookingRes.status, delBookingRes.data);
  } catch (err) {
    console.log(`DELETE /bookings/:id => ${err.response?.status || 'ERROR'}: ${err.response?.data?.message || err.message}`);
  }

  // Test DELETE /customers/:phone
  console.log('\n--- Testing DELETE /customers/:phone ---');
  try {
    const delCustomerRes = await api.delete('/customers/7777777772');
    logResponse('DELETE', '/customers/:phone', delCustomerRes.status, delCustomerRes.data);
  } catch (err) {
    console.log(`DELETE /customers/:phone => ${err.response?.status || 'ERROR'}: ${err.response?.data?.message || err.message}`);
  }

  // Cleanup test partner
  if (testPartnerId) {
    console.log('\n--- Cleaning up test partner ---');
    try {
      await api.delete(`/partners/${testPartnerId}`);
      console.log('Test partner deleted');
    } catch (err) {
      console.log(`Failed to delete test partner: ${err.message}`);
    }
  }
}

async function runContractCheck() {
  try {
    await loginAsAdmin();
    await testReadEndpoints();
    await testWriteEndpoints();
    console.log('\n\n=== CONTRACT CHECK COMPLETE ===');
  } catch (err) {
    console.error('\n\n=== ERROR ===');
    console.error(err.response?.data || err.message);
    console.error(err.response?.status);
    process.exit(1);
  }
}

runContractCheck();
