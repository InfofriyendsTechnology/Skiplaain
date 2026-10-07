import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getCustomerByPhone = async (req: Request, res: Response) => {
  try {
    const { phone } = req.params;

    const customer = await prisma.customer.findUnique({
      where: { phone },
      include: {
        bookings: {
          orderBy: { createdAt: 'desc' },
          take: 10,
        },
        memberships: {
          where: { status: 'active' },
        },
      },
    });

    if (!customer) {
      return responseHandler.notFound(res, 'Customer not found');
    }

    return responseHandler.success(res, customer, 'Customer fetched successfully');
  } catch (error) {
    console.error('Get Customer Error:', error);
    return responseHandler.error(res, 'Failed to fetch customer');
  }
};
