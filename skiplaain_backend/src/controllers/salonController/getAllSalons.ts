import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getAllSalons = async (req: AuthRequest, res: Response) => {
  try {
    const { search, city, lat, lng, limit, offset } = req.query;

    const where: any = {
      status: 'approved', // Only approved salons
    };

    // Search filter
    if (search && typeof search === 'string') {
      where.OR = [
        { salonName: { contains: search, mode: 'insensitive' } },
        { address: { contains: search, mode: 'insensitive' } },
      ];
    }

    // City filter
    if (city && typeof city === 'string') {
      where.city = { contains: city, mode: 'insensitive' };
    }

    // Pagination
    const limitNum = limit ? parseInt(limit as string) : 50;
    const offsetNum = offset ? parseInt(offset as string) : 0;

    const salons = await prisma.partner.findMany({
      where,
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
      orderBy: { createdAt: 'desc' },
      take: limitNum,
      skip: offsetNum,
    });

    return responseHandler.success(res, salons, 'Salons fetched successfully');
  } catch (error) {
    console.error('Get Salons Error:', error);
    return responseHandler.error(res, 'Failed to fetch salons');
  }
};
