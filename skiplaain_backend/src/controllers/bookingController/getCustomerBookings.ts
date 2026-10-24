import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getCustomerBookings = async (req: AuthRequest, res: Response) => {
  try {
    const { phone } = req.params;

    if (!req.user) {
      return responseHandler.unauthorized(res, 'Authentication required');
    }

    // Customer can only see their own bookings, admin can see all
    if (req.user.type === 'customer' && req.user.phone !== phone) {
      return responseHandler.forbidden(res, 'Access denied: you can only view your own bookings');
    }

    const bookings = await prisma.booking.findMany({
      where: { customerPhone: phone as string },
      include: {
        services: true,
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
