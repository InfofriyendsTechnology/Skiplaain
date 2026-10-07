import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getAllPartners = async (req: Request, res: Response) => {
  try {
    const { status } = req.query;

    const partners = await prisma.partner.findMany({
      where: status ? { status: status as string } : undefined,
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
    });

    return responseHandler.success(res, partners, 'Partners fetched successfully');
  } catch (error) {
    console.error('Get Partners Error:', error);
    return responseHandler.error(res, 'Failed to fetch partners');
  }
};
