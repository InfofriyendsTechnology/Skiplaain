import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getBookingById = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;

    if (!req.user) {
      return responseHandler.unauthorized(res, 'Authentication required');
    }

    const booking = await prisma.booking.findUnique({
      where: { id: id as string },
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

    // Access control: customer sees only their own, partner sees only their salon's, admin sees all
    if (req.user.type === 'customer' && booking.customerPhone !== req.user.phone) {
      return responseHandler.forbidden(res, 'Access denied: you can only view your own bookings');
    }

    if (req.user.type === 'partner' && booking.partnerId !== req.user.id) {
      return responseHandler.forbidden(res, 'Access denied: you can only view bookings for your salon');
    }

    return responseHandler.success(res, booking, 'Booking fetched successfully');
  } catch (error) {
    console.error('Get Booking Error:', error);
    return responseHandler.error(res, 'Failed to fetch booking');
  }
};
