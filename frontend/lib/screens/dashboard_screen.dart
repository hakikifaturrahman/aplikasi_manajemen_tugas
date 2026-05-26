import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../models/task.dart';

// Widget halaman Dashboard utama yang bersifat stateful
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// State untuk halaman Dashboard yang mengelola pemuatan data statistik tugas
class _DashboardScreenState extends State<DashboardScreen> {
  // Flag status pemuatan data dari server API
  bool _isLoading = true;
  
  // Daftar objek tugas yang didapatkan dari database backend
  List<Task> _tasks = [];
  
  // Variabel untuk menyimpan pesan kesalahan jika request gagal
  String _errorMessage = '';
  
  // Flag indikasi adanya notifikasi penting baru yang belum dibaca
  bool _hasUnreadNotifications = true;

  @override
  void initState() {
    super.initState();
    // Memulai pengambilan data dashboard saat pertama kali screen dimuat
    _fetchDashboardData();
  }

  // Mengambil data tugas dari backend untuk menampilkan ringkasan statistik di dashboard
  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; // Aktifkan indikator loading utama
      _errorMessage = ''; // Bersihkan pesan error sebelumnya
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // Mengambil daftar tugas terbaru milik user aktif dari API
      final rawTasks = await auth.apiService.getTasks();
      
      setState(() {
        // Mengonversi data JSON biner dari API menjadi daftar objek model Task di Flutter
        _tasks = rawTasks.map((t) => Task.fromJson(t)).toList();
        // Mengaktifkan tanda notifikasi merah untuk mensimulasikan notifikasi baru
        _hasUnreadNotifications = true;
      });
    } catch (e) {
      // Menangkap dan menyimpan pesan kesalahan pemuatan data
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Matikan indikator loading
        });
      }
    }
  }

  // Menampilkan lembar/panel notifikasi kustom berdasarkan kondisi deadline tugas
  void _showNotificationsPanel() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    setState(() {
      // Menandai bahwa pengguna telah membaca notifikasi terbaru
      _hasUnreadNotifications = false;
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Menampung daftar notifikasi dinamis yang dibuat secara lokal
    List<Map<String, dynamic>> systemNotifications = [];

    // 1. Memeriksa tugas-tugas yang belum selesai dan mendekati atau sudah melewati deadline
    for (var task in _tasks) {
      if (task.status != 'Done') {
        try {
          final taskDate = task.deadline;
          final cleanTaskDate = DateTime(taskDate.year, taskDate.month, taskDate.day);
          
          // Mengecek jika tenggat waktu tugas adalah HARI INI
          if (cleanTaskDate.isAtSameMomentAs(today)) {
            systemNotifications.add({
              'title': lang.translate('notif_due_today'),
              'body': lang.translate('notif_due_today_desc').replaceAll('{title}', task.title),
              'type': 'alert',
              'time': lang.currentLanguage == 'id' ? 'Hari ini' : 'Today',
              'icon': CupertinoIcons.exclamationmark_triangle_fill,
              'color': const Color(0xFFEF4444), // Merah
            });
          } 
          // Mengecek jika tenggat waktu tugas adalah BESOK
          else if (cleanTaskDate.isAtSameMomentAs(tomorrow)) {
            systemNotifications.add({
              'title': lang.translate('notif_due_tomorrow'),
              'body': lang.translate('notif_due_tomorrow_desc').replaceAll('{title}', task.title),
              'type': 'warning',
              'time': lang.currentLanguage == 'id' ? 'Besok' : 'Tomorrow',
              'icon': CupertinoIcons.clock_fill,
              'color': const Color(0xFFF59E0B), // Kuning Amber
            });
          } 
          // Mengecek jika tenggat waktu tugas sudah terlewat (lampau)
          else if (cleanTaskDate.isBefore(today)) {
            final formattedDeadline = task.deadline.toIso8601String().substring(0, 10);
            systemNotifications.add({
              'title': lang.translate('notif_overdue'),
              'body': lang.translate('notif_overdue_desc').replaceAll('{title}', task.title).replaceAll('{deadline}', formattedDeadline),
              'type': 'overdue',
              'time': lang.currentLanguage == 'id' ? 'Terlewat' : 'Overdue',
              'icon': CupertinoIcons.clear_circled_solid,
              'color': const Color(0xFFDC2626), // Merah Tua
            });
          }
        } catch (_) {}
      }
    }

    // 2. Mengecek tugas yang berhasil diselesaikan untuk memberikan selamat
    final completedTasks = _tasks.where((t) => t.status == 'Done').toList();
    for (var i = 0; i < completedTasks.length && i < 2; i++) {
      systemNotifications.add({
        'title': lang.translate('notif_completed'),
        'body': lang.translate('notif_completed_desc').replaceAll('{title}', completedTasks[i].title),
        'type': 'success',
        'time': lang.currentLanguage == 'id' ? 'Baru saja' : 'Just now',
        'icon': CupertinoIcons.checkmark_seal_fill,
        'color': const Color(0xFF10B981), // Hijau Emerald
      });
    }

    // 3. Menambahkan status aktivitas tugas yang sedang berjalan (In Progress)
    final progressCount = _tasks.where((t) => t.status == 'Progress').length;
    if (progressCount > 0) {
      systemNotifications.add({
        'title': lang.translate('notif_active_activities'),
        'body': lang.translate('notif_active_activities_desc').replaceAll('{count}', progressCount.toString()),
        'type': 'info',
        'time': lang.currentLanguage == 'id' ? 'Aktif' : 'Active',
        'icon': CupertinoIcons.bolt_fill,
        'color': const Color(0xFF6366F1), // Indigo
      });
    }

    // 4. Pesan selamat datang default jika tidak ada notifikasi penting lainnya
    if (systemNotifications.isEmpty) {
      systemNotifications.add({
        'title': lang.translate('notif_welcome'),
        'body': lang.translate('notif_welcome_desc'),
        'type': 'welcome',
        'time': lang.currentLanguage == 'id' ? 'Sistem' : 'System',
        'icon': CupertinoIcons.sparkles,
        'color': const Color(0xFF8B5CF6), // Ungu
      });
    }

    // Menampilkan panel dialog modal notifikasi dengan filter blur background
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            backgroundColor: Colors.white,
            elevation: 24,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 450, maxHeight: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Judul Header Dialog
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                CupertinoIcons.bell_fill,
                                color: Color(0xFF4F46E5),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              lang.translate('recent_notifications'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Outfit',
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(CupertinoIcons.xmark, color: Color(0xFF64748B), size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  
                  // Daftar Notifikasi Dinamis
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: systemNotifications.length,
                      itemBuilder: (context, index) {
                        final notif = systemNotifications[index];
                        final Color typeColor = notif['color'];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: typeColor.withOpacity(0.12), width: 1),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  notif['icon'],
                                  color: typeColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif['title'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Outfit',
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          notif['time'],
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Outfit',
                                            color: typeColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif['body'],
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontFamily: 'Outfit',
                                        color: Color(0xFF475569),
                                        height: 1.4,
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
                  ),
                  
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  // Tombol Penutup di bagian bawah dialog
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: const Color(0xFFEEF2F6),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              lang.translate('close'),
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final user = auth.user;
    const primaryColor = Color(0xFF4F46E5);

    // Menghitung status dan jumlah tugas untuk data statistik
    final totalTasks = _tasks.length;
    final pendingCount = _tasks.where((t) => t.status == 'Pending').length;
    final progressCount = _tasks.where((t) => t.status == 'Progress').length;
    final doneCount = _tasks.where((t) => t.status == 'Done').length;

    // Menghitung rasio penyelesaian tugas untuk ditampilkan pada diagram progress
    final completionRate = totalTasks > 0 ? (doneCount / totalTasks) : 0.0;
    final progressRate = totalTasks > 0 ? (progressCount / totalTasks) : 0.0;
    final pendingRate = totalTasks > 0 ? (pendingCount / totalTasks) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Warna dasar background Slate
      appBar: AppBar(
        title: Text(
          lang.translate('nav_dashboard'),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontFamily: 'Outfit',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Menyembunyikan tombol kembali bawaan
        actions: [
          // Tombol notifikasi beranimasi badge merah
          IconButton(
            icon: Stack(
              children: [
                const Icon(CupertinoIcons.bell, color: primaryColor, size: 24),
                if (_hasUnreadNotifications)
                  Positioned(
                    right: 1,
                    top: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showNotificationsPanel,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              // Menampilkan indikator loading saat memuat data dashboard
              child: CircularProgressIndicator(color: primaryColor),
            )
          : RefreshIndicator(
              onRefresh: _fetchDashboardData, // Memicu refresh manual dengan gestur swipe down
              color: primaryColor,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Kartu Sambutan (Welcome Card) Gradient Indah dengan ringkasan progres
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          // Ornamen lingkaran transparan dekorasi atas-kanan
                          Positioned(
                            top: -40,
                            right: -40,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          // Ornamen lingkaran transparan dekorasi bawah-kiri
                          Positioned(
                            bottom: -50,
                            left: 100,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.indigoAccent.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${lang.translate('dashboard_welcome')}, ${user?.name ?? 'User'}! 👋',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Outfit',
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        lang.translate('dashboard_welcome_sub'),
                                        style: const TextStyle(
                                          color: Color(0xFFC7D2FE), // Indigo 200
                                          fontSize: 14.5,
                                          fontFamily: 'Outfit',
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Menampilkan visual lingkaran progres jika user memiliki tugas
                                if (totalTasks > 0) ...[
                                  const SizedBox(width: 24),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 86,
                                        height: 86,
                                        child: CircularProgressIndicator(
                                          value: completionRate,
                                          backgroundColor: Colors.white.withOpacity(0.12),
                                          color: const Color(0xFF10B981), // Emerald Green
                                          strokeWidth: 9,
                                          strokeCap: StrokeCap.round,
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${(completionRate * 100).toInt()}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'Outfit',
                                            ),
                                          ),
                                          Text(
                                            lang.translate('done').toUpperCase(),
                                            style: const TextStyle(
                                              color: Color(0xFFC7D2FE),
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Outfit',
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Judul Bagian Ikhtisar Statistik
                  Text(
                    lang.translate('stats_overview'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid Kartu Ringkasan (Responsive Builder)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = (constraints.maxWidth - 16) / 2;
                      final isWide = constraints.maxWidth > 600;

                      Widget gridContent = Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildStatCard(
                            title: lang.translate('total_tasks'),
                            value: totalTasks.toString(),
                            icon: CupertinoIcons.square_list,
                            color: const Color(0xFF6366F1), // Indigo
                            rate: 1.0,
                            width: isWide ? (constraints.maxWidth - 48) / 4 : cardWidth,
                          ),
                          _buildStatCard(
                            title: lang.translate('pending'),
                            value: pendingCount.toString(),
                            icon: CupertinoIcons.clock,
                            color: const Color(0xFFEF4444), // Merah Rose
                            rate: pendingRate,
                            width: isWide ? (constraints.maxWidth - 48) / 4 : cardWidth,
                          ),
                          _buildStatCard(
                            title: lang.translate('progress'),
                            value: progressCount.toString(),
                            icon: CupertinoIcons.arrow_right_arrow_left,
                            color: const Color(0xFFF59E0B), // Amber
                            rate: progressRate,
                            width: isWide ? (constraints.maxWidth - 48) / 4 : cardWidth,
                          ),
                          _buildStatCard(
                            title: lang.translate('done'),
                            value: doneCount.toString(),
                            icon: CupertinoIcons.checkmark_seal,
                            color: const Color(0xFF10B981), // Emerald
                            rate: completionRate,
                            width: isWide ? (constraints.maxWidth - 48) / 4 : cardWidth,
                          ),
                        ],
                      );
                      return gridContent;
                    },
                  ),

                  const SizedBox(height: 28),

                  // Menampilkan pemberitahuan kesalahan jika terjadi error saat memuat data
                  if (_errorMessage.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Color(0xFF991B1B), fontFamily: 'Outfit'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Bagian Panduan Produktivitas (Guidelines / Tips)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED), // Warm Orange 50
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(CupertinoIcons.lightbulb_fill, color: Color(0xFFF59E0B), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              lang.translate('productivity_guidelines'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTipItem(
                          index: '1',
                          text: lang.translate('tip_1'),
                          color: const Color(0xFF6366F1), // Indigo
                        ),
                        _buildTipItem(
                          index: '2',
                          text: lang.translate('tip_2'),
                          color: const Color(0xFF10B981), // Emerald
                        ),
                        _buildTipItem(
                          index: '3',
                          text: lang.translate('tip_3'),
                          color: const Color(0xFFF59E0B), // Amber
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Membuat widget Kartu Statistik kustom yang dilengkapi dengan progress bar linier
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double rate,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar indikator rasio tugas
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: const Color(0xFFF1F5F9),
              color: color,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // Membuat widget item tips produktivitas di bagian bawah halaman
  Widget _buildTipItem({
    required String index,
    required String text,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              index,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'Outfit',
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF334155),
                fontFamily: 'Outfit',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
