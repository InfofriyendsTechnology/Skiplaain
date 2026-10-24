import { useState, useEffect } from 'react';
import { useOutletContext, useNavigate } from 'react-router-dom';
import { FiUsers, FiCalendar, FiTrendingUp, FiAward, FiInbox, FiUserCheck, FiDollarSign } from 'react-icons/fi';
import { motion } from 'framer-motion';
import Navbar from '../../components/layout/Navbar';
import StatCard from '../../components/common/StatCard';
import { getRevenue } from '../../services/apiService';
import toast from 'react-hot-toast';
import './DashboardOverview.scss';

const DashboardOverview = () => {
  const [revenueData, setRevenueData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const { onMenuClick } = useOutletContext() || {};
  const navigate = useNavigate();

  useEffect(() => {
    fetchRevenue();
  }, []);

  const fetchRevenue = async () => {
    setLoading(true);
    try {
      const params = {};
      if (dateFrom) params.from = dateFrom;
      if (dateTo) params.to = dateTo;
      
      const data = await getRevenue(params);
      setRevenueData(data);
    } catch (err) {
      toast.error('Failed to load revenue data: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleApplyFilter = () => {
    if (dateFrom && dateTo && new Date(dateFrom) > new Date(dateTo)) {
      toast.error('Start date must be before end date');
      return;
    }
    fetchRevenue();
  };

  const handleClearFilter = () => {
    setDateFrom('');
    setDateTo('');
    // Auto-fetch after clearing
    setTimeout(() => fetchRevenue(), 100);
  };

  const formatCurrency = (paise) => {
    if (paise == null || isNaN(paise)) return '₹0.00';
    return `₹${(paise / 100).toFixed(2)}`;
  };

  if (loading) {
    return (
      <>
        <Navbar
          title="Revenue Dashboard"
          subtitle="Loading revenue data..."
          onMenuClick={onMenuClick}
        />
        <div className="page-container">
          <div style={{ textAlign: 'center', padding: '60px 20px', color: '#888' }}>
            Loading...
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <Navbar
        title="Revenue Dashboard"
        subtitle={`${new Date().toLocaleDateString('en-IN', { weekday: 'long', day: 'numeric', month: 'short', year: 'numeric' })}`}
        onMenuClick={onMenuClick}
      />
      <div className="page-container">
        {/* Date Range Filter */}
        <motion.div
          className="card"
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          style={{ padding: '16px 20px', marginBottom: 20 }}
        >
          <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap' }}>
            <label style={{ fontSize: 12, color: '#888', fontWeight: 600 }}>Date Range:</label>
            <input
              type="date"
              className="form-input"
              value={dateFrom}
              onChange={(e) => setDateFrom(e.target.value)}
              style={{ width: 160, fontSize: 13 }}
              placeholder="From"
            />
            <span style={{ color: '#666' }}>to</span>
            <input
              type="date"
              className="form-input"
              value={dateTo}
              onChange={(e) => setDateTo(e.target.value)}
              style={{ width: 160, fontSize: 13 }}
              placeholder="To"
            />
            <button className="btn btn-primary btn-sm" onClick={handleApplyFilter}>
              Apply Filter
            </button>
            {(dateFrom || dateTo) && (
              <button className="btn btn-ghost btn-sm" onClick={handleClearFilter}>
                Clear
              </button>
            )}
          </div>
        </motion.div>

        {/* Revenue Stats */}
        <div className="stats-grid">
          <StatCard
            icon={<FiDollarSign />}
            label="Total Sales"
            value={formatCurrency(revenueData?.totalSales || 0)}
          />
          <StatCard
            icon={<FiTrendingUp />}
            label="Commission Owed"
            value={formatCurrency(revenueData?.commissionOwed || 0)}
          />
          <StatCard
            icon={<FiAward />}
            label="Commission Paid"
            value={formatCurrency(revenueData?.commissionPaid || 0)}
          />
          <StatCard
            icon={<FiUsers />}
            label="Platform Net"
            value={formatCurrency(revenueData?.platformNet || 0)}
          />
        </div>

        {/* By-Salon Revenue Breakdown */}
        <motion.div
          className="data-table-wrapper"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
        >
          <div className="data-table-header">
            <h3 className="data-table-title">Revenue by Salon</h3>
            <span className="data-table-count">{revenueData?.bySalon?.length || 0} salons</span>
          </div>
          {revenueData?.bySalon && revenueData.bySalon.length > 0 ? (
            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Salon Name</th>
                    <th>Total Sales</th>
                    <th>Commission Owed</th>
                    <th>Commission Paid</th>
                    <th>Platform Net</th>
                  </tr>
                </thead>
                <tbody>
                  {revenueData.bySalon.map((salon, idx) => (
                    <tr key={idx}>
                      <td className="td-primary">{salon.salonName || '—'}</td>
                      <td>{formatCurrency(salon.totalSales)}</td>
                      <td style={{ color: '#f59e0b' }}>{formatCurrency(salon.commissionOwed)}</td>
                      <td style={{ color: '#10b981' }}>{formatCurrency(salon.commissionPaid)}</td>
                      <td style={{ color: '#00ff00' }}>{formatCurrency(salon.platformNet)}</td>
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
              <h4 className="empty-state-title">No Revenue Data</h4>
              <p className="empty-state-desc">
                Revenue data will appear here once payments are processed.
              </p>
            </div>
          )}
        </motion.div>
      </div>
    </>
  );
};

export default DashboardOverview;
