import { Response } from 'express';
import { AuthRequest } from '../../middleware/auth';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';
import { generateBookingId } from '../../utils/idGenerator';

export const createBooking = async (req: AuthRequest, res: Response) => {
  try {
    // Require customer authentication
    if (!req.user) {
      return responseHandler.unauthorized(res, 'Authentication required');
    }

    if (req.user.type !== 'customer') {
      return responseHandler.forbidden(res, 'Customer access only');
    }

    const {
      salonId,
      salonName,
      salonPhone,
      salonAddress,
      selectedServices,
      totalAmount,
      bookingDate,
      timeSlot,
      barberId,
      barberName,
      specialInstructions,
    } = req.body;

    if (!salonId) {
      return responseHandler.badRequest(res, 'Salon ID is required');
    }

    // Find customer by phone from JWT (never trust client-provided customer data)
    let customer = await prisma.customer.findUnique({ 
      where: { phone: req.user.phone } 
    });

    if (!customer) {
      // Create customer if not exists (use name from JWT or body)
      customer = await prisma.customer.create({
        data: {
          phone: req.user.phone,
          name: req.user.name || req.body.customerName || 'Guest',
          activeSalonId: salonId,
        },
      });
    }

    // Check if partner exists and is active
    const partner = await prisma.partner.findUnique({
      where: { id: salonId },
      select: { id: true, plansEnabled: true, status: true }
    });

    if (!partner) {
      return responseHandler.notFound(res, 'Salon not found');
    }

    // Reject if partner is blocked or pending
    if (partner.status === 'blocked') {
      return responseHandler.forbidden(res, 'This salon is currently blocked and cannot accept bookings');
    }

    if (partner.status === 'pending') {
      return responseHandler.forbidden(res, 'This salon is pending approval and cannot accept bookings yet');
    }

    // If salon has subscription plans enabled, check for active subscription
    if (partner.plansEnabled) {
      const now = new Date();
      const activeSubscription = await prisma.membership.findFirst({
        where: {
          customerId: customer.id,
          partnerId: salonId,
          status: 'active',
          expiresAt: { gt: now }
        }
      });

      if (!activeSubscription) {
        return res.status(402).json({
          success: false,
          code: 'SUBSCRIPTION_REQUIRED',
          message: 'Active subscription required for this salon',
          data: null
        });
      }
    }

    // Generate collision-safe booking ID
    const bookingId = await generateBookingId(prisma);

    // Create booking with services
    const booking = await prisma.booking.create({
      data: {
        bookingId,
        partnerId: salonId,
        customerId: customer.id,
        barberId: barberId || null,
        customerName: customer.name,
        customerPhone: customer.phone,
        salonName,
        salonPhone,
        salonAddress,
        barberName: barberName || 'Any Available Barber',
        totalAmount,
        bookingDate,
        timeSlot,
        specialInstructions,
        status: 'confirmed',
        services: {
          create: selectedServices.map((service: any) => ({
            serviceId: service.id,
            name: service.name,
            price: service.price,
            duration: service.duration || 30,
          })),
        },
      },
      include: {
        services: true,
      },
    });

    // Update partner stats (only increment appointments, NOT totalEarnings)
    await prisma.partner.update({
      where: { id: salonId },
      data: {
        totalAppointments: { increment: 1 },
      },
    });

    return responseHandler.created(res, booking, 'Booking created successfully');
  } catch (error) {
    console.error('Create Booking Error:', error);
    return responseHandler.error(res, 'Failed to create booking');
  }
};
