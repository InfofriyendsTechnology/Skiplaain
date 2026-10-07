import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getCustomerMembership = async (req: Request, res: Response) => {
  try {
    const { phone, salonId } = req.params;

    const membership = await prisma.membership.findFirst({
      where: {
        customerPhone: phone,
        partnerId: salonId,
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
