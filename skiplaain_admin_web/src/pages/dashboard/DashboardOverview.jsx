import { useState, useEffect } from 'react';
import { useOutletContext, useNavigate } from 'react-router-dom';
import { FiUsers, FiCalendar, FiTrendingUp, FiAward, FiInbox, FiUserCheck } from 'react-icons/fi';
import { motion } from 'framer-motion';
import Navbar from '../../components/layout/Navbar';
import StatCard from '../../components/common/StatCard';
import { onPartnersSnapshot, onCustomersSnapshot, onBookingsSnapshot, onMembershipsSnapshot } from '../../services/firebaseService';
import './DashboardOverview.scss';

const DashboardOverview = () => {
  const [partners, setPartners] = useState([]);
  const [customers, setCustomers] = useState([]);
  const [bookings, setBookings] = useState([]);
  const [memberships, setMemberships] = useState([]);
  const { onMenuClick } = useOutletContext() || {};
  const navigate = useNavigate();

  useEffect(() => {
    const unsubPartners = onPartnersSnapshot(setPartners);
    const unsubCust = onCustomersSnapshot(setCustomers);
    const unsubBookings = onBookingsSnapshot(setBookings);
    const unsubMemberships = onMembershipsSnapshot(setMemberships);

    return () => {
      unsubPartners && unsubPartners();
      unsubCust && unsubCust();
      unsubBookings && unsubBookings();
      unsubMemberships && unsubMemberships();
    };
  }, []);

  const totalPartners = partners.length;
  const verifiedPartners = partners.filter(p => p.status === 'verified').length;
  const totalCustomers = customers.length;
  const totalBookings = bookings.length;
  const activeVipPasses = memberships.filter(m => m.status === 'active' || !m.status).length;

  return (
    <>
      <Navbar
        title="Super Admin Dashboard"
        subtitle={`${new Date().toLocaleDateString('en-IN', { weekday: 'long', day: 'numeric', month: 'short', year: 'numeric' })}`}
        onMenuClick={onMenuClick}
      />
      <div className="page-container">
        <div className="stats-grid">
          <StatCard
            icon={<FiUsers />}
            label="Total Partners"
            value={totalPartners}
          />
          <StatCard
            icon={<FiUserCheck />}
            label="Registered Customers"
            value={totalCustomers}
          />
          <StatCard
            icon={<FiCalendar />}
            label="Total Appointments"
            value={totalBookings}
          />
          <StatCard
            icon={<FiAward />}
            label="Active VIP Passes"
            value={activeVipPasses}
          />
        </div>

        {/* Recent Partners */}
        <motion.div
          className="data-table-wrapper"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
        >
          <div className="data-table-header">
            <h3 className="data-table-title">Partner Salons</h3>
            <span className="data-table-count">{totalPartners} total</span>
          </div>
          {partners.length > 0 ? (
            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Salon Name</th>
                    <th>Phone</th>
                    <th>Category</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {partners.slice(0, 6).map((partner) => (
                    <tr key={partner.id}>
                      <td className="td-primary">{partner.salonName || partner.businessName || '—'}</td>
                      <td>{partner.phone || '—'}</td>
                      <td>{partner.category || '—'}</td>
                      <td>
                        <span className={`badge ${(partner.status || 'pending').toLowerCase()}`}>
                          {partner.status || 'Pending'}
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
                <FiInbox />
              </div>
              <h4 className="empty-state-title">No Partners Yet</h4>
              <p className="empty-state-desc">
                Partner salons will appear here once they register on the Partner App.
              </p>
            </div>
          )}
        </motion.div>
      </div>
    </>
  );
};

export default DashboardOverview;
