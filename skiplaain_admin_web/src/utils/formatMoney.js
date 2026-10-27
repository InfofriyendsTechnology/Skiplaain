/**
 * Format paise to rupees with Indian grouping
 * @param {number} paise - Amount in paise (1 Rs = 100 paise)
 * @returns {string} Formatted amount with ₹ symbol and Indian grouping
 */
export function formatMoney(paise) {
  if (paise == null || isNaN(paise)) return '₹0.00';
  
  const rupees = paise / 100;
  
  // Indian number formatting: lakhs and crores
  return '₹' + rupees.toLocaleString('en-IN', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}

/**
 * Format paise to rupees as integer (no decimals)
 * @param {number} paise - Amount in paise
 * @returns {string} Formatted amount with ₹ symbol
 */
export function formatMoneyInt(paise) {
  if (paise == null || isNaN(paise)) return '₹0';
  
  const rupees = Math.round(paise / 100);
  
  return '₹' + rupees.toLocaleString('en-IN');
}
