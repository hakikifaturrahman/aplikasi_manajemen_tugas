import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../widgets/task_modal.dart';
import '../providers/language_provider.dart';

// Widget halaman pengelolaan Tugas (Tasks) yang bersifat stateful
class TasksScreen extends StatefulWidget {
  // Menerima parameter opsional kategori yang terpilih sebelumnya (misalnya jika dinavigasi dari halaman Categories)
  final int? preselectedCategoryId;
  const TasksScreen({super.key, this.preselectedCategoryId});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

// State untuk halaman Tugas yang mengelola list data, pencarian, dan filter
class _TasksScreenState extends State<TasksScreen> {
  // Flag pemuatan data awal dari API
  bool _isLoading = true;
  
  // List data tugas (tasks) yang berhasil diambil dari database
  List<Task> _tasks = [];
  
  // List data kategori untuk dropdown filter
  List<Category> _categories = [];
  
  // Menyimpan pesan kesalahan jika proses API gagal
  String _errorMsg = '';

  // Controller untuk field pencarian tugas berdasarkan teks
  final _searchController = TextEditingController();
  
  // Status filter tugas: 'All', 'Pending', 'Progress', 'Done'
  String _selectedStatus = 'All';
  
  // ID Kategori terpilih untuk memfilter list tugas
  int? _selectedCategoryId;
  
  // Mode pengurutan berdasarkan deadline: 'ASC' (terdekat) atau 'DESC' (terjauh)
  String _selectedSort = 'ASC';

  @override
  void initState() {
    super.initState();
    // Inisialisasi ID kategori jika dilewatkan dari navigasi
    _selectedCategoryId = widget.preselectedCategoryId;
    // Mengambil data awal
    _fetchInitialData();
  }

  @override
  void dispose() {
    // Membebaskan memori search controller
    _searchController.dispose();
    super.dispose();
  }

  // Mengambil data awal berupa list kategori (untuk filter) dan daftar tugas
  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      
      // Mengambil daftar kategori dari API
      final rawCategories = await auth.apiService.getCategories();
      _categories = rawCategories.map((c) => Category.fromJson(c)).toList();

      // Mengambil daftar tugas dari API berdasarkan parameter filter aktif
      await _fetchTasks();
    } catch (e) {
      setState(() {
        _errorMsg = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Mengambil daftar tugas dari API dengan menerapkan parameter query filter
  Future<void> _fetchTasks() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final rawTasks = await auth.apiService.getTasks(
        search: _searchController.text.trim(),
        status: _selectedStatus,
        categoryId: _selectedCategoryId,
        sort: _selectedSort,
      );

      setState(() {
        // Mengonversi data JSON biner menjadi objek model Task
        _tasks = rawTasks.map((t) => Task.fromJson(t)).toList();
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Failed to reload tasks';
      });
    }
  }

  // Memicu aksi pencarian saat form pencarian disubmit
  void _triggerSearch() {
    _fetchTasks();
  }

  // Mereset seluruh parameter filter pencarian kembali ke kondisi semula
  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = 'All';
      _selectedCategoryId = null;
      _selectedSort = 'ASC';
    });
    _fetchTasks(); // Memuat ulang tugas tanpa filter
  }

  // Menghapus tugas berdasarkan ID
  Future<void> _deleteTask(int id) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      await auth.apiService.deleteTask(id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.translate('task_deleted_success')), backgroundColor: Colors.redAccent),
        );
      }
      _fetchTasks(); // Memuat ulang list tugas setelah berhasil dihapus
    } catch (e) {
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      setState(() {
        _errorMsg = lang.translate('task_delete_failed');
      });
    }
  }

  // Menampilkan kotak dialog konfirmasi sebelum menghapus tugas secara permanen
  void _showDeleteConfirm(int id) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(lang.translate('confirm_deletion'), style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: Text(lang.translate('delete_task_confirm_desc'), style: const TextStyle(fontFamily: 'Outfit')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('cancel'), style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Outfit')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(id);
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

  // Membuka modal form tugas untuk kebutuhan Tambah Baru maupun Edit Tugas
  void _openTaskModal({Task? task}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TaskModal(task: task),
    );

    // Jika modal mengembalikan nilai true (berhasil simpan), muat ulang daftar tugas
    if (result == true) {
      _fetchTasks();
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
          lang.translate('nav_tasks'),
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
          : Column(
              children: [
                // 1. PANEL FILTERS & TOOLBAR PENCARIAN
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      // Baris Pertama: Field Pencarian Kata Kunci & Tombol Cari
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: lang.translate('search_tasks'),
                                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF64748B), size: 18),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onSubmitted: (_) => _triggerSearch(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Tombol Segarkan / Bersihkan Filter
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                            ),
                            child: IconButton(
                              icon: const Icon(CupertinoIcons.refresh, color: Color(0xFF64748B), size: 18),
                              tooltip: lang.translate('cancel'),
                              onPressed: _clearFilters,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Tombol Submit Cari
                          ElevatedButton.icon(
                            onPressed: _triggerSearch,
                            icon: const Icon(CupertinoIcons.search, size: 16, color: Colors.white),
                            label: Text(lang.translate('search'), style: const TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Baris Kedua: Pilihan Dropdown Filter (Status, Kategori, Urutan)
                      LayoutBuilder(builder: (context, constraints) {
                        Widget filterRow = Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.start,
                          children: [
                            // Dropdown Status
                            _buildFilterDropdown<String>(
                              value: _selectedStatus,
                              items: [
                                DropdownMenuItem(value: 'All', child: Text(lang.translate('all_statuses'))),
                                DropdownMenuItem(value: 'Pending', child: Text(lang.translate('pending'))),
                                DropdownMenuItem(value: 'Progress', child: Text(lang.translate('progress'))),
                                DropdownMenuItem(value: 'Done', child: Text(lang.translate('done'))),
                              ],
                              onChanged: (String? val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedStatus = val;
                                  });
                                  _fetchTasks();
                                }
                              },
                            ),

                            // Dropdown Kategori
                            _buildFilterDropdown<int?>(
                              value: _selectedCategoryId,
                              hint: lang.translate('all_categories'),
                              items: [
                                DropdownMenuItem<int?>(value: null, child: Text(lang.translate('all_categories'))),
                                ..._categories.map((c) {
                                  return DropdownMenuItem<int?>(value: c.id, child: Text(c.categoryName));
                                })
                              ],
                              onChanged: (int? val) {
                                setState(() {
                                  _selectedCategoryId = val;
                                });
                                _fetchTasks();
                              },
                            ),

                            // Dropdown Urutan Deadline
                            _buildFilterDropdown<String>(
                              value: _selectedSort,
                              items: [
                                DropdownMenuItem(value: 'ASC', child: Text(lang.translate('sort_deadline_asc'))),
                                DropdownMenuItem(value: 'DESC', child: Text(lang.translate('sort_deadline_desc'))),
                              ],
                              onChanged: (String? val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedSort = val;
                                  });
                                  _fetchTasks();
                                }
                              },
                            ),
                          ],
                        );
                        return SizedBox(
                           width: double.infinity,
                          child: filterRow,
                        );
                      }),
                    ],
                  ),
                ),

                // Panel Pemberitahuan Error jika terdeteksi kegagalan
                if (_errorMsg.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(_errorMsg, style: const TextStyle(color: Color(0xFF991B1B), fontFamily: 'Outfit')),
                    ),
                  ),
                ],

                // 2. DAFTAR KARTU TUGAS ATAU TAMPILAN KOSONG
                Expanded(
                  child: _tasks.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return _buildTaskCard(task);
                          },
                        ),
                ),
              ],
            ),
      // Tombol Tambah Tugas Baru (Floating Action Button)
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskModal(),
        backgroundColor: primaryColor,
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
    );
  }

  // Membuat widget tampilan kosong (Empty State) jika tidak ada tugas yang sesuai filter
  Widget _buildEmptyState() {
    final lang = Provider.of<LanguageProvider>(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.square_stack_3d_down_dottedline,
                color: Color(0xFF4F46E5),
                size: 56,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              lang.translate('no_tasks_found'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                fontFamily: 'Outfit',
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              lang.translate('no_tasks_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                color: Color(0xFF64748B),
                fontFamily: 'Outfit',
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Membuat widget pilihan dropdown filter kustom
  Widget _buildFilterDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: hint != null ? Text(hint, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Color(0xFF475569))) : null,
          icon: const Icon(CupertinoIcons.chevron_down, size: 14, color: Color(0xFF64748B)),
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Membangun kartu item tugas individu yang dilengkapi detail status, kategori, dan tenggat waktu
  Widget _buildTaskCard(Task task) {
    final lang = Provider.of<LanguageProvider>(context);
    Color statusColor;
    switch (task.status) {
      case 'Progress':
        statusColor = const Color(0xFFF59E0B); // Amber
        break;
      case 'Done':
        statusColor = const Color(0xFF10B981); // Emerald
        break;
      default:
        statusColor = const Color(0xFF64748B); // Slate
    }

    final formattedDeadline = DateFormat('MMM dd, yyyy').format(task.deadline);

    final deleteBackground = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 24),
          const SizedBox(width: 12),
          Text(
            lang.translate('delete_task'),
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );

    final doneBackground = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB3F5D4), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            lang.translate('mark_as_done'),
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(width: 12),
          const Icon(CupertinoIcons.checkmark_seal, color: Color(0xFF10B981), size: 24),
        ],
      ),
    );

    // Membungkus kartu tugas (task card) dengan Dismissible untuk mendeteksi gesture geser (swipe)
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.horizontal, // Mengizinkan geser ke kanan maupun ke kiri
      background: deleteBackground, // Tampilan latar belakang saat digeser ke kanan (Hapus)
      secondaryBackground: doneBackground, // Tampilan latar belakang saat digeser ke kiri (Selesai/Done)
      
      // Fungsi untuk mengonfirmasi aksi sebelum widget benar-benar terhapus/bergeser dari tree
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // --- AKSI GESER KE KANAN (START TO END) -> HAPUS TASK ---
          
          // Memunculkan dialog konfirmasi untuk memastikan user tidak sengaja menghapus task
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(lang.translate('confirm_deletion'), style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
              content: Text(lang.translate('delete_task_confirm_desc'), style: const TextStyle(fontFamily: 'Outfit')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false), // Tutup dialog dan kembalikan nilai false
                  child: Text(lang.translate('cancel'), style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Outfit')),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true), // Tutup dialog dan kembalikan nilai true
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(lang.translate('delete'), style: const TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          
          // Jika user mengonfirmasi "Delete", jalankan fungsi hapus task dan return true
          if (confirm == true) {
            await _deleteTask(task.id);
            return true; // Return true mengizinkan kartu terhapus dari tampilan
          }
          return false; // Return false membatalkan penghapusan dan mengembalikan posisi kartu
          
        } else if (direction == DismissDirection.endToStart) {
          // --- AKSI GESER KE KIRI (END TO START) -> SELESAIKAN TASK (MARK AS DONE) ---
          
          // Jika tugas sudah berkategori "Done", tampilkan informasi dan batalkan gesture
          if (task.status == 'Done') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(lang.translate('task_already_done')), backgroundColor: const Color(0xFF64748B)),
              );
            }
            return false; // Mengembalikan posisi kartu ke semula
          }
          
          try {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            // Mengirim request API untuk memperbarui status task menjadi 'Done'
            await auth.apiService.updateTask(task.id, status: 'Done');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(lang.translate('task_marked_done')), backgroundColor: const Color(0xFF10B981)),
              );
            }
            _fetchTasks(); // Memuat ulang list tugas agar status baru langsung teraplikasi ke UI
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${lang.translate('task_update_failed')}: $e'), backgroundColor: Colors.redAccent),
              );
            }
          }
          
          // Return false agar kartu tidak terbuang/hilang dari UI, melainkan memantul kembali 
          // ke posisinya semula dengan status warna yang sudah terupdate menjadi hijau (Done)
          return false; 
        }
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
              color: statusColor.withOpacity(0.02),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: statusColor.withOpacity(0.12),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Garis aksen warna status di sisi kiri kartu tugas
                Container(
                  width: 6,
                  color: statusColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Informasi detail utama tugas
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Judul dan Badge Status
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                        fontFamily: 'Outfit',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: statusColor.withOpacity(0.25),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      lang.translate(task.status.toLowerCase()),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Outfit',
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 8),

                              // Deskripsi Tugas
                              if (task.description.isNotEmpty) ...[
                                Text(
                                  task.description,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF475569),
                                    fontFamily: 'Outfit',
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Badge Kategori dan Badge Deadline (Tenggat waktu)
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  // Badge Kategori
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: const Color(0xFF6366F1).withOpacity(0.25),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(CupertinoIcons.folder_fill, size: 12, color: Color(0xFF6366F1)),
                                        const SizedBox(width: 6),
                                        Text(
                                          task.categoryName,
                                          style: const TextStyle(
                                            color: Color(0xFF6366F1),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'Outfit',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Badge Deadline (Tenggat waktu)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF43F5E).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: const Color(0xFFF43F5E).withOpacity(0.25),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(CupertinoIcons.calendar_today, size: 12, color: Color(0xFFF43F5E)),
                                        const SizedBox(width: 6),
                                        Text(
                                          formattedDeadline,
                                          style: const TextStyle(
                                            color: Color(0xFFF43F5E),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'Outfit',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Tombol Aksi Langsung (Edit dan Hapus)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(CupertinoIcons.pencil, color: Color(0xFF6366F1), size: 20),
                              tooltip: 'Edit Task',
                              onPressed: () => _openTaskModal(task: task),
                            ),
                            IconButton(
                              icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 20),
                              tooltip: 'Delete Task',
                              onPressed: () => _showDeleteConfirm(task.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
