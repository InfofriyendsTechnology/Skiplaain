import './LoadingSpinner.scss';

const LoadingSpinner = ({ size = 'medium', text = null }) => {
  const sizeClass = {
    small: 'spinner-small',
    medium: 'spinner-medium',
    large: 'spinner-large'
  }[size] || 'spinner-medium';

  return (
    <div className="loading-spinner-container">
      <div className={`loading-spinner ${sizeClass}`}>
        <div className="spinner-ring"></div>
        <div className="spinner-ring"></div>
        <div className="spinner-ring"></div>
      </div>
      {text && <p className="loading-text">{text}</p>}
    </div>
  );
};

export default LoadingSpinner;
