import { useState } from 'react';
import { useNavigate, useOutletContext } from 'react-router-dom';
import Navbar from '../../components/layout/Navbar';
import { FiLogOut, FiTrash2, FiAlertTriangle, FiRefreshCw, FiDatabase } from 'react-icons/fi';
import { 
  clearAllBookings, 
  clearAllCustomers, 
  clearAllMemberships, 
  purgeAllTestData 
} from '../../services/firebaseService';
import toast from 'react-hot-toast';
import './SettingsPage.scss';

const SettingsPage = () => {
  const navigate = useNavigate();
  const { onMenuClick } = useOutletContext() || {};
  const [isProcessing, setIsProcessing] = useState(false);

  const handleLogout = () => {
    sessionStorage.removeItem('skiplaain_admin_auth');
    toast.success('Logged out');
    navigate('/login');
  };

  const handleClearBookings = async () => {
    if (!window.confirm('⚠️ Are you sure you want to clear ALL booking history? This cannot be undone.')) return;
    setIsProcessing(true);
    try {
      const count = await clearAllBookings();
      toast.success(`Cleared ${count} booking(s) successfully!`);
    } catch (e) {
      toast.error('Failed to clear bookings: ' + e.message);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleClearCustomers = async () => {
    if (!window.confirm('⚠️ Are you sure you want to delete ALL customer records? This cannot be undone.')) return;
    setIsProcessing(true);
    try {
      const count = await clearAllCustomers();
      toast.success(`Cleared ${count} customer record(s)!`);
    } catch (e) {
      toast.error('Failed to clear customers: ' + e.message);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleClearMemberships = async () => {
    if (!window.confirm('⚠️ Are you sure you want to clear ALL VIP membership history?')) return;
    setIsProcessing(true);
    try {
      const count = await clearAllMemberships();
      toast.success(`Cleared ${count} membership record(s)!`);
    } catch (e) {
      toast.error('Failed to clear memberships: ' + e.message);
    } finally {
      setIsProcessing(false);
    }
  };

  const handlePurgeAll = async () => {
    const confirmation = window.prompt('🚨 TYPE "RESET" TO CONFIRM:\nThis will permanently delete all bookings, customer data, memberships, and clear all staff/barbers across all salons.');
    if (confirmation !== 'RESET') {
      if (confirmation !== null) toast.error('Confirmation text did not match. Aborted.');
      return;
    }

    setIsProcessing(true);
    try {
      const res = await purgeAllTestData();
      toast.success(`Complete Database Reset! Cleared ${res.bCount} bookings, ${res.cCount} customers, ${res.mCount} memberships across ${res.partnersAffected} salons.`);
    } catch (e) {
      toast.error('Purge failed: ' + e.message);
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <>
      <Navbar title="Settings & Data Management" subtitle="Platform configuration & database maintenance" onMenuClick={onMenuClick} />
      <div className="page-container">
        {/* Admin Account */}
        <div className="partner-detail-card">
          <h3 className="detail-card-title">Admin Account</h3>
          <div className="detail-grid">
            <div className="detail-item"><label>Admin Email</label><span>{import.meta.env.VITE_ADMIN_EMAIL}</span></div>
            <div className="detail-item"><label>Role</label><span>Super Admin (App Owner)</span></div>
            <div className="detail-item"><label>Firebase Project</label><span>{import.meta.env.VITE_FIREBASE_PROJECT_ID}</span></div>
            <div className="detail-item"><label>Platform</label><span>Skiplaain</span></div>
          </div>
        </div>

        {/* Platform Settings */}
        <div className="partner-detail-card" style={{ marginTop: 20 }}>
          <h3 className="detail-card-title">Platform Settings</h3>
          <div className="detail-grid">
            <div className="detail-item"><label>Commission Rate</label><span>10%</span></div>
            <div className="detail-item"><label>Partner Onboarding Mode</label><span style={{ color: '#00ff00', fontWeight: 'bold' }}>⚡ Instant Auto-Live</span></div>
          </div>
        </div>

        {/* SUPER ADMIN DANGER ZONE: DATA CLEANUP & PURGE */}
        <div 
          className="partner-detail-card" 
          style={{ 
            marginTop: 24, 
            border: '1px solid #7f1d1d', 
            background: 'linear-gradient(180deg, #181111 0%, #0d0909 100%)' 
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 14 }}>
            <div style={{ background: '#ef4444', padding: 6, borderRadius: 8, color: '#000', display: 'flex' }}>
              <FiAlertTriangle size={18} />
            </div>
            <div>
              <h3 className="detail-card-title" style={{ margin: 0, color: '#ef4444', fontSize: 16 }}>
                Danger Zone: Data & History Purge
              </h3>
              <p style={{ margin: '2px 0 0', fontSize: 12, color: '#888' }}>
                Quickly delete old test data, bookings history, customer accounts, and reset barbers.
              </p>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 12, marginTop: 16 }}>
            {/* Clear Bookings */}
            <div style={{ background: '#141414', padding: 14, borderRadius: 12, border: '1px solid #262626' }}>
              <strong style={{ color: '#fff', fontSize: 13, display: 'block' }}>Bookings History</strong>
              <p style={{ color: '#666', fontSize: 11, margin: '4px 0 12px' }}>Clear all past and upcoming appointment tickets from database.</p>
              <button 
                className="btn btn-danger btn-sm" 
                onClick={handleClearBookings}
                disabled={isProcessing}
                style={{ width: '100%', justifyContent: 'center' }}
              >
                <FiTrash2 /> Clear All Bookings
              </button>
            </div>

            {/* Clear Customers */}
            <div style={{ background: '#141414', padding: 14, borderRadius: 12, border: '1px solid #262626' }}>
              <strong style={{ color: '#fff', fontSize: 13, display: 'block' }}>Customers Database</strong>
              <p style={{ color: '#666', fontSize: 11, margin: '4px 0 12px' }}>Wipe all registered customer accounts and profile data.</p>
              <button 
                className="btn btn-danger btn-sm" 
                onClick={handleClearCustomers}
                disabled={isProcessing}
                style={{ width: '100%', justifyContent: 'center' }}
              >
                <FiTrash2 /> Clear All Customers
              </button>
            </div>

            {/* Clear VIP Passes */}
            <div style={{ background: '#141414', padding: 14, borderRadius: 12, border: '1px solid #262626' }}>
              <strong style={{ color: '#fff', fontSize: 13, display: 'block' }}>VIP Memberships</strong>
              <p style={{ color: '#666', fontSize: 11, margin: '4px 0 12px' }}>Reset all active customer VIP passes and subscription histories.</p>
              <button 
                className="btn btn-danger btn-sm" 
                onClick={handleClearMemberships}
                disabled={isProcessing}
                style={{ width: '100%', justifyContent: 'center' }}
              >
                <FiTrash2 /> Clear Memberships
              </button>
            </div>
          </div>

          {/* Full Purge Button */}
          <div style={{ marginTop: 20, paddingTop: 16, borderTop: '1px solid #2c1616', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 12 }}>
            <div>
              <strong style={{ color: '#ef4444', fontSize: 14, display: 'flex', alignItems: 'center', gap: 6 }}>
                <FiRefreshCw /> Full System Test Data Reset
              </strong>
              <span style={{ fontSize: 11, color: '#888' }}>
                Wipes all bookings, customers, memberships, and resets all barbers across all salons in one click.
              </span>
            </div>
            <button 
              className="btn btn-danger" 
              onClick={handlePurgeAll}
              disabled={isProcessing}
              style={{ background: '#dc2626', color: '#fff', fontWeight: 700 }}
            >
              <FiTrash2 /> Purge All Test Data
            </button>
          </div>
        </div>

        {/* Logout */}
        <button className="btn btn-danger" onClick={handleLogout} style={{ marginTop: 28 }}>
          <FiLogOut /> Logout Admin Session
        </button>
      </div>
    </>
  );
};

export default SettingsPage;
