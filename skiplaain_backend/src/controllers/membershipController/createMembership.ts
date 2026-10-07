import { Request, Response } from 'express';
import prisma from '../../utils/prisma';
import responseHandler from '../../utils/responseHandler';

export const createMembership = async (req: Request, res: Response) => {
  try {
    const {
      salonId,
      salonName,
      customerPhone,
      customerName,
      planName,
      price,
      durationMonths,
    } = req.body;

    const membershipId = `VIP-${Date.now().toString().substring(7)}`;
    const now = new Date();
    const expiresAt = new Date(now.getTime() + durationMonths * 30 * 24 * 60 * 60 * 1000);

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

    const membership = await prisma.membership.create({
      data: {
        membershipId,
        partnerId: salonId,
        customerId: customer.id,
        salonName,
        customerName,
        customerPhone,
        planName,
        price,
        durationMonths,
        status: 'active',
        activatedAt: now,
        expiresAt,
      },
    });

    return responseHandler.created(res, membership, 'Membership created successfully');
  } catch (error) {
    console.error('Create Membership Error:', error);
    return responseHandler.error(res, 'Failed to create membership');
  }
};
