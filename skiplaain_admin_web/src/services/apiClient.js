import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:61026/api',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000,
});

const AUTH_STORAGE_KEY = 'skiplaain_admin_session';
let isLoggingOut = false;
let unauthorizedHandler = null;

// Allow AuthContext to register logout handler
export const setUnauthorizedHandler = (handler) => {
  unauthorizedHandler = handler;
};

export const resetLogoutGuard = () => {
  isLoggingOut = false;
};

// Request interceptor
api.interceptors.request.use(
  (config) => {
    const stored = localStorage.getItem(AUTH_STORAGE_KEY);
    if (stored) {
      try {
        const { token } = JSON.parse(stored);
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
      } catch {}
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status;
    const requestUrl = error.config?.url || '';

    // Don't redirect on auth endpoints
    const isAuthEndpoint = requestUrl.includes('/auth/');

    if (status === 401 && !isAuthEndpoint && !isLoggingOut) {
      isLoggingOut = true;
      if (unauthorizedHandler) {
        unauthorizedHandler();
      }
    } else if (status === 403) {
      console.error('Permission denied:', error.response?.data?.message);
    }

    return Promise.reject(error);
  }
);

export default api;
