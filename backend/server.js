// Mengimpor file konfigurasi aplikasi Express (app.js)
const app = require('./app');
// Memuat variabel lingkungan dari file .env
require('dotenv').config();

// Menentukan port server dari variabel lingkungan (.env) atau default ke port 5000
const PORT = process.env.PORT || 5000;

// Memulai mendengarkan (listen) koneksi masuk pada port yang ditentukan
const server = app.listen(PORT, () => {
  console.log(`🚀 Server running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}`);
  console.log(`🔗 API Base URL: http://localhost:${PORT}`);
});

// Mendengarkan error "unhandledRejection" (Promise yang ditolak dan tidak di-catch) secara global
process.on('unhandledRejection', (err, promise) => {
  console.error(`Error: ${err.message}`);
  // Menutup server secara aman lalu menghentikan proses aplikasi dengan kode kegagalan (1)
  server.close(() => process.exit(1));
});
