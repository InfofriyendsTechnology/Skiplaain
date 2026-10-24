import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

/**
 * PUT /api/admin/plans/:id
 * Update a subscription plan
 */
export const updatePlan = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { name, durationMonths, pricePaise, sortOrder, isActive } = req.body;

    const updates: any = {};
    if (name !== undefined) updates.name = name;
    if (durationMonths !== undefined) updates.durationMonths = parseInt(durationMonths);
    if (pricePaise !== undefined) updates.pricePaise = parseInt(pricePaise);
    if (sortOrder !== undefined) updates.sortOrder = parseInt(sortOrder);
    if (isActive !== undefined) updates.isActive = isActive;

    const plan = await prisma.subscriptionPlan.update({
      where: { id: id as string },
      data: updates
    });

    return responseHandler.success(res, plan, 'Plan updated successfully');
  } catch (error) {
    console.error('Update Plan Error:', error);
    return responseHandler.error(res, 'Failed to update plan');
  }
};
