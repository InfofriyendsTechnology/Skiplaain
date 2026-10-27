import { Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';
import { AuthRequest } from '../../middleware/auth';

/**
 * Delete a booking (admin only)
 */
export const deleteBooking = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;

    // Ensure id is a string
    if (!id || typeof id !== 'string') {
      return responseHandler.badRequest(res, 'Invalid booking ID');
    }

    // Check if booking exists
    const booking = await prisma.booking.findUnique({
      where: { id },
    });

    if (!booking) {
      return responseHandler.notFound(res, 'Booking not found');
    }

    // Delete booking (cascade handles booking_services)
    await prisma.booking.delete({
      where: { id },
    });

    return responseHandler.success(res, null, 'Booking deleted successfully');
  } catch (error: any) {
    console.error('Delete booking error:', error);
    return responseHandler.error(res, 'Failed to delete booking', error.message);
  }
};
