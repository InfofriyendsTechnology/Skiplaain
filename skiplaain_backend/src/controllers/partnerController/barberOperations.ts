import { Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';
import { AuthRequest } from '../../middleware/auth';

/**
 * Add a barber to a partner salon (admin or owner only)
 */
export const addBarber = async (req: AuthRequest, res: Response) => {
  try {
    let partnerId = req.params.id;
    const { name, phone, specialty, image, isAvailable } = req.body;

    // Ensure partnerId is a string
    if (!partnerId || Array.isArray(partnerId)) {
      return responseHandler.badRequest(res, 'Invalid partner ID');
    }
    partnerId = partnerId as string;

    if (!name) {
      return responseHandler.badRequest(res, 'Barber name is required');
    }

    // Check if partner exists
    const partner = await prisma.partner.findUnique({
      where: { id: partnerId },
    });

    if (!partner) {
      return responseHandler.notFound(res, 'Partner not found');
    }

    // Create barber
    const barber = await prisma.barber.create({
      data: {
        partnerId,
        name,
        phone: phone || null,
        specialty: specialty || null,
        image: image || null,
        isAvailable: isAvailable !== undefined ? isAvailable : true,
      },
    });

    return responseHandler.success(res, barber, 'Barber added successfully');
  } catch (error: any) {
    console.error('Add barber error:', error);
    return responseHandler.error(res, 'Failed to add barber', error.message);
  }
};

/**
 * Delete a specific barber (admin or owner only)
 */
export const deleteBarber = async (req: AuthRequest, res: Response) => {
  try {
    let partnerId = req.params.id;
    let barberId = req.params.barberId;

    // Ensure params are strings
    if (!partnerId || Array.isArray(partnerId) || !barberId || Array.isArray(barberId)) {
      return responseHandler.badRequest(res, 'Invalid parameters');
    }
    partnerId = partnerId as string;
    barberId = barberId as string;

    // Check if barber belongs to this partner
    const barber = await prisma.barber.findFirst({
      where: { id: barberId, partnerId },
    });

    if (!barber) {
      return responseHandler.notFound(res, 'Barber not found for this partner');
    }

    // Delete barber (cascade handles booking relations)
    await prisma.barber.delete({
      where: { id: barberId },
    });

    return responseHandler.success(res, null, 'Barber deleted successfully');
  } catch (error: any) {
    console.error('Delete barber error:', error);
    return responseHandler.error(res, 'Failed to delete barber', error.message);
  }
};

/**
 * Delete all barbers for a partner (admin only)
 */
export const clearAllBarbers = async (req: AuthRequest, res: Response) => {
  try {
    let partnerId = req.params.id;

    // Ensure partnerId is a string
    if (!partnerId || Array.isArray(partnerId)) {
      return responseHandler.badRequest(res, 'Invalid partner ID');
    }
    partnerId = partnerId as string;

    // Check if partner exists
    const partner = await prisma.partner.findUnique({
      where: { id: partnerId },
    });

    if (!partner) {
      return responseHandler.notFound(res, 'Partner not found');
    }

    // Delete all barbers for this partner
    const result = await prisma.barber.deleteMany({
      where: { partnerId },
    });

    return responseHandler.success(
      res,
      { count: result.count },
      `Deleted ${result.count} barber(s) successfully`
    );
  } catch (error: any) {
    console.error('Clear all barbers error:', error);
    return responseHandler.error(res, 'Failed to clear barbers', error.message);
  }
};
