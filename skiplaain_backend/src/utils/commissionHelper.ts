/**
 * Resolve commission percentage for a partner
 * Uses partner override if set, otherwise platform default
 */
export function resolveCommissionPercent(
  partnerOverride: number | null | undefined,
  platformDefault: number
): number {
  return partnerOverride ?? platformDefault;
}

/**
 * Calculate commission in paise
 */
export function calculateCommissionPaise(pricePaise: number, commissionPercent: number): number {
  return Math.round((pricePaise * commissionPercent) / 100);
}
