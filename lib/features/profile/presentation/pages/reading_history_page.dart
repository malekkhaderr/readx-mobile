import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';

class ReadingHistoryPage extends StatefulWidget {
  const ReadingHistoryPage({super.key});
  @override
  State<ReadingHistoryPage> createState() => _ReadingHistoryPageState();
}

class _ReadingHistoryPageState extends State<ReadingHistoryPage> {
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await sl<DioClient>().dio.get('/reading-sessions', queryParameters: {'pageNumber': _page, 'pageSize': 20});
      if (response.statusCode == 200) {
        final data = response.data;
        final items = data is Map ? (data['items'] as List? ?? []) : [];
        final newSessions = items.map((e) => e as Map<String, dynamic>).toList();
        final totalPages = data is Map ? (data['totalPages'] as int? ?? 1) : 1;
        setState(() {
          _sessions.addAll(newSessions);
          _hasMore = _page < totalPages;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _loadMore() {
    if (!_hasMore || _loading) return;
    _page++;
    _load();
  }

  String _formatTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reading History', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textDark),
      ),
      body: _loading && _sessions.isEmpty
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _sessions.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _sessions.length) {
                      _loadMore();
                      return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                    }
                    return _buildItem(_sessions[i]);
                  },
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.auto_stories_rounded, size: 48, color: AppColors.textLight),
      const SizedBox(height: 12),
      Text('No reading sessions yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
      const SizedBox(height: 6),
      Text('Start reading a book to see your history here', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
    ]));
  }

  Widget _buildItem(Map<String, dynamic> s) {
    final title = s['bookTitle'] as String? ?? 'Unknown';
    final cover = s['coverImageUrl'] as String?;
    final progress = (s['progressPercentage'] as num?)?.toInt() ?? 0;
    final minutes = (s['totalReadingTimeMinutes'] as num?)?.toInt() ?? 0;
    final isCompleted = s['isCompleted'] as bool? ?? false;
    final bookId = s['bookId'] as int? ?? 0;
    final startedAt = s['startedAt'] != null ? DateTime.tryParse(s['startedAt'] as String) : null;

    return GestureDetector(
      onTap: () => context.push('/book/$bookId'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 0.8),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 50, height: 70,
              color: AppColors.primaryLight,
              child: cover != null && cover.startsWith('http')
                  ? Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Icon(Icons.menu_book_rounded, size: 22, color: AppColors.primary)))
                  : Center(child: Icon(Icons.menu_book_rounded, size: 22, color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.schedule_rounded, size: 12, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Text(_formatTime(minutes), style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
              if (startedAt != null) ...[
                const SizedBox(width: 10),
                Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textGrey),
                const SizedBox(width: 4),
                Text('${startedAt.day}/${startedAt.month}/${startedAt.year}', style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
              ],
            ]),
            const SizedBox(height: 6),
            // Progress bar
            Row(children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 5,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(isCompleted ? AppColors.successGreen : AppColors.primary),
                ),
              )),
              const SizedBox(width: 10),
              Text(isCompleted ? 'Done' : '$progress%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isCompleted ? AppColors.successGreen : AppColors.primary)),
            ]),
          ])),
        ]),
      ),
    );
  }
}
