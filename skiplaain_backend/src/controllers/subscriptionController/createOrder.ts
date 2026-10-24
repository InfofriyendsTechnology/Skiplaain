import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';
import Razorpay from 'razorpay';

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || '',
  key_secret: process.env.RAZORPAY_KEY_SECRET || ''
});

/**
 * POST /api/subscriptions/order
 * Create a Razorpay order for subscription purchase
 * Body: { planId, partnerId }
 * Requires customer JWT
 */
export const createOrder = async (req: AuthRequest, res: Response) => {
  try {
    const { planId, partnerId } = req.body;

    if (!req.user) {
      return responseHandler.unauthorized(res, 'Authentication required');
    }

    if (req.user.type !== 'customer') {
      return responseHandler.forbidden(res, 'Customer access only');
    }

    if (!planId || !partnerId) {
      return responseHandler.badRequest(res, 'Plan ID and Partner ID are required');
    }

    // Find customer
    const customer = await prisma.customer.findUnique({
      where: { phone: req.user.phone }
    });

    if (!customer) {
      return responseHandler.notFound(res, 'Customer not found');
    }

    // Verify partner exists
    const partner = await prisma.partner.findUnique({
      where: { id: partnerId }
    });

    if (!partner) {
      return responseHandler.notFound(res, 'Partner not found');
    }

    // Get plan details
    const plan = await prisma.subscriptionPlan.findUnique({
      where: { id: planId }
    });

    if (!plan || !plan.isActive) {
      return responseHandler.notFound(res, 'Plan not found or inactive');
    }

    // Get platform settings for commission percentage
    const settings = await prisma.platformSettings.findUnique({
      where: { id: 'default' }
    });

    if (!settings) {
      return responseHandler.error(res, 'Platform settings not configured');
    }

    // Use partner override if set, otherwise use platform default
    const commissionPercent = partner.commissionPercentOverride ?? settings.commissionPercent;

    // Create Razorpay order (amount in paise)
    const razorpayOrder = await razorpay.orders.create({
      amount: plan.pricePaise,
      currency: 'INR',
      receipt: `receipt_${customer.id}_${partnerId}_${Date.now()}`,
      notes: {
        customerId: customer.id,
        partnerId: partnerId,
        planId: plan.id,
        commissionPercent: commissionPercent.toString()
      }
    });

    // Create payment record in pending state
    const payment = await prisma.payment.create({
      data: {
        customerId: customer.id,
        partnerId: partnerId,
        planId: plan.id,
        razorpayOrderId: razorpayOrder.id,
        amountPaise: plan.pricePaise,
        currency: 'INR',
        status: 'created'
      }
    });

    return responseHandler.success(res, {
      orderId: razorpayOrder.id,
      amount: plan.pricePaise,
      currency: 'INR',
      paymentId: payment.id,
      planDetails: {
        id: plan.id,
        name: plan.name,
        durationMonths: plan.durationMonths,
        pricePaise: plan.pricePaise
      }
    }, 'Order created successfully');

  } catch (error) {
    console.error('Create Order Error:', error);
    return responseHandler.error(res, 'Failed to create order');
  }
};
