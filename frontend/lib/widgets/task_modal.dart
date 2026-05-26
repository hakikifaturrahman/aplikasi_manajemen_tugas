import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../providers/language_provider.dart';

/**
 * TaskModal: Modal Dialog untuk menambah tugas baru atau memperbarui (edit) tugas yang sudah ada.
 */
class TaskModal extends StatefulWidget {
  final Task? task; // Menerima data task jika dalam mode EDIT

  const TaskModal({super.key, this.task});

  @override
  State<TaskModal> createState() => _TaskModalState();
}

class _TaskModalState extends State<TaskModal> {
  final _formKey = GlobalKey<FormState>(); // Key validasi form input
  final _titleController = TextEditingController(); // Controller nama tugas
  final _descController = TextEditingController(); // Controller deskripsi tugas
  
  DateTime? _selectedDate; // Tanggal tenggat waktu (deadline)
  int? _selectedCategoryId; // ID kategori yang dipilih
  String _selectedStatus = 'Pending'; // Status tugas default
  
  List<Category> _categories = []; // Menyimpan daftar kategori yang ditarik dari database
  bool _isLoadingCategories = true; // Status loading kategori
  bool _isSaving = false; // Status loading simpan data
  String _errorMsg = ''; // Menyimpan pesan error

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Mengambil daftar kategori saat dialog dibuka
    
    // Jika dalam mode EDIT, inisialisasi kolom dengan data tugas lama
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descController.text = widget.task!.description;
      _selectedDate = widget.task!.deadline;
      _selectedCategoryId = widget.task!.categoryId;
      _selectedStatus = widget.task!.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Mengambil daftar kategori dari API database
  Future<void> _fetchCategories() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final rawCategories = await auth.apiService.getCategories();
      setState(() {
        _categories = rawCategories.map((c) => Category.fromJson(c)).toList();
        
        // Jika mode TAMBAH BARU dan kategori tidak kosong, pilih kategori pertama secara default
        if (widget.task == null && _categories.isNotEmpty) {
          _selectedCategoryId = _categories[0].id;
        }
      });
    } catch (e) {
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      setState(() {
        _errorMsg = lang.translate('load_categories_failed');
      });
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  // Menampilkan widget pemilih tanggal (Date Picker)
  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5), // Warna tema dialog
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Menangani penyimpanan data tugas (Tambah/Edit)
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return; // Batalkan jika form tidak valid
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (_selectedDate == null) {
      setState(() {
        _errorMsg = lang.translate('deadline_required');
      });
      return;
    }
    if (_selectedCategoryId == null) {
      setState(() {
        _errorMsg = lang.translate('category_required');
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMsg = '';
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      if (widget.task == null) {
        // --- TAMBAH TUGAS BARU ---
        await auth.apiService.createTask(
          _titleController.text.trim(),
          _descController.text.trim(),
          formattedDate,
          _selectedStatus,
          _selectedCategoryId!,
        );
      } else {
        // --- EDIT TUGAS LAMA ---
        await auth.apiService.updateTask(
          widget.task!.id,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          deadline: formattedDate,
          status: _selectedStatus,
          categoryId: _selectedCategoryId!,
        );
      }
      
      if (mounted) {
        Navigator.pop(context, true); // Tutup modal dan return true untuk merefresh daftar tugas
      }
    } catch (e) {
      setState(() {
        _errorMsg = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    const primaryColor = Color(0xFF4F46E5);
    final isEdit = widget.task != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Dialog
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? lang.translate('edit_task') : lang.translate('new_task'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        fontFamily: 'Outfit',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark, color: Color(0xFF64748B), size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFE2E8F0)),
                const SizedBox(height: 16),

                // Alert panel error
                if (_errorMsg.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      _errorMsg,
                      style: const TextStyle(color: Color(0xFF991B1B), fontFamily: 'Outfit', fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 1. Input Nama Tugas
                Text(
                  lang.translate('task_name_label'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 15),
                  decoration: InputDecoration(
                    hintText: lang.translate('task_name_hint'),
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                    if (value == null || value.trim().isEmpty) return lang.translate('task_name_required');
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 2. Input Deskripsi
                Text(
                  lang.translate('description_label'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 15),
                  decoration: InputDecoration(
                    hintText: lang.translate('task_desc_hint'),
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                ),
                const SizedBox(height: 20),

                // 3. Dropdown Pemilih Kategori
                Text(
                  lang.translate('task_category'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 8),
                _isLoadingCategories
                    ? const Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2))
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedCategoryId,
                            isExpanded: true,
                            hint: Text(lang.translate('select_a_category'), style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFF94A3B8))),
                            style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: Color(0xFF0F172A)),
                            items: _categories.map((Category cat) {
                              return DropdownMenuItem<int>(
                                value: cat.id,
                                child: Text(cat.categoryName),
                              );
                            }).toList(),
                            onChanged: (int? newVal) {
                              setState(() {
                                _selectedCategoryId = newVal;
                              });
                            },
                          ),
                        ),
                      ),
                const SizedBox(height: 20),

                // 4. Input Tanggal Tenggat (DatePicker)
                Text(
                  lang.translate('deadline_label'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDeadline(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate == null
                              ? lang.translate('deadline_placeholder')
                              : DateFormat('MM/dd/yyyy').format(_selectedDate!),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            color: _selectedDate == null ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                          ),
                        ),
                        const Icon(CupertinoIcons.calendar, color: Color(0xFF64748B), size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Dropdown Pemilih Status (Pending, Progress, Done)
                Text(
                  lang.translate('task_status'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: Color(0xFF0F172A)),
                      items: [
                        DropdownMenuItem<String>(value: 'Pending', child: Text(lang.translate('pending'))),
                        DropdownMenuItem<String>(value: 'Progress', child: Text(lang.translate('progress'))),
                        DropdownMenuItem<String>(value: 'Done', child: Text(lang.translate('done'))),
                      ],
                      onChanged: (String? newVal) {
                        if (newVal != null) {
                          setState(() {
                            _selectedStatus = newVal;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Aksi Bottom Buttons (Cancel & Save)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        lang.translate('cancel'),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              lang.translate('save_task'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Outfit',
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
