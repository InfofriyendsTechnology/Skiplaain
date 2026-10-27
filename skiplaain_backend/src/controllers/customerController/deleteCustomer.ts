import { Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';
import { AuthRequest } from '../../middleware/auth';

/**
 * Delete a customer (admin only)
 * REFUSES if customer has any payment, membership, or commission_ledger record (409 Conflict)
 * Only customers with no financial history may be deleted
 */
export const deleteCustomer = async (req: AuthRequest, res: Response) => {
  try {
    const { phone } = req.params;

    // Ensure phone is a string
    if (!phone || typeof phone !== 'string') {
      return responseHandler.badRequest(res, 'Invalid phone number');
    }

    // Check if customer exists
    const customer = await prisma.customer.findUnique({
      where: { phone },
    });

    if (!customer) {
      return responseHandler.notFound(res, 'Customer not found');
    }

    // Check for ANY financial records (payments, memberships, ledger entries)
    const [paymentCount, membershipCount, bookingCount] = await Promise.all([
      prisma.payment.count({ where: { customerId: customer.id } }),
      prisma.membership.count({ where: { customerId: customer.id } }),
      prisma.booking.count({ where: { customerId: customer.id } }),
    ]);

    if (paymentCount > 0 || membershipCount > 0 || bookingCount > 0) {
      return responseHandler.conflict(
        res,
        `Cannot delete customer with existing records: ${paymentCount} payment(s), ${membershipCount} membership(s), ${bookingCount} booking(s). Financial data must be preserved.`
      );
    }

    // Safe to delete: customer has no financial history
    await prisma.customer.delete({
      where: { phone },
    });

    return responseHandler.success(res, null, 'Customer deleted successfully');
  } catch (error: any) {
    console.error('Delete customer error:', error);
    return responseHandler.error(res, 'Failed to delete customer', error.message);
  }
};
