import { Router } from 'express';
import {
  getPlansForSalon,
  getSubscriptionStatus,
  createOrder,
  verifyPayment,
  getMySubscriptions,
} from '../controllers/subscriptionController';
import { authenticate, requireRole } from '../middleware/auth';
import { rateLimiter } from '../middleware/rateLimiter';

const router = Router();

// Customer routes with rate limiting on payment endpoints
router.get('/my', authenticate, requireRole(['customer']), getMySubscriptions);
router.get('/status', authenticate, requireRole(['customer']), getSubscriptionStatus);
router.post('/order', authenticate, requireRole(['customer']), rateLimiter, createOrder);
router.post('/verify', authenticate, requireRole(['customer']), rateLimiter, verifyPayment);

export default router;
