import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

/**
 * POST /api/admin/plans
 * Create a new subscription plan
 */
export const createPlan = async (req: AuthRequest, res: Response) => {
  try {
    const { name, durationMonths, pricePaise, sortOrder } = req.body;

    if (!name || !durationMonths || pricePaise === undefined) {
      return responseHandler.badRequest(res, 'Name, duration and price are required');
    }

    const plan = await prisma.subscriptionPlan.create({
      data: {
        name,
        durationMonths: parseInt(durationMonths),
        pricePaise: parseInt(pricePaise),
        sortOrder: sortOrder !== undefined ? parseInt(sortOrder) : 0,
        isActive: true
      }
    });

    return responseHandler.created(res, plan, 'Plan created successfully');
  } catch (error) {
    console.error('Create Plan Error:', error);
    return responseHandler.error(res, 'Failed to create plan');
  }
};
