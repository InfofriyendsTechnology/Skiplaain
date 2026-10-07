import { Request, Response } from 'express';
import otpService from '../../utils/otpService';
import jwtHelper from '../../utils/jwtHelper';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const verifyOtp = async (req: Request, res: Response) => {
  try {
    const { phone, otp, userType = 'customer', name } = req.body;

    if (!phone || !otp) {
      return responseHandler.badRequest(res, 'Phone and OTP are required');
    }

    // Verify OTP
    const isValid = await otpService.verifyOtp(phone, otp);

    if (!isValid) {
      return responseHandler.badRequest(res, 'Invalid or expired OTP');
    }

    let user;
    let userData;
    let isNewUser = false;
    let needsOnboarding = false;

    if (userType === 'customer') {
      // Find or create customer
      user = await prisma.customer.findUnique({ where: { phone } });

      if (!user) {
        // Create new customer
        user = await prisma.customer.create({
          data: {
            phone,
            name: name || 'Customer',
          },
        });
        isNewUser = true;
      }

      userData = {
        id: user.id,
        phone: user.phone,
        name: user.name,
        type: 'customer' as const,
        isNewUser,
        needsOnboarding: false,
      };
    } else if (userType === 'partner') {
      // Find partner
      user = await prisma.partner.findUnique({ where: { phone } });

      if (!user) {
        // NEW: Don't error out - indicate new partner needs registration
        isNewUser = true;
        needsOnboarding = true;

        // Create minimal partner record for phone verification
        user = await prisma.partner.create({
          data: {
            phone,
            ownerName: 'New Partner',
            salonName: '', // Will be filled during onboarding
            address: '',
            status: 'incomplete', // New status for unfinished registration
          },
        });

        userData = {
          id: user.id,
          phone: user.phone,
          name: user.ownerName,
          salonName: null,
          status: 'incomplete',
          type: 'partner' as const,
          isNewUser: true,
          needsOnboarding: true,
        };
      } else {
        // Existing partner - check if profile is complete
        const isProfileComplete = user.salonName && user.salonName.trim() !== '';
        needsOnboarding = !isProfileComplete || user.status === 'incomplete';

        userData = {
          id: user.id,
          phone: user.phone,
          name: user.ownerName,
          salonName: user.salonName || null,
          status: user.status,
          type: 'partner' as const,
          isNewUser: false,
          needsOnboarding,
        };
      }
    } else {
      return responseHandler.badRequest(res, 'Invalid user type');
    }

    // Generate JWT token
    const token = jwtHelper.generateToken({
      id: user.id,
      phone: user.phone,
      type: userType as 'customer' | 'partner',
    });

    return responseHandler.success(res, {
      token,
      user: userData,
    }, isNewUser ? 'Welcome to Skiplaain!' : 'Login successful');
  } catch (error) {
    console.error('Verify OTP Error:', error);
    return responseHandler.error(res, 'OTP verification failed');
  }
};
