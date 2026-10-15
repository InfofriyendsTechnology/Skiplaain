import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getAllBookings = async (req: Request, res: Response) => {
  try {
    const { status, search, startDate, endDate, limit, offset } = req.query;

    // Build search filters
    const where: any = {};

    // Filter by status
    if (status) {
      where.status = status as string;
    }

    // Search by customer name or phone
    if (search && typeof search === 'string') {
      where.customer = {
        OR: [
          { name: { contains: search, mode: 'insensitive' } },
          { phone: { contains: search } },
        ],
      };
    }

    // Filter by date range
    if (startDate || endDate) {
      where.bookingDate = {};
      if (startDate) {
        where.bookingDate.gte = new Date(startDate as string);
      }
      if (endDate) {
        where.bookingDate.lte = new Date(endDate as string);
      }
    }

    // Pagination
    const limitNum = limit ? parseInt(limit as string) : undefined;
    const offsetNum = offset ? parseInt(offset as string) : undefined;

    const bookings = await prisma.booking.findMany({
      where: Object.keys(where).length > 0 ? where : undefined,
      include: {
        services: true,
        partner: {
          select: {
            id: true,
            salonName: true,
            address: true,
          },
        },
        customer: {
          select: {
            id: true,
            name: true,
            phone: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: limitNum,
      skip: offsetNum,
    });

    return responseHandler.success(res, bookings, 'Bookings fetched successfully');
  } catch (error) {
    console.error('Get Bookings Error:', error);
    return responseHandler.error(res, 'Failed to fetch bookings');
  }
};
