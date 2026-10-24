import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import rootRoutes from './routes/index';
import responseHandler from './utils/responseHandler';

dotenv.config();

// Validate required environment variables
if (!process.env.JWT_SECRET && process.env.NODE_ENV === 'production') {
  console.error('❌ FATAL: JWT_SECRET is required in production');
  process.exit(1);
}

if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
  console.warn('⚠️  WARNING: Razorpay credentials not configured');
}

const app = express();

// CORS Configuration
const allowedOrigins = process.env.CORS_ORIGINS 
  ? process.env.CORS_ORIGINS.split(',').map(origin => origin.trim())
  : ['http://localhost:19826', 'http://localhost:5353', 'http://localhost:5454'];

app.use(cors({
  origin: process.env.NODE_ENV === 'production' ? allowedOrigins : '*',
  credentials: true,
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Global Health Check
app.get('/api/health', (req, res) => {
  return responseHandler.success(res, {
    status: 'running',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  }, 'Skiplaain Backend API is running smoothly! 💈');
});

// API Routes
app.use('/api', rootRoutes);

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.path} not found`,
  });
});

// Global Error Handler
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Global Error:', err);
  return responseHandler.error(res, err.message || 'Internal server error', 500);
});

export default app;
