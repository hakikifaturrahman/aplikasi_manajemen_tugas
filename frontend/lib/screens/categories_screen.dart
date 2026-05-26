import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/category.dart';
import '../widgets/category_modal.dart';
import '../providers/language_provider.dart';

// Widget halaman pengelolaan Kategori (Categories) yang bersifat stateful
class CategoriesScreen extends StatefulWidget {
  // Callback opsional saat kategori dipilih (digunakan untuk mem-filter tugas berdasarkan kategori tersebut)
  final Function(int)? onCategorySelected;
  const CategoriesScreen({super.key, this.onCategorySelected});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

// State untuk halaman Kategori yang mengelola pengambilan data, penambahan, edit, dan hapus kategori
class _CategoriesScreenState extends State<CategoriesScreen> {
  // Flag pemuatan data awal dari API
  bool _isLoading = true;
  
  // Daftar kategori yang berhasil dimuat dari database
  List<Category> _categories = [];
  
  // Menyimpan pesan kesalahan jika request API gagal
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    // Memulai pemuatan daftar kategori saat pertama kali screen dibuka
    _fetchCategories();
  }

  // Mengambil daftar kategori dari backend
  Future<void> _fetchCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // Memicu API request untuk mendapatkan kategori
      final rawCategories = await auth.apiService.getCategories();
      
      setState(() {
        // Mengonversi data JSON biner menjadi list model Category
        _categories = rawCategories.map((c) => Category.fromJson(c)).toList();
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Matikan indikator pemuatan
        });
      }
    }
  }

  // Menghapus kategori berdasarkan ID dari API
  Future<void> _deleteCategory(int id) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // Mengirimkan perintah hapus kategori ke backend
      await auth.apiService.deleteCategory(id);
      
      if (mounted) {
        final lang = Provider.of<LanguageProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.translate('category_deleted_success')), backgroundColor: Colors.redAccent),
        );
      }
      _fetchCategories(); // Memuat ulang list kategori
    } catch (e) {
      // Menangkap error jika kategori gagal dihapus (misalnya jika ada tugas di dalamnya)
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      setState(() {
        _errorMsg = lang.translate('category_delete_failed');
      });
    }
  }

  // Menampilkan kotak dialog konfirmasi sebelum menghapus kategori
  void _showDeleteConfirm(int id) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(lang.translate('confirm_deletion'), style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: Text(
          lang.translate('delete_category_confirm_desc'),
          style: const TextStyle(fontFamily: 'Outfit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('cancel'), style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Outfit')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(lang.translate('delete'), style: const TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Membuka modal form kategori untuk kebutuhan Tambah Baru maupun Edit Kategori
  void _openCategoryModal({Category? category}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CategoryModal(category: category),
    );

    // Jika modal berhasil menyimpan data (mengembalikan nilai true), muat ulang daftar kategori
    if (result == true) {
      _fetchCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4F46E5);
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          lang.translate('categories'),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontFamily: 'Outfit',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _fetchCategories, // Memicu pemuatan ulang dengan gestur swipe down
              color: primaryColor,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [

                  // Tampilan panel error jika proses gagal
                  if (_errorMsg.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(_errorMsg, style: const TextStyle(color: Color(0xFF991B1B), fontFamily: 'Outfit')),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Memeriksa jika daftar kategori kosong, tampilkan Empty State
                  _categories.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            
                            // Menyesuaikan gaya visual & warna tema dinamis berdasarkan kata kunci nama kategori
                            final nameLower = cat.categoryName.toLowerCase();
                            
                            Color avatarBgColor;
                            Color iconColor;
                            IconData iconData;
                            
                            Color badgeBgColor;
                            Color badgeTextColor;
                            IconData badgeIcon;
                            String displayName = cat.categoryName;

                            // 1. Tema untuk kategori desain / UI/UX
                            if (nameLower.contains('ui') || nameLower.contains('ux') || nameLower.contains('design')) {
                              avatarBgColor = const Color(0xFFDBEAFE); // Biru Muda
                              iconColor = const Color(0xFF2563EB); // Biru
                              iconData = CupertinoIcons.wrench_fill; 
                              
                              badgeBgColor = const Color(0xFFD1FAE5); // Hijau Muda
                              badgeTextColor = const Color(0xFF065F46); // Hijau Tua
                              badgeIcon = CupertinoIcons.checkmark_circle;
                            } 
                            // 2. Tema untuk kategori pengembangan software / programming
                            else if (nameLower.contains('backend') || nameLower.contains('frontend') || nameLower.contains('development') || nameLower.contains('code') || nameLower.contains('dev')) {
                              avatarBgColor = const Color(0xFFE0E7FF); // Indigo Muda
                              iconColor = const Color(0xFF4F46E5); // Indigo
                              iconData = CupertinoIcons.chevron_left_slash_chevron_right;
                              
                              badgeBgColor = const Color(0xFFE0E7FF); 
                              badgeTextColor = const Color(0xFF4338CA); 
                              badgeIcon = CupertinoIcons.circle;
                            } 
                            // 3. Tema untuk kategori pemasaran / marketing
                            else if (nameLower.contains('marketing') || nameLower.contains('promo')) {
                              avatarBgColor = const Color(0xFFFCE7F3); // Pink Muda
                              iconColor = const Color(0xFFDB2777); // Pink
                              iconData = CupertinoIcons.speaker_2_fill;
                              
                              badgeBgColor = const Color(0xFFF1F5F9); 
                              badgeTextColor = const Color(0xFF475569); 
                              badgeIcon = CupertinoIcons.clock;
                            } 
                            // 4. Tema untuk kategori administrasi / QA / operasi
                            else if (nameLower.contains('operations') || nameLower.contains('admin') || nameLower.contains('testing') || nameLower.contains('qa')) {
                              avatarBgColor = const Color(0xFFE2E8F0); // Abu-abu
                              iconColor = const Color(0xFF475569); // Slate
                              iconData = CupertinoIcons.archivebox_fill;
                              
                              badgeBgColor = const Color(0xFFF1F5F9); 
                              badgeTextColor = const Color(0xFF475569); 
                              badgeIcon = CupertinoIcons.clock;
                            } 
                            // 5. Tema cadangan default jika tidak ada kata kunci yang cocok
                            else {
                              avatarBgColor = const Color(0xFFFEF3C7); // Kuning Amber
                              iconColor = const Color(0xFFD97706); // Amber
                              iconData = CupertinoIcons.folder_fill;
                              
                              badgeBgColor = const Color(0xFFF1F5F9); 
                              badgeTextColor = const Color(0xFF475569); 
                              badgeIcon = CupertinoIcons.clock;
                            }

                            // Membungkus kartu kategori dengan InkWell agar bisa diklik dengan efek ripple material design
                            return InkWell(
                              onTap: () {
                                // Memicu callback jika ada, untuk berpindah halaman dan mem-filter task berdasarkan ID kategori ini
                                widget.onCategorySelected?.call(cat.id);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: iconColor.withOpacity(0.02),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: iconColor.withOpacity(0.12),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                  // Kotak Ikon Avatar Kategori di sisi kiri dengan efek neon glow
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: avatarBgColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: iconColor.withOpacity(0.35),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: iconColor.withOpacity(0.15),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(iconData, color: iconColor, size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Bagian Tengah: Informasi Nama Kategori dan Jumlah Tugas (Task Count)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                            fontFamily: 'Outfit',
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // Badge Kapsul untuk jumlah tugas
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: badgeBgColor,
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(badgeIcon, color: badgeTextColor, size: 12),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${cat.taskCount} ${lang.translate('nav_tasks')}',
                                                style: TextStyle(
                                                  color: badgeTextColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'Outfit',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Tombol Aksi Kategori di sisi kanan (Edit dan Hapus)
                                  IconButton(
                                    icon: const Icon(CupertinoIcons.pencil, color: Color(0xFF64748B), size: 20),
                                    onPressed: () => _openCategoryModal(category: cat),
                                  ),
                                  IconButton(
                                    icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 20),
                                    onPressed: () => _showDeleteConfirm(cat.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        ),
                ],
              ),
            ),
      // Floating Action Button untuk menambah kategori baru
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCategoryModal(),
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        elevation: 6,
        child: const Icon(CupertinoIcons.add, color: Colors.white, size: 24),
      ),
    );
  }

  // Membuat widget tampilan kosong jika belum ada kategori sama sekali
  Widget _buildEmptyState() {
    final lang = Provider.of<LanguageProvider>(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.folder_badge_plus,
                color: Color(0xFFD97706),
                size: 52,
              ),
            ),
            const SizedBox(height: 24),
             Text(
              lang.translate('no_categories_yet'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                fontFamily: 'Outfit',
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lang.translate('no_categories_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
