import { Router } from 'express';
import {
  getAllMemberships,
  getMembershipById,
  createMembership,
  getCustomerMembership,
} from '../controllers/membershipController';
import { authenticate } from '../middleware/auth';

const router = Router();

router.get('/', authenticate, getAllMemberships);
router.get('/:id', authenticate, getMembershipById);
router.post('/', authenticate, createMembership);
router.get('/customer/:phone/:salonId', authenticate, getCustomerMembership);

export default router;
