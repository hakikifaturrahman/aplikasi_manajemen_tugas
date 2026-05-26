// Mengimpor modul utama Express
const express = require('express');
// Mengimpor middleware CORS untuk mengizinkan request lintas asal (cross-origin)
const cors = require('cors');
// Mengimpor modul path bawaan Node.js untuk manipulasi jalur direktori
const path = require('path');
// Mengimpor modul fs bawaan Node.js untuk manipulasi file system
const fs = require('fs');
// Mengimpor middleware global penanganan error
const { errorHandler } = require('./middleware/errorMiddleware');

// Mengimpor rute-rute API
const authRoutes = require('./routes/authRoutes');
const taskRoutes = require('./routes/taskRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const supportRoutes = require('./routes/supportRoutes');

// Menginisialisasi aplikasi Express
const app = express();

// Memastikan folder 'uploads' untuk menampung file upload sudah dibuat
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir);
}

// Memasang middleware CORS (Cross-Origin Resource Sharing)
app.use(cors({
  origin: '*', // Di fase development, izinkan semua domain mengakses API ini
  methods: ['GET', 'POST', 'PUT', 'DELETE'], // HTTP methods yang diizinkan
  allowedHeaders: ['Content-Type', 'Authorization'] // Headers request yang diizinkan
}));

// Menyajikan file statis dari folder 'uploads' (seperti gambar profil)
app.use('/uploads', express.static(uploadsDir));

// Memasang middleware parser body request berformat JSON dengan limit ukuran 50mb
app.use(express.json({ limit: '50mb' }));
// Memasang middleware parser URL-encoded body dengan limit ukuran 50mb
app.use(express.urlencoded({ limit: '50mb', extended: false }));

// Menghubungkan (mounting) router spesifik ke basis jalur API masing-masing
app.use('/api/auth', authRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/support', supportRoutes);

// Membuat rute basis '/' untuk mengecek apakah API aktif
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to TaskFlow - Todo Team Management REST API'
  });
});

// Middleware penangkap rute yang tidak terdaftar (Catch-all 404)
app.use((req, res, next) => {
  res.status(404);
  const error = new Error(`Not Found - ${req.originalUrl}`);
  next(error); // Melempar error ke middleware penanganan error berikutnya
});

// Memasang middleware global untuk penanganan error/pengecualian (Error Handler)
app.use(errorHandler);

// Mengekspor objek app agar bisa dijalankan oleh server.js
module.exports = app;
