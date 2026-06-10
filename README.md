# TaskFlow - Todo Team Management (Fullstack REST API)

TaskFlow adalah aplikasi manajemen tugas tim berbasis web modern yang menggunakan arsitektur **REST API**. Aplikasi ini dirancang agar bersih (*clean code*), terstruktur (*scalable*), mudah dipahami untuk mahasiswa, serta memiliki tampilan UI/UX profesional yang modern.

---

## 👥 Anggota Kelompok (TodoTeam)

| Nama | NPM |
| :--- | :--- |
| **Muardi Wijayanto** | 5230411172 |
| **Muhammad Idris Anwar** | 5230411186 |
| **Bagas Setyawan** | 5230411197 |
| **Hakiki Faturrahman** | 5230411219 |
| **Farokhi Akbar Assobakh** | 5230411220 |

---

## 📂 Struktur Folder Proyek

```text
tugas_backend/
│
├── database/
│   └── schema.sql              # Skema database MySQL lengkap
│
├── backend/                    # Node.js + Express REST API
│   ├── config/
│   │   └── db.js               # Konfigurasi Pool Connection MySQL2
│   ├── controllers/
│   │   ├── authController.js   # Logic Register, Login, & Profile
│   │   ├── categoryController.js # Logic CRUD Categories & Jumlah Task
│   │   └── taskController.js   # Logic CRUD Tasks, Search, Filter, Sort
│   ├── middleware/
│   │   ├── authMiddleware.js   # JWT Validation Gating Route
│   │   └── errorMiddleware.js  # Global JSON Error Handler Exception
│   ├── routes/
│   │   ├── authRoutes.js       # Endpoints Auth
│   │   ├── categoryRoutes.js   # Endpoints Category
│   │   └── taskRoutes.js       # Endpoints Task
│   ├── .env                    # Variabel Lingkungan (Konfigurasi Port, DB, JWT)
│   ├── app.js                  # Konfigurasi middleware Express & Routing
│   ├── server.js               # Entry Point Server Listening
│   ├── init-db.js              # Script Inisialisasi Otomatis Database & Seeders
│   └── package.json            # Daftar Dependencies Backend
│
└── frontend/                   # Dart / Flutter Web Frontend
    ├── pubspec.yaml            # Konfigurasi Dart Packages (HTTP, Provider, dll)
    ├── web/
    │   └── index.html          # HTML Shell Web App
    └── lib/
        ├── main.dart           # App Entry Point, Theme & JWT Route Guard
        ├── models/
        │   ├── user.dart       # Model User Serialization
        │   ├── category.dart   # Model Category Serialization
        │   └── task.dart       # Model Task Serialization
        ├── services/
        │   └── api_service.dart # HTTP Client REST Request (Singleton)
        ├── providers/
        │   └── auth_provider.dart # Auth State Management & Persistent Token
        ├── widgets/
        │   ├── responsive_layout.dart # Sidebar (Desktop) & Bottom Nav (Mobile)
        │   ├── task_modal.dart # Dialog Modal Input Task (Mockup Page 6)
        │   └── category_modal.dart # Dialog Modal Input Category
        └── screens/
            ├── login_screen.dart # Halaman Login Mockup (Page 2)
            ├── register_screen.dart # Halaman Register Mockup (Page 1)
            ├── dashboard_screen.dart # Halaman Dashboard Stats & Progress
            ├── tasks_screen.dart # Halaman Task Management & Filters Toolbar
            ├── categories_screen.dart # Halaman Category CRUD (Page 5)
            └── profile_screen.dart # Halaman Profile & Mock Menus (Page 4)
```

---

## 🛢️ Database Relasional Schema (MySQL)

Database menggunakan **MySQL** dengan minimal 3 tabel yang terhubung melalui relasi *Foreign Key* dengan *Cascade Deletion* (jika user/kategori dihapus, task terkait terhapus otomatis).

1. **`users`**: Menyimpan akun pengguna (Password di-hash bcryptjs).
2. **`categories`**: Menyimpan daftar kategori tugas (Default: Backend, Frontend, UI/UX, Testing, Dokumentasi).
3. **`tasks`**: Menyimpan data tugas tim (Status: Pending, Progress, Done) terhubung dengan User ID dan Category ID.

Skema SQL lengkap dapat Anda temukan pada file:
👉 **[database/schema.sql](file:///d:/tugas_backend/database/schema.sql)**

---

## 🚀 Cara Menjalankan Project Secara Lokal

### 1. Prasyarat (*Prerequisites*)
Pastikan perangkat Anda sudah menginstal:
* [Node.js](https://nodejs.org/) (Versi terbaru)
* [MySQL Server](https://dev.mysql.com/downloads/mysql/) (bisa menggunakan XAMPP, Laragon, atau Docker)
* [Flutter SDK / Dart](https://docs.flutter.dev/get-started/install)

---

### 2. Inisialisasi Database
1. Jalankan server MySQL Anda (misal: aktifkan MySQL di panel XAMPP).
2. Masuk ke folder backend, dan periksa konfigurasi database pada file `.env`:
   ```env
   DB_HOST=localhost
   DB_PORT=3306
   DB_USER=root
   DB_PASSWORD=
   DB_NAME=taskflow_db
   ```
3. Jalankan script inisialisasi otomatis untuk membuat database, tabel, dan seeders data kategori:
   ```bash
   cd backend
   npm run init-db
   ```
   *Script akan otomatis membuat database `taskflow_db` jika belum ada dan mengisikan 5 kategori bawaan.*

---

### 3. Menjalankan Backend API
1. Install seluruh package dependencies backend:
   ```bash
   cd backend
   npm install
   ```
2. Jalankan server dalam mode development (akan otomatis merestart jika kode diubah menggunakan nodemon):
   ```bash
   npm run dev
   ```
   Server akan berjalan pada URL: **`http://localhost:5000`**

---

### 4. Menjalankan Frontend Dart (Flutter Web)
1. Buka terminal baru dan masuk ke folder `frontend`:
   ```bash
   cd frontend
   flutter pub get
   ```
2. Jalankan aplikasi frontend di browser Chrome:
   ```bash
   flutter run -d chrome
   ```
   Aplikasi Flutter Web akan memuat antarmuka premium, siap digunakan dan terhubung langsung ke backend port `5000`.

---

## 🔌 Cara Koneksi Database

Koneksi database dibangun secara aman menggunakan pool connection pada `backend/config/db.js` dengan library `mysql2/promise` (mendukung `async/await` agar kode clean).
```javascript
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'taskflow_db',
  waitForConnections: true,
  connectionLimit: 10
});
```

---

## 🧪 Cara Testing API Menggunakan Postman

Anda dapat menguji seluruh REST API endpoints menggunakan **Postman** dengan langkah berikut:

### 1. Register User Baru
* **Method**: `POST`
* **URL**: `http://localhost:5000/api/auth/register`
* **Body (JSON)**:
  ```json
  {
    "name": "Alex Carter",
    "email": "alex.carter@taskflow.inc",
    "password": "superpassword"
  }
  ```
* **Response**: Anda akan menerima token JWT dan detail user.

### 2. Login User
* **Method**: `POST`
* **URL**: `http://localhost:5000/api/auth/login`
* **Body (JSON)**:
  ```json
  {
    "email": "alex.carter@taskflow.inc",
    "password": "superpassword"
  }
  ```
* **Response**: Menyalin string `"token"` dari data respons untuk digunakan pada request berikutnya.

### 3. Mengakses Protected Route (Contoh: Menampilkan Tugas)
* **Method**: `GET`
* **URL**: `http://localhost:5000/api/tasks`
* **Headers**:
  * Tambahkan key: `Authorization`
  * Value: `Bearer <SALIN_TOKEN_JWT_DISINI>`
* **Query Parameters (Opsional)**:
  * `search` = `landing` (mencari tugas)
  * `status` = `Progress` (filter status)
  * `category_id` = `1` (filter kategori)
  * `sort` = `DESC` (mengurutkan deadline terjauh)

---

## 🌐 Cara Deploy Project

### 1. Deploy Backend (Railway / Render)
1. Buat repositori baru di GitHub dan push folder `backend` Anda ke sana.
2. Daftar di [Render](https://render.com/) atau [Railway](https://railway.app/).
3. Buat layanan MySQL database di cloud dan salin Connection String-nya.
4. Buat Web Service baru di cloud, hubungkan dengan repositori GitHub backend Anda.
5. Tambahkan Environment Variables pada menu setting di cloud:
   * `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `PORT`
   * `JWT_SECRET` (string acak rahasia)
6. Jalankan build command: `npm install` dan Start command: `node server.js`.

### 2. Deploy Frontend Dart (Vercel / Netlify / GitHub Pages)
1. Build Flutter Web ke file statis HTML/JS:
   ```bash
   cd frontend
   flutter build web --release
   ```
2. Hasil build web statis berada di folder: **`frontend/build/web`**
3. Anda bisa mengunggah folder `web` tersebut ke **Vercel**, **Netlify**, atau mengaktifkan **GitHub Pages** di repositori Anda.

---

## 📖 Penjelasan Bagian Kode Utama untuk Tugas Kuliah

### A. JWT Authentication Middleware (`backend/middleware/authMiddleware.js`)
Fungsinya mengamankan rute dari pengguna ilegal. Rute protected tidak akan memproses controller jika header tidak menyertakan JWT token yang valid. Token diuraikan (*decoded*) untuk melampirkan data `req.user` pada request context.

### B. dynamic SQL Joins (`backend/controllers/categoryController.js`)
Untuk menampilkan jumlah tugas per kategori milik user yang sedang aktif secara dinamis, controller menggunakan teknik `LEFT JOIN` dan `GROUP BY` pada query database:
```sql
SELECT c.id, c.category_name, COUNT(t.id) AS task_count
FROM categories c
LEFT JOIN tasks t ON c.id = t.category_id AND t.user_id = ?
GROUP BY c.id;
```

### C. State Persistence (`frontend/lib/providers/auth_provider.dart`)
Mengintegrasikan `SharedPreferences` pada Flutter Web untuk menyimpan JWT string. Saat halaman direfresh, sistem memanggil fungsi `_loadTokenFromStorage()` untuk membaca token, memverifikasinya ke `/api/auth/profile`, lalu memulihkan status login otomatis pengguna.

### D. Responsive UI Layout (`frontend/lib/widgets/responsive_layout.dart`)
Mengatur layout adaptif. Menggunakan `LayoutBuilder` untuk mendeteksi lebar pixel:
* Jika `< 768px` (mobile), ia menampilkan antarmuka bottom navigation bar persis seperti di mockup PDF.
* Jika `>= 768px` (desktop), ia secara premium menampilkan sidebar navigasi kiri yang luas dan rapi.
