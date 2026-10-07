import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const createPartner = async (req: Request, res: Response) => {
  try {
    const {
      phone,
      ownerName,
      salonName,
      address,
      city,
      pincode,
      email,
      latitude,
      longitude,
      profileImage,
      barbers = [],
      services = [],
    } = req.body;

    // Check if partner already exists
    const existing = await prisma.partner.findUnique({ where: { phone } });
    if (existing) {
      return responseHandler.badRequest(res, 'Partner with this phone already exists');
    }

    // Create partner with barbers and services
    const partner = await prisma.partner.create({
      data: {
        phone,
        ownerName,
        salonName,
        address,
        city,
        pincode,
        email,
        latitude,
        longitude,
        profileImage,
        status: 'pending',
        barbers: {
          create: barbers.map((b: any) => ({
            name: b.name,
            phone: b.phone,
            specialty: b.specialty,
            image: b.image,
          })),
        },
        services: {
          create: services.map((s: any) => ({
            name: s.name,
            price: s.price,
            duration: s.duration || 30,
            description: s.description,
            category: s.category,
            image: s.image,
          })),
        },
      },
      include: {
        barbers: true,
        services: true,
      },
    });

    return responseHandler.created(res, partner, 'Partner registered successfully. Pending approval.');
  } catch (error) {
    console.error('Create Partner Error:', error);
    return responseHandler.error(res, 'Failed to create partner');
  }
};
