/*
  Warnings:

  - A unique constraint covering the columns `[payment_id]` on the table `memberships` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `commission_paise` to the `memberships` table without a default value. This is not possible if the table is not empty.
  - Added the required column `commission_percent` to the `memberships` table without a default value. This is not possible if the table is not empty.
  - Added the required column `price_paise` to the `memberships` table without a default value. This is not possible if the table is not empty.
  - Added the required column `starts_at` to the `memberships` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "memberships" ADD COLUMN     "commission_paise" INTEGER NOT NULL,
ADD COLUMN     "commission_percent" DOUBLE PRECISION NOT NULL,
ADD COLUMN     "payment_id" TEXT,
ADD COLUMN     "plan_id" TEXT,
ADD COLUMN     "price_paise" INTEGER NOT NULL,
ADD COLUMN     "starts_at" TIMESTAMP(3) NOT NULL;

-- AlterTable
ALTER TABLE "partners" ADD COLUMN     "commission_percent_override" DOUBLE PRECISION,
ADD COLUMN     "payout_bank_account_name" TEXT,
ADD COLUMN     "payout_bank_account_number" TEXT,
ADD COLUMN     "payout_bank_ifsc" TEXT,
ADD COLUMN     "payout_upi_id" TEXT,
ADD COLUMN     "plans_enabled" BOOLEAN NOT NULL DEFAULT true;

-- CreateTable
CREATE TABLE "subscription_plans" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "duration_months" INTEGER NOT NULL,
    "price_paise" INTEGER NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "subscription_plans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payments" (
    "id" TEXT NOT NULL,
    "customer_id" TEXT NOT NULL,
    "partner_id" TEXT NOT NULL,
    "plan_id" TEXT NOT NULL,
    "amount_paise" INTEGER NOT NULL,
    "razorpay_order_id" TEXT NOT NULL,
    "razorpay_payment_id" TEXT,
    "razorpay_signature" TEXT,
    "status" TEXT NOT NULL DEFAULT 'created',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "paid_at" TIMESTAMP(3),

    CONSTRAINT "payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commission_ledger" (
    "id" TEXT NOT NULL,
    "partner_id" TEXT NOT NULL,
    "membership_id" TEXT NOT NULL,
    "payment_id" TEXT NOT NULL,
    "gross_paise" INTEGER NOT NULL,
    "commission_percent" DOUBLE PRECISION NOT NULL,
    "commission_paise" INTEGER NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "payout_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "commission_ledger_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "partner_payouts" (
    "id" TEXT NOT NULL,
    "partner_id" TEXT NOT NULL,
    "period_start" TIMESTAMP(3) NOT NULL,
    "period_end" TIMESTAMP(3) NOT NULL,
    "total_paise" INTEGER NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "paid_at" TIMESTAMP(3),
    "payment_reference" TEXT,
    "paid_by" TEXT,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "partner_payouts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "platform_settings" (
    "id" TEXT NOT NULL DEFAULT 'default',
    "commission_percent" DOUBLE PRECISION NOT NULL DEFAULT 10,
    "payout_cycle_days" INTEGER NOT NULL DEFAULT 14,
    "min_payout_paise" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "platform_settings_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "payments_razorpay_order_id_key" ON "payments"("razorpay_order_id");

-- CreateIndex
CREATE INDEX "payments_customer_id_idx" ON "payments"("customer_id");

-- CreateIndex
CREATE INDEX "payments_partner_id_idx" ON "payments"("partner_id");

-- CreateIndex
CREATE INDEX "payments_status_idx" ON "payments"("status");

-- CreateIndex
CREATE UNIQUE INDEX "commission_ledger_membership_id_key" ON "commission_ledger"("membership_id");

-- CreateIndex
CREATE UNIQUE INDEX "commission_ledger_payment_id_key" ON "commission_ledger"("payment_id");

-- CreateIndex
CREATE INDEX "commission_ledger_partner_id_status_idx" ON "commission_ledger"("partner_id", "status");

-- CreateIndex
CREATE INDEX "commission_ledger_status_created_at_idx" ON "commission_ledger"("status", "created_at");

-- CreateIndex
CREATE INDEX "partner_payouts_partner_id_status_idx" ON "partner_payouts"("partner_id", "status");

-- CreateIndex
CREATE UNIQUE INDEX "memberships_payment_id_key" ON "memberships"("payment_id");

-- CreateIndex
CREATE INDEX "memberships_customer_id_partner_id_status_expires_at_idx" ON "memberships"("customer_id", "partner_id", "status", "expires_at");

-- CreateIndex
CREATE INDEX "memberships_partner_id_status_idx" ON "memberships"("partner_id", "status");

-- AddForeignKey
ALTER TABLE "memberships" ADD CONSTRAINT "memberships_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "subscription_plans"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "memberships" ADD CONSTRAINT "memberships_payment_id_fkey" FOREIGN KEY ("payment_id") REFERENCES "payments"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_partner_id_fkey" FOREIGN KEY ("partner_id") REFERENCES "partners"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "subscription_plans"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commission_ledger" ADD CONSTRAINT "commission_ledger_partner_id_fkey" FOREIGN KEY ("partner_id") REFERENCES "partners"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commission_ledger" ADD CONSTRAINT "commission_ledger_membership_id_fkey" FOREIGN KEY ("membership_id") REFERENCES "memberships"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commission_ledger" ADD CONSTRAINT "commission_ledger_payment_id_fkey" FOREIGN KEY ("payment_id") REFERENCES "payments"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commission_ledger" ADD CONSTRAINT "commission_ledger_payout_id_fkey" FOREIGN KEY ("payout_id") REFERENCES "partner_payouts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "partner_payouts" ADD CONSTRAINT "partner_payouts_partner_id_fkey" FOREIGN KEY ("partner_id") REFERENCES "partners"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
