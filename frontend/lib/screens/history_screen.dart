import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _historyList = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final list = await auth.apiService.getTaskHistory();
      setState(() {
        _historyList = list;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    const primaryColor = Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          lang.translate('task_history'),
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
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : RefreshIndicator(
              onRefresh: _fetchHistory,
              color: primaryColor,
              child: _errorMessage.isNotEmpty
                  ? _buildErrorView()
                  : _historyList.isEmpty
                      ? _buildEmptyView(lang)
                      : _buildTimelineView(lang),
            ),
    );
  }

  Widget _buildErrorView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
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
      ],
    );
  }

  Widget _buildEmptyView(LanguageProvider lang) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.time,
                size: 64,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              lang.translate('no_history_found'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineView(LanguageProvider lang) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: _historyList.length,
      itemBuilder: (context, index) {
        final item = _historyList[index];
        final String action = item['action'] ?? '';
        final String title = item['task_title'] ?? '';
        final String details = item['details'] ?? '';
        final String dateStr = item['created_at'] != null
            ? item['created_at'].toString().substring(0, 19).replaceAll('T', ' ')
            : '';

        // Determine action styling
        Color actionColor;
        IconData actionIcon;
        String actionLabelKey;

        switch (action) {
          case 'Created':
            actionColor = const Color(0xFF10B981); // Emerald Green
            actionIcon = CupertinoIcons.add;
            actionLabelKey = 'history_created';
            break;
          case 'Updated Status':
            actionColor = const Color(0xFFF59E0B); // Amber
            actionIcon = CupertinoIcons.arrow_right_arrow_left;
            actionLabelKey = 'history_updated_status';
            break;
          case 'Updated Details':
            actionColor = const Color(0xFF3B82F6); // Blue
            actionIcon = CupertinoIcons.pencil;
            actionLabelKey = 'history_updated_details';
            break;
          case 'Deleted':
            actionColor = const Color(0xFFEF4444); // Red
            actionIcon = CupertinoIcons.trash;
            actionLabelKey = 'history_deleted';
            break;
          default:
            actionColor = const Color(0xFF64748B); // Slate
            actionIcon = CupertinoIcons.info;
            actionLabelKey = 'history_log';
        }

        // Custom localized text format for details
        String displayDetails = details;
        if (action == 'Created') {
          displayDetails = lang.currentLanguage == 'id'
              ? 'Tugas "$title" telah berhasil dibuat.'
              : 'Task "$title" was successfully created.';
        } else if (action == 'Deleted') {
          displayDetails = lang.currentLanguage == 'id'
              ? 'Tugas "$title" telah dihapus.'
              : 'Task "$title" was deleted.';
        } else if (action == 'Updated Status') {
          // Translate "Changed status from Pending to Progress"
          displayDetails = details
              .replaceAll('Changed status from Pending to Progress', lang.currentLanguage == 'id' ? 'Mengubah status dari Tertunda ke Sedang Berjalan' : 'Changed status from Pending to In Progress')
              .replaceAll('Changed status from Pending to Done', lang.currentLanguage == 'id' ? 'Mengubah status dari Tertunda ke Selesai' : 'Changed status from Pending to Completed')
              .replaceAll('Changed status from Progress to Pending', lang.currentLanguage == 'id' ? 'Mengubah status dari Sedang Berjalan ke Tertunda' : 'Changed status from In Progress to Pending')
              .replaceAll('Changed status from Progress to Done', lang.currentLanguage == 'id' ? 'Mengubah status dari Sedang Berjalan ke Selesai' : 'Changed status from In Progress to Completed')
              .replaceAll('Changed status from Done to Pending', lang.currentLanguage == 'id' ? 'Mengubah status dari Selesai ke Tertunda' : 'Changed status from Completed to Pending')
              .replaceAll('Changed status from Done to Progress', lang.currentLanguage == 'id' ? 'Mengubah status dari Selesai ke Sedang Berjalan' : 'Changed status from Completed to In Progress');
        } else if (action == 'Updated Details') {
          displayDetails = lang.currentLanguage == 'id'
              ? 'Memperbarui rincian data tugas.'
              : 'Updated details of the task.';
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline visual line and indicator
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: actionColor.withOpacity(0.3), width: 1.5),
                  ),
                  child: Icon(
                    actionIcon,
                    color: actionColor,
                    size: 16,
                  ),
                ),
                if (index < _historyList.length - 1)
                  Container(
                    width: 2,
                    height: 54,
                    color: const Color(0xFFE2E8F0),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // History Details Card
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: actionColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            lang.translate(actionLabelKey),
                            style: TextStyle(
                              color: actionColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayDetails,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        height: 1.4,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
