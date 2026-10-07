import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';
import { AuthRequest } from '../../middleware/auth';

export const updateBookingStatus = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { status, cancelReason } = req.body; // confirmed, completed, cancelled

    if (!['confirmed', 'completed', 'cancelled'].includes(status)) {
      return responseHandler.badRequest(res, 'Invalid status value');
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

    const booking = await prisma.booking.update({
      where: { id },
      data: updateData,
      include: {
        services: true,
      },
    });

    return responseHandler.success(res, booking, `Booking ${status} successfully`);
  } catch (error) {
    console.error('Update Booking Status Error:', error);
    return responseHandler.error(res, 'Failed to update booking status');
  }
};
