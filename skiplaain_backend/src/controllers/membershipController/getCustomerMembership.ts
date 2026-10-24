import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getCustomerMembership = async (req: AuthRequest, res: Response) => {
  try {
    const { phone, salonId } = req.params;

    if (!req.user) {
      return responseHandler.unauthorized(res, 'Authentication required');
    }

    // Access control: customer only for their own phone, or admin
    if (req.user.type === 'customer' && req.user.phone !== phone) {
      return responseHandler.forbidden(res, 'Access denied: you can only view your own memberships');
    }

    if (req.user.type === 'partner') {
      return responseHandler.forbidden(res, 'Partners cannot view customer memberships directly');
    }

    const membership = await prisma.membership.findFirst({
      where: {
        customerPhone: phone as string,
        partnerId: salonId as string,
        status: 'active',
      },
      include: {
        partner: {
          select: {
            salonName: true,
            address: true,
          },
        },
      },
    });

    if (!membership) {
      return responseHandler.notFound(res, 'No active membership found');
    }

    return responseHandler.success(res, membership, 'Membership fetched successfully');
  } catch (error) {
    console.error('Get Customer Membership Error:', error);
    return responseHandler.error(res, 'Failed to fetch membership');
  }
};
