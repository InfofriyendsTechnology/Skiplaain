import { Navigate } from 'react-router-dom';

const ProtectedRoute = ({ children }) => {
  const isAuth = sessionStorage.getItem('skiplaain_admin_auth') === 'true';

  if (!isAuth) {
    return <Navigate to="/login" replace />;
  }

  return children;
};

export default ProtectedRoute;
