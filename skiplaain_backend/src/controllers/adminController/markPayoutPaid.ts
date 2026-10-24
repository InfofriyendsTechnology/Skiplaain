import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

/**
 * POST /api/admin/payouts/:id/mark-paid
 */
export const markPayoutPaid = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { paymentReference, notes } = req.body;

    if (!paymentReference) {
      return responseHandler.badRequest(res, 'Payment reference is required');
    }

    const result = await prisma.$transaction(async (tx: any) => {
      const payout = await tx.partnerPayout.findUnique({
        where: { id: id as string }
      });

      if (!payout) throw new Error('Payout not found');

      if (payout.status === 'paid') {
        return { conflict: true, payout };
      }

      const updatedPayout = await tx.partnerPayout.update({
        where: { id: id as string },
        data: {
          status: 'paid',
          paidAt: new Date(),
          paymentReference,
          paidBy: req.user?.id,
          notes
        }
      });

      await tx.commissionLedger.updateMany({
        where: { payoutId: id as string },
        data: { status: 'paid' }
      });

      return { conflict: false, payout: updatedPayout };
    });

    if (result.conflict) {
      return res.status(409).json({
        success: false,
        message: 'Payout already paid',
        data: result.payout
      });
    }

    return responseHandler.success(res, result.payout, 'Payout marked as paid');
  } catch (error) {
    console.error('Mark Payout Paid Error:', error);
    return responseHandler.error(res, 'Failed to mark payout as paid');
  }
};
