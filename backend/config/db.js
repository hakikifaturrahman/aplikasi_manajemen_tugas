// Mengimpor library mysql2 versi promise untuk interaksi database asinkron
const mysql = require('mysql2/promise');
// Memuat variabel lingkungan dari file .env
require('dotenv').config();

// Membuat connection pool (kumpulan koneksi) ke MySQL database
// Pool ini mengelola penggunaan kembali koneksi secara otomatis demi efisiensi
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'taskflow_db',
  waitForConnections: true, // Menunggu jika semua slot koneksi sedang digunakan
  connectionLimit: 10,     // Batas maksimal koneksi simultan yang diizinkan
  queueLimit: 0,           // Batas antrean koneksi (0 = tidak terbatas)
  ssl: { rejectUnauthorized: false } // Aiven mewajibkan SSL
});

// Melakukan uji koneksi awal ke database MySQL
pool.getConnection()
  .then(connection => {
    console.log('MySQL Connected successfully to database:', process.env.DB_NAME);
    connection.release(); // Mengembalikan koneksi kembali ke pool agar bisa digunakan pihak lain
  })
  .catch(err => {
    console.error('MySQL Connection Error:', err.message);
  });

// Mengekspor objek pool agar bisa dipakai di bagian lain (misalnya controller)
module.exports = pool;
