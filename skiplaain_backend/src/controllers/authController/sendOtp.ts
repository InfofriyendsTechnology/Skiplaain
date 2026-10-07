import { Request, Response } from 'express';
import otpService from '../../utils/otpService';
import responseHandler from '../../utils/responseHandler';

export const sendOtp = async (req: Request, res: Response) => {
  try {
    const { phone, purpose = 'login' } = req.body;

    if (!phone) {
      return responseHandler.badRequest(res, 'Phone number is required');
    }

    const result = await otpService.sendOtp(phone, purpose);

    if (!result.success) {
      return responseHandler.error(res, result.message);
    }

    return responseHandler.success(res, null, result.message);
  } catch (error) {
    console.error('Send OTP Error:', error);
    return responseHandler.error(res, 'Failed to send OTP');
  }
};
