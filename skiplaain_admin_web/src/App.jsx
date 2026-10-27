import { Toaster } from 'react-hot-toast';
import { BrowserRouter } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import AppRoutes from './routes/AppRoutes';
import './styles/main.scss';

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Toaster
          position="top-right"
          toastOptions={{
            style: {
              background: '#111111',
              color: '#fff',
              border: '1px solid #1e1e1e',
              fontSize: '13px',
            },
            success: {
              iconTheme: {
                primary: '#00ff00',
                secondary: '#000',
              },
            },
          }}
        />
        <AppRoutes />
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
