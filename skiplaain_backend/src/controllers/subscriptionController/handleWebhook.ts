import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';
import { verifyWebhookSignature } from '../../utils/razorpayHelper';

/**
 * POST /api/webhooks/razorpay
 * Handle Razorpay webhook events
 * This provides backup verification in case client-side verification fails
 */
export const handleWebhook = async (req: Request, res: Response) => {
  try {
    const signature = req.headers['x-razorpay-signature'];

    if (!signature || typeof signature !== 'string') {
      return responseHandler.badRequest(res, 'Missing webhook signature');
    }

    // Verify webhook signature
    const isValid = verifyWebhookSignature(
      JSON.stringify(req.body),
      signature,
      process.env.RAZORPAY_WEBHOOK_SECRET || ''
    );

    if (!isValid) {
      return responseHandler.badRequest(res, 'Invalid webhook signature');
    }

    const { event, payload } = req.body;

    // Handle payment.captured event
    if (event === 'payment.captured') {
      const { payment: razorpayPayment } = payload;

      // Find payment record by order ID
      const payment = await prisma.payment.findUnique({
        where: { razorpayOrderId: razorpayPayment.order_id }
      });

      if (!payment) {
        console.warn('Webhook: Payment record not found for order:', razorpayPayment.order_id);
        return res.status(200).json({ received: true });
      }

      // Update payment if not already captured
      if (payment.status !== 'paid') {
        await prisma.payment.update({
          where: { id: payment.id },
          data: {
            razorpayPaymentId: razorpayPayment.id,
            status: 'paid',
            paidAt: new Date(razorpayPayment.created_at * 1000)
          }
        });
      }
    }

    // Handle payment.failed event
    if (event === 'payment.failed') {
      const { payment: razorpayPayment } = payload;

      const payment = await prisma.payment.findUnique({
        where: { razorpayOrderId: razorpayPayment.order_id }
      });

      if (payment && payment.status === 'created') {
        await prisma.payment.update({
          where: { id: payment.id },
          data: {
            status: 'failed',
            razorpayPaymentId: razorpayPayment.id
          }
        });
      }
    }

    return res.status(200).json({ received: true });

  } catch (error) {
    console.error('Webhook Error:', error);
    return res.status(500).json({ error: 'Webhook processing failed' });
  }
};
