import { NavLink, useLocation, useNavigate } from 'react-router-dom';
import { FiGrid, FiUsers, FiCalendar, FiSettings, FiLogOut } from 'react-icons/fi';
import toast from 'react-hot-toast';
import './Sidebar.scss';

const navItems = [
  { path: '/', label: 'Overview', icon: <FiGrid /> },
  { path: '/partners', label: 'Partners', icon: <FiUsers /> },
  { path: '/bookings', label: 'Bookings', icon: <FiCalendar /> },
  { path: '/settings', label: 'Settings', icon: <FiSettings /> },
];

const Sidebar = ({ isOpen, onClose }) => {
  const location = useLocation();
  const navigate = useNavigate();

  const handleLogout = () => {
    sessionStorage.removeItem('skiplaain_admin_auth');
    toast.success('Logged out');
    navigate('/login');
  };

  return (
    <>
      {/* Mobile overlay */}
      {isOpen && <div className="sidebar-overlay" onClick={onClose} />}

      <aside className={`sidebar ${isOpen ? 'sidebar-open' : ''}`}>
        <div className="sidebar-logo">
          <img src="/logo.png" alt="Skiplaain" className="sidebar-logo-img" />
          <span className="sidebar-admin-badge">ADMIN</span>
        </div>

        <nav className="sidebar-nav">
          <div className="sidebar-section-label">Main Menu</div>
          {navItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              className={`sidebar-link ${location.pathname === item.path ? 'active' : ''}`}
              onClick={onClose}
            >
              <span className="sidebar-icon">{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-footer">
          <button className="sidebar-link sidebar-logout" onClick={handleLogout}>
            <span className="sidebar-icon"><FiLogOut /></span>
            Logout
          </button>
        </div>
      </aside>
    </>
  );
};

export default Sidebar;
