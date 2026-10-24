const axios = require('axios');

const BASE = 'http://localhost:61026/api';
const results = [];

(async () => {
  try {
    let r = await axios.post(`${BASE}/auth/send-otp`, {phone: '9999999999'});
    results.push(`1. POST /auth/send-otp: ${r.status}`);
    
    r = await axios.post(`${BASE}/auth/verify-otp`, {phone: '9999999999', otp: '111111'});
    const token = r.data.token;
    results.push(`2. POST /auth/verify-otp: ${r.status}`);
    
    const h = {headers: {Authorization: `Bearer ${token}`}};
    
    r = await axios.get(`${BASE}/admin/settings`, h);
    results.push(`3. GET /admin/settings: ${r.status}`);
    
    r = await axios.put(`${BASE}/admin/settings`, {default_commission_percent: 15.5}, h);
    results.push(`4. PUT /admin/settings: ${r.status}`);
    
    r = await axios.get(`${BASE}/admin/plans`, h);
    results.push(`5. GET /admin/plans: ${r.status}`);
    
    r = await axios.post(`${BASE}/admin/plans`, {name: 'T1M', duration_months: 1, price: 1000}, h);
    const pid = r.data.id;
    results.push(`6. POST /admin/plans: ${r.status}`);
    
    r = await axios.put(`${BASE}/admin/plans/${pid}`, {price: 1500}, h);
    results.push(`7. PUT /admin/plans/:id: ${r.status}`);
    
    r = await axios.delete(`${BASE}/admin/plans/${pid}`, h);
    results.push(`8. DELETE /admin/plans/:id: ${r.status}`);
    
    try {
      r = await axios.put(`${BASE}/admin/partners/1/commission`, {custom_commission_percent: 12.5}, h);
      results.push(`9. PUT /admin/partners/:id/commission: ${r.status}`);
    } catch(e) {
      results.push(`9. PUT /admin/partners/:id/commission: ${e.response?.status || 'ERROR'}`);
    }
    
    r = await axios.get(`${BASE}/admin/revenue`, h);
    results.push(`10. GET /admin/revenue: ${r.status}`);
    
    r = await axios.post(`${BASE}/admin/payouts/generate`, {force: false}, h);
    results.push(`11. POST /admin/payouts/generate: ${r.status}`);
    
    r = await axios.get(`${BASE}/admin/payouts`, h);
    results.push(`12. GET /admin/payouts: ${r.status}`);
    
  } catch(e) {
    results.push(`ERROR: ${e.message}`);
  }
  
  results.forEach(l => console.log(l));
  require('fs').writeFileSync('endpoint_results.txt', results.join('\n'));
})();
