import api from './apiClient';

// ============================================
// AUTH APIs
// ============================================

export const sendOtp = async (phone) => {
  const { data } = await api.post('/auth/send-otp', { phone, purpose: 'login' });
  return data;
};

export const verifyOtp = async (phone, otp) => {
  const { data } = await api.post('/auth/verify-otp', {
    phone,
    otp,
    userType: 'admin',
  });
  return data;
};

// ============================================
// PARTNER APIs
// ============================================

export const getPartners = async (status = null) => {
  const url = status ? `/partners?status=${status}` : '/partners';
  const { data } = await api.get(url);
  return data.data || [];
};

export const getPartnerById = async (id) => {
  const { data } = await api.get(`/partners/${id}`);
  return data.data;
};

export const updatePartnerStatus = async (partnerId, status) => {
  const { data } = await api.patch(`/partners/${partnerId}/status`, { status });
  return data.data;
};

export const deletePartner = async (partnerId) => {
  const { data } = await api.delete(`/partners/${partnerId}`);
  return data;
};

export const updatePartner = async (partnerId, updateData) => {
  const { data } = await api.put(`/partners/${partnerId}`, updateData);
  return data.data;
};

// ============================================
// BOOKING APIs
// ============================================

export const getBookings = async (status = null) => {
  const url = status ? `/bookings?status=${status}` : '/bookings';
  const { data } = await api.get(url);
  return data.data || [];
};

export const getBookingById = async (id) => {
  const { data } = await api.get(`/bookings/${id}`);
  return data.data;
};

export const updateBookingStatus = async (bookingId, status, cancelReason = null) => {
  const { data } = await api.patch(`/bookings/${bookingId}/status`, {
    status,
    ...(cancelReason && { cancelReason }),
  });
  return data.data;
};

// ============================================
// CUSTOMER APIs
// ============================================

export const getCustomers = async () => {
  const { data } = await api.get('/customers');
  return data.data || [];
};

export const getCustomerByPhone = async (phone) => {
  const { data } = await api.get(`/customers/${phone}`);
  return data.data;
};

// ============================================
// MEMBERSHIP APIs
// ============================================

export const getMemberships = async (status = null) => {
  const url = status ? `/memberships?status=${status}` : '/memberships';
  const { data } = await api.get(url);
  return data.data || [];
};

export const getMembershipById = async (id) => {
  const { data } = await api.get(`/memberships/${id}`);
  return data.data;
};

// ============================================
// REAL-TIME POLLING (Replaces Firebase Listeners)
// ============================================

// Polling function for real-time updates
export const createPollingListener = (fetchFunction, callback, intervalMs = 5000) => {
  let intervalId;
  let isActive = true;

  const poll = async () => {
    if (!isActive) return;
    
    try {
      const data = await fetchFunction();
      if (isActive) {
        callback(data);
      }
    } catch (error) {
      console.error('Polling error:', error);
    }
  };

  // Initial fetch
  poll();

  // Start polling
  intervalId = setInterval(poll, intervalMs);

  // Return cleanup function
  return () => {
    isActive = false;
    clearInterval(intervalId);
  };
};

// Real-time listeners using polling
export const onPartnersSnapshot = (callback, status = null) => {
  return createPollingListener(() => getPartners(status), callback);
};

export const onBookingsSnapshot = (callback, status = null) => {
  return createPollingListener(() => getBookings(status), callback);
};

export const onCustomersSnapshot = (callback) => {
  return createPollingListener(getCustomers, callback);
};

export const onMembershipsSnapshot = (callback, status = null) => {
  return createPollingListener(() => getMemberships(status), callback);
};

// ============================================
// ADMIN OPERATIONS (Batch Delete for Testing)
// ============================================

export const clearAllBookings = async () => {
  // This would need a backend endpoint for batch delete
  const bookings = await getBookings();
  // For now, delete one by one (implement batch endpoint in backend later)
  await Promise.all(bookings.map(b => api.delete(`/bookings/${b.id}`)));
  return bookings.length;
};

export const clearAllCustomers = async () => {
  const customers = await getCustomers();
  // Backend should handle cascade delete
  await Promise.all(customers.map(c => api.delete(`/customers/${c.phone}`)));
  return customers.length;
};

export const clearAllMemberships = async () => {
  const memberships = await getMemberships();
  await Promise.all(memberships.map(m => api.delete(`/memberships/${m.id}`)));
  return memberships.length;
};

export const purgeAllTestData = async () => {
  const [bCount, cCount, mCount] = await Promise.all([
    clearAllBookings(),
    clearAllCustomers(),
    clearAllMemberships(),
  ]);

  return { bCount, cCount, mCount };
};
