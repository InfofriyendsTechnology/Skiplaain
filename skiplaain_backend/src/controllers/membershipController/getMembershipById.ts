import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const getMembershipById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const membership = await prisma.membership.findUnique({
      where: { id },
      include: {
        partner: true,
        customer: true,
      },
    });

    if (!membership) {
      return responseHandler.notFound(res, 'Membership not found');
    }

    return responseHandler.success(res, membership, 'Membership fetched successfully');
  } catch (error) {
    console.error('Get Membership Error:', error);
    return responseHandler.error(res, 'Failed to fetch membership');
  }
};
