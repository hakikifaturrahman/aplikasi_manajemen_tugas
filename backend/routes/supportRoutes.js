const express = require('express');
const router = express.Router();
// Mengimpor handler untuk pembuatan tiket support
const { createSupportTicket } = require('../controllers/supportController');
// Mengimpor middleware proteksi token JWT
const { protect } = require('../middleware/authMiddleware');

// Rute terproteksi untuk membuat tiket support baru (POST /api/support/ticket)
router.post('/ticket', protect, createSupportTicket);

module.exports = router;
