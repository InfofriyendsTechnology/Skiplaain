import { Router } from 'express';
import {
  getAllMemberships,
  getMembershipById,
  getCustomerMembership,
} from '../controllers/membershipController';
import { authenticate, requireRole } from '../middleware/auth';

const router = Router();

// Admin only routes
router.get('/', authenticate, requireRole(['admin']), getAllMemberships);
router.get('/:id', authenticate, requireRole(['admin']), getMembershipById);

// DEPRECATED: Use /subscriptions/* endpoints instead
// router.post('/', authenticate, requireRole(['admin']), createMembership);

// Customer lookup
router.get('/customer/:phone/:salonId', authenticate, getCustomerMembership);

export default router;
