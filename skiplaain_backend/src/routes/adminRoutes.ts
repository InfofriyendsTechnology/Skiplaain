import { Router } from 'express';
import {
  getSettings,
  updateSettings,
  getPlans,
  createPlan,
  updatePlan,
  deletePlan,
  updatePartnerCommission,
  getRevenue,
  generatePayouts,
  getPayouts,
  markPayoutPaid,
  getPendingPayoutsSummary,
} from '../controllers/adminController';
import { authenticate, requireRole } from '../middleware/auth';

const router = Router();

// All admin routes require admin role
router.use(authenticate, requireRole(['admin']));

// Settings
router.get('/settings', getSettings);
router.put('/settings', updateSettings);

// Plans CRUD
router.get('/plans', getPlans);
router.post('/plans', createPlan);
router.put('/plans/:id', updatePlan);
router.delete('/plans/:id', deletePlan);

// Partner commission
router.put('/partners/:id/commission', updatePartnerCommission);

// Revenue
router.get('/revenue', getRevenue);

// Payouts
router.post('/payouts/generate', generatePayouts);
router.get('/payouts/pending-summary', getPendingPayoutsSummary);
router.get('/payouts', getPayouts);
router.post('/payouts/:id/mark-paid', markPayoutPaid);

export default router;
