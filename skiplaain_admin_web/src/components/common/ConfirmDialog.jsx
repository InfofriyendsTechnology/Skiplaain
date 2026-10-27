import { motion } from 'framer-motion';
import { FiAlertTriangle, FiX } from 'react-icons/fi';
import './ConfirmDialog.scss';

const ConfirmDialog = ({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  variant = 'default', // 'default', 'danger', 'warning'
  loading = false
}) => {
  if (!isOpen) return null;

  const handleConfirm = () => {
    onConfirm();
  };

  return (
    <div className="confirm-dialog-overlay" onClick={onClose}>
      <motion.div
        className={`confirm-dialog confirm-dialog-${variant}`}
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.9 }}
        onClick={(e) => e.stopPropagation()}
      >
        <button className="confirm-dialog-close" onClick={onClose} aria-label="Close dialog">
          <FiX />
        </button>

        {variant === 'danger' || variant === 'warning' ? (
          <div className={`confirm-dialog-icon confirm-dialog-icon-${variant}`}>
            <FiAlertTriangle />
          </div>
        ) : null}

        <h3 className="confirm-dialog-title">{title}</h3>
        {message && <p className="confirm-dialog-message">{message}</p>}

        <div className="confirm-dialog-actions">
          <button
            className={`btn ${variant === 'danger' ? 'btn-danger' : 'btn-primary'}`}
            onClick={handleConfirm}
            disabled={loading}
          >
            {loading ? 'Processing...' : confirmText}
          </button>
          <button
            className="btn btn-ghost"
            onClick={onClose}
            disabled={loading}
          >
            {cancelText}
          </button>
        </div>
      </motion.div>
    </div>
  );
};

export default ConfirmDialog;
