/*
  Warnings:

  - The `status` column on the `commission_ledger` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The `status` column on the `partner_payouts` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The `status` column on the `payments` table would be dropped and recreated. This will lead to data loss if there is data in the column.

*/
-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('created', 'paid', 'failed');

-- CreateEnum
CREATE TYPE "PayoutStatus" AS ENUM ('pending', 'paid');

-- CreateEnum
CREATE TYPE "CommissionStatus" AS ENUM ('pending', 'included', 'paid');

-- AlterTable
ALTER TABLE "commission_ledger" DROP COLUMN "status",
ADD COLUMN     "status" "CommissionStatus" NOT NULL DEFAULT 'pending';

-- AlterTable
ALTER TABLE "partner_payouts" DROP COLUMN "status",
ADD COLUMN     "status" "PayoutStatus" NOT NULL DEFAULT 'pending';

-- AlterTable
ALTER TABLE "payments" DROP COLUMN "status",
ADD COLUMN     "status" "PaymentStatus" NOT NULL DEFAULT 'created';

-- CreateIndex
CREATE INDEX "commission_ledger_partner_id_status_idx" ON "commission_ledger"("partner_id", "status");

-- CreateIndex
CREATE INDEX "commission_ledger_status_earned_at_idx" ON "commission_ledger"("status", "earned_at");

-- CreateIndex
CREATE INDEX "partner_payouts_partner_id_status_idx" ON "partner_payouts"("partner_id", "status");

-- CreateIndex
CREATE INDEX "payments_status_idx" ON "payments"("status");
