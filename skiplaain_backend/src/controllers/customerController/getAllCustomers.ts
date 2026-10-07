import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getAllCustomers = async (req: Request, res: Response) => {
  try {
    const customers = await prisma.customer.findMany({
      include: {
        _count: {
          select: {
            bookings: true,
            memberships: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return responseHandler.success(res, customers, 'Customers fetched successfully');
  } catch (error) {
    console.error('Get Customers Error:', error);
    return responseHandler.error(res, 'Failed to fetch customers');
  }
};
