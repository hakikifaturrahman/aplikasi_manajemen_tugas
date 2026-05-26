const pool = require('../config/db');

// @desc    Mengambil semua kategori (beserta jumlah task yang dimiliki oleh masing-masing user)
// @route   GET /api/categories
// @access  Private (Harus login)
const getCategories = async (req, res, next) => {
  try {
    const userId = req.user.id;

    // Mengambil seluruh kategori beserta jumlah task terkait milik user yang sedang aktif
    const [categories] = await pool.query(
      `SELECT c.id, c.category_name, c.created_at, COUNT(t.id) AS task_count
       FROM categories c
       LEFT JOIN tasks t ON c.id = t.category_id AND t.user_id = ?
       GROUP BY c.id, c.category_name, c.created_at
       ORDER BY c.category_name ASC`,
      [userId]
    );

    res.status(200).json({
      success: true,
      message: 'Categories retrieved successfully',
      data: categories
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Membuat kategori baru
// @route   POST /api/categories
// @access  Private (Harus login)
const createCategory = async (req, res, next) => {
  try {
    const { category_name } = req.body;

    // Validasi nama kategori wajib diisi
    if (!category_name) {
      res.status(400);
      throw new Error('Category name is required');
    }

    // Memeriksa duplikasi nama kategori (tidak sensitif huruf besar/kecil)
    const [existing] = await pool.query(
      'SELECT id FROM categories WHERE LOWER(category_name) = LOWER(?)',
      [category_name.trim()]
    );

    if (existing.length > 0) {
      res.status(400);
      throw new Error('Category already exists');
    }

    // Menyisipkan kategori baru
    const [result] = await pool.query(
      'INSERT INTO categories (category_name) VALUES (?)',
      [category_name.trim()]
    );

    const newId = result.insertId;

    res.status(201).json({
      success: true,
      message: 'Category created successfully',
      data: {
        id: newId,
        category_name: category_name.trim(),
        task_count: 0
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Memperbarui nama kategori
// @route   PUT /api/categories/:id
// @access  Private (Harus login)
const updateCategory = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { category_name } = req.body;

    if (!category_name) {
      res.status(400);
      throw new Error('Category name is required');
    }

    // Memastikan kategori yang akan diubah memang ada
    const [cat] = await pool.query('SELECT id FROM categories WHERE id = ?', [id]);
    if (cat.length === 0) {
      res.status(404);
      throw new Error('Category not found');
    }

    // Memeriksa jika nama baru bentrok dengan kategori lain yang sudah ada
    const [existing] = await pool.query(
      'SELECT id FROM categories WHERE LOWER(category_name) = LOWER(?) AND id != ?',
      [category_name.trim(), id]
    );

    if (existing.length > 0) {
      res.status(400);
      throw new Error('Another category with this name already exists');
    }

    // Menjalankan query update
    await pool.query(
      'UPDATE categories SET category_name = ? WHERE id = ?',
      [category_name.trim(), id]
    );

    res.status(200).json({
      success: true,
      message: 'Category updated successfully',
      data: {
        id: parseInt(id),
        category_name: category_name.trim()
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Menghapus kategori
// @route   DELETE /api/categories/:id
// @access  Private (Harus login)
const deleteCategory = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Memastikan kategori yang akan dihapus terdaftar
    const [cat] = await pool.query('SELECT id FROM categories WHERE id = ?', [id]);
    if (cat.length === 0) {
      res.status(404);
      throw new Error('Category not found');
    }

    // Menghapus kategori. Task yang terhubung akan terhapus otomatis di DB karena ON DELETE CASCADE
    await pool.query('DELETE FROM categories WHERE id = ?', [id]);

    res.status(200).json({
      success: true,
      message: 'Category deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getCategories,
  createCategory,
  updateCategory,
  deleteCategory
};
