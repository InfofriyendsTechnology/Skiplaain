import app from './app';

const PORT = process.env.PORT || 61026;

// Start Server
app.listen(PORT, () => {
  console.log(`\n🚀 Skiplaain Backend API is running on http://localhost:${PORT}`);
  console.log(`📊 Health Check: http://localhost:${PORT}/api/health`);
  console.log(`🔐 Environment: ${process.env.NODE_ENV || 'development'}\n`);
});
