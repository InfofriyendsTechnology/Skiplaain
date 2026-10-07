import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getAllMemberships = async (req: Request, res: Response) => {
  try {
    const { status } = req.query;

    const memberships = await prisma.membership.findMany({
      where: status ? { status: status as string } : undefined,
      include: {
        partner: {
          select: {
            salonName: true,
            address: true,
          },
        },
        customer: {
          select: {
            name: true,
            phone: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return responseHandler.success(res, memberships, 'Memberships fetched successfully');
  } catch (error) {
    console.error('Get Memberships Error:', error);
    return responseHandler.error(res, 'Failed to fetch memberships');
  }
};
