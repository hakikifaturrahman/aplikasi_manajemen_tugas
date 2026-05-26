import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import '../providers/language_provider.dart';


// Widget halaman login utama yang bersifat stateful
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// State untuk halaman login yang mengelola form, controller, dan interaksi user
class _LoginScreenState extends State<LoginScreen> {
  // GlobalKey untuk mengontrol status validasi Form
  final _formKey = GlobalKey<FormState>();
  
  // Controller untuk menangkap input teks email
  final _emailController = TextEditingController();
  
  // Controller untuk menangkap input teks password
  final _passwordController = TextEditingController();
  
  // Flag untuk menyembunyikan/menampilkan teks password
  bool _obscurePassword = true;
  
  // Menyimpan pesan kesalahan jika proses login gagal
  String _errorMessage = '';
  
  // Status loading untuk menunjukkan indikator proses pengiriman data
  bool _isSubmitting = false;

  @override
  void dispose() {
    // Membebaskan memori controller saat widget dihancurkan
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Menangani proses masuk (login) pengguna
  Future<void> _handleLogin() async {
    // Memvalidasi form input (email & password). Jika tidak valid, batalkan proses
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true; // Aktifkan indikator loading
      _errorMessage = '';   // Bersihkan pesan error sebelumnya
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Memicu fungsi login pada AuthProvider untuk otentikasi ke API backend
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      // Menangkap jika login gagal dan menampilkan pesan error ke layar
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false; // Matikan indikator loading
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    // Warna utama tema aplikasi
    const primaryColor = Color(0xFF4F46E5);
    
    // Mendapatkan lebar layar untuk menyesuaikan responsivitas layout
    final width = MediaQuery.of(context).size.width;
    
    // Menentukan apakah aplikasi sedang berjalan pada layar ukuran Desktop (lebar >= 768)
    final isDesktop = width >= 768;

    // Membangun konten utama form login
    Widget formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo Badge berwarna biru (di tengah atas kartu login)
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.checkmark_shield_fill,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Teks Judul Selamat Datang
          Center(
            child: Text(
              lang.translate('login_welcome_back'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                fontFamily: 'Outfit',
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              lang.translate('login_welcome_desc'),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontFamily: 'Outfit',
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Panel Error - hanya ditampilkan jika ada pesan error
          if (_errorMessage.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Color(0xFF991B1B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Input field untuk Email
          Text(
            lang.translate('email_address'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 15),
            decoration: InputDecoration(
              hintText: lang.translate('email_hint'),
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(CupertinoIcons.mail, color: Color(0xFF94A3B8), size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return lang.translate('email_required');
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Input field untuk Password
          Text(
            lang.translate('password'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 15),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(CupertinoIcons.lock, color: Color(0xFF94A3B8), size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () {
                  // Mengubah status visibilitas teks password
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return lang.translate('password_required');
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Tombol untuk mengirimkan form login (Sign In)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      lang.translate('sign_in'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Tautan/Link untuk mengarahkan pengguna ke halaman Pendaftaran (Register)
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "${lang.translate('dont_have_account_question')} ",
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontFamily: 'Outfit',
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: '\n${lang.translate('register_now')}',
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Helper untuk membuat spanduk grafis dekoratif di bagian atas kartu login
    Widget buildGraphicBanner(double bannerHeight) {
      return Container(
        height: bannerHeight,
        width: double.infinity,
        color: const Color(0xFFF1F5F9),
        child: Image.asset(
          'assets/images/login_banner.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Tampilan cadangan berkualitas tinggi jika asset gambar tidak tersedia atau gagal dimuat
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD), Color(0xFFE0E7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.device_laptop, color: primaryColor.withOpacity(0.6), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'TaskFlow Team Workspace',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: primaryColor.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // Mengembalikan layout khusus Desktop jika lebar layar memenuhi kriteria
    if (isDesktop) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF4338CA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Efek lingkaran dekoratif background atas-kiri
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Efek lingkaran dekoratif background bawah-kanan
              Positioned(
                bottom: -150,
                right: -150,
                child: Container(
                  width: 450,
                  height: 450,
                  decoration: BoxDecoration(
                    color: Colors.indigoAccent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Kartu Login Desktop di tengah layar
              Center(
                child: Container(
                  width: 460,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          buildGraphicBanner(180),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
                            child: formContent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mengembalikan layout Mobile default dengan form scrollable di tengah layar
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Lingkaran dekoratif background atas-kanan
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Lingkaran dekoratif background bawah-kiri
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.indigoAccent.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Kartu login mobile di tengah layar
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: formContent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
