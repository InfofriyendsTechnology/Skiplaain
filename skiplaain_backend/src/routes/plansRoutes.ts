import { Router } from 'express';
import { getPlansForSalon } from '../controllers/subscriptionController';
import { authenticate } from '../middleware/auth';

const router = Router();

// Main plans endpoint (authenticated, requires salonId query param)
router.get('/', authenticate, getPlansForSalon);

export default router;
