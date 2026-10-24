-- DropIndex
DROP INDEX "commission_ledger_status_created_at_idx";

-- AlterTable
ALTER TABLE "commission_ledger" ADD COLUMN     "earned_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- AlterTable
ALTER TABLE "payments" ADD COLUMN     "currency" TEXT NOT NULL DEFAULT 'INR',
ALTER COLUMN "status" SET DEFAULT 'pending';

-- CreateIndex
CREATE INDEX "commission_ledger_status_earned_at_idx" ON "commission_ledger"("status", "earned_at");

-- CreateIndex
CREATE INDEX "memberships_customer_id_idx" ON "memberships"("customer_id");
