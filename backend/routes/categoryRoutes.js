const express = require('express');
const router = express.Router();
// Mengimpor handler function dari categoryController
const { getCategories, createCategory, updateCategory, deleteCategory } = require('../controllers/categoryController');
// Mengimpor middleware proteksi token JWT
const { protect } = require('../middleware/authMiddleware');

// Memasang middleware proteksi ke seluruh rute kategori di bawah ini (Global filter)
router.use(protect);

// Rute berbasis '/' (GET: Ambil semua kategori, POST: Tambahkan kategori baru)
router.route('/')
  .get(getCategories)
  .post(createCategory);

// Rute berbasis '/:id' (PUT: Perbarui kategori, DELETE: Hapus kategori)
router.route('/:id')
  .put(updateCategory)
  .delete(deleteCategory);

module.exports = router;
