import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

/**
 * PUT /api/admin/settings
 * Update platform settings
 */
export const updateSettings = async (req: AuthRequest, res: Response) => {
  try {
    const { commissionPercent, payoutCycleDays, minPayoutPaise } = req.body;

    const updates: any = {};
    if (commissionPercent !== undefined) updates.commissionPercent = parseFloat(commissionPercent);
    if (payoutCycleDays !== undefined) updates.payoutCycleDays = parseInt(payoutCycleDays);
    if (minPayoutPaise !== undefined) updates.minPayoutPaise = parseInt(minPayoutPaise);

    const settings = await prisma.platformSettings.upsert({
      where: { id: 'default' },
      update: updates,
      create: {
        id: 'default',
        commissionPercent: updates.commissionPercent || 10,
        payoutCycleDays: updates.payoutCycleDays || 14,
        minPayoutPaise: updates.minPayoutPaise || 0
      }
    });

    return responseHandler.success(res, settings, 'Settings updated successfully');
  } catch (error) {
    console.error('Update Settings Error:', error);
    return responseHandler.error(res, 'Failed to update settings');
  }
};
