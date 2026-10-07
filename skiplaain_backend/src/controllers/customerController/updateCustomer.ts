import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const updateCustomer = async (req: Request, res: Response) => {
  try {
    const { phone } = req.params;
    const updateData = req.body;

    const customer = await prisma.customer.update({
      where: { phone },
      data: updateData,
    });

    return responseHandler.success(res, customer, 'Customer updated successfully');
  } catch (error) {
    console.error('Update Customer Error:', error);
    return responseHandler.error(res, 'Failed to update customer');
  }
};
