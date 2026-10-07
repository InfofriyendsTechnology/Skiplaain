import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getPartnerBookings = async (req: Request, res: Response) => {
  try {
    const { partnerId } = req.params;
    const { status } = req.query;

    const bookings = await prisma.booking.findMany({
      where: {
        partnerId,
        ...(status && { status: status as string }),
      },
      include: {
        bookingServices: {
          include: {
            service: true,
          },
        },
        customer: {
          select: {
            id: true,
            name: true,
            phone: true,
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

    return responseHandler.success(res, bookings, 'Partner bookings fetched successfully');
  } catch (error) {
    console.error('Get Partner Bookings Error:', error);
    return responseHandler.error(res, 'Failed to fetch partner bookings');
  }
};
