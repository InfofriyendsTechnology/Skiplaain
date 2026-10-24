import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

/**
 * GET /api/admin/revenue?from=&to=
 * Get revenue report (all amounts in paise)
 */
export const getRevenue = async (req: AuthRequest, res: Response) => {
  try {
    const { from, to } = req.query;

    const where: any = {};
    if (from) where.createdAt = { ...where.createdAt, gte: new Date(from as string) };
    if (to) where.createdAt = { ...where.createdAt, lte: new Date(to as string) };

    // Get all captured payments in the date range
    const payments = await prisma.payment.findMany({
      where: {
        status: 'paid',
        ...where
      },
      select: {
        amountPaise: true,
        partnerId: true,
        partner: {
          select: {
            id: true,
            salonName: true
          }
        }
      }
    });

    // Get commission ledger entries
    const ledger = await prisma.commissionLedger.findMany({
      where: {
        ...where
      },
      select: {
        commissionPaise: true,
        status: true,
        partnerId: true
      }
    });

    const totalPlanSales = payments.reduce((sum: number, p: any) => sum + p.amountPaise, 0);
    const commissionPending = ledger.filter((l: any) => l.status === 'pending').reduce((sum: number, l: any) => sum + l.commissionPaise, 0);
    const commissionIncluded = ledger.filter((l: any) => l.status === 'included').reduce((sum: number, l: any) => sum + l.commissionPaise, 0);
    const commissionPaid = ledger.filter((l: any) => l.status === 'paid').reduce((sum: number, l: any) => sum + l.commissionPaise, 0);
    const commissionOwed = commissionPending + commissionIncluded;
    const platformNet = totalPlanSales - commissionPending - commissionIncluded - commissionPaid;

    // By-salon breakdown
    const bySalonMap: any = {};
    payments.forEach((p: any) => {
      if (!bySalonMap[p.partnerId]) {
        bySalonMap[p.partnerId] = {
          partnerId: p.partnerId,
          salonName: p.partner.salonName,
          totalSales: 0,
          commissionOwed: 0,
          commissionPaid: 0
        };
      }
      bySalonMap[p.partnerId].totalSales += p.amountPaise;
    });

    ledger.forEach((l: any) => {
      if (bySalonMap[l.partnerId]) {
        if (l.status === 'pending' || l.status === 'included') {
          bySalonMap[l.partnerId].commissionOwed += l.commissionPaise;
        } else if (l.status === 'paid') {
          bySalonMap[l.partnerId].commissionPaid += l.commissionPaise;
        }
      }
    });

    const bySalon = Object.values(bySalonMap);

    return responseHandler.success(res, {
      totalPlanSales,
      commissionOwed,
      commissionPaid,
      platformNet,
      bySalon
    }, 'Revenue report generated');
  } catch (error) {
    console.error('Get Revenue Error:', error);
    return responseHandler.error(res, 'Failed to get revenue report');
  }
};
