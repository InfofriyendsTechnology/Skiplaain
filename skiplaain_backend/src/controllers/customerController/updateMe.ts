import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const updateMe = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.user) {
      return responseHandler.unauthorized(res, 'Authentication required');
    }

    if (req.user.type !== 'customer') {
      return responseHandler.forbidden(res, 'Customer access only');
    }

    const { name, email } = req.body;

    // Only allow updating name and email
    const updateData: any = {};
    if (name !== undefined) updateData.name = name;
    if (email !== undefined) updateData.email = email;

    const customer = await prisma.customer.update({
      where: { phone: req.user.phone },
      data: updateData,
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

    return responseHandler.success(res, customer, 'Customer profile updated successfully');
  } catch (error) {
    console.error('Update Me Error:', error);
    return responseHandler.error(res, 'Failed to update customer profile');
  }
};
