import { createContext, useContext, useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { setUnauthorizedHandler, resetLogoutGuard } from '../services/apiClient';

const AuthContext = createContext(null);

const AUTH_STORAGE_KEY = 'skiplaain_admin_session';
const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:61026/api';

// Decode JWT and check expiry
const parseJWT = (token) => {
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch {
    return null;
  }
};

const isTokenValid = (token) => {
  const payload = parseJWT(token);
  if (!payload || !payload.exp) return false;
  return payload.exp * 1000 > Date.now();
};

export const AuthProvider = ({ children }) => {
  const [token, setToken] = useState(null);
  const [user, setUser] = useState(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isInitialized, setIsInitialized] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();

  // Register unauthorized handler FIRST (before any async operations)
  useEffect(() => {
    setUnauthorizedHandler(() => {
      localStorage.removeItem(AUTH_STORAGE_KEY);
      setToken(null);
      setUser(null);
      setIsAuthenticated(false);
      navigate('/login', { replace: true });
    });
  }, [navigate]);

  // Hydrate from storage and validate
  useEffect(() => {
    const init = async () => {
      const stored = localStorage.getItem(AUTH_STORAGE_KEY);
      if (!stored) {
        setIsInitialized(true);
        return;
      }

      try {
        const { token: storedToken, user: storedUser } = JSON.parse(stored);
        
        // Check token expiry
        if (!isTokenValid(storedToken)) {
          localStorage.removeItem(AUTH_STORAGE_KEY);
          setIsInitialized(true);
          return;
        }

        // Verify with backend
        const res = await axios.get(`${API_BASE}/admin/settings`, {
          headers: { Authorization: `Bearer ${storedToken}` },
        });

        if (res.status === 200) {
          setToken(storedToken);
          setUser(storedUser);
          setIsAuthenticated(true);
        }
      } catch (err) {
        localStorage.removeItem(AUTH_STORAGE_KEY);
      } finally {
        setIsInitialized(true);
      }
    };

    init();
  }, []);

  // Multi-tab sync
  useEffect(() => {
    const handleStorageChange = (e) => {
      if (e.key === AUTH_STORAGE_KEY && !e.newValue) {
        // Logged out in another tab
        setToken(null);
        setUser(null);
        setIsAuthenticated(false);
      }
    };

    window.addEventListener('storage', handleStorageChange);
    return () => window.removeEventListener('storage', handleStorageChange);
  }, []);

  const sendOtp = async (phone) => {
    setIsLoading(true);
    try {
      const res = await axios.post(`${API_BASE}/auth/send-otp`, {
        phone,
        purpose: 'login',
      });
      return res.data;
    } finally {
      setIsLoading(false);
    }
  };

  const login = async (phone, otp) => {
    setIsLoading(true);
    try {
      const res = await axios.post(`${API_BASE}/auth/verify-otp`, {
        phone,
        otp,
        userType: 'admin',
      });

      const { token: newToken, user: newUser } = res.data.data;
      
      localStorage.setItem(
        AUTH_STORAGE_KEY,
        JSON.stringify({ token: newToken, user: newUser })
      );

      setToken(newToken);
      setUser(newUser);
      setIsAuthenticated(true);
      resetLogoutGuard();
      
      return res.data;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    localStorage.removeItem(AUTH_STORAGE_KEY);
    setToken(null);
    setUser(null);
    setIsAuthenticated(false);
    navigate('/login', { replace: true });
  };

  const value = {
    token,
    user,
    isAuthenticated,
    isInitialized,
    isLoading,
    sendOtp,
    login,
    logout,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};
