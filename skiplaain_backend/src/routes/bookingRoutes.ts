import { Router } from 'express';
import {
  getAllBookings,
  getBookingById,
  createBooking,
  updateBookingStatus,
  getCustomerBookings,
  getPartnerBookings,
} from '../controllers/bookingController';
import { authenticate, requireRole } from '../middleware/auth';

const router = Router();

// Customer creates booking
router.post('/', authenticate, requireRole(['customer']), createBooking);

// Protected routes
router.get('/', authenticate, requireRole(['admin']), getAllBookings);
router.get('/:id', authenticate, getBookingById); // Any authenticated user
router.patch('/:id/status', authenticate, updateBookingStatus);

// Scoped routes
router.get('/customer/:phone', authenticate, getCustomerBookings); // Customer sees own, admin sees all
router.get('/partner/:partnerId', authenticate, getPartnerBookings); // Partner sees own, admin sees all

export default router;
