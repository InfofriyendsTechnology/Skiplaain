import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getAllCustomers = async (req: Request, res: Response) => {
  try {
    const { search, limit, offset } = req.query;

    // Build search filters
    const where: any = {};

    // Search by name or phone
    if (search && typeof search === 'string') {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { phone: { contains: search } },
      ];
    }

    // Pagination
    const limitNum = limit ? parseInt(limit as string) : undefined;
    const offsetNum = offset ? parseInt(offset as string) : undefined;

    const customers = await prisma.customer.findMany({
      where: Object.keys(where).length > 0 ? where : undefined,
      include: {
        _count: {
          select: {
            bookings: true,
            memberships: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: limitNum,
      skip: offsetNum,
    });

    return responseHandler.success(res, customers, 'Customers fetched successfully');
  } catch (error) {
    console.error('Get Customers Error:', error);
    return responseHandler.error(res, 'Failed to fetch customers');
  }
};
