import { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { motion } from 'framer-motion';
import { FiArrowRight } from 'react-icons/fi';
import toast from 'react-hot-toast';
import { useAuth } from '../../context/AuthContext';
import './LoginPage.scss';

const LoginPage = () => {
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [step, setStep] = useState('phone'); // 'phone' or 'otp'
  const [resendTimer, setResendTimer] = useState(0);
  
  const navigate = useNavigate();
  const location = useLocation();
  const { isAuthenticated, sendOtp, login, isLoading } = useAuth();

  const from = location.state?.from?.pathname || '/';

  // Redirect if already authenticated
  useEffect(() => {
    if (isAuthenticated) {
      navigate(from, { replace: true });
    }
  }, [isAuthenticated, navigate, from]);

  // Resend timer
  useEffect(() => {
    if (resendTimer > 0) {
      const timer = setTimeout(() => setResendTimer(resendTimer - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [resendTimer]);

  const handleSendOtp = async (e) => {
    e.preventDefault();
    
    if (!phone.trim()) {
      toast.error('Please enter phone number');
      return;
    }

    if (phone.length < 10) {
      toast.error('Invalid phone number');
      return;
    }

    try {
      await sendOtp(phone);
      toast.success('OTP sent successfully');
      setStep('otp');
      setResendTimer(30);
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to send OTP');
    }
  };

  const handleVerifyOtp = async (e) => {
    e.preventDefault();

    if (!otp.trim()) {
      toast.error('Please enter OTP');
      return;
    }

    if (otp.length !== 6) {
      toast.error('OTP must be 6 digits');
      return;
    }

    try {
      await login(phone, otp);
      toast.success('Login successful!');
      navigate(from, { replace: true });
    } catch (error) {
      toast.error(error.response?.data?.message || 'Invalid OTP');
    }
  };

  const handleResend = async () => {
    if (resendTimer > 0) return;
    
    try {
      await sendOtp(phone);
      toast.success('OTP resent');
      setResendTimer(30);
    } catch (error) {
      toast.error('Failed to resend OTP');
    }
  };

  const handleBack = () => {
    setStep('phone');
    setOtp('');
  };

  return (
    <div className="login-page">
      <motion.div
        className="login-card"
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
      >
        <div className="login-logo">
          <img src="/logo.png" alt="Skiplaain" className="login-logo-img" />
          <span className="login-badge">ADMIN</span>
        </div>

        <h2 className="login-title">
          {step === 'phone' ? 'Admin Login' : 'Enter OTP'}
        </h2>
        <p className="login-subtitle">
          {step === 'phone' 
            ? 'Enter your registered admin phone number' 
            : `OTP sent to ${phone}`
          }
        </p>

        {step === 'phone' ? (
          <form onSubmit={handleSendOtp} className="login-form">
            <div className="login-field">
              <label>Phone Number</label>
              <input
                type="tel"
                placeholder="9999999999"
                value={phone}
                onChange={(e) => setPhone(e.target.value.replace(/\D/g, ''))}
                maxLength="10"
                autoFocus
              />
            </div>

            <button type="submit" className="login-btn" disabled={isLoading}>
              {isLoading ? 'Sending...' : (
                <>
                  Send OTP <FiArrowRight />
                </>
              )}
            </button>
          </form>
        ) : (
          <form onSubmit={handleVerifyOtp} className="login-form">
            <div className="login-field">
              <label>OTP Code</label>
              <input
                type="text"
                placeholder="111111"
                value={otp}
                onChange={(e) => setOtp(e.target.value.replace(/\D/g, ''))}
                maxLength="6"
                autoFocus
              />
              <div style={{ marginTop: '8px', fontSize: '11px', color: '#666' }}>
                Dev OTP: <span style={{ color: '#0f0' }}>111111</span>
              </div>
            </div>

            <button type="submit" className="login-btn" disabled={isLoading}>
              {isLoading ? 'Verifying...' : 'Login'}
            </button>

            <div style={{ display: 'flex', gap: '12px', marginTop: '12px' }}>
              <button
                type="button"
                className="login-btn-secondary"
                onClick={handleBack}
                disabled={isLoading}
              >
                Back
              </button>
              <button
                type="button"
                className="login-btn-secondary"
                onClick={handleResend}
                disabled={isLoading || resendTimer > 0}
              >
                {resendTimer > 0 ? `Resend (${resendTimer}s)` : 'Resend OTP'}
              </button>
            </div>
          </form>
        )}
      </motion.div>
    </div>
  );
};

export default LoginPage;
