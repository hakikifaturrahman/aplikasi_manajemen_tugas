const express = require('express');
const router = express.Router();
// Mengimpor handler function dari taskController
const { getTasks, getTaskById, createTask, updateTask, deleteTask, getTaskHistory } = require('../controllers/taskController');
// Mengimpor middleware proteksi token JWT
const { protect } = require('../middleware/authMiddleware');

// Memasang middleware proteksi ke seluruh rute tugas di bawah ini (Global filter)
router.use(protect);

// Rute riwayat aktivitas tugas
router.route('/history')
  .get(getTaskHistory);

// Rute berbasis '/' (GET: Ambil semua tugas, POST: Tambahkan tugas baru)
router.route('/')
  .get(getTasks)
  .post(createTask);

// Rute berbasis '/:id' (GET: Ambil tugas detail, PUT: Perbarui tugas, DELETE: Hapus tugas)
router.route('/:id')
  .get(getTaskById)
  .put(updateTask)
  .delete(deleteTask);

module.exports = router;
