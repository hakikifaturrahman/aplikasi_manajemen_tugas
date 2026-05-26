import 'dart:convert';
import 'package:http/http.dart' as http;

/**
 * Service class untuk menangani seluruh komunikasi HTTP ke Node.js Backend API
 */
class ApiService {
  // IP Local PC untuk testing via HP fisik (sesuaikan dengan adb reverse atau IP lokal Wifi Anda)
  static const String baseUrl = 'http://localhost:5000/api';
  String? _token;

  // Menyimpan token akses JWT secara aktif
  void setToken(String? token) {
    _token = token;
  }

  // Helper untuk menyusun Headers HTTP standar, menyertakan Bearer token jika user login
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token'; // Autentikasi JWT
    }
    return headers;
  }

  // Helper untuk mendeteksi error HTTP (status >= 400) dan melempar pesan kesalahan yang ramah pengguna
  void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Server error: Code ${response.statusCode}');
      }
      throw Exception(body['message'] ?? 'An error occurred on the server.');
    }
  }

  // ==================== AUTHENTICATION API ====================

  // Mendaftarkan user baru
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _getHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );
    _handleError(response);
    return jsonDecode(response.body);
  }

  // Melakukan login pengguna
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    _handleError(response);
    return jsonDecode(response.body);
  }

  // Mengambil profil pengguna yang sedang login
  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: _getHeaders(),
    );
    _handleError(response);
    return jsonDecode(response.body);
  }

  // Memperbarui informasi profil pengguna
  Future<Map<String, dynamic>> updateProfile(String name, String email, {String? password, String? profilePicture}) async {
    final Map<String, dynamic> body = {
      'name': name,
      'email': email,
    };
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }
    if (profilePicture != null) {
      body['profile_picture'] = profilePicture;
    }
    final response = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: _getHeaders(),
      body: jsonEncode(body),
    );
    _handleError(response);
    return jsonDecode(response.body);
  }

  // Mengunggah gambar profil berformat Base64
  Future<String> uploadProfilePicture(String base64Image, String fileName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/upload'),
      headers: _getHeaders(),
      body: jsonEncode({
        'imageBase64': base64Image,
        'fileName': fileName,
      }),
    );
    _handleError(response);
    final data = jsonDecode(response.body);
    return data['url'] as String;
  }

  // ==================== TASKS API ====================

  // Mengambil seluruh tugas milik user (Mendukung pencarian, filter status, filter kategori, sorting)
  Future<List<dynamic>> getTasks({
    String? search,
    String? status,
    int? categoryId,
    String? sort,
  }) async {
    final Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status != 'All') queryParams['status'] = status;
    if (categoryId != null) queryParams['category_id'] = categoryId.toString();
    if (sort != null) queryParams['sort'] = sort;

    final uri = Uri.parse('$baseUrl/tasks').replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: _getHeaders(),
    );
    _handleError(response);
    final data = jsonDecode(response.body);
    return data['data'] as List<dynamic>;
  }

  // Menambahkan tugas baru
  Future<Map<String, dynamic>> createTask(
    String title,
    String description,
    String deadline,
    String status,
    int categoryId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: _getHeaders(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'deadline': deadline,
        'status': status,
        'category_id': categoryId,
      }),
    );
    _handleError(response);
    return jsonDecode(response.body)['data'];
  }

  // Memperbarui rincian data tugas
  Future<Map<String, dynamic>> updateTask(
    int id, {
    String? title,
    String? description,
    String? deadline,
    String? status,
    int? categoryId,
  }) async {
    final Map<String, dynamic> body = {};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (deadline != null) body['deadline'] = deadline;
    if (status != null) body['status'] = status;
    if (categoryId != null) body['category_id'] = categoryId;

    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: _getHeaders(),
      body: jsonEncode(body),
    );
    _handleError(response);
    return jsonDecode(response.body)['data'];
  }

  // Menghapus data tugas berdasarkan ID
  Future<void> deleteTask(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: _getHeaders(),
    );
    _handleError(response);
  }

  // Mengambil riwayat aktivitas tugas milik user
  Future<List<dynamic>> getTaskHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/history'),
      headers: _getHeaders(),
    );
    _handleError(response);
    final data = jsonDecode(response.body);
    return data['data'] as List<dynamic>;
  }


  // ==================== CATEGORIES API ====================

  // Mengambil seluruh kategori daftar tugas
  Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: _getHeaders(),
    );
    _handleError(response);
    final data = jsonDecode(response.body);
    return data['data'] as List<dynamic>;
  }

  // Membuat kategori baru
  Future<Map<String, dynamic>> createCategory(String categoryName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: _getHeaders(),
      body: jsonEncode({
        'category_name': categoryName,
      }),
    );
    _handleError(response);
    return jsonDecode(response.body)['data'];
  }

  // Memperbarui nama kategori
  Future<Map<String, dynamic>> updateCategory(int id, String categoryName) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: _getHeaders(),
      body: jsonEncode({
        'category_name': categoryName,
      }),
    );
    _handleError(response);
    return jsonDecode(response.body)['data'];
  }

  // Menghapus kategori berdasarkan ID
  Future<void> deleteCategory(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: _getHeaders(),
    );
    _handleError(response);
  }

  // ==================== SETTINGS & SUPPORT API ====================

  // Memperbarui pengaturan personal milik pengguna
  Future<Map<String, dynamic>> updateUserSettings({
    bool? remindDeadlines,
    bool? weeklyReport,
    bool? newTasks,
    bool? emailAlerts,
    bool? isPrivateProfile,
    bool? enableTwoFactor,
    bool? sessionTimeout,
  }) async {
    final Map<String, dynamic> body = {};
    if (remindDeadlines != null) body['remind_deadlines'] = remindDeadlines ? 1 : 0;
    if (weeklyReport != null) body['weekly_report'] = weeklyReport ? 1 : 0;
    if (newTasks != null) body['new_tasks'] = newTasks ? 1 : 0;
    if (emailAlerts != null) body['email_alerts'] = emailAlerts ? 1 : 0;
    if (isPrivateProfile != null) body['is_private_profile'] = isPrivateProfile ? 1 : 0;
    if (enableTwoFactor != null) body['enable_two_factor'] = enableTwoFactor ? 1 : 0;
    if (sessionTimeout != null) body['session_timeout'] = sessionTimeout ? 1 : 0;

    final response = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: _getHeaders(),
      body: jsonEncode(body),
    );
    _handleError(response);
    return jsonDecode(response.body);
  }

  // Mengirimkan tiket bantuan (support ticket) ke admin database
  Future<Map<String, dynamic>> submitSupportTicket(String subject, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/support/ticket'),
      headers: _getHeaders(),
      body: jsonEncode({
        'subject': subject,
        'message': message,
      }),
    );
    _handleError(response);
    return jsonDecode(response.body);
  }
}
