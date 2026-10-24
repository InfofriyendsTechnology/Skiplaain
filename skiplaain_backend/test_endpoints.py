import requests
import json

BASE_URL = "http://localhost:61026/api"

results = []

try:
    # 1. Send OTP
    r = requests.post(f"{BASE_URL}/auth/send-otp", json={"phone": "9999999999"}, timeout=5)
    results.append(f"1. POST /auth/send-otp: {r.status_code}")
    
    # 2. Verify OTP
    r = requests.post(f"{BASE_URL}/auth/verify-otp", json={"phone": "9999999999", "otp": "111111"}, timeout=5)
    token = r.json()["token"]
    results.append(f"2. POST /auth/verify-otp: {r.status_code}")
    
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    
    # 3. GET /admin/settings
    r = requests.get(f"{BASE_URL}/admin/settings", headers=headers, timeout=5)
    results.append(f"3. GET /admin/settings: {r.status_code}")
    
    # 4. PUT /admin/settings
    r = requests.put(f"{BASE_URL}/admin/settings", headers=headers, json={"default_commission_percent": 15.5}, timeout=5)
    results.append(f"4. PUT /admin/settings: {r.status_code}")
    
    # 5. GET /admin/plans
    r = requests.get(f"{BASE_URL}/admin/plans", headers=headers, timeout=5)
    results.append(f"5. GET /admin/plans: {r.status_code}")
    
    # 6. POST /admin/plans
    r = requests.post(f"{BASE_URL}/admin/plans", headers=headers, json={"name": "Test1M", "duration_months": 1, "price": 1000}, timeout=5)
    plan_id = r.json()["id"]
    results.append(f"6. POST /admin/plans: {r.status_code}")
    
    # 7. PUT /admin/plans/:id
    r = requests.put(f"{BASE_URL}/admin/plans/{plan_id}", headers=headers, json={"price": 1500}, timeout=5)
    results.append(f"7. PUT /admin/plans/:id: {r.status_code}")
    
    # 8. DELETE /admin/plans/:id
    r = requests.delete(f"{BASE_URL}/admin/plans/{plan_id}", headers=headers, timeout=5)
    results.append(f"8. DELETE /admin/plans/:id: {r.status_code}")
    
    # 9. PUT /admin/partners/:id/commission (use partner 1 if exists)
    try:
        r = requests.put(f"{BASE_URL}/admin/partners/1/commission", headers=headers, json={"custom_commission_percent": 12.5}, timeout=5)
        results.append(f"9. PUT /admin/partners/:id/commission: {r.status_code}")
    except Exception as e:
        results.append(f"9. PUT /admin/partners/:id/commission: ERROR or 404")
    
    # 10. GET /admin/revenue
    r = requests.get(f"{BASE_URL}/admin/revenue", headers=headers, timeout=5)
    results.append(f"10. GET /admin/revenue: {r.status_code}")
    
    # 11. POST /admin/payouts/generate
    r = requests.post(f"{BASE_URL}/admin/payouts/generate", headers=headers, json={"force": False}, timeout=5)
    results.append(f"11. POST /admin/payouts/generate: {r.status_code}")
    
    # 12. GET /admin/payouts
    r = requests.get(f"{BASE_URL}/admin/payouts", headers=headers, timeout=5)
    results.append(f"12. GET /admin/payouts: {r.status_code}")
    
except Exception as e:
    results.append(f"ERROR: {str(e)}")

# Write results
for line in results:
    print(line)

with open("endpoint_test_results.txt", "w") as f:
    f.write("\n".join(results))
    
print("\n✓ Results saved to endpoint_test_results.txt")
