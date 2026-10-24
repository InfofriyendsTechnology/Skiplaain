import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';
import { AuthRequest } from '../../middleware/auth';

export const updateBookingStatus = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { status, cancelReason } = req.body;

    if (!req.user) {
      return responseHandler.unauthorized(res, 'Authentication required');
    }

    if (!['confirmed', 'completed', 'cancelled'].includes(status)) {
      return responseHandler.badRequest(res, 'Invalid status value');
    }

    // Get booking first to check ownership
    const booking = await prisma.booking.findUnique({
      where: { id: id as string }
    });

    if (!booking) {
      return responseHandler.notFound(res, 'Booking not found');
    }

    // Access control
    if (req.user.type === 'customer') {
      if (booking.customerPhone !== req.user.phone) {
        return responseHandler.forbidden(res, 'Access denied: you can only update your own bookings');
      }
      if (status === 'completed') {
        return responseHandler.forbidden(res, 'Customers cannot mark bookings as completed');
      }
    }

    if (req.user.type === 'partner' && booking.partnerId !== req.user.id) {
      return responseHandler.forbidden(res, 'Access denied: you can only update bookings for your salon');
    }

    const updateData: any = {
      status,
      updatedAt: new Date(),
    };

    if (status === 'completed') {
      updateData.completedAt = new Date();
      updateData.completedBy = req.user?.id;
    } else if (status === 'cancelled') {
      updateData.cancelledAt = new Date();
      updateData.cancelledBy = req.user?.id;
      if (cancelReason) {
        updateData.cancelReason = cancelReason;
      }
    }

    const updatedBooking = await prisma.booking.update({
      where: { id: id as string },
      data: updateData,
      include: {
        services: true,
      },
    });

    return responseHandler.success(res, updatedBooking, `Booking ${status} successfully`);
  } catch (error) {
    console.error('Update Booking Status Error:', error);
    return responseHandler.error(res, 'Failed to update booking status');
  }
};
