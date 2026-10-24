import '../src/app'; // Force app initialization
import app from '../src/app';

// Wait for routes to be registered
setTimeout(() => {
  const listEndpoints = require('express-list-endpoints');
  const routes = listEndpoints(app);

  console.log('\n📋 API Routes:\n');
  routes.forEach((route: any) => {
    route.methods.forEach((method: string) => {
      console.log(`${method.padEnd(7)} ${route.path}`);
    });
  });

  console.log(`\n✅ Total routes: ${routes.length}\n`);

  // Check required routes
  const required = [
    { method: 'PUT', path: '/api/admin/settings' },
    { method: 'POST', path: '/api/admin/payouts/:id/mark-paid' },
    { method: 'GET', path: '/api/plans' },
    { method: 'POST', path: '/api/webhooks/razorpay' },
    { method: 'GET', path: '/api/subscriptions/status' },
    { method: 'POST', path: '/api/subscriptions/order' },
    { method: 'POST', path: '/api/subscriptions/verify' },
    { method: 'GET', path: '/api/partner/earnings' },
    { method: 'PUT', path: '/api/partner/payout-details' }
  ];

  console.log('🔍 Required routes check:\n');
  required.forEach(r => {
    const found = routes.some((route: any) => 
      route.methods.includes(r.method) && route.path === r.path
    );
    console.log(`${found ? '✅' : '❌'} ${r.method} ${r.path}`);
  });

  process.exit(0);
}, 100);
