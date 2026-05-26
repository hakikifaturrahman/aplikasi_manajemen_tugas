import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('app_language') ?? 'en';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading language: $e');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode == _currentLanguage) return;
    _currentLanguage = languageCode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', languageCode);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  String translate(String key) {
    if (_translations[key] != null && _translations[key]![_currentLanguage] != null) {
      return _translations[key]![_currentLanguage]!;
    }
    return key;
  }

  static const Map<String, Map<String, String>> _translations = {
    // Common
    'cancel': {
      'en': 'Cancel',
      'id': 'Batal',
    },
    'save': {
      'en': 'Save',
      'id': 'Simpan',
    },
    'delete': {
      'en': 'Delete',
      'id': 'Hapus',
    },
    'edit': {
      'en': 'Edit',
      'id': 'Ubah',
    },
    'close': {
      'en': 'Close',
      'id': 'Tutup',
    },
    'all': {
      'en': 'All',
      'id': 'Semua',
    },
    'pending': {
      'en': 'Pending',
      'id': 'Tertunda',
    },
    'progress': {
      'en': 'In Progress',
      'id': 'Sedang Berjalan',
    },
    'done': {
      'en': 'Completed',
      'id': 'Selesai',
    },

    // Navigation Tabs
    'nav_dashboard': {
      'en': 'Dashboard',
      'id': 'Dasbor',
    },
    'nav_tasks': {
      'en': 'Tasks',
      'id': 'Tugas',
    },
    'nav_category': {
      'en': 'Category',
      'id': 'Kategori',
    },
    'nav_history': {
      'en': 'History',
      'id': 'Riwayat',
    },
    'nav_profile': {
      'en': 'Profile',
      'id': 'Profil',
    },

    // Login Screen
    'login_welcome_title': {
      'en': 'Welcome to TaskFlow',
      'id': 'Selamat Datang di TaskFlow',
    },
    'login_welcome_sub': {
      'en': 'Sign in to manage your tasks effectively',
      'id': 'Masuk untuk mengelola tugas Anda secara efektif',
    },
    'email_address': {
      'en': 'Email Address',
      'id': 'Alamat Email',
    },
    'password': {
      'en': 'Password',
      'id': 'Kata Sandi',
    },
    'sign_in': {
      'en': 'Sign In',
      'id': 'Masuk',
    },
    'dont_have_account': {
      'en': "Don't have an account? Sign Up",
      'id': 'Belum punya akun? Daftar',
    },
    'email_required': {
      'en': 'Email is required',
      'id': 'Email wajib diisi',
    },
    'valid_email_required': {
      'en': 'Enter a valid email address',
      'id': 'Masukkan alamat email yang valid',
    },
    'password_required': {
      'en': 'Password is required',
      'id': 'Kata sandi wajib diisi',
    },

    // Register Screen
    'register_title': {
      'en': 'Create Account',
      'id': 'Buat Akun baru',
    },
    'register_sub': {
      'en': 'Sign up to start collaborating with your team',
      'id': 'Daftar untuk mulai berkolaborasi dengan tim Anda',
    },
    'full_name': {
      'en': 'Full Name',
      'id': 'Nama Lengkap',
    },
    'sign_up': {
      'en': 'Sign Up',
      'id': 'Daftar',
    },
    'already_have_account': {
      'en': 'Already have an account? Sign In',
      'id': 'Sudah punya akun? Masuk',
    },
    'name_required': {
      'en': 'Name is required',
      'id': 'Nama wajib diisi',
    },
    'please_wait': {
      'en': 'Please wait...',
      'id': 'Mohon tunggu...',
    },

    // Dashboard Screen
    'dashboard_welcome': {
      'en': 'Welcome back',
      'id': 'Selamat datang kembali',
    },
    'dashboard_welcome_sub': {
      'en': "Here is an overview of your team's task accomplishments for today. Keep up the amazing work!",
      'id': 'Berikut adalah ringkasan pencapaian tugas tim Anda hari ini. Pertahankan kerja bagus Anda!',
    },
    'stats_overview': {
      'en': 'Stats Overview',
      'id': 'Ikhtisar Statistik',
    },
    'total_tasks': {
      'en': 'Total Tasks',
      'id': 'Total Tugas',
    },
    'productivity_guidelines': {
      'en': 'Productivity Guidelines',
      'id': 'Panduan Produktivitas',
    },
    'tip_1': {
      'en': 'Sort your tasks by deadline to avoid missing key deliveries.',
      'id': 'Urutkan tugas berdasarkan tenggat waktu untuk menghindari keterlambatan penyerahan.',
    },
    'tip_2': {
      'en': 'Define task categories first so tasks are structured cleanly.',
      'id': 'Tentukan kategori tugas terlebih dahulu agar tugas terstruktur dengan rapi.',
    },
    'tip_3': {
      'en': 'Try updating status to "Progress" as soon as you start working.',
      'id': 'Cobalah memperbarui status menjadi "Progress" segera setelah Anda mulai bekerja.',
    },
    'recent_notifications': {
      'en': 'Recent Notifications',
      'id': 'Notifikasi Terbaru',
    },
    'no_notifications': {
      'en': 'No notifications',
      'id': 'Tidak ada notifikasi',
    },
    'notif_due_today': {
      'en': 'Due Today! ⚠️',
      'id': 'Jatuh Tempo Hari Ini! ⚠️',
    },
    'notif_due_today_desc': {
      'en': 'Task "{title}" must be completed today.',
      'id': 'Tugas "{title}" harus diselesaikan hari ini.',
    },
    'notif_due_tomorrow': {
      'en': 'Due Tomorrow ⏰',
      'id': 'Tenggat Besok ⏰',
    },
    'notif_due_tomorrow_desc': {
      'en': 'Task "{title}" is approaching deadline tomorrow.',
      'id': 'Tugas "{title}" mendekati batas waktu besok.',
    },
    'notif_overdue': {
      'en': 'Overdue 🚨',
      'id': 'Terlewat (Overdue) 🚨',
    },
    'notif_overdue_desc': {
      'en': 'Task "{title}" has passed its deadline ({deadline}).',
      'id': 'Tugas "{title}" telah melewati tenggat waktu ({deadline}).',
    },
    'notif_completed': {
      'en': 'Task Completed! 🎉',
      'id': 'Tugas Selesai! 🎉',
    },
    'notif_completed_desc': {
      'en': 'Great job! You have completed task "{title}".',
      'id': 'Hebat! Anda telah menyelesaikan tugas "{title}".',
    },
    'notif_active_activities': {
      'en': 'Active Activities ⚡',
      'id': 'Aktivitas Berjalan ⚡',
    },
    'notif_active_activities_desc': {
      'en': 'You have {count} tasks currently in progress. Stay focused!',
      'id': 'Anda memiliki {count} tugas yang sedang dikerjakan. Tetap fokus!',
    },
    'notif_welcome': {
      'en': 'Welcome to TaskFlow 👋',
      'id': 'Selamat Datang di TaskFlow 👋',
    },
    'notif_welcome_desc': {
      'en': 'No important notifications yet. Add a new task to start tracking your productivity!',
      'id': 'Belum ada pemberitahuan penting. Tambahkan tugas baru untuk memulai produktivitas Anda!',
    },
    'restoring_session': {
      'en': 'Restoring TaskFlow session...',
      'id': 'Memulihkan sesi TaskFlow...',
    },

    // Tasks Screen
    'search': {
      'en': 'Search',
      'id': 'Cari',
    },
    'search_tasks': {
      'en': 'Search tasks...',
      'id': 'Cari tugas...',
    },
    'no_tasks_desc': {
      'en': 'Your workspace is completely clear. Get started by adding a new task using the button below!',
      'id': 'Ruang kerja Anda sepenuhnya bersih. Mulailah dengan menambahkan tugas baru menggunakan tombol di bawah!',
    },
    'filter_status': {
      'en': 'Filter Status',
      'id': 'Filter Status',
    },
    'filter_category': {
      'en': 'Filter Category',
      'id': 'Filter Kategori',
    },
    'sort_deadline_asc': {
      'en': 'Deadline ASC',
      'id': 'Tenggat Terdekat',
    },
    'sort_deadline_desc': {
      'en': 'Deadline DESC',
      'id': 'Tenggat Terjauh',
    },
    'no_tasks_found': {
      'en': 'No tasks found.',
      'id': 'Tidak ada tugas ditemukan.',
    },
    'add_task': {
      'en': 'Add Task',
      'id': 'Tambah Tugas',
    },
    'edit_task': {
      'en': 'Edit Task',
      'id': 'Ubah Tugas',
    },
    'delete_task': {
      'en': 'Delete Task',
      'id': 'Hapus Tugas',
    },
    'delete_task_confirm': {
      'en': 'Are you sure you want to delete this task?',
      'id': 'Apakah Anda yakin ingin menghapus tugas ini?',
    },
    'task_title': {
      'en': 'Task Title',
      'id': 'Judul Tugas',
    },
    'task_title_required': {
      'en': 'Task title is required',
      'id': 'Judul tugas wajib diisi',
    },
    'task_desc': {
      'en': 'Description (Optional)',
      'id': 'Deskripsi (Opsional)',
    },
    'task_deadline': {
      'en': 'Deadline Date',
      'id': 'Tenggat Waktu',
    },
    'task_category': {
      'en': 'Category',
      'id': 'Kategori',
    },
    'task_status': {
      'en': 'Status',
      'id': 'Status',
    },
    'select_category': {
      'en': 'Select category',
      'id': 'Pilih kategori',
    },
    'category_required': {
      'en': 'Category is required',
      'id': 'Kategori wajib diisi',
    },

    // Category Screen
    'categories': {
      'en': 'Categories',
      'id': 'Kategori',
    },
    'add_category': {
      'en': 'Add Category',
      'id': 'Tambah Kategori',
    },
    'edit_category': {
      'en': 'Edit Category',
      'id': 'Ubah Kategori',
    },
    'delete_category': {
      'en': 'Delete Category',
      'id': 'Hapus Kategori',
    },
    'delete_category_confirm': {
      'en': 'Are you sure you want to delete this category? All tasks associated with this category will also be deleted.',
      'id': 'Apakah Anda yakin ingin menghapus kategori ini? Semua tugas yang berkaitan dengan kategori ini juga akan dihapus.',
    },
    'category_name': {
      'en': 'Category Name',
      'id': 'Nama Kategori',
    },
    'category_name_required': {
      'en': 'Category name is required',
      'id': 'Nama kategori wajib diisi',
    },

    // History Screen
    'task_history': {
      'en': 'Task History',
      'id': 'Riwayat Tugas',
    },
    'history_log': {
      'en': 'Activity Log',
      'id': 'Log Aktivitas',
    },
    'no_history_found': {
      'en': 'No history records found.',
      'id': 'Tidak ada riwayat aktivitas ditemukan.',
    },
    'history_created': {
      'en': 'Created',
      'id': 'Dibuat',
    },
    'history_updated_status': {
      'en': 'Updated Status',
      'id': 'Diperbarui Status',
    },
    'history_updated_details': {
      'en': 'Updated Details',
      'id': 'Diperbarui Rincian',
    },
    'history_deleted': {
      'en': 'Deleted',
      'id': 'Dihapus',
    },

    // Profile Screen
    'profile': {
      'en': 'Profile',
      'id': 'Profil',
    },
    'language': {
      'en': 'Language',
      'id': 'Bahasa',
    },
    'change_language': {
      'en': 'Change Language',
      'id': 'Ubah Bahasa',
    },
    'edit_profile': {
      'en': 'Edit Profile',
      'id': 'Ubah Profil',
    },
    'change_password': {
      'en': 'Change Password',
      'id': 'Ubah Kata Sandi',
    },
    'notifications': {
      'en': 'Notifications',
      'id': 'Notifikasi',
    },
    'privacy_security': {
      'en': 'Privacy & Security',
      'id': 'Privasi & Keamanan',
    },
    'help_support': {
      'en': 'Help & Support',
      'id': 'Bantuan & Dukungan',
    },
    'logout': {
      'en': 'Logout',
      'id': 'Keluar',
    },
    'confirm_logout': {
      'en': 'Confirm Logout',
      'id': 'Konfirmasi Keluar',
    },
    'logout_confirm_msg': {
      'en': 'Are you sure you want to log out of your session?',
      'id': 'Apakah Anda yakin ingin keluar dari sesi Anda?',
    },
    'avatar_change_title': {
      'en': 'Change Profile Picture',
      'id': 'Ubah Foto Profil',
    },
    'avatar_preset': {
      'en': 'Choose from Preset Avatars:',
      'id': 'Pilih dari Avatar Preset:',
    },
    'avatar_pick_device': {
      'en': 'Choose from Device',
      'id': 'Pilih dari Perangkat',
    },
    'avatar_custom_url': {
      'en': 'Or enter custom Photo URL:',
      'id': 'Atau masukkan URL Foto kustom:',
    },
    'avatar_success_msg': {
      'en': 'Profile picture uploaded successfully! Click Save to apply.',
      'id': 'Foto profil berhasil diunggah! Klik Simpan untuk menerapkan.',
    },
    'avatar_fail_msg': {
      'en': 'Failed to select image:',
      'id': 'Gagal memilih foto:',
    },
    'notif_setting_remind': {
      'en': 'Remind task deadlines',
      'id': 'Ingatkan batas waktu tugas',
    },
    'notif_setting_remind_sub': {
      'en': 'Receive alerts when tasks approach deadline',
      'id': 'Terima peringatan ketika tugas mendekati batas waktu',
    },
    'notif_setting_report': {
      'en': 'Weekly report',
      'id': 'Laporan mingguan',
    },
    'notif_setting_report_sub': {
      'en': 'Receive weekly progress summary via email',
      'id': 'Terima ringkasan progres mingguan via email',
    },
    'notif_setting_new_task': {
      'en': 'New team tasks',
      'id': 'Tugas tim baru',
    },
    'notif_setting_new_task_sub': {
      'en': 'Notification when assigned to a new task',
      'id': 'Notifikasi saat ditugaskan tugas baru',
    },
    'notif_setting_email': {
      'en': 'Email alerts',
      'id': 'Notifikasi email',
    },
    'notif_setting_email_sub': {
      'en': 'Receive copies of important alerts in your email',
      'id': 'Terima salinan notifikasi penting di email',
    },
    'notif_save_success': {
      'en': 'Notification settings saved successfully!',
      'id': 'Pengaturan notifikasi berhasil disimpan!',
    },
    'security_private_profile': {
      'en': 'Private Profile',
      'id': 'Profil Privat',
    },
    'security_private_profile_sub': {
      'en': 'Only team members can view your profile details',
      'id': 'Hanya anggota tim yang dapat melihat detail profil Anda',
    },
    'security_2fa': {
      'en': 'Two-Factor Authentication',
      'id': 'Autentikasi Dua Faktor',
    },
    'security_2fa_sub': {
      'en': 'Extra security using Google Authenticator OTP codes',
      'id': 'Keamanan ekstra menggunakan kode OTP Google Authenticator',
    },
    'security_session_timeout': {
      'en': 'Automatic Session Timeout',
      'id': 'Timeout Sesi Otomatis',
    },
    'security_session_timeout_sub': {
      'en': 'Log out automatically if inactive for 30 minutes',
      'id': 'Keluarkan akun secara otomatis jika tidak ada aktivitas selama 30 menit',
    },
    'security_encryption_method': {
      'en': 'Encryption Method',
      'id': 'Metode Enkripsi',
    },
    'security_session_token': {
      'en': 'Session Token',
      'id': 'Token Sesi',
    },
    'security_save_success': {
      'en': 'Security settings updated successfully!',
      'id': 'Pengaturan keamanan berhasil diperbarui!',
    },
    'support_faq_q1': {
      'en': 'How to create a task?',
      'id': 'Bagaimana cara membuat tugas?',
    },
    'support_faq_a1': {
      'en': 'You can create tasks by clicking the "+" button in the Tasks or Dashboard menus.',
      'id': 'Anda bisa membuat tugas dengan mengeklik tombol "+" di menu Tasks atau Dashboard.',
    },
    'support_faq_q2': {
      'en': 'How to change category?',
      'id': 'Bagaimana cara mengganti kategori?',
    },
    'support_faq_a2': {
      'en': 'Manage categories in the Categories page, then select the category when editing or creating a task.',
      'id': 'Kelola kategori di halaman Categories, lalu pilih kategori tersebut saat mengedit atau membuat tugas.',
    },
    'support_contact_us': {
      'en': 'Contact Us',
      'id': 'Hubungi Kami',
    },
    'support_subject': {
      'en': 'Subject',
      'id': 'Subjek',
    },
    'support_message': {
      'en': 'Message or Problem Description',
      'id': 'Pesan atau Deskripsi Masalah',
    },
    'support_subject_required': {
      'en': 'Subject is required',
      'id': 'Subjek harus diisi',
    },
    'support_message_required': {
      'en': 'Message is required',
      'id': 'Pesan harus diisi',
    },
    'support_success_msg': {
      'en': 'Your message regarding "{subject}" has been successfully sent and saved!',
      'id': 'Pesan Anda mengenai "\${subject}" berhasil dikirim dan disimpan!',
    },
    'support_fail_msg': {
      'en': 'Failed to send message:',
      'id': 'Gagal mengirim pesan:',
    },
    'profile_save_changes': {
      'en': 'Save Changes',
      'id': 'Simpan Perubahan',
    },
    'profile_new_password': {
      'en': 'New Password',
      'id': 'Kata Sandi Baru',
    },
    'profile_update_btn': {
      'en': 'Update',
      'id': 'Perbarui',
    },
    // New translation keys
    'all_statuses': {
      'en': 'All Statuses',
      'id': 'Semua Status',
    },
    'all_categories': {
      'en': 'All Categories',
      'id': 'Semua Kategori',
    },
    'confirm_deletion': {
      'en': 'Confirm Deletion',
      'id': 'Konfirmasi Penghapusan',
    },
    'delete_task_confirm_desc': {
      'en': 'Are you sure you want to permanently delete this task?',
      'id': 'Apakah Anda yakin ingin menghapus tugas ini secara permanen?',
    },
    'delete_category_confirm_desc': {
      'en': 'Are you sure you want to permanently delete this category? Note: All tasks under this category will also be deleted.',
      'id': 'Apakah Anda yakin ingin menghapus kategori ini secara permanen? Catatan: Semua tugas di bawah kategori ini juga akan dihapus.',
    },
    'task_deleted_success': {
      'en': 'Task deleted successfully',
      'id': 'Tugas berhasil dihapus',
    },
    'task_delete_failed': {
      'en': 'Failed to delete task',
      'id': 'Gagal menghapus tugas',
    },
    'task_marked_done': {
      'en': 'Task marked as Done! 🎉',
      'id': 'Tugas ditandai Selesai! 🎉',
    },
    'task_already_done': {
      'en': 'Task is already completed!',
      'id': 'Tugas sudah selesai!',
    },
    'task_update_failed': {
      'en': 'Failed to update task',
      'id': 'Gagal memperbarui tugas',
    },
    'mark_as_done': {
      'en': 'Mark as Done',
      'id': 'Tandai Selesai',
    },
    'category_deleted_success': {
      'en': 'Category deleted successfully',
      'id': 'Kategori berhasil dihapus',
    },
    'category_delete_failed': {
      'en': 'Failed to delete category (tasks might exist)',
      'id': 'Gagal menghapus kategori (mungkin masih ada tugas di dalamnya)',
    },
    'no_categories_yet': {
      'en': 'No Categories Yet',
      'id': 'Belum Ada Kategori',
    },
    'no_categories_desc': {
      'en': 'Organize your work by creating custom categories first.',
      'id': 'Organisasikan pekerjaan Anda dengan membuat kategori kustom terlebih dahulu.',
    },
    'login_welcome_back': {
      'en': 'Welcome Back',
      'id': 'Selamat Datang Kembali',
    },
    'login_welcome_desc': {
      'en': 'Please enter your details to sign in.',
      'id': 'Silakan masukkan detail Anda untuk masuk.',
    },
    'email_hint': {
      'en': 'name@company.com',
      'id': 'nama@perusahaan.com',
    },
    'dont_have_account_question': {
      'en': "Don't have an account?",
      'id': 'Belum punya akun?',
    },
    'register_now': {
      'en': 'Register now',
      'id': 'Daftar sekarang',
    },
    'register_welcome_desc': {
      'en': 'Join TaskFlow and streamline your work.',
      'id': 'Bergabunglah dengan TaskFlow dan permudah pekerjaan Anda.',
    },
    'password_min_length': {
      'en': 'Password must be at least 8 characters',
      'id': 'Kata sandi minimal harus 8 karakter',
    },
    'password_hint_characters': {
      'en': 'Must be at least 8 characters.',
      'id': 'Minimal harus 8 karakter.',
    },
    'register_success_msg': {
      'en': 'Registration successful! Please log in.',
      'id': 'Registrasi berhasil! Silakan login dengan akun Anda.',
    },
    'new_task': {
      'en': 'New Task',
      'id': 'Tugas Baru',
    },
    'task_name_label': {
      'en': 'Task Name',
      'id': 'Nama Tugas',
    },
    'task_name_hint': {
      'en': 'e.g. Design Landing Page',
      'id': 'misal: Desain Halaman Utama',
    },
    'task_name_required': {
      'en': 'Task name is required',
      'id': 'Nama tugas wajib diisi',
    },
    'description_label': {
      'en': 'Description',
      'id': 'Deskripsi',
    },
    'task_desc_hint': {
      'en': 'Add details about this task...',
      'id': 'Tambahkan detail tugas ini...',
    },
    'select_a_category': {
      'en': 'Select a category',
      'id': 'Pilih kategori',
    },
    'deadline_label': {
      'en': 'Deadline',
      'id': 'Tenggat Waktu',
    },
    'deadline_placeholder': {
      'en': 'mm/dd/yyyy',
      'id': 'bb/hh/tttt',
    },
    'save_task': {
      'en': 'Save Task',
      'id': 'Simpan Tugas',
    },
    'new_category': {
      'en': 'New Category',
      'id': 'Kategori Baru',
    },
    'category_name_hint': {
      'en': 'e.g. UI/UX, Backend, QA',
      'id': 'misal: UI/UX, Backend, QA',
    },
    'deadline_required': {
      'en': 'Please select a deadline',
      'id': 'Silakan pilih tenggat waktu',
    },
    'load_categories_failed': {
      'en': 'Failed to load categories',
      'id': 'Gagal memuat kategori',
    },
  };
}
