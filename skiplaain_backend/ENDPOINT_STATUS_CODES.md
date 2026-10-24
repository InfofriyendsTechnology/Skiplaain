# Admin API Endpoint Status Codes (Phase 2)

Based on implementation in adminController/* and routes:

## Settings
- **GET /api/admin/settings** → 200 (returns platform settings)
- **PUT /api/admin/settings** → 200 (updates commission%, payout cycle, min payout)

## Subscription Plans
- **GET /api/admin/plans** → 200 (returns all plans array)
- **POST /api/admin/plans** → 200 (creates new plan)
- **PUT /api/admin/plans/:id** → 200 (updates plan)
- **DELETE /api/admin/plans/:id** → 200 (soft deletes plan: is_active=false)

## Partners
- **PUT /api/admin/partners/:id/commission** → 200 (sets custom_commission_percent, null=default)
  - 404 if partner not found

## Revenue
- **GET /api/admin/revenue** → 200 (totalSales, commissionOwed, commissionPaid, platformNet, bySalon[])
  - Query params: ?from=YYYY-MM-DD&to=YYYY-MM-DD (optional date range)

## Payouts
- **POST /api/admin/payouts/generate** → 200 (generates payouts for pending commissions)
  - Body: {force: boolean} (force=true bypasses existing payout check)
  - Returns: {generated: number}
- **GET /api/admin/payouts** → 200 (returns PartnerPayout[] with partner data)
- **POST /api/admin/payouts/:id/mark-paid** → 200 (marks payout as paid)
  - Body: {paymentReference: string, notes?: string}
  - Sets status='paid', paidAt=now, paymentReference, notes
  - Updates commission_ledger entries to status='paid'
  - 404 if payout not found
  - 400 if payout already paid

## Auth (used for admin login)
- **POST /api/auth/send-otp** → 200 (sends OTP, test mode always succeeds)
- **POST /api/auth/verify-otp** → 200 (returns JWT token, test OTP: 111111)
  - Body: {phone: string, otp: string}
  - 401 if OTP invalid
  - 403 if phone not in ADMIN_PHONES env (for admin routes)

All admin routes require JWT token in Authorization: Bearer <token> header.
All routes return 401 if token missing/invalid.
