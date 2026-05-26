const express = require('express');
const router = express.Router();
// Mengimpor handler function dari authController
const { register, login, getProfile, updateProfile, uploadProfilePicture } = require('../controllers/authController');
// Mengimpor middleware protect untuk verifikasi token JWT
const { protect } = require('../middleware/authMiddleware');

// --- RUTE PUBLIK (Bisa diakses tanpa login) ---
// Rute untuk melakukan registrasi user baru (POST /api/auth/register)
router.post('/register', register);
// Rute untuk melakukan login (POST /api/auth/login)
router.post('/login', login);

// --- RUTE TERPROTEKSI (Harus mengirimkan token JWT yang valid) ---
// Rute untuk mengambil profil user yang sedang login (GET /api/auth/profile)
router.get('/profile', protect, getProfile);
// Rute untuk memperbarui profil user yang sedang login (PUT /api/auth/profile)
router.put('/profile', protect, updateProfile);
// Rute untuk mengunggah gambar profil user (POST /api/auth/upload)
router.post('/upload', protect, uploadProfilePicture);

module.exports = router;
