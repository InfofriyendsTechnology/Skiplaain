import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getMe = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.user) {
      return responseHandler.unauthorized(res, 'Authentication required');
    }

    if (req.user.type !== 'customer') {
      return responseHandler.forbidden(res, 'Customer access only');
    }

    const customer = await prisma.customer.findUnique({
      where: { phone: req.user.phone },
      select: {
        id: true,
        phone: true,
        name: true,
        email: true,
        activeSalonId: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!customer) {
      return responseHandler.notFound(res, 'Customer not found');
    }

    return responseHandler.success(res, customer, 'Customer profile fetched successfully');
  } catch (error) {
    console.error('Get Me Error:', error);
    return responseHandler.error(res, 'Failed to fetch customer profile');
  }
};
