import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';
import { verifyPaymentSignature } from '../../utils/razorpayHelper';
import { generateMembershipId } from '../../utils/idGenerator';
import { resolveCommissionPercent, calculateCommissionPaise } from '../../utils/commissionHelper';

/**
 * POST /api/subscriptions/verify
 * Verify Razorpay payment and activate subscription
 * Body: { orderId, paymentId, signature }
 * Requires customer JWT
 * This endpoint is idempotent - multiple calls with same orderId won't create duplicates
 */
export const verifyPayment = async (req: AuthRequest, res: Response) => {
  try {
    const { orderId, paymentId, signature } = req.body;

    if (!req.user) {
      return responseHandler.unauthorized(res, 'Authentication required');
    }

    if (req.user.type !== 'customer') {
      return responseHandler.forbidden(res, 'Customer access only');
    }

    if (!orderId || !paymentId || !signature) {
      return responseHandler.badRequest(res, 'Order ID, Payment ID and Signature are required');
    }

    // Find customer
    const customer = await prisma.customer.findUnique({
      where: { phone: req.user.phone }
    });

    if (!customer) {
      return responseHandler.notFound(res, 'Customer not found');
    }

    // Find payment record by orderId
    const payment = await prisma.payment.findUnique({
      where: { razorpayOrderId: orderId },
      include: {
        plan: true
      }
    });

    if (!payment) {
      return responseHandler.notFound(res, 'Payment record not found');
    }

    // Check if payment belongs to this customer
    if (payment.customerId !== customer.id) {
      return responseHandler.forbidden(res, 'Unauthorized access to payment');
    }

    // Idempotency check: if already verified, return existing membership
    if (payment.status === 'paid' && payment.razorpayPaymentId === paymentId) {
      const existingMembership = await prisma.membership.findFirst({
        where: { paymentId: payment.id },
        include: { plan: true }
      });

      if (existingMembership) {
        return responseHandler.success(res, {
          membership: existingMembership,
          message: 'Payment already verified'
        }, 'Subscription already active');
      }
    }

    // Verify signature
    const isValid = verifyPaymentSignature(
      orderId,
      paymentId,
      signature,
      process.env.RAZORPAY_KEY_SECRET || ''
    );

    if (!isValid) {
      return responseHandler.badRequest(res, 'Invalid payment signature');
    }

    // Use transaction to ensure atomicity
    const result = await prisma.$transaction(async (tx: any) => {
      // Update payment status
      const updatedPayment = await tx.payment.update({
        where: { id: payment.id },
        data: {
          razorpayPaymentId: paymentId,
          razorpaySignature: signature,
          status: 'paid',
          paidAt: new Date()
        }
      });

      // Calculate commission
      const partner = await tx.partner.findUnique({
        where: { id: payment.partnerId }
      });

      if (!partner) {
        throw new Error('Partner not found');
      }

      const settings = await tx.platformSettings.findUnique({
        where: { id: 'default' }
      });

      if (!settings) {
        throw new Error('Platform settings not found');
      }

      const commissionPercent = resolveCommissionPercent(partner.commissionPercentOverride, settings.commissionPercent);
      const commissionPaise = calculateCommissionPaise(payment.amountPaise, commissionPercent);

      // Check for existing active subscription for stacking
      const now = new Date();
      const existingSubscription = await tx.membership.findFirst({
        where: {
          customerId: customer.id,
          partnerId: payment.partnerId,
          status: 'active',
          expiresAt: { gt: now }
        },
        orderBy: { expiresAt: 'desc' }
      });

      // Calculate start and end dates
      let startsAt = now;
      let expiresAt = new Date(now);

      if (existingSubscription) {
        // Stack: new plan starts when current plan expires
        startsAt = existingSubscription.expiresAt;
        expiresAt = new Date(existingSubscription.expiresAt);
      }

      expiresAt.setMonth(expiresAt.getMonth() + payment.plan.durationMonths);

      // Generate unique membership ID
      const membershipId = await generateMembershipId(tx as any);

      // Create membership record
      const membership = await tx.membership.create({
        data: {
          membershipId,
          customerId: customer.id,
          partnerId: payment.partnerId,
          planId: payment.plan.id,
          paymentId: payment.id,
          salonName: partner.salonName,
          customerName: customer.name,
          customerPhone: customer.phone,
          planName: payment.plan.name,
          price: Math.round(payment.amountPaise / 100),
          pricePaise: payment.amountPaise,
          durationMonths: payment.plan.durationMonths,
          commissionPercent,
          commissionPaise,
          status: 'active',
          activatedAt: now,
          startsAt,
          expiresAt
        },
        include: {
          plan: true,
          payment: true
        }
      });

      // Create commission ledger entry
      await tx.commissionLedger.create({
        data: {
          membershipId: membership.id,
          paymentId: payment.id,
          partnerId: payment.partnerId,
          grossPaise: payment.amountPaise,
          commissionPercent,
          commissionPaise,
          status: 'pending',
          earnedAt: now
        }
      });

      return membership;
    });

    return responseHandler.success(res, {
      membership: result
    }, 'Subscription activated successfully');

  } catch (error) {
    console.error('Verify Payment Error:', error);
    return responseHandler.error(res, 'Failed to verify payment');
  }
};
