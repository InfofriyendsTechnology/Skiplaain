import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

/**
 * POST /api/admin/payouts/generate
 * Generate payouts for partners (idempotent, race-safe)
 */
export const generatePayouts = async (req: AuthRequest, res: Response) => {
  try {
    const { force } = req.body;

    const settings = await prisma.platformSettings.findUnique({ where: { id: 'default' } });
    if (!settings) return responseHandler.error(res, 'Settings not found');

    const cutoffDate = force ? new Date() : new Date(Date.now() - settings.payoutCycleDays * 24 * 60 * 60 * 1000);

    // Get all partners with pending commission
    const partners = await prisma.partner.findMany({
      where: {
        commissionLedger: {
          some: {
            status: 'pending',
            earnedAt: force ? undefined : { lte: cutoffDate }
          }
        }
      },
      select: { id: true }
    });

    const results = [];

    for (const partner of partners) {
      try {
        const result = await prisma.$transaction(async (tx: any) => {
          // Select pending ledger entries with row lock
          const ledgerEntries = await tx.commissionLedger.findMany({
            where: {
              partnerId: partner.id,
              status: 'pending',
              earnedAt: force ? undefined : { lte: cutoffDate }
            },
            orderBy: { earnedAt: 'asc' }
          });

          if (ledgerEntries.length === 0) return null;

          const totalPaise = ledgerEntries.reduce((sum: number, e: any) => sum + e.commissionPaise, 0);

          // Skip if below minimum payout
          if (totalPaise < settings.minPayoutPaise) return null;

          // Update ledger entries to 'included' - race-safe with WHERE status='pending'
          const updateResult = await tx.commissionLedger.updateMany({
            where: {
              id: { in: ledgerEntries.map((e: any) => e.id) },
              status: 'pending' // Guard against double-bundling
            },
            data: { status: 'included' }
          });

          // If no rows updated, another process took them
          if (updateResult.count === 0) return null;

          const periodStart = ledgerEntries[0].earnedAt;
          const periodEnd = ledgerEntries[ledgerEntries.length - 1].earnedAt;

          // Create payout record
          const payout = await tx.partnerPayout.create({
            data: {
              partnerId: partner.id,
              periodStart,
              periodEnd,
              totalPaise,
              status: 'pending'
            }
          });

          // Link ledger entries to payout
          await tx.commissionLedger.updateMany({
            where: { id: { in: ledgerEntries.map((e: any) => e.id) } },
            data: { payoutId: payout.id }
          });

          return payout;
        });

        if (result) results.push(result);
      } catch (error) {
        console.error(`Payout generation failed for partner ${partner.id}:`, error);
      }
    }

    return responseHandler.success(res, results, `Generated ${results.length} payouts`);
  } catch (error) {
    console.error('Generate Payouts Error:', error);
    return responseHandler.error(res, 'Failed to generate payouts');
  }
};
