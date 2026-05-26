const pool = require('../config/db');

// @desc    Membuat/mengirim tiket bantuan (support ticket) baru
// @route   POST /api/support/ticket
// @access  Private (Harus login)
const createSupportTicket = async (req, res, next) => {
  try {
    const { subject, message } = req.body;
    const userId = req.user.id; // Diambil dari data JWT pengguna

    // Validasi kolom subjek dan pesan harus diisi
    if (!subject || !message) {
      res.status(400);
      throw new Error('Please fill in all fields');
    }

    // Menyisipkan data tiket bantuan baru ke database
    const [result] = await pool.query(
      'INSERT INTO support_tickets (user_id, subject, message) VALUES (?, ?, ?)',
      [userId, subject, message]
    );

    const ticketId = result.insertId;

    // Mengambil data tiket bantuan yang baru saja disimpan untuk dikembalikan ke client
    const [ticket] = await pool.query('SELECT * FROM support_tickets WHERE id = ?', [ticketId]);

    res.status(201).json({
      success: true,
      message: 'Support ticket submitted successfully',
      data: ticket[0]
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { createSupportTicket };
