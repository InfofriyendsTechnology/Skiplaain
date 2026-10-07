import { Router } from 'express';
import {
  getAllPartners,
  getPartnerById,
  createPartner,
  updatePartner,
  deletePartner,
  updatePartnerStatus,
} from '../controllers/partnerController';
import { authenticate } from '../middleware/auth';

const router = Router();

// Public routes
router.get('/', getAllPartners);
router.get('/:id', getPartnerById);

// Protected routes
router.post('/', createPartner);
router.put('/:id', authenticate, updatePartner);
router.delete('/:id', authenticate, deletePartner);
router.patch('/:id/status', authenticate, updatePartnerStatus);

export default router;
