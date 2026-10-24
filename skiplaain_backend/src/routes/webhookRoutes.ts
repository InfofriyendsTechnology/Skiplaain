import { Router } from 'express';
import { handleWebhook } from '../controllers/subscriptionController';

const router = Router();

// Webhook endpoint (no auth - verified by signature)
router.post('/razorpay', handleWebhook);

export default router;
