import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

/**
 * GET /api/plans?salonId=xxx
 * Get subscription plans for a specific salon (authenticated)
 * Returns empty array if salon has plans_enabled=false
 */
export const getPlansForSalon = async (req: AuthRequest, res: Response) => {
  try {
    const { salonId, partnerId } = req.query;
    const id = (salonId || partnerId) as string;

    if (!req.user) {
      return responseHandler.unauthorized(res, 'Authentication required');
    }

    if (!id) {
      return responseHandler.badRequest(res, 'Salon ID is required');
    }

    // Check if partner exists and has plans enabled
    const partner = await prisma.partner.findUnique({
      where: { id },
      select: { plansEnabled: true }
    });

    if (!partner) {
      return responseHandler.notFound(res, 'Salon not found');
    }

    // If plans not enabled, return empty array
    if (!partner.plansEnabled) {
      return responseHandler.success(res, [], 'Plans not enabled for this salon');
    }

    // Get active plans sorted by sort_order
    const plans = await prisma.subscriptionPlan.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' }
    });

    return responseHandler.success(res, plans, 'Plans retrieved successfully');
  } catch (error) {
    console.error('Get Plans For Salon Error:', error);
    return responseHandler.error(res, 'Failed to retrieve plans');
  }
};
