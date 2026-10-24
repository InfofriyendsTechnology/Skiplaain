import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

/**
 * DELETE /api/admin/plans/:id
 * Soft-delete (set isActive=false) if memberships reference it, otherwise hard-delete
 */
export const deletePlan = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;

    // Check if any memberships reference this plan
    const membershipCount = await prisma.membership.count({
      where: { planId: id as string }
    });

    if (membershipCount > 0) {
      // Soft delete
      const plan = await prisma.subscriptionPlan.update({
        where: { id: id as string },
        data: { isActive: false }
      });
      return responseHandler.success(res, plan, `Plan soft-deleted (${membershipCount} memberships reference it)`);
    } else {
      // Hard delete
      await prisma.subscriptionPlan.delete({
        where: { id: id as string }
      });
      return responseHandler.success(res, null, 'Plan deleted successfully');
    }
  } catch (error) {
    console.error('Delete Plan Error:', error);
    return responseHandler.error(res, 'Failed to delete plan');
  }
};
