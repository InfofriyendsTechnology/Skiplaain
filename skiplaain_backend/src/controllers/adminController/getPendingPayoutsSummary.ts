import { Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';
import { AuthRequest } from '../../middleware/auth';

/**
 * Get pending payouts summary per partner
 * Shows partners with pending commissions ready for payout
 */
export const getPendingPayoutsSummary = async (req: AuthRequest, res: Response) => {
  try {
    // Get platform settings for min payout threshold
    const settings = await prisma.platformSettings.findUnique({
      where: { id: 'default' },
    });

    const minPayoutPaise = settings?.minPayoutPaise || 0;

    // Get all pending commission ledger entries grouped by partner
    const pendingCommissions = await prisma.commissionLedger.groupBy({
      by: ['partnerId'],
      where: {
        status: 'pending',
      },
      _sum: {
        commissionPaise: true,
      },
      _count: {
        id: true,
      },
      _min: {
        earnedAt: true,
      },
    });

    // Fetch partner details for each
    const summaries = await Promise.all(
      pendingCommissions.map(async (commission: any) => {
        const partner = await prisma.partner.findUnique({
          where: { id: commission.partnerId },
          select: {
            id: true,
            salonName: true,
            payoutUpiId: true,
            payoutBankAccountName: true,
            payoutBankAccountNumber: true,
            payoutBankIfsc: true,
          },
        });

        const pendingPaise = commission._sum.commissionPaise || 0;
        const aboveMinPayout = pendingPaise >= minPayoutPaise;

        return {
          partnerId: commission.partnerId,
          salonName: partner?.salonName || 'Unknown Salon',
          pendingPaise,
          count: commission._count.id,
          oldestEarnedAt: commission._min.earnedAt,
          aboveMinPayout,
          payoutUpiId: partner?.payoutUpiId || null,
          payoutBankAccountName: partner?.payoutBankAccountName || null,
          payoutBankAccountNumber: partner?.payoutBankAccountNumber || null,
          payoutBankIfsc: partner?.payoutBankIfsc || null,
        };
      })
    );

    // Sort by pending amount descending
    summaries.sort((a: any, b: any) => b.pendingPaise - a.pendingPaise);

    return responseHandler.success(res, summaries, 'Pending payouts summary retrieved');
  } catch (error: any) {
    console.error('Get pending payouts summary error:', error);
    return responseHandler.error(res, 'Failed to get pending payouts summary', error.message);
  }
};
