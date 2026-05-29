import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';

class ReadingHistorySection extends StatefulWidget {
  const ReadingHistorySection({super.key});
  @override
  State<ReadingHistorySection> createState() => _ReadingHistorySectionState();
}

class _ReadingHistorySectionState extends State<ReadingHistorySection> {
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await sl<DioClient>().dio.get('/reading-sessions', queryParameters: {'pageNumber': 1, 'pageSize': 10});
      if (response.statusCode == 200) {
        final data = response.data;
        final items = data is Map ? (data['items'] as List? ?? []) : [];
        _sessions = items.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _formatTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  // Stats calculations
  int get _totalMinutes => _sessions.fold(0, (sum, s) => sum + ((s['totalReadingTimeMinutes'] as num?)?.toInt() ?? 0));
  int get _totalBooks => _sessions.map((s) => s['bookId']).toSet().length;
  int get _completedCount => _sessions.where((s) => s['isCompleted'] == true).length;
  int get _avgProgress => _sessions.isEmpty ? 0 : _sessions.fold(0, (sum, s) => sum + ((s['progressPercentage'] as num?)?.toInt() ?? 0)) ~/ _sessions.length;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Icon(Icons.history_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Reading History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/reading-history'),
            child: Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ]),
        // Stats summary
        if (!_loading && _sessions.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _miniStat(Icons.schedule_rounded, _formatTime(_totalMinutes), 'Total Time', AppColors.primary),
              _miniDivider(),
              _miniStat(Icons.menu_book_rounded, '$_totalBooks', 'Books', AppColors.successGreen),
              _miniDivider(),
              _miniStat(Icons.check_circle_rounded, '$_completedCount', 'Finished', AppColors.gold),
              _miniDivider(),
              _miniStat(Icons.trending_up_rounded, '$_avgProgress%', 'Avg', AppColors.warningOrange),
            ]),
          ),
        ],
        const SizedBox(height: 14),
        // Sessions list
        if (_loading)
          const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_sessions.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(children: [
              Icon(Icons.auto_stories_rounded, size: 28, color: AppColors.textLight),
              const SizedBox(height: 6),
              Text('No reading sessions yet', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
            ]),
          ))
        else
          ...List.generate(_sessions.length > 3 ? 3 : _sessions.length, (i) => _buildSessionRow(_sessions[i], i)),
      ]),
    );
  }

  Widget _miniStat(IconData icon, String value, String label, Color color) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
      const SizedBox(height: 1),
      Text(label, style: TextStyle(fontSize: 9, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _miniDivider() => Container(width: 1, height: 28, color: AppColors.divider);

  Widget _buildSessionRow(Map<String, dynamic> s, int i) {
    final title = s['bookTitle'] as String? ?? 'Unknown';
    final cover = s['coverImageUrl'] as String?;
    final progress = (s['progressPercentage'] as num?)?.toInt() ?? 0;
    final minutes = (s['totalReadingTimeMinutes'] as num?)?.toInt() ?? 0;
    final isCompleted = s['isCompleted'] as bool? ?? false;
    final currentPage = (s['currentPage'] as num?)?.toInt() ?? 0;
    final totalPages = (s['totalPages'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: EdgeInsets.only(bottom: i < 2 ? 12 : 0),
      child: Row(children: [
        // Cover
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 40, height: 56,
            color: AppColors.primaryLight,
            child: cover != null && cover.startsWith('http')
                ? Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Icon(Icons.menu_book_rounded, size: 18, color: AppColors.primary)))
                : Center(child: Icon(Icons.menu_book_rounded, size: 18, color: AppColors.primary)),
          ),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.schedule_rounded, size: 11, color: AppColors.textGrey),
            const SizedBox(width: 4),
            Text(_formatTime(minutes), style: TextStyle(fontSize: 10.5, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            if (totalPages > 0) ...[
              Icon(Icons.description_outlined, size: 11, color: AppColors.textGrey),
              const SizedBox(width: 3),
              Text('$currentPage/$totalPages', style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.successGreen.withOpacity(0.1) : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(isCompleted ? 'Done' : '$progress%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: isCompleted ? AppColors.successGreen : AppColors.primary)),
            ),
          ]),
        ])),
        // Circular progress
        SizedBox(
          width: 36, height: 36,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(value: progress / 100, strokeWidth: 3, strokeCap: StrokeCap.round, backgroundColor: AppColors.divider, valueColor: AlwaysStoppedAnimation(isCompleted ? AppColors.successGreen : AppColors.primary)),
            if (isCompleted)
              Icon(Icons.check_rounded, size: 13, color: AppColors.successGreen)
            else
              Text('$progress', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          ]),
        ),
      ]),
    );
  }
}
