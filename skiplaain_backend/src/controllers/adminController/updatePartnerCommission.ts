import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

/**
 * PUT /api/admin/partners/:id/commission
 * Update partner commission override and plans_enabled
 */
export const updatePartnerCommission = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { commissionPercentOverride, plansEnabled } = req.body;

    // Validate commission percentage
    if (commissionPercentOverride !== undefined && commissionPercentOverride !== null) {
      const percent = parseFloat(commissionPercentOverride);
      if (isNaN(percent) || percent < 0 || percent > 100) {
        return responseHandler.badRequest(res, 'Commission percent must be between 0 and 100');
      }
    }

    const updates: any = {};
    if (commissionPercentOverride !== undefined) {
      updates.commissionPercentOverride = commissionPercentOverride === null ? null : parseFloat(commissionPercentOverride);
    }
    if (plansEnabled !== undefined) {
      updates.plansEnabled = Boolean(plansEnabled);
    }

    const partner = await prisma.partner.update({
      where: { id: id as string },
      data: updates
    });

    return responseHandler.success(res, partner, 'Partner commission settings updated');
  } catch (error) {
    console.error('Update Partner Commission Error:', error);
    return responseHandler.error(res, 'Failed to update partner commission');
  }
};
