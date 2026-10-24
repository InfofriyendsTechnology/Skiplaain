const http = require('http');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'skiplaain-secret-key-2024';
const customerToken = jwt.sign(
  { phone: '9000000777', type: 'customer', name: 'Test Customer' },
  JWT_SECRET,
  { expiresIn: '30d' }
);

async function makeRequest(method, path, data = null, token = null) {
  return new Promise((resolve, reject) => {
    const body = data ? JSON.stringify(data) : '';
    const options = {
      hostname: 'localhost',
      port: 61026,
      path: '/api' + path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
        ...(token && { 'Authorization': `Bearer ${token}` })
      }
    };

    const req = http.request(options, (res) => {
      let responseBody = '';
      res.on('data', chunk => responseBody += chunk);
      res.on('end', () => {
        try {
          const jsonData = JSON.parse(responseBody);
          resolve({ status: res.statusCode, data: jsonData });
        } catch (e) {
          resolve({ status: res.statusCode, data: responseBody });
        }
      });
    });

    req.on('error', (e) => {
      console.log(`   Request failed: ${e.message}`);
      resolve({ status: 0, data: null });
    });
    
    if (body) {
      req.write(body);
    }
    
    req.end();
  });
}

async function runTests() {
  console.log('=== Phase 3 Backend Endpoint Tests ===\n');

  // First, create a customer via auth flow
  console.log('0. Setup: Creating test customer via auth');
  try {
    // Send OTP
    await makeRequest('POST', '/auth/send-otp', { phone: '9000000777', type: 'customer' });
    // Verify with static OTP
    const authRes = await makeRequest('POST', '/auth/verify-otp', { 
      phone: '9000000777', 
      otp: '111111',
      type: 'customer',
      name: 'Test Customer'
    });
    console.log(`   Customer created/logged in: ${authRes.status === 200 ? 'YES' : 'NO'}`);
  } catch (e) {
    console.log(`   Setup error: ${e.message}`);
  }

  let testSalonId = null;
  let testBookingId = null;

  // Test 1: GET /salons
  console.log('1. GET /salons');
  try {
    const res = await makeRequest('GET', '/salons', null, customerToken);
    console.log(`   Status: ${res.status}`);
    if (res.status === 200 && res.data.data && res.data.data.length > 0) {
      testSalonId = res.data.data[0].id;
      const salon = res.data.data[0];
      const hasSensitive = salon.phone || salon.email || salon.ownerName || salon.totalEarnings || salon.payoutUpiId;
      console.log(`   Has sensitive data: ${hasSensitive ? 'YES (FAIL)' : 'NO (PASS)'}`);
    }
  } catch (e) {
    console.log(`   Error: ${e.message}`);
  }

  // Test 2: GET /salons/:id
  if (testSalonId) {
    console.log(`\n2. GET /salons/${testSalonId}`);
    try {
      const res = await makeRequest('GET', `/salons/${testSalonId}`, null, customerToken);
      console.log(`   Status: ${res.status}`);
      if (res.status === 200 && res.data.data) {
        const salon = res.data.data;
        const hasSensitive = salon.phone || salon.email || salon.ownerName;
        console.log(`   Has sensitive data: ${hasSensitive ? 'YES (FAIL)' : 'NO (PASS)'}`);
      }
    } catch (e) {
      console.log(`   Error: ${e.message}`);
    }
  }

  // Test 3: GET /customers/me
  console.log('\n3. GET /customers/me');
  try {
    const res = await makeRequest('GET', '/customers/me', null, customerToken);
    console.log(`   Status: ${res.status}`);
  } catch (e) {
    console.log(`   Error: ${e.message}`);
  }

  // Test 4: PUT /customers/me
  console.log('\n4. PUT /customers/me');
  try {
    const res = await makeRequest('PUT', '/customers/me', { name: 'Updated Test Customer', email: 'test@example.com' }, customerToken);
    console.log(`   Status: ${res.status}`);
  } catch (e) {
    console.log(`   Error: ${e.message}`);
  }

  // Test 5: GET /subscriptions/my
  console.log('\n5. GET /subscriptions/my');
  try {
    const res = await makeRequest('GET', '/subscriptions/my', null, customerToken);
    console.log(`   Status: ${res.status}`);
  } catch (e) {
    console.log(`   Error: ${e.message}`);
  }

  // Test 6: GET /plans?salonId=
  if (testSalonId) {
    console.log(`\n6. GET /plans?salonId=${testSalonId}`);
    try {
      const res = await makeRequest('GET', `/plans?salonId=${testSalonId}`, null, customerToken);
      console.log(`   Status: ${res.status}`);
    } catch (e) {
      console.log(`   Error: ${e.message}`);
    }
  }

  // Test 7: GET /subscriptions/status?salonId=
  if (testSalonId) {
    console.log(`\n7. GET /subscriptions/status?salonId=${testSalonId}`);
    try {
      const res = await makeRequest('GET', `/subscriptions/status?salonId=${testSalonId}`, null, customerToken);
      console.log(`   Status: ${res.status}`);
    } catch (e) {
      console.log(`   Error: ${e.message}`);
    }
  }

  // Test 8: POST /bookings without plan (should return 402)
  if (testSalonId) {
    console.log('\n8. POST /bookings (without active plan - expect 402)');
    try {
      const res = await makeRequest('POST', '/bookings', {
        partnerId: testSalonId,
        serviceIds: ['test-service-id'],
        slotStartTime: new Date().toISOString(),
        date: new Date().toISOString().split('T')[0],
      }, customerToken);
      console.log(`   Status: ${res.status}`);
      if (res.status === 402) {
        console.log('   Correctly returns 402 for no active plan');
        testBookingId = null;
      } else if (res.status === 201) {
        testBookingId = res.data.data?.id;
      }
    } catch (e) {
      console.log(`   Error: ${e.message}`);
    }
  }

  // Test 9: PATCH /bookings/:id/status (cancel)
  if (testBookingId) {
    console.log(`\n9. PATCH /bookings/${testBookingId}/status (cancel)`);
    try {
      const res = await makeRequest('PATCH', `/bookings/${testBookingId}/status`, { status: 'cancelled' }, customerToken);
      console.log(`   Status: ${res.status}`);
    } catch (e) {
      console.log(`   Error: ${e.message}`);
    }
  } else {
    console.log('\n9. PATCH /bookings/:id/status - SKIP (no booking created)');
  }

  // Test 10: Customer token on /partners (should return 403)
  console.log('\n10. GET /partners (expect 403)');
  try {
    const res = await makeRequest('GET', '/partners', null, customerToken);
    console.log(`   Status: ${res.status}`);
    console.log(`   Correctly blocked: ${res.status === 403 ? 'YES (PASS)' : 'NO (FAIL)'}`);
  } catch (e) {
    console.log(`   Error: ${e.message}`);
  }

  console.log('\n=== Tests Complete ===');
}

runTests().catch(console.error);
