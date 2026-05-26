import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

// Widget halaman registrasi utama yang bersifat stateful
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

// State untuk halaman registrasi yang mengelola input data user baru
class _RegisterScreenState extends State<RegisterScreen> {
  // GlobalKey untuk validasi status Form registrasi
  final _formKey = GlobalKey<FormState>();
  
  // Controller untuk menangkap input nama lengkap
  final _nameController = TextEditingController();
  
  // Controller untuk menangkap input alamat email
  final _emailController = TextEditingController();
  
  // Controller untuk menangkap input password
  final _passwordController = TextEditingController();
  
  // Menyembunyikan/menampilkan teks password
  bool _obscurePassword = true;
  
  // Menyimpan pesan kesalahan jika proses registrasi gagal
  String _errorMessage = '';
  
  // Status loading untuk menunjukkan indikator proses pengiriman data
  bool _isSubmitting = false;

  @override
  void dispose() {
    // Membebaskan memori controller saat widget dihancurkan dari widget tree
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Menangani proses pendaftaran (registrasi) pengguna baru
  Future<void> _handleRegister() async {
    // Memvalidasi seluruh input form (Nama, Email, Password). Jika tidak valid, batalkan proses
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true; // Aktifkan indikator loading
      _errorMessage = '';   // Bersihkan pesan error sebelumnya
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Memicu fungsi registrasi pada AuthProvider untuk mengirim data ke API backend
      await authProvider.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      // Jika registrasi berhasil, munculkan SnackBar petunjuk dan kembali ke halaman Login
      if (mounted) {
        final lang = Provider.of<LanguageProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang.translate('register_success_msg'),
              style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF10B981), // Emerald green
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Kembali ke halaman sebelumnya (LoginScreen)
      }
    } catch (e) {
      // Menangkap pesan error dari server jika proses gagal
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
    
    // Mendapatkan lebar layar untuk kebutuhan responsivitas
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 768;

    // Membangun konten utama form registrasi
    Widget formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Judul Form
          Text(
            lang.translate('register_title'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              fontFamily: 'Outfit',
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          // Sub-judul Form
          Text(
            lang.translate('register_welcome_desc'),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 28),

          // Panel Error - ditampilkan jika ada pesan error
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

          // Input field untuk Nama Lengkap
          Text(
            lang.translate('full_name'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 15),
            decoration: InputDecoration(
              hintText: 'John Doe',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
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
              if (value == null || value.trim().isEmpty) return lang.translate('name_required');
              return null;
            },
          ),
          const SizedBox(height: 20),

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
              // Validasi format alamat email menggunakan regular expression
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                return lang.translate('valid_email_required');
              }
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
              if (value.length < 8) return lang.translate('password_min_length');
              return null;
            },
          ),
          const SizedBox(height: 6),
          Text(
            lang.translate('password_hint_characters'),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 28),

          // Tombol untuk mengirimkan data pendaftaran (Register)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleRegister,
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
                      lang.translate('sign_up'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 28),

          // Tautan kembali ke Halaman Login jika pengguna sudah memiliki akun
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: RichText(
                text: TextSpan(
                  text: '${lang.translate('already_have_account').split('?').first}? ',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontFamily: 'Outfit',
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: lang.translate('sign_in'),
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
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

    // Membangun spanduk gelombang (wave banner) di atas form menggunakan WavePainter
    Widget buildWaveBanner(double bannerHeight) {
      return CustomPaint(
        painter: WavePainter(),
        child: SizedBox(
          height: bannerHeight,
          width: double.infinity,
          child: Stack(
            children: [
              // Tombol kembali yang aman diletakkan di pojok kiri atas spanduk
              Positioned(
                top: 40,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(CupertinoIcons.back, color: Color(0xFF4F46E5)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Badge Logo berwarna putih mengambang
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.checkmark_shield,
                          color: primaryColor,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Teks Aplikasi "TaskFlow"
                    const Text(
                      'TaskFlow',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mengembalikan layout Desktop jika lebar layar memenuhi kriteria desktop
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
              // Lingkaran dekorasi latar belakang atas-kiri
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
              // Lingkaran dekorasi latar belakang bawah-kanan
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
              // Kartu form pendaftaran Desktop di tengah layar
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
                          buildWaveBanner(180),
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
            // Lingkaran dekorasi latar belakang atas-kanan
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
            // Lingkaran dekorasi latar belakang bawah-kiri
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
            // Kartu form pendaftaran mobile di tengah layar
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

// Wave CustomPainter untuk menggambar kurva/gelombang mengalir biru muda yang indah pada bagian atas spanduk
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Menggambar latar belakang spanduk dengan gradient biru muda
    final rect = Offset.zero & size;
    final paintBase = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE), Color(0xFF93C5FD)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, paintBase);

    // 2. Menggambar kurva bergelombang putih semi-transparan pertama
    final paintWave1 = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    
    final path1 = Path();
    path1.moveTo(0, size.height * 0.4);
    path1.quadraticBezierTo(size.width * 0.25, size.height * 0.2, size.width * 0.6, size.height * 0.55);
    path1.quadraticBezierTo(size.width * 0.8, size.height * 0.75, size.width, size.height * 0.65);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paintWave1);

    // 3. Menggambar kurva bergelombang putih semi-transparan kedua
    final paintWave2 = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.fill;
      
    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    path2.quadraticBezierTo(size.width * 0.35, size.height * 0.85, size.width * 0.7, size.height * 0.5);
    path2.quadraticBezierTo(size.width * 0.85, size.height * 0.35, size.width, size.height * 0.45);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paintWave2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
