import { PrismaClient } from '@prisma/client';

const BASE32_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed confusing chars: I, O, 0, 1

/**
 * Generate a random base32 string
 * @param length Length of the string (6-8 recommended)
 * @returns Random base32 string
 */
function generateRandomBase32(length: number): string {
  let result = '';
  for (let i = 0; i < length; i++) {
    result += BASE32_CHARS.charAt(Math.floor(Math.random() * BASE32_CHARS.length));
  }
  return result;
}

/**
 * Generate a collision-safe SKP booking ID
 * @param prisma Prisma client instance
 * @param maxRetries Maximum retry attempts (default: 5)
 * @returns Unique SKP-XXXXXX booking ID
 */
export async function generateBookingId(
  prisma: PrismaClient,
  maxRetries: number = 5
): Promise<string> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const randomPart = generateRandomBase32(6);
    const bookingId = `SKP-${randomPart}`;
    
    // Check if this ID already exists
    const existing = await prisma.booking.findUnique({
      where: { bookingId },
      select: { bookingId: true }
    });
    
    if (!existing) {
      return bookingId;
    }
  }
  
  // If all retries failed, use 8 characters
  const randomPart = generateRandomBase32(8);
  const bookingId = `SKP-${randomPart}`;
  
  // Final check
  const existing = await prisma.booking.findUnique({
    where: { bookingId },
    select: { bookingId: true }
  });
  
  if (existing) {
    throw new Error('Failed to generate unique booking ID after maximum retries');
  }
  
  return bookingId;
}

/**
 * Generate a collision-safe VIP membership ID
 * @param prisma Prisma client instance
 * @param maxRetries Maximum retry attempts (default: 5)
 * @returns Unique VIP-XXXXXX membership ID
 */
export async function generateMembershipId(
  prisma: PrismaClient,
  maxRetries: number = 5
): Promise<string> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const randomPart = generateRandomBase32(6);
    const membershipId = `VIP-${randomPart}`;
    
    // Check if this ID already exists
    const existing = await prisma.membership.findUnique({
      where: { membershipId },
      select: { membershipId: true }
    });
    
    if (!existing) {
      return membershipId;
    }
  }
  
  // If all retries failed, use 8 characters
  const randomPart = generateRandomBase32(8);
  const membershipId = `VIP-${randomPart}`;
  
  // Final check
  const existing = await prisma.membership.findUnique({
    where: { membershipId },
    select: { membershipId: true }
  });
  
  if (existing) {
    throw new Error('Failed to generate unique membership ID after maximum retries');
  }
  
  return membershipId;
}
