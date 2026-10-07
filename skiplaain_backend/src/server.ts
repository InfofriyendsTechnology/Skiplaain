import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import rootRoutes from './routes/index';
import responseHandler from './utils/responseHandler';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 61026;

// Middlewares
app.use(cors({
  origin: process.env.CORS_ORIGINS?.split(',') || '*',
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

// Start Server
app.listen(PORT, () => {
  console.log(`\n🚀 Skiplaain Backend API is running on http://localhost:${PORT}`);
  console.log(`📊 Health Check: http://localhost:${PORT}/api/health`);
  console.log(`🔐 Environment: ${process.env.NODE_ENV || 'development'}\n`);
});

export default app;
