import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

const UPI_REGEX = /^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$/;
const IFSC_REGEX = /^[A-Z]{4}0[A-Z0-9]{6}$/;
const ACCOUNT_NUMBER_REGEX = /^\d{9,18}$/;

/**
 * PUT /partner/payout-details
 */
export const updatePayoutDetails = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.user || req.user.type !== 'partner') {
      return responseHandler.forbidden(res, 'Partner access only');
    }

    const { payoutUpiId, payoutBankAccountName, payoutBankAccountNumber, payoutBankIfsc } = req.body;

    const updates: any = {};

    if (payoutUpiId !== undefined) {
      if (payoutUpiId && !UPI_REGEX.test(payoutUpiId)) {
        return responseHandler.badRequest(res, 'Invalid UPI ID format');
      }
      updates.payoutUpiId = payoutUpiId;
    }

    if (payoutBankIfsc !== undefined) {
      if (payoutBankIfsc && !IFSC_REGEX.test(payoutBankIfsc)) {
        return responseHandler.badRequest(res, 'Invalid IFSC code format');
      }
      updates.payoutBankIfsc = payoutBankIfsc;
    }

    if (payoutBankAccountNumber !== undefined) {
      if (payoutBankAccountNumber && !ACCOUNT_NUMBER_REGEX.test(payoutBankAccountNumber)) {
        return responseHandler.badRequest(res, 'Account number must be 9-18 digits');
      }
      updates.payoutBankAccountNumber = payoutBankAccountNumber;
    }

    if (payoutBankAccountName !== undefined) {
      updates.payoutBankAccountName = payoutBankAccountName;
    }

    const partner = await prisma.partner.update({
      where: { id: req.user.id },
      data: updates
    });

    return responseHandler.success(res, partner, 'Payout details updated');
  } catch (error) {
    console.error('Update Payout Details Error:', error);
    return responseHandler.error(res, 'Failed to update payout details');
  }
};
