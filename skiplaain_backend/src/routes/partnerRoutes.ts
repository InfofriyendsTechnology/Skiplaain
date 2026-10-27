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
import { addBarber, deleteBarber, clearAllBarbers } from '../controllers/partnerController/barberOperations';
import { authenticate, requireRole, requireOwnerOrAdmin } from '../middleware/auth';
import { authRateLimiter, rateLimiter } from '../middleware/rateLimiter';

const router = Router();

// Public routes (onboarding and check-phone)
router.post('/check-phone', authRateLimiter, checkPhone);
router.post('/', authRateLimiter, createPartner);

// Protected routes - admin or owner
router.get('/', authenticate, requireRole(['admin']), rateLimiter, getAllPartners);
router.get('/:id', authenticate, requireOwnerOrAdmin, rateLimiter, getPartnerById);
router.put('/:id', authenticate, requireOwnerOrAdmin, rateLimiter, updatePartner);
router.delete('/:id', authenticate, requireOwnerOrAdmin, rateLimiter, deletePartner);
router.patch('/:id/status', authenticate, requireRole(['admin']), rateLimiter, updatePartnerStatus);

// Barber management (admin or owner)
router.post('/:id/barbers', authenticate, requireOwnerOrAdmin, rateLimiter, addBarber);
router.delete('/:id/barbers/:barberId', authenticate, requireOwnerOrAdmin, rateLimiter, deleteBarber);
router.delete('/:id/barbers', authenticate, requireRole(['admin']), rateLimiter, clearAllBarbers);

export default router;
