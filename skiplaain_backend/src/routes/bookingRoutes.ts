import { Router } from 'express';
import {
  getAllBookings,
  getBookingById,
  createBooking,
  updateBookingStatus,
  getCustomerBookings,
  getPartnerBookings,
} from '../controllers/bookingController';
import { authenticate } from '../middleware/auth';

const router = Router();

// Public booking creation
router.post('/', createBooking);

// Protected routes
router.get('/', authenticate, getAllBookings);
router.get('/:id', authenticate, getBookingById);
router.patch('/:id/status', authenticate, updateBookingStatus);
router.get('/customer/:phone', authenticate, getCustomerBookings);
router.get('/partner/:partnerId', authenticate, getPartnerBookings);

export default router;
