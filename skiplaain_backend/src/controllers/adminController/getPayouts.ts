import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

/**
 * GET /api/admin/payouts?status=&partnerId=
 */
export const getPayouts = async (req: AuthRequest, res: Response) => {
  try {
    const { status, partnerId } = req.query;

    const where: any = {};
    if (status) where.status = status as string;
    if (partnerId) where.partnerId = partnerId as string;

    const payouts = await prisma.partnerPayout.findMany({
      where,
      include: {
        partner: {
          select: {
            id: true,
            salonName: true,
            phone: true
          }
        },
        ledgerEntries: true
      },
      orderBy: { createdAt: 'desc' }
    });

    return responseHandler.success(res, payouts, 'Payouts retrieved');
  } catch (error) {
    console.error('Get Payouts Error:', error);
    return responseHandler.error(res, 'Failed to get payouts');
  }
};
