import { FiMenu } from 'react-icons/fi';
import './Navbar.scss';

const Navbar = ({ title, subtitle, onMenuClick }) => {
  return (
    <header className="navbar">
      <div className="navbar-left">
        {onMenuClick && (
          <button className="mobile-menu-btn" onClick={onMenuClick}>
            <FiMenu />
          </button>
        )}
        <div>
          <h2 className="navbar-title">{title}</h2>
          {subtitle && <p className="navbar-subtitle">{subtitle}</p>}
        </div>
      </div>
    </header>
  );
};

export default Navbar;
