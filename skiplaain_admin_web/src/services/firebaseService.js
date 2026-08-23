import { collection, getDocs, doc, updateDoc, onSnapshot, query, orderBy, limit } from 'firebase/firestore';
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

// Get all bookings
export const getBookings = async () => {
  const snapshot = await getDocs(collection(db, 'bookings'));
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

// Listen to bookings in real-time
export const onBookingsSnapshot = (callback) => {
  const q = query(collection(db, 'bookings'), orderBy('createdAt', 'desc'), limit(50));
  return onSnapshot(q, (snapshot) => {
    const bookings = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    callback(bookings);
  });
};
