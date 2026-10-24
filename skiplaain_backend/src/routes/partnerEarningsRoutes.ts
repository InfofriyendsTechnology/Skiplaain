import { Router } from 'express';
import { getEarnings, updatePayoutDetails } from '../controllers/partnerController';
import { authenticate, requireRole } from '../middleware/auth';

const router = Router();

// Partner-only routes
router.get('/earnings', authenticate, requireRole(['partner']), getEarnings);
router.put('/payout-details', authenticate, requireRole(['partner']), updatePayoutDetails);

export default router;
