import { Router } from 'express';
import { getAllCustomers, getCustomerByPhone, updateCustomer, getMe, updateMe } from '../controllers/customerController';
import { authenticate, requireRole } from '../middleware/auth';

const router = Router();

// Customer self-service routes
router.get('/me', authenticate, requireRole(['customer']), getMe);
router.put('/me', authenticate, requireRole(['customer']), updateMe);

// Admin only routes
router.get('/', authenticate, requireRole(['admin']), getAllCustomers);
router.get('/:phone', authenticate, requireRole(['admin']), getCustomerByPhone);

// Customer or admin can update
router.put('/:phone', authenticate, updateCustomer);

export default router;
