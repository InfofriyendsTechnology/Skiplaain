import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

/**
 * GET /api/subscriptions/plans
 * Get all available subscription plans
 */
export const getPlans = async (req: Request, res: Response) => {
  try {
    const plans = await prisma.subscriptionPlan.findMany({
      where: { isActive: true },
      orderBy: { durationMonths: 'asc' }
    });

    return responseHandler.success(res, plans, 'Plans retrieved successfully');
  } catch (error) {
    console.error('Get Plans Error:', error);
    return responseHandler.error(res, 'Failed to retrieve plans');
  }
};
