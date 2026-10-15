import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

/**
 * Check if phone number exists (Google-grade UX)
 * Returns: { exists: true/false, partner: {...} if exists }
 */
export const checkPhone = async (req: Request, res: Response) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return responseHandler.badRequest(res, 'Phone number is required');
    }

    const partner = await prisma.partner.findUnique({
      where: { phone },
      select: {
        id: true,
        phone: true,
        salonName: true,
        ownerName: true,
        status: true,
        createdAt: true,
      },
    });

    if (partner) {
      return responseHandler.success(res, {
        exists: true,
        partner: partner,
        message: 'Welcome back!',
      });
    }

    return responseHandler.success(res, {
      exists: false,
      message: 'New user - proceed to registration',
    });
  } catch (error) {
    console.error('Check Phone Error:', error);
    return responseHandler.error(res, 'Failed to check phone number');
  }
};
