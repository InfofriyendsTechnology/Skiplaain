import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const createBooking = async (req: Request, res: Response) => {
  try {
    const {
      salonId,
      salonName,
      salonPhone,
      salonAddress,
      customerName,
      customerPhone,
      selectedServices,
      totalAmount,
      bookingDate,
      timeSlot,
      barberId,
      barberName,
      specialInstructions,
    } = req.body;

    // Generate booking ID
    const bookingId = `SKP-${Date.now().toString().substring(7)}`;

    // Find or create customer
    let customer = await prisma.customer.findUnique({ where: { phone: customerPhone } });
    if (!customer) {
      customer = await prisma.customer.create({
        data: {
          phone: customerPhone,
          name: customerName,
          activeSalonId: salonId,
        },
      });
    }

    // Create booking with services
    const booking = await prisma.booking.create({
      data: {
        bookingId,
        partnerId: salonId,
        customerId: customer.id,
        barberId: barberId || null,
        customerName,
        customerPhone,
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

    // Update partner stats
    await prisma.partner.update({
      where: { id: salonId },
      data: {
        totalAppointments: { increment: 1 },
        totalEarnings: { increment: totalAmount },
      },
    });

    return responseHandler.created(res, booking, 'Booking created successfully');
  } catch (error) {
    console.error('Create Booking Error:', error);
    return responseHandler.error(res, 'Failed to create booking');
  }
};
