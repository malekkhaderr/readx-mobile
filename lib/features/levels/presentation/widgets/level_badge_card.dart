import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/datasources/levels_remote_datasource.dart';
import '../../data/models/reader_level_model.dart';

class LevelBadgeCard extends StatefulWidget {
  final int? levelId;
  final String levelLabel;
  final int totalTokensEarned;
  final int tokenBalance;
  final VoidCallback onTap;

  const LevelBadgeCard({
    super.key,
    required this.levelId,
    required this.levelLabel,
    required this.totalTokensEarned,
    required this.tokenBalance,
    required this.onTap,
  });

  @override
  State<LevelBadgeCard> createState() => _LevelBadgeCardState();
}

class _LevelBadgeCardState extends State<LevelBadgeCard> {
  ReaderLevel? _currentLevel;
  ReaderLevel? _nextLevel;
  bool _loaded = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _loadLevelInfo();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadLevelInfo() async {
    try {
      final ds = LevelsRemoteDataSource(dioClient: sl());
      final levels = await ds.getAllLevels();
      levels.sort((a, b) => a.levelNumber.compareTo(b.levelNumber));

      ReaderLevel? current;
      if (widget.levelId != null) {
        current = levels.where((l) => l.id == widget.levelId).firstOrNull;
      }
      current ??= levels.isNotEmpty ? levels.first : null;

      ReaderLevel? next;
      if (current != null) {
        final idx = levels.indexOf(current);
        if (idx < levels.length - 1) next = levels[idx + 1];
      }

      if (_disposed) return;
      setState(() { _currentLevel = current; _nextLevel = next; _loaded = true; });
    } catch (_) {
      if (_disposed) return;
      setState(() => _loaded = true);
    }
  }

  double get _progress {
    if (_currentLevel == null || _nextLevel == null) return _nextLevel == null && _currentLevel != null ? 1.0 : 0.0;
    final range = _nextLevel!.minTokens - _currentLevel!.minTokens;
    if (range <= 0) return 1.0;
    return ((widget.totalTokensEarned - _currentLevel!.minTokens) / range).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final level = _currentLevel;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 14, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            // Level icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: _loaded && level?.iconUrl != null && level!.iconUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: level.iconUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _iconFallback(),
                      ),
                    )
                  : _iconFallback(),
            ),
            const SizedBox(width: 14),
            // Level info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        level?.name ?? widget.levelLabel,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      if (level != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Lvl ${level.levelNumber}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.9))),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  if (_loaded) ...[
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: _progress,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 4)],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Image.asset('assets/images/purple_feather.png', width: 11, height: 11),
                          const SizedBox(width: 4),
                          Text('${widget.tokenBalance}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
                        ]),
                        if (_nextLevel != null)
                          Text('${_nextLevel!.minTokens - widget.totalTokensEarned} to next', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500))
                        else
                          Text('Max Level', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ] else
                    Container(height: 6, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(3))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.7), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _iconFallback() {
    return Center(child: Icon(Icons.workspace_premium_rounded, size: 24, color: Colors.white.withOpacity(0.8)));
  }
}
