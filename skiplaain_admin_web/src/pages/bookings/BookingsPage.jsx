import { useState, useEffect } from 'react';
import { useOutletContext } from 'react-router-dom';
import { motion } from 'framer-motion';
import { FiCalendar, FiUserCheck, FiTrash2 } from 'react-icons/fi';
import Navbar from '../../components/layout/Navbar';
import { onBookingsSnapshot, clearAllBookings } from '../../services/firebaseService';
import toast from 'react-hot-toast';
import './BookingsPage.scss';

const BookingsPage = () => {
  const [bookings, setBookings] = useState([]);
  const [filter, setFilter] = useState('All');
  const [isClearing, setIsClearing] = useState(false);
  const { onMenuClick } = useOutletContext() || {};

  useEffect(() => {
    const unsubscribe = onBookingsSnapshot((data) => {
      setBookings(data);
    });
    return () => unsubscribe && unsubscribe();
  }, []);

  const handleClearHistory = async () => {
    if (bookings.length === 0) {
      toast.error('No bookings to clear.');
      return;
    }
    if (!window.confirm(`⚠️ Are you sure you want to delete all ${bookings.length} booking(s)? This will permanently clear booking history.`)) return;

    setIsClearing(true);
    try {
      const count = await clearAllBookings();
      toast.success(`Cleared ${count} booking(s) successfully!`);
    } catch (err) {
      toast.error('Failed to clear bookings: ' + err.message);
    } finally {
      setIsClearing(false);
    }
  };

  const filters = ['All', 'Confirmed', 'Pending', 'Completed', 'Cancelled'];

  const filteredBookings = bookings.filter(b => {
    return filter === 'All' || (b.status || '').toLowerCase() === filter.toLowerCase();
  });

  return (
    <>
      <Navbar
        title="Live Bookings"
        subtitle={`${bookings.length} total platform bookings`}
        onMenuClick={onMenuClick}
      />
      <div className="page-container">
        <div className="filters-row">
          {filters.map(f => (
            <button key={f} className={`filter-chip ${filter === f ? 'active' : ''}`} onClick={() => setFilter(f)}>
              {f}
            </button>
          ))}
        </div>

        <motion.div className="data-table-wrapper" initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.4 }}>
          <div className="data-table-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <h3 className="data-table-title">All Bookings</h3>
              <span className="data-table-count">{filteredBookings.length} bookings</span>
            </div>
            {bookings.length > 0 && (
              <button 
                className="btn btn-danger btn-sm" 
                onClick={handleClearHistory}
                disabled={isClearing}
                style={{ padding: '6px 12px', fontSize: 12 }}
              >
                <FiTrash2 /> Clear All History
              </button>
            )}
          </div>
          {filteredBookings.length > 0 ? (
            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Customer</th>
                    <th>Salon</th>
                    <th>Barber / Specialist</th>
                    <th>Service</th>
                    <th>Amount</th>
                    <th>Date & Time</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredBookings.map((booking) => (
                    <tr key={booking.id}>
                      <td className="td-primary">{booking.customerName || '—'}</td>
                      <td>{booking.salonName || '—'}</td>
                      <td>
                        <span className="barber-badge">
                          <FiUserCheck style={{ marginRight: 4 }} />
                          {booking.barberName || 'Any Available'}
                        </span>
                      </td>
                      <td>{booking.service || '—'}</td>
                      <td className="td-accent">₹{booking.totalAmount || booking.price || '0'}</td>
                      <td>{booking.bookingDate ? `${booking.bookingDate}, ` : ''}{booking.timeSlot || booking.time || '—'}</td>
                      <td>
                        <span className={`badge ${(booking.status || 'pending').toLowerCase()}`}>
                          {booking.status || 'Pending'}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="empty-state">
              <div className="empty-state-icon">
                <FiCalendar />
              </div>
              <h4 className="empty-state-title">No Bookings Yet</h4>
              <p className="empty-state-desc">Bookings will appear here in real-time when customers book appointments.</p>
            </div>
          )}
        </motion.div>
      </div>
    </>
  );
};

export default BookingsPage;
