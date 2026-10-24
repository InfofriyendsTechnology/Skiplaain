import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

/**
 * GET /api/admin/settings
 * Get platform settings
 */
export const getSettings = async (req: AuthRequest, res: Response) => {
  try {
    const settings = await prisma.platformSettings.findUnique({
      where: { id: 'default' }
    });

    if (!settings) {
      return responseHandler.notFound(res, 'Settings not found');
    }

    return responseHandler.success(res, settings, 'Settings retrieved successfully');
  } catch (error) {
    console.error('Get Settings Error:', error);
    return responseHandler.error(res, 'Failed to retrieve settings');
  }
};
