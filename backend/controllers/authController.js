// Mengimpor library bcryptjs untuk hashing password pengguna secara aman
const bcrypt = require('bcryptjs');
// Mengimpor library jsonwebtoken untuk pembuatan token akses JWT
const jwt = require('jsonwebtoken');
// Mengimpor pool database MySQL
const pool = require('../config/db');
// Mengimpor library manipulasi file system
const fs = require('fs');
const path = require('path');
require('dotenv').config();

/**
 * Helper untuk men-generate token JWT bagi user yang terautentikasi
 * @param {number} id - ID User dari database
 * @returns {string} - Token JWT
 */
const generateToken = (id) => {
  return jwt.sign(
    { id }, 
    process.env.JWT_SECRET || 'taskflow_secret_key_2026_jwt', 
    { expiresIn: process.env.JWT_EXPIRE || '30d' } // Default kedaluwarsa dalam 30 hari
  );
};

// @desc    Mendaftarkan user baru (Registrasi)
// @route   POST /api/auth/register
// @access  Public (Bisa diakses tanpa login)
const register = async (req, res, next) => {
  try {
    const { name, email, password } = req.body;

    // Validasi input wajib terisi
    if (!name || !email || !password) {
      res.status(400);
      throw new Error('Please fill in all fields');
    }

    // Validasi panjang minimum password
    if (password.length < 6) {
      res.status(400);
      throw new Error('Password must be at least 6 characters long');
    }

    // Memeriksa apakah alamat email sudah terdaftar sebelumnya
    const [existingUsers] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existingUsers.length > 0) {
      res.status(400);
      throw new Error('Email is already registered');
    }

    // Mengamankan password dengan hashing (salt rounds = 10)
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Menyisipkan user baru ke database
    const [result] = await pool.query(
      'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
      [name, email, hashedPassword]
    );

    const userId = result.insertId;

    // Mengembalikan response sukses beserta data user dan token JWT
    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        token: generateToken(userId),
        user: {
          id: userId,
          name,
          email,
          profile_picture: null,
          remind_deadlines: 1,
          weekly_report: 0,
          new_tasks: 1,
          email_alerts: 1,
          is_private_profile: 0,
          enable_two_factor: 0,
          session_timeout: 1
        }
      }
    });
  } catch (error) {
    next(error); // Lempar error ke middleware penanganan error global
  }
};

// @desc    Autentikasi masuk user (Login)
// @route   POST /api/auth/login
// @access  Public (Bisa diakses tanpa login)
const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Validasi kelengkapan input
    if (!email || !password) {
      res.status(400);
      throw new Error('Please enter email and password');
    }

    // Mencari user di database berdasarkan email
    const [users] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
    if (users.length === 0) {
      res.status(401);
      throw new Error('Invalid email or password');
    }

    const user = users[0];

    // Memverifikasi apakah password cocok dengan hash di database
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      res.status(401);
      throw new Error('Invalid email or password');
    }

    // Mengembalikan response sukses dan token login
    res.status(200).json({
      success: true,
      message: 'Logged in successfully',
      data: {
        token: generateToken(user.id),
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          profile_picture: user.profile_picture,
          remind_deadlines: user.remind_deadlines,
          weekly_report: user.weekly_report,
          new_tasks: user.new_tasks,
          email_alerts: user.email_alerts,
          is_private_profile: user.is_private_profile,
          enable_two_factor: user.enable_two_factor,
          session_timeout: user.session_timeout
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Mengambil profil user yang sedang login
// @route   GET /api/auth/profile
// @access  Private (Harus login)
const getProfile = async (req, res, next) => {
  try {
    // req.user diisi otomatis oleh middleware protect (authMiddleware.js)
    res.status(200).json({
      success: true,
      message: 'User profile retrieved successfully',
      data: {
        user: req.user
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Memperbarui profil / pengaturan user
// @route   PUT /api/auth/profile
// @access  Private (Harus login)
const updateProfile = async (req, res, next) => {
  try {
    const { 
      name, 
      email, 
      password, 
      profile_picture,
      remind_deadlines,
      weekly_report,
      new_tasks,
      email_alerts,
      is_private_profile,
      enable_two_factor,
      session_timeout
    } = req.body;
    const userId = req.user.id;

    // Menyiapkan basis query update
    let query = 'UPDATE users SET name = ?, email = ?';
    let params = [name || req.user.name, email || req.user.email];

    // Jika pengguna mengganti email, pastikan email baru tersebut belum dipakai orang lain
    if (email && email !== req.user.email) {
      const [existingUsers] = await pool.query('SELECT id FROM users WHERE email = ? AND id != ?', [email, userId]);
      if (existingUsers.length > 0) {
        res.status(400);
        throw new Error('Email is already registered by another account');
      }
    }

    // Jika pengguna mengganti password
    if (password) {
      if (password.length < 6) {
        res.status(400);
        throw new Error('Password must be at least 6 characters long');
      }
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(password, salt);
      query += ', password = ?';
      params.push(hashedPassword);
    }

    // Pengecekan kolom dinamis lainnya
    if (profile_picture !== undefined) {
      query += ', profile_picture = ?';
      params.push(profile_picture);
    }

    if (remind_deadlines !== undefined) {
      query += ', remind_deadlines = ?';
      params.push(remind_deadlines);
    }

    if (weekly_report !== undefined) {
      query += ', weekly_report = ?';
      params.push(weekly_report);
    }

    if (new_tasks !== undefined) {
      query += ', new_tasks = ?';
      params.push(new_tasks);
    }

    if (email_alerts !== undefined) {
      query += ', email_alerts = ?';
      params.push(email_alerts);
    }

    if (is_private_profile !== undefined) {
      query += ', is_private_profile = ?';
      params.push(is_private_profile);
    }

    if (enable_two_factor !== undefined) {
      query += ', enable_two_factor = ?';
      params.push(enable_two_factor);
    }

    if (session_timeout !== undefined) {
      query += ', session_timeout = ?';
      params.push(session_timeout);
    }

    query += ' WHERE id = ?';
    params.push(userId);

    // Menjalankan query update ke database
    await pool.query(query, params);

    // Mengambil data terupdate pengguna dari database
    const [updatedUser] = await pool.query('SELECT id, name, email, profile_picture, remind_deadlines, weekly_report, new_tasks, email_alerts, is_private_profile, enable_two_factor, session_timeout, created_at FROM users WHERE id = ?', [userId]);

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: updatedUser[0]
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Mengunggah foto profil (Berformat base64 string dari HP/Web)
// @route   POST /api/auth/upload
// @access  Private (Harus login)
const uploadProfilePicture = async (req, res, next) => {
  try {
    const { imageBase64, fileName } = req.body;
    if (!imageBase64) {
      res.status(400);
      throw new Error('Please provide imageBase64 string');
    }

    // Membersihkan metadata base64 jika ada (contoh: data:image/png;base64, )
    const base64Data = imageBase64.replace(/^data:image\/\w+;base64,/, "");
    // Mengonversi data string base64 menjadi Buffer biner
    const buffer = Buffer.from(base64Data, 'base64');

    // Membuat nama file yang unik untuk menghindari tabrakan nama file antar pengguna
    const ext = path.extname(fileName || 'avatar.png') || '.png';
    const newFileName = `avatar_${req.user.id}_${Date.now()}${ext}`;
    const uploadPath = path.join(__dirname, '..', 'uploads', newFileName);

    // Menulis file biner tersebut ke folder uploads server
    fs.writeFileSync(uploadPath, buffer);

    // Membuat tautan publik absolut agar gambar bisa diakses langsung lewat HTTP di aplikasi mobile
    const fileUrl = `${req.protocol}://${req.get('host')}/uploads/${newFileName}`;

    res.status(200).json({
      success: true,
      message: 'Image uploaded successfully',
      url: fileUrl
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  login,
  getProfile,
  updateProfile,
  uploadProfilePicture
};
