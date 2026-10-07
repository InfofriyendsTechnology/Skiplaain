import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const deletePartner = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    await prisma.partner.delete({ where: { id } });

    return responseHandler.success(res, null, 'Partner deleted successfully');
  } catch (error) {
    console.error('Delete Partner Error:', error);
    return responseHandler.error(res, 'Failed to delete partner');
  }
};
