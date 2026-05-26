import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/category.dart';
import '../providers/language_provider.dart';

/**
 * CategoryModal: Modal Dialog untuk menambah atau mengedit kategori tugas.
 */
class CategoryModal extends StatefulWidget {
  final Category? category; // Menerima objek category jika dalam mode EDIT

  const CategoryModal({super.key, this.category});

  @override
  State<CategoryModal> createState() => _CategoryModalState();
}

class _CategoryModalState extends State<CategoryModal> {
  final _formKey = GlobalKey<FormState>(); // GlobalKey untuk validasi form
  final _nameController = TextEditingController(); // Controller input nama kategori
  bool _isSaving = false; // Status loading saat proses menyimpan
  String _errorMsg = ''; // Menyimpan pesan error jika proses gagal

  @override
  void initState() {
    super.initState();
    // Jika data category dikirimkan (mode Edit), isi input textfield dengan nama kategori saat ini
    if (widget.category != null) {
      _nameController.text = widget.category!.categoryName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose(); // Membersihkan controller dari memori setelah modal ditutup
    super.dispose();
  }

  // Menangani proses simpan (create/update) kategori
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return; // Batalkan jika validasi form gagal

    setState(() {
      _isSaving = true;
      _errorMsg = '';
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      if (widget.category == null) {
        // --- BUAT KATEGORI BARU ---
        await auth.apiService.createCategory(_nameController.text.trim());
      } else {
        // --- EDIT KATEGORI YANG SUDAH ADA ---
        await auth.apiService.updateCategory(
          widget.category!.id,
          _nameController.text.trim(),
        );
      }
      
      if (mounted) {
        Navigator.pop(context, true); // Tutup dialog dan kembalikan nilai true untuk refresh daftar kategori
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
    final isEdit = widget.category != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bagian Header Dialog (Menampilkan judul dinamis)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? lang.translate('edit_category') : lang.translate('new_category'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Outfit',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark, size: 18, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),

              // Menampilkan kotak peringatan jika ada error
              if (_errorMsg.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Text(
                    _errorMsg,
                    style: const TextStyle(color: Color(0xFF991B1B), fontFamily: 'Outfit', fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Input Nama Kategori
              Text(
                lang.translate('category_name'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 15),
                decoration: InputDecoration(
                  hintText: lang.translate('category_name_hint'),
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
                  if (value == null || value.trim().isEmpty) return lang.translate('category_name_required');
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Tombol Batal & Simpan
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(lang.translate('cancel'), style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(lang.translate('save'), style: const TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
