import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getPartnerById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const partner = await prisma.partner.findUnique({
      where: { id },
      include: {
        barbers: true,
        services: {
          where: { isActive: true },
        },
        _count: {
          select: {
            bookings: true,
            memberships: true,
          },
        },
      },
    });

    if (!partner) {
      return responseHandler.notFound(res, 'Partner not found');
    }

    return responseHandler.success(res, partner, 'Partner fetched successfully');
  } catch (error) {
    console.error('Get Partner Error:', error);
    return responseHandler.error(res, 'Failed to fetch partner');
  }
};
