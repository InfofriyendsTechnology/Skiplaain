import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getPartnerBookings = async (req: AuthRequest, res: Response) => {
  try {
    const { partnerId } = req.params;
    const { status } = req.query;

    if (!req.user) {
      return responseHandler.unauthorized(res, 'Authentication required');
    }

    // Partner can only see their own bookings, admin can see all
    if (req.user.type === 'partner' && req.user.id !== partnerId) {
      return responseHandler.forbidden(res, 'Access denied: you can only view your own bookings');
    }

    const bookings = await prisma.booking.findMany({
      where: {
        partnerId: partnerId as string,
        ...(status && { status: status as string }),
      },
      include: {
        services: true,
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
