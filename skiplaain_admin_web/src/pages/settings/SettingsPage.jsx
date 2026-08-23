import { useNavigate, useOutletContext } from 'react-router-dom';
import Navbar from '../../components/layout/Navbar';
import { FiLogOut } from 'react-icons/fi';
import toast from 'react-hot-toast';
import './SettingsPage.scss';

const SettingsPage = () => {
  const navigate = useNavigate();
  const { onMenuClick } = useOutletContext() || {};

  const handleLogout = () => {
    sessionStorage.removeItem('skiplaain_admin_auth');
    toast.success('Logged out');
    navigate('/login');
  };

  return (
    <>
      <Navbar title="Settings" subtitle="Platform configuration" onMenuClick={onMenuClick} />
      <div className="page-container">
        <div className="partner-detail-card">
          <h3 className="detail-card-title">Admin Account</h3>
          <div className="detail-grid">
            <div className="detail-item"><label>Admin Email</label><span>{import.meta.env.VITE_ADMIN_EMAIL}</span></div>
            <div className="detail-item"><label>Role</label><span>Super Admin (App Owner)</span></div>
            <div className="detail-item"><label>Firebase Project</label><span>{import.meta.env.VITE_FIREBASE_PROJECT_ID}</span></div>
            <div className="detail-item"><label>Platform</label><span>Skiplaain</span></div>
          </div>
        </div>

        <div className="partner-detail-card">
          <h3 className="detail-card-title">Platform Settings</h3>
          <div className="detail-grid">
            <div className="detail-item"><label>Commission Rate</label><span>10%</span></div>
            <div className="detail-item"><label>Partner Onboarding Mode</label><span style={{ color: '#00ff00', fontWeight: 'bold' }}>⚡ Instant Auto-Live</span></div>
          </div>
        </div>

        <button className="btn btn-danger" onClick={handleLogout} style={{ marginTop: 24 }}>
          <FiLogOut /> Logout
        </button>
      </div>
    </>
  );
};

export default SettingsPage;
