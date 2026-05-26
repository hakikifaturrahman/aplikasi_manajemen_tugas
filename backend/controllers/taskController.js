const pool = require('../config/db');

// Helper function to log task history
const logTaskHistory = async (userId, taskId, taskTitle, action, details) => {
  try {
    await pool.query(
      'INSERT INTO task_histories (user_id, task_id, task_title, action, details) VALUES (?, ?, ?, ?, ?)',
      [userId, taskId, taskTitle, action, details]
    );
  } catch (err) {
    console.error('Error logging task history:', err.message);
  }
};

// @desc    Mengambil daftar tugas milik user (Mendukung pencarian, filter kategori/status, dan pengurutan)
// @route   GET /api/tasks
// @access  Private (Harus login)
const getTasks = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { search, status, category_id, sort } = req.query;

    // Basis query sql untuk mengambil data tugas dengan join nama kategori
    let query = `
      SELECT t.id, t.title, t.description, t.deadline, t.status, t.category_id, t.user_id, t.created_at, c.category_name
      FROM tasks t
      JOIN categories c ON t.category_id = c.id
      WHERE t.user_id = ?
    `;
    const params = [userId];

    // Logika pencarian berdasarkan judul tugas atau deskripsi tugas
    if (search) {
      query += ` AND (t.title LIKE ? OR t.description LIKE ?)`;
      const searchWildcard = `%${search}%`;
      params.push(searchWildcard, searchWildcard);
    }

    // Logika filter status tugas (Pending, Progress, Done)
    if (status && status !== 'All') {
      query += ` AND t.status = ?`;
      params.push(status);
    }

    // Logika filter berdasarkan ID kategori
    if (category_id) {
      query += ` AND t.category_id = ?`;
      params.push(parseInt(category_id));
    }

    // Mengatur arah pengurutan deadline (ASC = Tenggat terdekat, DESC = Tenggat terjauh)
    const sortOrder = sort && sort.toUpperCase() === 'DESC' ? 'DESC' : 'ASC';
    query += ` ORDER BY t.deadline ${sortOrder}`;

    // Menjalankan query ke database dengan parameter terikat (prepared statement)
    const [tasks] = await pool.query(query, params);

    res.status(200).json({
      success: true,
      message: 'Tasks retrieved successfully',
      data: tasks
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Mengambil data tugas tunggal berdasarkan ID
// @route   GET /api/tasks/:id
// @access  Private (Harus login)
const getTaskById = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    // Query pencarian tugas spesifik milik user tertentu
    const [tasks] = await pool.query(
      `SELECT t.*, c.category_name 
       FROM tasks t
       JOIN categories c ON t.category_id = c.id
       WHERE t.id = ? AND t.user_id = ?`,
      [id, userId]
    );

    // Kirim error 404 jika tugas tidak ditemukan atau bukan milik pengguna tersebut
    if (tasks.length === 0) {
      res.status(404);
      throw new Error('Task not found');
    }

    res.status(200).json({
      success: true,
      message: 'Task retrieved successfully',
      data: tasks[0]
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Membuat tugas baru
// @route   POST /api/tasks
// @access  Private (Harus login)
const createTask = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { title, description, deadline, status, category_id } = req.body;

    // Validasi input wajib terisi
    if (!title || !deadline || !category_id) {
      res.status(400);
      throw new Error('Please enter all required fields (title, deadline, category_id)');
    }

    // Validasi nilai status harus sesuai ENUM di database
    const validStatuses = ['Pending', 'Progress', 'Done'];
    const taskStatus = status || 'Pending';
    if (!validStatuses.includes(taskStatus)) {
      res.status(400);
      throw new Error('Status must be Pending, Progress, or Done');
    }

    // Memastikan kategori yang dipilih valid (terdaftar di database)
    const [category] = await pool.query('SELECT id FROM categories WHERE id = ?', [category_id]);
    if (category.length === 0) {
      res.status(400);
      throw new Error('Invalid category selected');
    }

    // Menyisipkan data tugas baru
    const [result] = await pool.query(
      'INSERT INTO tasks (title, description, deadline, status, category_id, user_id) VALUES (?, ?, ?, ?, ?, ?)',
      [title, description || null, deadline, taskStatus, category_id, userId]
    );

    // Mengambil ulang data tugas yang baru saja disimpan (join nama kategori) untuk response
    const [insertedTask] = await pool.query(
      `SELECT t.*, c.category_name 
       FROM tasks t 
       JOIN categories c ON t.category_id = c.id 
       WHERE t.id = ?`,
      [result.insertId]
    );

    // Log task history
    await logTaskHistory(userId, result.insertId, title, 'Created', `Task "${title}" was created.`);

    res.status(201).json({
      success: true,
      message: 'Task created successfully',
      data: insertedTask[0]
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Memperbarui data tugas
// @route   PUT /api/tasks/:id
// @access  Private (Harus login)
const updateTask = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { title, description, deadline, status, category_id } = req.body;

    // Memastikan tugas tersebut ada dan memang milik user bersangkutan
    const [existing] = await pool.query('SELECT id, title, status FROM tasks WHERE id = ? AND user_id = ?', [id, userId]);
    if (existing.length === 0) {
      res.status(404);
      throw new Error('Task not found');
    }
    const oldTask = existing[0];

    // Menyiapkan parameter query update secara dinamis
    const updates = [];
    const params = [];

    if (title !== undefined) {
      updates.push('title = ?');
      params.push(title);
    }
    if (description !== undefined) {
      updates.push('description = ?');
      params.push(description);
    }
    if (deadline !== undefined) {
      updates.push('deadline = ?');
      params.push(deadline);
    }
    if (status !== undefined) {
      const validStatuses = ['Pending', 'Progress', 'Done'];
      if (!validStatuses.includes(status)) {
        res.status(400);
        throw new Error('Status must be Pending, Progress, or Done');
      }
      updates.push('status = ?');
      params.push(status);
    }
    if (category_id !== undefined) {
      // Memastikan kategori pengganti valid
      const [category] = await pool.query('SELECT id FROM categories WHERE id = ?', [category_id]);
      if (category.length === 0) {
        res.status(400);
        throw new Error('Invalid category selected');
      }
      updates.push('category_id = ?');
      params.push(category_id);
    }

    // Jika tidak ada data kolom yang dikirimkan untuk diupdate
    if (updates.length === 0) {
      res.status(400);
      throw new Error('No fields to update provided');
    }

    // Menggabungkan query update dinamis
    let query = `UPDATE tasks SET ${updates.join(', ')} WHERE id = ? AND user_id = ?`;
    params.push(id, userId);

    await pool.query(query, params);

    // Mengambil data tugas terupdate dari database
    const [updatedTask] = await pool.query(
      `SELECT t.*, c.category_name 
       FROM tasks t 
       JOIN categories c ON t.category_id = c.id 
       WHERE t.id = ?`,
      [id]
    );

    // Log history
    const taskTitle = title !== undefined ? title : oldTask.title;
    if (status !== undefined && status !== oldTask.status) {
      await logTaskHistory(userId, id, taskTitle, 'Updated Status', `Changed status from ${oldTask.status} to ${status}`);
    } else {
      await logTaskHistory(userId, id, taskTitle, 'Updated Details', `Updated details of the task.`);
    }

    res.status(200).json({
      success: true,
      message: 'Task updated successfully',
      data: updatedTask[0]
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Menghapus tugas
// @route   DELETE /api/tasks/:id
// @access  Private (Harus login)
const deleteTask = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    // Memastikan tugas tersebut terdaftar
    const [existing] = await pool.query('SELECT id, title FROM tasks WHERE id = ? AND user_id = ?', [id, userId]);
    if (existing.length === 0) {
      res.status(404);
      throw new Error('Task not found');
    }
    const taskTitle = existing[0].title;

    // Menghapus data tugas
    await pool.query('DELETE FROM tasks WHERE id = ? AND user_id = ?', [id, userId]);

    // Log history
    await logTaskHistory(userId, id, taskTitle, 'Deleted', `Task "${taskTitle}" was deleted.`);

    res.status(200).json({
      success: true,
      message: 'Task deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Mengambil riwayat aktivitas tugas milik user
// @route   GET /api/tasks/history
// @access  Private (Harus login)
const getTaskHistory = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const [history] = await pool.query(
      'SELECT * FROM task_histories WHERE user_id = ? ORDER BY created_at DESC',
      [userId]
    );
    res.status(200).json({
      success: true,
      message: 'Task history retrieved successfully',
      data: history
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getTasks,
  getTaskById,
  createTask,
  updateTask,
  deleteTask,
  getTaskHistory
};
