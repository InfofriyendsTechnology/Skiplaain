import { createContext, useContext, useState, useEffect } from 'react';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(() => {
    // Initialize from sessionStorage on mount
    return sessionStorage.getItem('skiplaain_admin_auth') === 'true';
  });
  const [isLoading, setIsLoading] = useState(false);

  // Sync auth state with sessionStorage
  useEffect(() => {
    const handleStorageChange = () => {
      const authValue = sessionStorage.getItem('skiplaain_admin_auth') === 'true';
      setIsAuthenticated(authValue);
    };

    // Listen for storage events (for multi-tab sync)
    window.addEventListener('storage', handleStorageChange);
    
    return () => {
      window.removeEventListener('storage', handleStorageChange);
    };
  }, []);

  const login = (email, password) => {
    return new Promise((resolve, reject) => {
      setIsLoading(true);
      
      const adminEmail = import.meta.env.VITE_ADMIN_EMAIL;
      const adminPassword = import.meta.env.VITE_ADMIN_PASSWORD;

      setTimeout(() => {
        if (email === adminEmail && password === adminPassword) {
          sessionStorage.setItem('skiplaain_admin_auth', 'true');
          setIsAuthenticated(true);
          setIsLoading(false);
          resolve(true);
        } else {
          setIsLoading(false);
          reject(new Error('Invalid credentials'));
        }
      }, 600);
    });
  };

  const logout = () => {
    sessionStorage.removeItem('skiplaain_admin_auth');
    setIsAuthenticated(false);
  };

  const value = {
    isAuthenticated,
    isLoading,
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
