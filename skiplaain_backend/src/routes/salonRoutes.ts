import { Router } from 'express';
import { getAllSalons, getSalonById } from '../controllers/salonController';
import { authenticate, requireRole } from '../middleware/auth';

const router = Router();

// Customer-safe salon endpoints (approved partners only, no sensitive data)
router.get('/', authenticate, requireRole(['customer']), getAllSalons);
router.get('/:id', authenticate, requireRole(['customer']), getSalonById);

export default router;
