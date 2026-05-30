import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/sound_service.dart';
import '../../data/datasources/levels_remote_datasource.dart';
import '../../data/models/reader_level_model.dart';

class LevelsRoadmapPage extends StatefulWidget {
  final int? currentLevelId;
  final int totalTokens;

  const LevelsRoadmapPage({
    super.key,
    required this.currentLevelId,
    required this.totalTokens,
  });

  @override
  State<LevelsRoadmapPage> createState() => _LevelsRoadmapPageState();
}

class _LevelsRoadmapPageState extends State<LevelsRoadmapPage> with TickerProviderStateMixin {
  List<ReaderLevel> _levels = [];
  bool _loading = true;
  String? _error;
  int? _expandedIndex;

  late final AnimationController _progressAnimController;
  late final Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _progressAnim = CurvedAnimation(parent: _progressAnimController, curve: Curves.easeOutCubic);
    _loadLevels();
  }

  @override
  void dispose() {
    _progressAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadLevels() async {
    try {
      final ds = LevelsRemoteDataSource(dioClient: sl());
      final levels = await ds.getAllLevels();
      levels.sort((a, b) => a.levelNumber.compareTo(b.levelNumber));
      if (mounted) {
        setState(() { _levels = levels; _loading = false; });
        _progressAnimController.forward();
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load levels'; _loading = false; });
    }
  }

  ReaderLevel? get _currentLevel {
    if (widget.currentLevelId == null) return _levels.isNotEmpty ? _levels.first : null;
    return _levels.where((l) => l.id == widget.currentLevelId).firstOrNull ?? (_levels.isNotEmpty ? _levels.first : null);
  }

  ReaderLevel? get _nextLevel {
    final current = _currentLevel;
    if (current == null) return null;
    final idx = _levels.indexOf(current);
    if (idx < _levels.length - 1) return _levels[idx + 1];
    return null;
  }

  double get _progress {
    final current = _currentLevel;
    final next = _nextLevel;
    if (current == null) return 0;
    if (next == null) return 1.0;
    final range = next.minTokens - current.minTokens;
    if (range <= 0) return 1.0;
    return ((widget.totalTokens - current.minTokens) / range).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(child: _buildStatsRow()),
                    SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.route_rounded, size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Text('Your Journey', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                        const Spacer(),
                        Text('${_levels.length} levels', style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                      ]),
                    )),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final level = _levels[index];
                            final current = _currentLevel;
                            final isUnlocked = current != null && level.levelNumber < current.levelNumber;
                            final isCurrent = level.id == current?.id;
                            final isLocked = !isUnlocked && !isCurrent;
                            return _InteractiveTimelineItem(
                              level: level,
                              isUnlocked: isUnlocked,
                              isCurrent: isCurrent,
                              isLocked: isLocked,
                              isLast: index == _levels.length - 1,
                              isExpanded: _expandedIndex == index,
                              totalTokens: widget.totalTokens,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                // Play level_up chime when expanding the current level card
                                if (_levels[index].id == _currentLevel?.id && _expandedIndex != index) {
                                  sl<SoundService>().levelUp();
                                }
                                setState(() => _expandedIndex = _expandedIndex == index ? null : index);
                              },
                            );
                          },
                          childCount: _levels.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
    );
  }

  Widget _buildSliverAppBar() {
    final current = _currentLevel;
    final isMax = _nextLevel == null && current != null;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.surface,
      iconTheme: IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(children: [
                    // Level icon
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: current?.localIconAsset != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset(current!.localIconAsset!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _shieldIcon()))
                          : _shieldIcon(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(current?.name ?? 'Reader', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('Level ${current?.levelNumber ?? 1}  •  ${widget.totalTokens} lifetime tokens', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w500)),
                    ])),
                  ]),
                  const SizedBox(height: 18),
                  // Animated progress bar
                  AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, __) => Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(isMax ? 'Maximum Level Achieved' : 'Progress to ${_nextLevel?.name ?? "Next"}', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600)),
                        Text('${(_progress * _progressAnim.value * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 8),
                      Stack(children: [
                        Container(height: 8, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(4))),
                        FractionallySizedBox(
                          widthFactor: isMax ? _progressAnim.value : _progress * _progressAnim.value,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: isMax
                                  ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA726), Color(0xFFFFD700)])
                                  : null,
                              color: isMax ? null : Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 6)],
                            ),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final current = _currentLevel;
    final levelsUnlocked = _levels.where((l) => current != null && l.levelNumber <= current.levelNumber).length;
    final tokensToNext = _nextLevel != null ? _nextLevel!.minTokens - widget.totalTokens : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(children: [
        _StatChip(icon: Icons.emoji_events_rounded, value: '$levelsUnlocked/${_levels.length}', label: 'Unlocked', color: AppColors.successGreen),
        const SizedBox(width: 10),
        _StatChip(icon: Icons.toll_rounded, value: '${widget.totalTokens}', label: 'Earned', color: AppColors.primary),
        const SizedBox(width: 10),
        _StatChip(icon: Icons.arrow_upward_rounded, value: tokensToNext > 0 ? '$tokensToNext' : '—', label: 'To Next', color: AppColors.warningOrange),
      ]),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textGrey),
      const SizedBox(height: 12),
      Text(_error!, style: TextStyle(color: AppColors.textGrey, fontSize: 14)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: () { setState(() { _loading = true; _error = null; }); _loadLevels(); }, child: const Text('Retry')),
    ]));
  }

  Widget _shieldIcon() => Center(child: Icon(Icons.workspace_premium_rounded, size: 28, color: Colors.white.withOpacity(0.8)));
}

// ─── Stat Chip ─────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatChip({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
      ]),
    ));
  }
}

// ─── Interactive Timeline Item ─────────────────────────────────

class _InteractiveTimelineItem extends StatelessWidget {
  final ReaderLevel level;
  final bool isUnlocked, isCurrent, isLocked, isLast, isExpanded;
  final int totalTokens;
  final VoidCallback onTap;

  const _InteractiveTimelineItem({
    required this.level, required this.isUnlocked, required this.isCurrent,
    required this.isLocked, required this.isLast, required this.isExpanded,
    required this.totalTokens, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Timeline connector
        SizedBox(width: 44, child: Column(children: [
          // Dot
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isCurrent ? 30 : 24,
            height: isCurrent ? 30 : 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent ? AppColors.primary : isUnlocked ? AppColors.successGreen : AppColors.divider,
              border: isCurrent ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 3) : null,
              boxShadow: isCurrent ? [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 10, spreadRadius: 2)] : null,
            ),
            child: Center(child: isCurrent
                ? const Icon(Icons.star_rounded, size: 14, color: Colors.white)
                : isUnlocked
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : Icon(Icons.lock_rounded, size: 11, color: AppColors.textGrey)),
          ),
          // Line
          if (!isLast) Expanded(child: Container(
            width: 2.5,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isUnlocked || isCurrent ? AppColors.primary.withOpacity(0.25) : AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          )),
        ])),
        const SizedBox(width: 12),
        // Card
        Expanded(child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(bottom: 14),
            padding: EdgeInsets.all(isExpanded ? 18 : 14),
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.primary.withOpacity(0.06) : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCurrent ? AppColors.primary.withOpacity(0.4) : isExpanded ? AppColors.primary.withOpacity(0.2) : AppColors.divider,
                width: isCurrent ? 1.5 : 0.8,
              ),
              boxShadow: [
                if (isCurrent || isExpanded) BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4)),
              ],
            ),
            child: Opacity(
              opacity: isLocked ? 0.55 : 1.0,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  // Icon
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: isLocked ? AppColors.divider : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(13),
                      border: isCurrent ? Border.all(color: AppColors.primary.withOpacity(0.2)) : null,
                    ),
                    child: level.localIconAsset != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ColorFiltered(
                              colorFilter: isLocked ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                              child: Image.asset(level.localIconAsset!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback()),
                            ))
                        : _fallback(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('Level ${level.levelNumber}', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(7)),
                          child: const Text('CURRENT', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        ),
                      ] else if (isUnlocked) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.verified_rounded, size: 14, color: AppColors.successGreen),
                      ],
                    ]),
                    const SizedBox(height: 3),
                    Text(level.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  ])),
                  // Token range badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLocked ? AppColors.divider : AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      level.maxTokens != null ? '${level.minTokens}–${level.maxTokens}' : '${level.minTokens}+',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: isLocked ? AppColors.textLight : AppColors.primary),
                    ),
                  ),
                ]),
                // Expanded content
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _expandedContent(context),
                  crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                  sizeCurve: Curves.easeOutCubic,
                ),
              ]),
            ),
          ),
        )),
      ]),
    );
  }

  Widget _expandedContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Divider
        Container(height: 1, color: AppColors.divider),
        const SizedBox(height: 14),
        // Description
        if (level.description != null && level.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textGrey),
              const SizedBox(width: 8),
              Expanded(child: Text(level.description!, style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.5))),
            ]),
          ),
        // Token requirement
        Row(children: [
          _InfoPill(icon: Icons.toll_rounded, label: 'Min: ${level.minTokens} tokens', color: AppColors.primary),
          const SizedBox(width: 8),
          if (level.maxTokens != null)
            _InfoPill(icon: Icons.arrow_upward_rounded, label: 'Max: ${level.maxTokens}', color: AppColors.warningOrange)
          else
            _InfoPill(icon: Icons.all_inclusive_rounded, label: 'No limit', color: AppColors.successGreen),
        ]),
        // Progress for current
        if (isCurrent) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.12)),
            ),
            child: Row(children: [
              Icon(Icons.trending_up_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('You have $totalTokens tokens. Keep reading to level up!', style: TextStyle(fontSize: 11, color: AppColors.textDark, fontWeight: FontWeight.w500))),
            ]),
          ),
        ],
        // Lock message
        if (isLocked) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.divider.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textLight),
              const SizedBox(width: 8),
              Expanded(child: Text('Earn ${level.minTokens - totalTokens} more tokens to unlock this level', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _fallback() => Center(child: Icon(Icons.workspace_premium_rounded, size: 22, color: AppColors.primary));
}

// ─── Info Pill ─────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.12))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}
