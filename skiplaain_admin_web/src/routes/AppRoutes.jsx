import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import Layout from '../components/layout/Layout';
import ProtectedRoute from '../components/auth/ProtectedRoute';
import LoginPage from '../pages/auth/LoginPage';
import DashboardOverview from '../pages/dashboard/DashboardOverview';
import PartnersPage from '../pages/partners/PartnersPage';
import CustomersPage from '../pages/customers/CustomersPage';
import BookingsPage from '../pages/bookings/BookingsPage';

import SettingsPage from '../pages/settings/SettingsPage';

const AppRoutes = () => {
  const { isAuthenticated } = useAuth();

  return (
    <Routes>
      <Route 
        path="/login" 
        element={isAuthenticated ? <Navigate to="/" replace /> : <LoginPage />} 
      />
      <Route
        element={
          <ProtectedRoute>
            <Layout />
          </ProtectedRoute>
        }
      >
        <Route path="/" element={<DashboardOverview />} />
        <Route path="/partners" element={<PartnersPage />} />
        <Route path="/customers" element={<CustomersPage />} />
        <Route path="/bookings" element={<BookingsPage />} />
        <Route path="/settings" element={<SettingsPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
};

export default AppRoutes;
