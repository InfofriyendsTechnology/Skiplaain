import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

/**
 * GET /api/subscriptions/my
 * Get all customer's memberships (active and expired)
 * Requires customer JWT
 */
export const getMySubscriptions = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.user) {
      return responseHandler.unauthorized(res, 'Authentication required');
    }

    if (req.user.type !== 'customer') {
      return responseHandler.forbidden(res, 'Customer access only');
    }

    // Find customer
    const customer = await prisma.customer.findUnique({
      where: { phone: req.user.phone }
    });

    if (!customer) {
      return responseHandler.notFound(res, 'Customer not found');
    }

    // Get all memberships
    const memberships = await prisma.membership.findMany({
      where: {
        customerId: customer.id
      },
      select: {
        id: true,
        membershipId: true,
        salonName: true,
        planName: true,
        pricePaise: true,
        durationMonths: true,
        status: true,
        startsAt: true,
        expiresAt: true,
        activatedAt: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' }
    });

    return responseHandler.success(res, memberships, 'Subscriptions retrieved successfully');
  } catch (error) {
    console.error('Get My Subscriptions Error:', error);
    return responseHandler.error(res, 'Failed to retrieve subscriptions');
  }
};
