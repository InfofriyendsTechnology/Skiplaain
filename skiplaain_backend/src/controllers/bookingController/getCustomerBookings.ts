import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getCustomerBookings = async (req: Request, res: Response) => {
  try {
    const { phone } = req.params;

    const bookings = await prisma.booking.findMany({
      where: { customerPhone: phone },
      include: {
        bookingServices: {
          include: {
            service: true,
          },
        },
        partner: {
          select: {
            id: true,
            salonName: true,
            address: true,
            phone: true,
          },
        },
        barber: {
          select: {
            id: true,
            name: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return responseHandler.success(res, bookings, 'Customer bookings fetched successfully');
  } catch (error) {
    console.error('Get Customer Bookings Error:', error);
    return responseHandler.error(res, 'Failed to fetch customer bookings');
  }
};
