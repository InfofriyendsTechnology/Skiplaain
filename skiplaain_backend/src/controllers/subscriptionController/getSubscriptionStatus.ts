import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

/**
 * GET /api/subscriptions/status?salonId=xxx (or partnerId=xxx)
 * Get customer's subscription status for a specific partner/salon
 * Returns { hasActivePlan, expiresAt, plansEnabled, planName }
 * Requires customer JWT
 */
export const getSubscriptionStatus = async (req: AuthRequest, res: Response) => {
  try {
    const { salonId, partnerId } = req.query;
    const id = (salonId || partnerId) as string;

    if (!req.user) {
      return responseHandler.unauthorized(res, 'Authentication required');
    }

    if (req.user.type !== 'customer') {
      return responseHandler.forbidden(res, 'Customer access only');
    }

    if (!id) {
      return responseHandler.badRequest(res, 'Salon ID is required');
    }

    // Check if partner exists
    const partner = await prisma.partner.findUnique({
      where: { id },
      select: { plansEnabled: true }
    });

    if (!partner) {
      return responseHandler.notFound(res, 'Salon not found');
    }

    // Find customer by phone from JWT
    const customer = await prisma.customer.findUnique({
      where: { phone: req.user.phone }
    });

    if (!customer) {
      return responseHandler.success(res, {
        hasActivePlan: false,
        expiresAt: null,
        plansEnabled: partner.plansEnabled,
        planName: null
      }, 'Customer not found');
    }

    // Check for active subscription
    const now = new Date();
    const activeSubscription = await prisma.membership.findFirst({
      where: {
        customerId: customer.id,
        partnerId: id,
        status: 'active',
        expiresAt: { gt: now }
      },
      include: {
        plan: true
      },
      orderBy: { expiresAt: 'desc' }
    });

    if (!activeSubscription) {
      return responseHandler.success(res, {
        hasActivePlan: false,
        expiresAt: null,
        plansEnabled: partner.plansEnabled,
        planName: null
      }, 'No active subscription');
    }

    return responseHandler.success(res, {
      hasActivePlan: true,
      expiresAt: activeSubscription.expiresAt,
      plansEnabled: partner.plansEnabled,
      planName: activeSubscription.plan?.name || activeSubscription.planName
    }, 'Subscription retrieved successfully');

  } catch (error) {
    console.error('Get Subscription Status Error:', error);
    return responseHandler.error(res, 'Failed to retrieve subscription status');
  }
};
