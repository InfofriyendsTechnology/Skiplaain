import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getSalonById = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;

    const salon = await prisma.partner.findFirst({
      where: {
        id: id as string,
        status: 'approved', // Only approved salons
      },
      select: {
        id: true,
        salonName: true,
        address: true,
        city: true,
        pincode: true,
        latitude: true,
        longitude: true,
        profileImage: true,
        rating: true,
        plansEnabled: true,
        barbers: {
          select: {
            id: true,
            name: true,
            specialty: true,
            image: true,
            isAvailable: true,
          },
        },
        services: {
          where: { isActive: true },
          select: {
            id: true,
            name: true,
            price: true,
            duration: true,
            description: true,
            image: true,
            category: true,
          },
        },
      },
    });

    if (!salon) {
      return responseHandler.notFound(res, 'Salon not found or not approved');
    }

    return responseHandler.success(res, salon, 'Salon fetched successfully');
  } catch (error) {
    console.error('Get Salon Error:', error);
    return responseHandler.error(res, 'Failed to fetch salon');
  }
};
