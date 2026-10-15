import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getAllPartners = async (req: Request, res: Response) => {
  try {
    const { status, search, city, limit, offset } = req.query;

    // Build search filters
    const where: any = {};

    // Filter by status (active, pending, etc.)
    if (status) {
      where.status = status as string;
    }

    // Search by salon name, owner name, or address
    if (search && typeof search === 'string') {
      where.OR = [
        { salonName: { contains: search, mode: 'insensitive' } },
        { ownerName: { contains: search, mode: 'insensitive' } },
        { address: { contains: search, mode: 'insensitive' } },
      ];
    }

    // Filter by city
    if (city && typeof city === 'string') {
      where.city = { contains: city, mode: 'insensitive' };
    }

    // Pagination
    const limitNum = limit ? parseInt(limit as string) : undefined;
    const offsetNum = offset ? parseInt(offset as string) : undefined;

    const partners = await prisma.partner.findMany({
      where: Object.keys(where).length > 0 ? where : undefined,
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
      orderBy: { createdAt: 'desc' },
      take: limitNum,
      skip: offsetNum,
    });

    return responseHandler.success(res, partners, 'Partners fetched successfully');
  } catch (error) {
    console.error('Get Partners Error:', error);
    return responseHandler.error(res, 'Failed to fetch partners');
  }
};
