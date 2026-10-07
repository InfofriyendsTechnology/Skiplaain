import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const updatePartner = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const partner = await prisma.partner.update({
      where: { id },
      data: updateData,
      include: {
        barbers: true,
        services: true,
      },
    });

    return responseHandler.success(res, partner, 'Partner updated successfully');
  } catch (error) {
    console.error('Update Partner Error:', error);
    return responseHandler.error(res, 'Failed to update partner');
  }
};
