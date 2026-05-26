// Mengimpor library jsonwebtoken untuk verifikasi token JWT
const jwt = require('jsonwebtoken');
// Mengimpor pool database untuk mencocokkan user di database
const pool = require('../config/db');
require('dotenv').config();

/**
 * Middleware untuk memproteksi rute API (harus login / memiliki token JWT yang valid)
 */
const protect = async (req, res, next) => {
  let token;

  // Memeriksa keberadaan header Authorization dan memastikan tipenya adalah "Bearer"
  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    try {
      // Mengambil token JWT (memisahkan kata "Bearer" dengan string token aslinya)
      token = req.headers.authorization.split(' ')[1];

      // Memverifikasi tanda tangan (signature) token JWT menggunakan secret key
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'taskflow_secret_key_2026_jwt');

      // Mengambil data user dari database berdasarkan ID yang didekode dari token JWT
      // (Password sengaja diabaikan demi alasan keamanan)
      const [rows] = await pool.query(
        'SELECT id, name, email, profile_picture, remind_deadlines, weekly_report, new_tasks, email_alerts, is_private_profile, enable_two_factor, session_timeout, created_at FROM users WHERE id = ?',
        [decoded.id]
      );

      // Jika user tidak ditemukan di database (misalnya akun sudah dihapus)
      if (rows.length === 0) {
        return res.status(401).json({
          success: false,
          message: 'Unauthorized: User not found'
        });
      }

      // Menyematkan data user yang login ke objek request (req.user) agar bisa dibaca oleh controller rute berikutnya
      req.user = rows[0];
      next(); // Melanjutkan eksekusi ke controller rute
    } catch (error) {
      console.error('JWT Verification Error:', error.message);
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Invalid token'
      });
    }
  }

  // Jika token JWT sama sekali tidak dikirimkan di header request
  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized: No token provided'
    });
  }
};

module.exports = { protect };
