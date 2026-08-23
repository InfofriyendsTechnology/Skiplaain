import { motion } from 'framer-motion';
import './StatCard.scss';

const StatCard = ({ icon, label, value, trend, trendDir = 'up' }) => {
  return (
    <motion.div
      className="stat-card"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
    >
      <div className="stat-card-header">
        <div className="stat-card-icon">{icon}</div>
        {trend && (
          <span className={`stat-card-trend ${trendDir}`}>{trend}</span>
        )}
      </div>
      <div className="stat-card-value">{value}</div>
      <div className="stat-card-label">{label}</div>
    </motion.div>
  );
};

export default StatCard;
