import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

// Widget halaman profil utama pengguna yang bersifat stateful
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// State untuk halaman profil yang mengelola data diri, foto, dan preferensi akun
class _ProfileScreenState extends State<ProfileScreen> {
  // Flag status loading untuk proses pembaruan data
  bool _isLoading = false;

  // Memilih gambar dari galeri perangkat dan mengunggahnya ke API backend sebagai Base64
  Future<void> _pickAndUploadImage(StateSetter setStateModal, TextEditingController urlController, Function(String) onUploadSuccess) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final picker = ImagePicker();
    try {
      // Membuka galeri sistem untuk memilih satu gambar
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return; // Batalkan jika pengguna membatalkan pemilihan

      setStateModal(() {
        _isLoading = true; // Aktifkan indikator loading di dalam dialog modal
      });

      // Membaca file gambar sebagai deretan bytes
      final bytes = await image.readAsBytes();
      // Mengodekan bytes gambar menjadi format string Base64 agar dapat dikirim via JSON
      final base64Image = base64Encode(bytes);
      final fileName = image.name;

      // Mengirimkan data Base64 ke server backend untuk disimpan
      final uploadedUrl = await auth.apiService.uploadProfilePicture(base64Image, fileName);

      setStateModal(() {
        urlController.text = uploadedUrl; // Mengisi field URL dengan tautan gambar yang baru diunggah
      });
      onUploadSuccess(uploadedUrl); // Memicu callback sukses

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.translate('avatar_success_msg')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking or uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lang.translate('avatar_fail_msg')} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setStateModal(() {
        _isLoading = false; // Matikan indikator loading
      });
    }
  }

  // Membuka modal dialog untuk mengganti foto profil (Preset avatar / Unggah kustom)
  void _openChangeProfilePictureModal() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return;

    final urlController = TextEditingController(text: user.profilePicture ?? '');
    String selectedUrl = user.profilePicture ?? '';
    final formKey = GlobalKey<FormState>();

    // Daftar URL gambar avatar bawaan yang dapat langsung dipilih oleh pengguna
    final List<String> presetAvatars = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&q=80&w=200',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=200',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=200',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&q=80&w=200',
      'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&q=80&w=200',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=200',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            lang.translate('avatar_change_title'),
            style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lang.translate('avatar_preset'),
                    style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  // Grid list untuk menampilkan avatar bawaan
                  SizedBox(
                    width: 280,
                    height: 150,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: presetAvatars.length,
                      itemBuilder: (context, index) {
                        final avatarUrl = presetAvatars[index];
                        final isSelected = selectedUrl == avatarUrl;
                        return GestureDetector(
                          onTap: () {
                            setStateModal(() {
                              selectedUrl = avatarUrl;
                              urlController.text = avatarUrl;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(avatarUrl),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tombol pemicu unggah gambar kustom dari perangkat
                  Center(
                    child: TextButton.icon(
                      onPressed: _isLoading ? null : () {
                        _pickAndUploadImage(setStateModal, urlController, (url) {
                          setStateModal(() {
                            selectedUrl = url;
                          });
                        });
                      },
                      icon: const Icon(Icons.file_upload, color: Color(0xFF4F46E5)),
                      label: Text(
                        lang.translate('avatar_pick_device'),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        backgroundColor: const Color(0xFF4F46E5).withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    lang.translate('avatar_custom_url'),
                    style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: urlController,
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'https://example.com/foto.jpg',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (val) {
                      setStateModal(() {
                        selectedUrl = val.trim();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.translate('cancel'), style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Outfit')),
            ),
            // Tombol simpan untuk mengirim data foto profil ke database
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setStateModal(() {
                        _isLoading = true;
                      });
                      try {
                        await auth.updateProfile(
                          user.name,
                          user.email,
                          profilePicture: urlController.text.trim(),
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        debugPrint('Error updating profile photo: $e');
                      } finally {
                        setStateModal(() {
                          _isLoading = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              child: Text(lang.translate('save'), style: const TextStyle(color: Colors.white, fontFamily: 'Outfit')),
            ),
          ],
        ),
      ),
    );
  }

  // Membuka modal pengaturan notifikasi (Deadline, Email alerts, dll)
  void _openNotificationsModal() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return;

    bool remindDeadlines = user.remindDeadlines;
    bool weeklyReport = user.weeklyReport;
    bool newTasks = user.newTasks;
    bool emailAlerts = user.emailAlerts;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(CupertinoIcons.bell_fill, color: Colors.indigoAccent),
              const SizedBox(width: 8),
              Text(lang.translate('notifications'), style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: remindDeadlines,
                title: Text(lang.translate('notif_setting_remind'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 14)),
                subtitle: Text(lang.translate('notif_setting_remind_sub'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 12)),
                onChanged: isSaving ? null : (val) => setStateModal(() => remindDeadlines = val),
                activeColor: Colors.indigoAccent,
              ),
              SwitchListTile(
                value: weeklyReport,
                title: Text(lang.translate('notif_setting_report'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 14)),
                subtitle: Text(lang.translate('notif_setting_report_sub'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 12)),
                onChanged: isSaving ? null : (val) => setStateModal(() => weeklyReport = val),
                activeColor: Colors.indigoAccent,
              ),
              SwitchListTile(
                value: newTasks,
                title: Text(lang.translate('notif_setting_new_task'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 14)),
                subtitle: Text(lang.translate('notif_setting_new_task_sub'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 12)),
                onChanged: isSaving ? null : (val) => setStateModal(() => newTasks = val),
                activeColor: Colors.indigoAccent,
              ),
              SwitchListTile(
                value: emailAlerts,
                title: Text(lang.translate('notif_setting_email'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 14)),
                subtitle: Text(lang.translate('notif_setting_email_sub'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 12)),
                onChanged: isSaving ? null : (val) => setStateModal(() => emailAlerts = val),
                activeColor: Colors.indigoAccent,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: Text(lang.translate('cancel'), style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Outfit')),
            ),
            // Tombol simpan pengaturan ke API
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setStateModal(() {
                        isSaving = true;
                      });
                      try {
                        await auth.updateUserSettings(
                          remindDeadlines: remindDeadlines,
                          weeklyReport: remindDeadlines, // Note: weeklyReport is preserved here as remindDeadlines due to original logic
                          newTasks: newTasks,
                          emailAlerts: emailAlerts,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(lang.translate('notif_save_success'), style: const TextStyle(fontFamily: 'Outfit')),
                              backgroundColor: Colors.indigoAccent,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${lang.currentLanguage == 'id' ? 'Gagal menyimpan' : 'Failed to save'}: $e', style: const TextStyle(fontFamily: 'Outfit')),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        setStateModal(() {
                          isSaving = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(lang.translate('save'), style: const TextStyle(color: Colors.white, fontFamily: 'Outfit')),
            ),
          ],
        ),
      ),
    );
  }

  // Membuka modal pengaturan Keamanan & Privasi (2FA, Profile Privat, Sesi timeout)
  void _openPrivacySecurityModal() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return;

    bool isPrivateProfile = user.isPrivateProfile;
    bool enableTwoFactor = user.enableTwoFactor;
    bool sessionTimeout = user.sessionTimeout;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(CupertinoIcons.shield_fill, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text(lang.translate('privacy_security'), style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: isPrivateProfile,
                title: Text(lang.translate('security_private_profile'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 14)),
                subtitle: Text(lang.translate('security_private_profile_sub'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 12)),
                onChanged: isSaving ? null : (val) => setStateModal(() => isPrivateProfile = val),
                activeColor: Colors.blueAccent,
              ),
              SwitchListTile(
                value: enableTwoFactor,
                title: Text(lang.translate('security_2fa'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 14)),
                subtitle: Text(lang.translate('security_2fa_sub'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 12)),
                onChanged: isSaving ? null : (val) => setStateModal(() => enableTwoFactor = val),
                activeColor: Colors.blueAccent,
              ),
              SwitchListTile(
                value: sessionTimeout,
                title: Text(lang.translate('security_session_timeout'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 14)),
                subtitle: Text(lang.translate('security_session_timeout_sub'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 12)),
                onChanged: isSaving ? null : (val) => setStateModal(() => sessionTimeout = val),
                activeColor: Colors.blueAccent,
              ),
              const Divider(color: Color(0xFFF1F5F9), height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lang.translate('security_encryption_method'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold)),
                    const Text('bcryptjs (10 rounds)', style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.blueAccent)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lang.translate('security_session_token'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold)),
                    const Text('JWT (30 days expire)', style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.blueAccent)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: Text(lang.translate('cancel'), style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Outfit')),
            ),
            // Tombol simpan pengaturan privasi keamanan ke API
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setStateModal(() {
                        isSaving = true;
                      });
                      try {
                        await auth.updateUserSettings(
                          isPrivateProfile: isPrivateProfile,
                          enableTwoFactor: enableTwoFactor,
                          sessionTimeout: sessionTimeout,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(lang.translate('security_save_success'), style: const TextStyle(fontFamily: 'Outfit')),
                              backgroundColor: Colors.blueAccent,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${lang.currentLanguage == 'id' ? 'Gagal menyimpan' : 'Failed to save'}: $e', style: const TextStyle(fontFamily: 'Outfit')),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        setStateModal(() {
                          isSaving = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(lang.translate('save'), style: const TextStyle(color: Colors.white, fontFamily: 'Outfit')),
            ),
          ],
        ),
      ),
    );
  }

  // Membuka modal bantuan & tiket dukungan (Submit support ticket & FAQ)
  void _openHelpSupportModal() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final supportFormKey = GlobalKey<FormState>();
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(CupertinoIcons.question_circle_fill, color: Colors.orangeAccent),
              const SizedBox(width: 8),
              Text(lang.translate('help_support'), style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 320,
              child: Form(
                key: supportFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(lang.translate('support_faq'), style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    // Menampilkan FAQ dengan widget ExpansionTile
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: Column(
                        children: [
                          ExpansionTile(
                            title: Text(lang.translate('support_faq_q1'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: Text(lang.translate('support_faq_a1'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 12)),
                              ),
                            ],
                          ),
                          ExpansionTile(
                            title: Text(lang.translate('support_faq_q2'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: Text(lang.translate('support_faq_a2'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFFF1F5F9), height: 24),
                    Text(lang.translate('support_contact_us'), style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    // Field Input Subjek Masalah
                    TextFormField(
                      controller: subjectController,
                      enabled: !isSaving,
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 13),
                      decoration: InputDecoration(
                        labelText: lang.translate('support_subject'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? lang.translate('support_subject_required') : null,
                    ),
                    const SizedBox(height: 12),
                    // Field Input Isi Pesan/Detail Masalah
                    TextFormField(
                      controller: messageController,
                      enabled: !isSaving,
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 13),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: lang.translate('support_message'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? lang.translate('support_message_required') : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: Text(lang.translate('cancel'), style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Outfit')),
            ),
            // Tombol Kirim Tiket Dukungan ke Server API
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (supportFormKey.currentState!.validate()) {
                        setStateModal(() {
                          isSaving = true;
                        });
                        try {
                          await auth.submitSupportTicket(
                            subjectController.text.trim(),
                            messageController.text.trim(),
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  lang.translate('support_success_msg')
                                      .replaceAll(r'{subject}', subjectController.text.trim())
                                      .replaceAll(r'${subject}', subjectController.text.trim())
                                      .replaceAll(r'$subject', subjectController.text.trim()),
                                  style: const TextStyle(fontFamily: 'Outfit'),
                                ),
                                backgroundColor: Colors.orangeAccent,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${lang.translate('support_fail_msg')} $e', style: const TextStyle(fontFamily: 'Outfit')),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          setStateModal(() {
                            isSaving = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(lang.currentLanguage == 'id' ? 'Kirim Pesan' : 'Send Message', style: const TextStyle(color: Colors.white, fontFamily: 'Outfit')),
            ),
          ],
        ),
      ),
    );
  }

  // Membuka modal untuk mengedit data diri dasar profil (Nama, Email)
  void _openEditProfileModal() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(lang.translate('edit_profile'), style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(lang.translate('full_name'), style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? lang.translate('name_required') : null,
                ),
                const SizedBox(height: 16),
                Text(lang.translate('email_address'), style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return lang.translate('email_required');
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                      return lang.translate('valid_email_required');
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.translate('cancel'), style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Outfit')),
            ),
            // Mengirim request edit data profil ke API
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setStateModal(() { _isLoading = true; });
                try {
                  await auth.updateProfile(nameController.text.trim(), emailController.text.trim());
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  setStateModal(() { _isLoading = false; });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              child: Text(lang.translate('profile_save_changes'), style: const TextStyle(color: Colors.white, fontFamily: 'Outfit')),
            ),
          ],
        ),
      ),
    );
  }

  // Membuka modal untuk mengganti kata sandi (Password) pengguna
  void _openChangePasswordModal() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return;

    final passController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(lang.translate('change_password'), style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(lang.translate('profile_new_password'), style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return lang.translate('password_required');
                    if (value.length < 6) return lang.currentLanguage == 'id' ? 'Kata sandi minimal 6 karakter' : 'Password must be >= 6 characters';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.translate('cancel'), style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Outfit')),
            ),
            // Mengirim request update password ke API
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setStateModal(() { _isLoading = true; });
                try {
                  await auth.updateProfile(user.name, user.email, password: passController.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(lang.translate('profile_update_btn')), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  setStateModal(() { _isLoading = false; });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              child: Text(lang.translate('profile_update_btn'), style: const TextStyle(color: Colors.white, fontFamily: 'Outfit')),
            ),
          ],
        ),
      ),
    );
  }

  // Menampilkan kotak dialog konfirmasi sebelum keluar (Logout)
  void _showLogoutConfirm(BuildContext context, AuthProvider auth) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(lang.translate('confirm_logout'), style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: Text(lang.translate('logout_confirm_msg'), style: const TextStyle(fontFamily: 'Outfit')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('cancel'), style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Outfit')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              auth.logout(); // Menghapus token lokal dan mengembalikan user ke halaman login
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(lang.translate('logout'), style: const TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final user = auth.user;
    final String? profilePictureUrl = user?.profilePicture;
    const primaryColor = Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate background
      appBar: AppBar(
        title: Text(
          lang.translate('profile'),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontFamily: 'Outfit',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Sembunyikan tombol kembali bawaan
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Widget Avatar Profil (Mendukung pemuatan dinamis dan placeholder huruf awal)
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundImage: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                            ? NetworkImage(profilePictureUrl)
                            : null,
                        onBackgroundImageError: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                            ? (_, __) {}
                            : null,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: profilePictureUrl == null || profilePictureUrl.isEmpty
                            ? Text(
                                user != null ? user.name.substring(0, 1).toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor),
                              )
                            : null,
                      ),
                    ),
                    // Tombol Kamera Mengambang untuk Memicu Modal Ganti Foto
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _openChangeProfilePictureModal,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.camera_fill,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),

                // Menampilkan nama lengkap dan email pengguna aktif
                Text(
                  user?.name ?? 'Alex Carter',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user?.email ?? 'alex.carter@taskflow.inc',
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: Color(0xFF64748B),
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 28),

                // Tombol Edit Profile (Solid Indigo dengan Ikon Pensil)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _openEditProfileModal,
                    icon: const Icon(CupertinoIcons.pencil, color: Colors.white, size: 18),
                    label: Text(
                      lang.translate('edit_profile'),
                      style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Tombol Ganti Password (Solid Indigo dengan Ikon Gembok)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _openChangePasswordModal,
                    icon: const Icon(CupertinoIcons.lock_shield, color: Colors.white, size: 18),
                    label: Text(
                      lang.translate('change_password'),
                      style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Menu Opsi Pengaturan Tambahan (Notifikasi, Privasi Keamanan, Hubungi Bantuan)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.015),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    children: [
                      _buildListItem(
                        icon: CupertinoIcons.globe,
                        color: Colors.teal,
                        title: lang.translate('language'),
                        trailingText: lang.currentLanguage == 'id' ? 'Bahasa Indonesia' : 'English',
                        onTap: () => _openLanguageChooserModal(context, lang),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      _buildListItem(
                        icon: CupertinoIcons.bell,
                        color: Colors.indigoAccent,
                        title: lang.translate('notifications'),
                        onTap: _openNotificationsModal,
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      _buildListItem(
                        icon: CupertinoIcons.shield,
                        color: Colors.blueAccent,
                        title: lang.translate('privacy_security'),
                        onTap: _openPrivacySecurityModal,
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      _buildListItem(
                        icon: CupertinoIcons.question_circle,
                        color: Colors.orangeAccent,
                        title: lang.translate('help_support'),
                        onTap: _openHelpSupportModal,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Tombol Logout Sesi Akun (Merah Transparan lembut)
                InkWell(
                  onTap: () => _showLogoutConfirm(context, auth),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.square_arrow_right, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          lang.translate('logout'),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget untuk membangun item list pilihan pengaturan (ListTile) secara konsisten
  Widget _buildListItem({
    required IconData icon,
    required Color color,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF334155),
          fontFamily: 'Outfit',
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _openLanguageChooserModal(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          lang.translate('change_language'),
          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English', style: TextStyle(fontFamily: 'Outfit')),
              trailing: lang.currentLanguage == 'en' ? const Icon(Icons.check, color: Color(0xFF4F46E5)) : null,
              onTap: () {
                lang.setLanguage('en');
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('Bahasa Indonesia', style: TextStyle(fontFamily: 'Outfit')),
              trailing: lang.currentLanguage == 'id' ? const Icon(Icons.check, color: Color(0xFF4F46E5)) : null,
              onTap: () {
                lang.setLanguage('id');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
