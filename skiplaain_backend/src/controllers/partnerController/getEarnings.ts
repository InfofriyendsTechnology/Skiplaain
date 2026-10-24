import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

/**
 * GET /partner/earnings
 */
export const getEarnings = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.user || req.user.type !== 'partner') {
      return responseHandler.forbidden(res, 'Partner access only');
    }

    const partnerId = req.user.id;

    const ledger = await prisma.commissionLedger.findMany({
      where: { partnerId },
      include: {
        membership: {
          include: {
            customer: { select: { name: true } },
            plan: { select: { name: true } }
          }
        }
      },
      orderBy: { earnedAt: 'desc' }
    });

    const payouts = await prisma.partnerPayout.findMany({
      where: { partnerId },
      orderBy: { createdAt: 'desc' }
    });

    const pendingPaise = ledger.filter((l: any) => l.status === 'pending').reduce((sum: number, l: any) => sum + l.commissionPaise, 0);
    const includedNotPaidPaise = ledger.filter((l: any) => l.status === 'included').reduce((sum: number, l: any) => sum + l.commissionPaise, 0);
    const paidTotalPaise = ledger.filter((l: any) => l.status === 'paid').reduce((sum: number, l: any) => sum + l.commissionPaise, 0);
    const lifetimeEarnedPaise = ledger.reduce((sum: number, l: any) => sum + l.commissionPaise, 0);

    // Next payout date
    const settings = await prisma.platformSettings.findUnique({ where: { id: 'default' } });
    const lastPaidPayout = payouts.find((p: any) => p.status === 'paid');
    const nextPayoutDate = lastPaidPayout && settings 
      ? new Date(lastPaidPayout.paidAt!.getTime() + settings.payoutCycleDays * 24 * 60 * 60 * 1000)
      : null;

    const ledgerRows = ledger.map((l: any) => ({
      id: l.id,
      customerName: l.membership.customer.name,
      planName: l.membership.plan?.name || l.membership.planName,
      commissionPaise: l.commissionPaise,
      earnedAt: l.earnedAt,
      status: l.status
    }));

    return responseHandler.success(res, {
      pendingPaise,
      includedNotPaidPaise,
      lifetimeEarnedPaise,
      paidTotalPaise,
      ledgerRows,
      payouts,
      nextPayoutDate
    }, 'Earnings retrieved');
  } catch (error) {
    console.error('Get Earnings Error:', error);
    return responseHandler.error(res, 'Failed to get earnings');
  }
};
