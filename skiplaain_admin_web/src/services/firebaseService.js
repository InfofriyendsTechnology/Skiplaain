import { 
  collection, 
  getDocs, 
  doc, 
  updateDoc, 
  deleteDoc, 
  onSnapshot, 
  query, 
  orderBy, 
  limit, 
  writeBatch 
} from 'firebase/firestore';
import { db } from '../config/firebase';

// Get all partners
export const getPartners = async () => {
  const snapshot = await getDocs(collection(db, 'partners'));
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

// Listen to partners in real-time
export const onPartnersSnapshot = (callback) => {
  const q = query(collection(db, 'partners'), orderBy('createdAt', 'desc'));
  return onSnapshot(q, (snapshot) => {
    const partners = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    callback(partners);
  });
};

// Update partner status (approve / block / pending)
export const updatePartnerStatus = async (partnerId, status) => {
  const ref = doc(db, 'partners', partnerId);
  await updateDoc(ref, { status });
};

// Delete a specific barber from a salon partner
export const deletePartnerBarber = async (partnerId, barberId) => {
  const partnerRef = doc(db, 'partners', partnerId);
  const snapshot = await getDocs(collection(db, 'partners'));
  const partnerDoc = snapshot.docs.find(d => d.id === partnerId);
  
  if (partnerDoc) {
    const barbers = partnerDoc.data().barbers || [];
    const updatedBarbers = barbers.filter(b => b.id !== barberId);
    await updateDoc(partnerRef, { barbers: updatedBarbers });
    return updatedBarbers;
  }
};

// Clear all barbers from a salon partner
export const clearSalonBarbers = async (partnerId) => {
  const ref = doc(db, 'partners', partnerId);
  await updateDoc(ref, { barbers: [] });
};

// Delete an entire salon partner
export const deletePartner = async (partnerId) => {
  const ref = doc(db, 'partners', partnerId);
  await deleteDoc(ref);
};

// Get all bookings
export const getBookings = async () => {
  const snapshot = await getDocs(collection(db, 'bookings'));
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

// Listen to bookings in real-time
export const onBookingsSnapshot = (callback) => {
  const q = query(collection(db, 'bookings'), orderBy('createdAt', 'desc'), limit(100));
  return onSnapshot(q, (snapshot) => {
    const bookings = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    callback(bookings);
  });
};

// Listen to customers in real-time
export const onCustomersSnapshot = (callback) => {
  const q = collection(db, 'customers');
  return onSnapshot(q, (snapshot) => {
    const customers = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    callback(customers);
  });
};

// Listen to VIP memberships in real-time
export const onMembershipsSnapshot = (callback) => {
  const q = collection(db, 'memberships');
  return onSnapshot(q, (snapshot) => {
    const memberships = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    callback(memberships);
  });
};

// Helper to batch delete all documents in a collection
export const clearCollection = async (collectionName) => {
  const snapshot = await getDocs(collection(db, collectionName));
  if (snapshot.empty) return 0;

  const batch = writeBatch(db);
  snapshot.docs.forEach((docItem) => {
    batch.delete(docItem.ref);
  });
  await batch.commit();
  return snapshot.size;
};

// Purge all bookings history
export const clearAllBookings = async () => {
  return await clearCollection('bookings');
};

// Purge all customers data
export const clearAllCustomers = async () => {
  return await clearCollection('customers');
};

// Purge all memberships data
export const clearAllMemberships = async () => {
  return await clearCollection('memberships');
};

// Purge full test database (bookings, customers, memberships, and clear barbers)
export const purgeAllTestData = async () => {
  const [bCount, cCount, mCount] = await Promise.all([
    clearCollection('bookings'),
    clearCollection('customers'),
    clearCollection('memberships')
  ]);

  // Also clear barbers across all partners
  const partnersSnapshot = await getDocs(collection(db, 'partners'));
  if (!partnersSnapshot.empty) {
    const batch = writeBatch(db);
    partnersSnapshot.docs.forEach((pDoc) => {
      batch.update(pDoc.ref, { barbers: [] });
    });
    await batch.commit();
  }

  return { bCount, cCount, mCount, partnersAffected: partnersSnapshot.size };
};
