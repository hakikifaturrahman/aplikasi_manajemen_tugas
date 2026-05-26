import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

/**
 * AuthProvider: Mengelola state global autentikasi pengguna menggunakan ChangeNotifier.
 * Menyimpan token login, memulihkan sesi, melakukan registrasi/login, dan mengupdate profil/pengaturan.
 */
class AuthProvider extends ChangeNotifier {
  // Menginisialisasi satu instance ApiService untuk komunikasi API
  final ApiService apiService = ApiService();
  
  User? _user;
  String? _token;
  bool _isAuthenticated = false;
  bool _isLoading = true; // Status loading saat pertama kali memuat session

  // Getters untuk mendistribusikan data ke UI secara aman (read-only)
  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  // Konstruktor: Otomatis memuat token tersimpan dari storage local saat aplikasi dibuka
  AuthProvider() {
    _loadTokenFromStorage();
  }

  // Memulihkan session JWT dari SharedPreferences local storage
  Future<void> _loadTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('jwt_token');

      if (savedToken != null) {
        _token = savedToken;
        apiService.setToken(savedToken); // Set token ke ApiService agar tersemat di Header HTTP

        // Memvalidasi token ke server dengan memanggil API getProfile
        final response = await apiService.getProfile();
        if (response['success'] == true) {
          _user = User.fromJson(response['data']['user']);
          _isAuthenticated = true;
          debugPrint('Session restored successfully for user: ${_user?.name}');
        } else {
          // Token kedaluwarsa atau tidak valid di database backend
          _clearSession();
        }
      }
    } catch (e) {
      debugPrint('Error loading saved token: $e');
      _clearSession();
    } finally {
      _isLoading = false;
      notifyListeners(); // Memberitahu UI untuk me-rebuild widget tree (misalnya beralih dari loading ke dashboard/login)
    }
  }

  // Melakukan Registrasi pengguna baru
  Future<void> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.register(name, email, password);
      
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Registration failed');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Melakukan Login pengguna
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.login(email, password);

      if (response['success'] == true) {
        final tokenData = response['data']['token'];
        final userData = response['data']['user'];

        _token = tokenData;
        _user = User.fromJson(userData);
        _isAuthenticated = true;

        apiService.setToken(tokenData); // Masukkan token ke instance ApiService
        
        // Menyimpan token JWT ke penyimpanan lokal HP secara persisten
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', tokenData);
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Memperbarui informasi profil pengguna
  Future<void> updateProfile(String name, String email, {String? password, String? profilePicture}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.updateProfile(name, email, password: password, profilePicture: profilePicture);
      if (response['success'] == true) {
        _user = User.fromJson(response['data']['user']);
      } else {
        throw Exception(response['message'] ?? 'Profile update failed');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper untuk membersihkan state autentikasi lokal dan menghapus token dari storage
  Future<void> _clearSession() async {
    _user = null;
    _token = null;
    _isAuthenticated = false;
    apiService.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // Melakukan Logout pengguna
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _clearSession();

    _isLoading = false;
    notifyListeners();
  }

  // Memperbarui pengaturan personal milik pengguna
  Future<void> updateUserSettings({
    bool? remindDeadlines,
    bool? weeklyReport,
    bool? newTasks,
    bool? emailAlerts,
    bool? isPrivateProfile,
    bool? enableTwoFactor,
    bool? sessionTimeout,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.updateUserSettings(
        remindDeadlines: remindDeadlines,
        weeklyReport: weeklyReport,
        newTasks: newTasks,
        emailAlerts: emailAlerts,
        isPrivateProfile: isPrivateProfile,
        enableTwoFactor: enableTwoFactor,
        sessionTimeout: sessionTimeout,
      );
      if (response['success'] == true) {
        _user = User.fromJson(response['data']['user']);
      } else {
        throw Exception(response['message'] ?? 'Failed to update settings');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mengirimkan tiket bantuan (support ticket) ke database
  Future<void> submitSupportTicket(String subject, String message) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.submitSupportTicket(subject, message);
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to submit support ticket');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
