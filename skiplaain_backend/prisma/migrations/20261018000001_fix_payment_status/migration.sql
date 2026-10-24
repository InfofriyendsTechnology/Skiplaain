-- Fix Payment.status enum: pending/captured/failed -> created/paid/failed
ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_status_check;
UPDATE payments SET status = 'paid' WHERE status = 'captured';
UPDATE payments SET status = 'created' WHERE status = 'pending';
ALTER TABLE payments ADD CONSTRAINT payments_status_check CHECK (status IN ('created', 'paid', 'failed'));

-- Fix PartnerPayout.status enum: keep pending/paid (already correct in schema)
ALTER TABLE partner_payouts DROP CONSTRAINT IF EXISTS partner_payouts_status_check;
ALTER TABLE partner_payouts ADD CONSTRAINT partner_payouts_status_check CHECK (status IN ('pending', 'paid'));
