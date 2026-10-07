import { Router } from 'express';
import authRoutes from './authRoutes';
import partnerRoutes from './partnerRoutes';
import bookingRoutes from './bookingRoutes';
import customerRoutes from './customerRoutes';
import membershipRoutes from './membershipRoutes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/partners', partnerRoutes);
router.use('/bookings', bookingRoutes);
router.use('/customers', customerRoutes);
router.use('/memberships', membershipRoutes);

export default router;
