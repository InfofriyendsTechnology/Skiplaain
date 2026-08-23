import { useState, useEffect } from 'react';
import { useOutletContext } from 'react-router-dom';
import { FiUsers, FiCalendar, FiDollarSign, FiTrendingUp, FiInbox } from 'react-icons/fi';
import { motion } from 'framer-motion';
import Navbar from '../../components/layout/Navbar';
import StatCard from '../../components/common/StatCard';
import { onPartnersSnapshot } from '../../services/firebaseService';
import './DashboardOverview.scss';

const DashboardOverview = () => {
  const [partners, setPartners] = useState([]);
  const { onMenuClick } = useOutletContext() || {};

  useEffect(() => {
    const unsubscribe = onPartnersSnapshot((data) => {
      setPartners(data);
    });
    return () => unsubscribe && unsubscribe();
  }, []);

  const totalPartners = partners.length;
  const verifiedPartners = partners.filter(p => p.status === 'verified').length;
  const pendingPartners = partners.filter(p => !p.status || p.status === 'pending').length;

  return (
    <>
      <Navbar
        title="Dashboard"
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
            icon={<FiTrendingUp />}
            label="Verified Partners"
            value={verifiedPartners}
          />
          <StatCard
            icon={<FiCalendar />}
            label="Pending Approval"
            value={pendingPartners}
          />
          <StatCard
            icon={<FiDollarSign />}
            label="Total Revenue"
            value="₹0"
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
            <h3 className="data-table-title">Recent Partners</h3>
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
                  {partners.slice(0, 8).map((partner) => (
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
                When salon owners register via the Partner App, they'll appear here in real-time.
              </p>
            </div>
          )}
        </motion.div>
      </div>
    </>
  );
};

export default DashboardOverview;
