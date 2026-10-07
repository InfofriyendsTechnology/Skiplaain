import { Router } from 'express';
import { getAllCustomers, getCustomerByPhone, updateCustomer } from '../controllers/customerController';
import { authenticate } from '../middleware/auth';

const router = Router();

router.get('/', authenticate, getAllCustomers);
router.get('/:phone', authenticate, getCustomerByPhone);
router.put('/:phone', authenticate, updateCustomer);

export default router;
