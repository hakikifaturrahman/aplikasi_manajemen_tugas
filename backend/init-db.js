// Mengimpor library mysql2 versi promise untuk interaksi database asinkron
const mysql = require('mysql2/promise');
// Memuat variabel lingkungan dari file .env
require('dotenv').config();

// Fungsi asinkron utama untuk menginisialisasi database
async function initDB() {
  console.log('Initializing MySQL Database...');
  
  // Membuat koneksi ke server MySQL tanpa memilih database terlebih dahulu
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || ''
  });

  try {
    const dbName = process.env.DB_NAME || 'taskflow_db';
    
    // 1. Membuat Database jika database tersebut belum ada
    await connection.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\``);
    console.log(`✔ Database "${dbName}" checked/created.`);

    // 2. Mengubah fokus koneksi ke database yang ditargetkan
    await connection.query(`USE \`${dbName}\``);

    // 3. Membuat Tabel users untuk menyimpan data pengguna sistem
    await connection.query(`
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        profile_picture VARCHAR(1000) DEFAULT NULL,
        remind_deadlines TINYINT(1) DEFAULT 1,
        weekly_report TINYINT(1) DEFAULT 0,
        new_tasks TINYINT(1) DEFAULT 1,
        email_alerts TINYINT(1) DEFAULT 1,
        is_private_profile TINYINT(1) DEFAULT 0,
        enable_two_factor TINYINT(1) DEFAULT 0,
        session_timeout TINYINT(1) DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);
    console.log('✔ Users table checked/created.');

    // Migrasi aman: Tambahkan kolom profile_picture ke tabel users jika belum ada (untuk kasus tabel lama)
    try {
      await connection.query('ALTER TABLE users ADD COLUMN profile_picture VARCHAR(1000) DEFAULT NULL');
      console.log('✔ Added profile_picture column to users table (migration).');
    } catch (err) {
      // Error diabaikan karena kolom mungkin sudah ada
    }

    // Migrasi aman untuk kolom-kolom pengaturan/settings pengguna
    const columns = [
      { name: 'remind_deadlines', type: 'TINYINT(1) DEFAULT 1' },
      { name: 'weekly_report', type: 'TINYINT(1) DEFAULT 0' },
      { name: 'new_tasks', type: 'TINYINT(1) DEFAULT 1' },
      { name: 'email_alerts', type: 'TINYINT(1) DEFAULT 1' },
      { name: 'is_private_profile', type: 'TINYINT(1) DEFAULT 0' },
      { name: 'enable_two_factor', type: 'TINYINT(1) DEFAULT 0' },
      { name: 'session_timeout', type: 'TINYINT(1) DEFAULT 1' }
    ];

    for (const col of columns) {
      try {
        await connection.query(`ALTER TABLE users ADD COLUMN ${col.name} ${col.type}`);
        console.log(`✔ Added ${col.name} column to users table (migration).`);
      } catch (err) {
        // Error diabaikan karena kolom mungkin sudah ada
      }
    }

    // 4. Membuat Tabel categories untuk klasifikasi tugas
    await connection.query(`
      CREATE TABLE IF NOT EXISTS categories (
        id INT AUTO_INCREMENT PRIMARY KEY,
        category_name VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);
    console.log('✔ Categories table checked/created.');

    // 5. Membuat Tabel tasks untuk menyimpan data tugas/todo list
    // Memiliki relasi (foreign key) ke tabel categories dan users dengan relasi CASCADE
    await connection.query(`
      CREATE TABLE IF NOT EXISTS tasks (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        description TEXT DEFAULT NULL,
        deadline DATE NOT NULL,
        status ENUM('Pending', 'Progress', 'Done') DEFAULT 'Pending',
        category_id INT NOT NULL,
        user_id INT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);
    console.log('✔ Tasks table checked/created.');

    // 6. Membuat Tabel support_tickets untuk menampung masukan/laporan pengguna
    await connection.query(`
      CREATE TABLE IF NOT EXISTS support_tickets (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        subject VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);
    console.log('✔ Support Tickets table checked/created.');

    // 6b. Membuat Tabel task_histories untuk riwayat perubahan tugas
    await connection.query(`
      CREATE TABLE IF NOT EXISTS task_histories (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        task_id INT DEFAULT NULL,
        task_title VARCHAR(255) NOT NULL,
        action VARCHAR(50) NOT NULL,
        details TEXT DEFAULT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE SET NULL
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);
    console.log('✔ Task Histories table checked/created.');


    // 7. Seeding Awal untuk Kategori Default jika tabel kategori masih kosong
    const [rows] = await connection.query('SELECT COUNT(*) as count FROM categories');
    if (rows[0].count === 0) {
      const defaultCategories = ['Backend', 'Frontend', 'UI/UX', 'Testing', 'Dokumentasi'];
      for (const cat of defaultCategories) {
        await connection.query('INSERT INTO categories (category_name) VALUES (?)', [cat]);
      }
      console.log('✔ Default categories seeded successfully (Backend, Frontend, UI/UX, Testing, Dokumentasi).');
    } else {
      console.log('✔ Categories already exist. Seeding skipped.');
    }

    console.log('🎉 Database initialization complete!');
  } catch (error) {
    console.error('❌ Database Initialization Failed:', error.message);
  } finally {
    // Menutup koneksi database utama setelah proses selesai
    await connection.end();
  }
}

// Menjalankan fungsi inisialisasi database
initDB();
