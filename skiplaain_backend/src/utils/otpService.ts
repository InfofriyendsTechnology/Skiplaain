import prisma from './prisma';

class OtpService {
  // Generate 6-digit OTP
  generateOtp(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  // Send OTP via SMS (2Factor API or any SMS provider)
  async sendOtp(phone: string, purpose: string = 'login'): Promise<{ success: boolean; message: string }> {
    try {
      const otp = '111111'; // Static OTP for development
      const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

      // Delete old OTPs for this phone
      await prisma.otpVerification.deleteMany({
        where: { phone, verified: false },
      });

      // Save new OTP to database
      await prisma.otpVerification.create({
        data: {
          phone,
          otp,
          purpose,
          expiresAt,
        },
      });

      // STATIC OTP MODE - No SMS sent
      console.log(`📱 Static OTP for ${phone}: ${otp} (Development Mode - SMS Disabled)`);

      return {
        success: true,
        message: 'OTP sent successfully',
      };
    } catch (error) {
      console.error('OTP Send Error:', error);
      return {
        success: false,
        message: 'Failed to send OTP',
      };
    }
  }

  // Verify OTP
  async verifyOtp(phone: string, otp: string): Promise<boolean> {
    try {
      // STATIC OTP MODE - Always accept 111111
      if (otp === '111111') {
        console.log(`🔓 Static OTP accepted for ${phone}`);
        return true;
      }

      // Fallback to DB check (shouldn't be needed)
      const record = await prisma.otpVerification.findFirst({
        where: {
          phone,
          otp,
          verified: false,
          expiresAt: { gte: new Date() },
        },
      });

      if (!record) {
        return false;
      }

      await prisma.otpVerification.update({
        where: { id: record.id },
        data: { verified: true },
      });

      return true;
    } catch (error) {
      console.error('OTP Verification Error:', error);
      return false;
    }
  }
}

export default new OtpService();
