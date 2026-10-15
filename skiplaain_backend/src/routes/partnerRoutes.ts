import { Router } from 'express';
import {
  getAllPartners,
  getPartnerById,
  createPartner,
  updatePartner,
  deletePartner,
  updatePartnerStatus,
  checkPhone,
} from '../controllers/partnerController';
import { authenticate } from '../middleware/auth';
import { authRateLimiter, rateLimiter } from '../middleware/rateLimiter';

const router = Router();

// Phone check endpoint (for smart auth flow)
router.post('/check-phone', authRateLimiter, checkPhone);

// Public routes
router.get('/', rateLimiter, getAllPartners);
router.get('/:id', rateLimiter, getPartnerById);

// Protected routes with rate limiting
router.post('/', authRateLimiter, createPartner);
router.put('/:id', authenticate, rateLimiter, updatePartner);
router.delete('/:id', authenticate, rateLimiter, deletePartner);
router.patch('/:id/status', authenticate, rateLimiter, updatePartnerStatus);

export default router;
