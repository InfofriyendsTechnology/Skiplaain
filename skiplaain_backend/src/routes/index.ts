import { Router } from 'express';
import authRoutes from './authRoutes';
import partnerRoutes from './partnerRoutes';
import partnerEarningsRoutes from './partnerEarningsRoutes';
import bookingRoutes from './bookingRoutes';
import customerRoutes from './customerRoutes';
import membershipRoutes from './membershipRoutes';
import plansRoutes from './plansRoutes';
import subscriptionRoutes from './subscriptionRoutes';
import webhookRoutes from './webhookRoutes';
import adminRoutes from './adminRoutes';
import salonRoutes from './salonRoutes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/partners', partnerRoutes);
router.use('/partner', partnerEarningsRoutes);
router.use('/salons', salonRoutes);
router.use('/bookings', bookingRoutes);
router.use('/customers', customerRoutes);
router.use('/memberships', membershipRoutes);
router.use('/plans', plansRoutes);
router.use('/subscriptions', subscriptionRoutes);
router.use('/webhooks', webhookRoutes);
router.use('/admin', adminRoutes);

export default router;
