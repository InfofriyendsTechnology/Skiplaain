import { Toaster } from 'react-hot-toast';
import AppRoutes from './routes/AppRoutes';
import './styles/main.scss';

function App() {
  return (
    <>
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
    </>
  );
}

export default App;
