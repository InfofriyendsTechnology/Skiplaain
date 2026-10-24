import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

/**
 * GET /api/admin/plans
 * Get all subscription plans
 */
export const getPlans = async (req: AuthRequest, res: Response) => {
  try {
    const plans = await prisma.subscriptionPlan.findMany({
      orderBy: { sortOrder: 'asc' }
    });

    return responseHandler.success(res, plans, 'Plans retrieved successfully');
  } catch (error) {
    console.error('Get Plans Error:', error);
    return responseHandler.error(res, 'Failed to retrieve plans');
  }
};
