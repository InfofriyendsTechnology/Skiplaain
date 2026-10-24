import crypto from 'crypto';

/**
 * Verify Razorpay payment signature
 * @param orderId Razorpay order ID
 * @param paymentId Razorpay payment ID
 * @param signature Signature from client
 * @param secret Razorpay key secret
 * @returns true if signature is valid
 */
export function verifyPaymentSignature(
  orderId: string,
  paymentId: string,
  signature: string,
  secret: string
): boolean {
  const text = `${orderId}|${paymentId}`;
  const generatedSignature = crypto
    .createHmac('sha256', secret)
    .update(text)
    .digest('hex');
  
  return generatedSignature === signature;
}

/**
 * Verify Razorpay webhook signature
 * @param body Raw webhook body
 * @param signature Signature from webhook header
 * @param secret Razorpay webhook secret
 * @returns true if webhook is authentic
 */
export function verifyWebhookSignature(
  body: string,
  signature: string,
  secret: string
): boolean {
  const generatedSignature = crypto
    .createHmac('sha256', secret)
    .update(body)
    .digest('hex');
  
  return generatedSignature === signature;
}
