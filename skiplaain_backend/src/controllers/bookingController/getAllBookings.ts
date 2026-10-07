import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getAllBookings = async (req: Request, res: Response) => {
  try {
    const { status } = req.query;

    const bookings = await prisma.booking.findMany({
      where: status ? { status: status as string } : undefined,
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
    });

    return responseHandler.success(res, bookings, 'Bookings fetched successfully');
  } catch (error) {
    console.error('Get Bookings Error:', error);
    return responseHandler.error(res, 'Failed to fetch bookings');
  }
};
