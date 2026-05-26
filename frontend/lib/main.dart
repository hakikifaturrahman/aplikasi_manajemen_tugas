import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'widgets/responsive_layout.dart';
import 'screens/login_screen.dart';

// Fungsi utama entry point jalannya aplikasi Flutter
void main() {
  runApp(
    // Menggunakan MultiProvider untuk mengelola state global menggunakan Provider
    MultiProvider(
      providers: [
        // Menyediakan AuthProvider (State Management Authentikasi) ke seluruh widget tree
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Menyediakan LanguageProvider ke seluruh widget tree
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const TaskFlowApp(),
    ),
  );
}

// Widget utama root aplikasi
class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4F46E5); // Warna tema indigo utama
    final lang = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      title: 'TaskFlow - Todo Team Management',
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug di pojok kanan atas
      
      // Konfigurasi tema global aplikasi (Material 3, Outfit font family, HSL palette)
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          surface: Colors.white,
          background: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Outfit', // Font kustom
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      
      // Menggunakan Consumer untuk mendengarkan perubahan state di AuthProvider secara dinamis
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // 1. Loading screen saat aplikasi memulihkan session JWT dari storage local
          if (auth.isLoading) {
             return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      lang.translate('restoring_session'),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // 2. Proteksi Rute (Route Guard): Jika sudah terautentikasi (JWT valid/ada), arahkan ke dashboard
          if (auth.isAuthenticated) {
            return const ResponsiveLayout();
          }

          // 3. Fallback: Jika belum login, tampilkan layar masuk (LoginScreen)
          return const LoginScreen();
        },
      ),
    );
  }
}
