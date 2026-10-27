import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const updateCustomer = async (req: AuthRequest, res: Response) => {
  try {
    const { phone } = req.params;
    
    // Admin can edit any, customer can only edit their own
    if (req.user?.type === 'customer' && req.user?.phone !== phone) {
      return responseHandler.forbidden(res, 'You can only update your own profile');
    }
    
    const updateData = req.body;

    const customer = await prisma.customer.update({
      where: { phone: phone as string },
      data: updateData,
    });

    return responseHandler.success(res, customer, 'Customer updated successfully');
  } catch (error) {
    console.error('Update Customer Error:', error);
    return responseHandler.error(res, 'Failed to update customer');
  }
};
