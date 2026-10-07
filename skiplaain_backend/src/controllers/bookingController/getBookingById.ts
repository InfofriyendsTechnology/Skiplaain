import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getBookingById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const booking = await prisma.booking.findUnique({
      where: { id },
      include: {
        services: true,
        partner: true,
        customer: true,
        barber: true,
      },
    });

    if (!booking) {
      return responseHandler.notFound(res, 'Booking not found');
    }

    return responseHandler.success(res, booking, 'Booking fetched successfully');
  } catch (error) {
    console.error('Get Booking Error:', error);
    return responseHandler.error(res, 'Failed to fetch booking');
  }
};
