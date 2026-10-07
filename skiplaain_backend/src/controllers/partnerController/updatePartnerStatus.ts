import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const updatePartnerStatus = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { status } = req.body; // approved, pending, blocked

    if (!['approved', 'pending', 'blocked'].includes(status)) {
      return responseHandler.badRequest(res, 'Invalid status value');
    }

    const partner = await prisma.partner.update({
      where: { id },
      data: { status },
    });

    return responseHandler.success(res, partner, `Partner ${status} successfully`);
  } catch (error) {
    console.error('Update Status Error:', error);
    return responseHandler.error(res, 'Failed to update partner status');
  }
};
