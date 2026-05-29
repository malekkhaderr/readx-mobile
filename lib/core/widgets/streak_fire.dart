import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class StreakFire extends StatefulWidget {
  final int streakDays;
  final int maxStreak;
  final bool isBroken;
  final double size;

  const StreakFire({
    super.key,
    required this.streakDays,
    this.maxStreak = 14,
    this.isBroken = false,
    this.size = 70,
  });

  @override
  State<StreakFire> createState() => _StreakFireState();
}

class _StreakFireState extends State<StreakFire> with TickerProviderStateMixin {
  late AnimationController _progressCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _sparkCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _sparkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();

    final target = widget.isBroken ? 0.0 : (widget.streakDays / widget.maxStreak).clamp(0.0, 1.0);
    _progressAnim = Tween<double>(begin: 0, end: target).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic));
    _progressCtrl.forward();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _pulseCtrl.dispose();
    _sparkCtrl.dispose();
    super.dispose();
  }

  // Each day gets its own color — progresses through a warm spectrum
  Color get _dayColor {
    if (widget.isBroken) return AppColors.textLight;
    final days = widget.streakDays.clamp(0, 14);
    final colors = [
      const Color(0xFFBDBDBD), // 0 - grey (no streak)
      const Color(0xFFFFE082), // 1 - soft yellow
      const Color(0xFFFFC107), // 2 - amber
      const Color(0xFFFFB300), // 3 - deep amber
      const Color(0xFFFFA000), // 4 - orange-amber
      const Color(0xFFFF8F00), // 5 - deep orange
      const Color(0xFFFF6D00), // 6 - vivid orange
      const Color(0xFFFF5722), // 7 - red-orange
      const Color(0xFFF4511E), // 8 - deep red-orange
      const Color(0xFFE64A19), // 9 - burnt orange
      const Color(0xFFD84315), // 10 - fiery red
      const Color(0xFFBF360C), // 11 - dark fire
      const Color(0xFFB71C1C), // 12 - deep crimson
      const Color(0xFF880E4F), // 13 - magenta fire
      const Color(0xFFD4930D), // 14 - legendary gold
    ];
    return colors[days];
  }

  // Size scales with days — starts small, grows to full
  double get _scaleFactor {
    if (widget.isBroken) return 0.7;
    final days = widget.streakDays.clamp(0, 14);
    // Starts at 0.6x, grows to 1.0x at 14 days
    return 0.6 + (days / 14.0) * 0.4;
  }

  bool get _isComplete => widget.streakDays >= widget.maxStreak && !widget.isBroken;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = widget.size * _scaleFactor;
    final color = _dayColor;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: effectiveSize,
        height: effectiveSize,
        child: Stack(alignment: Alignment.center, children: [
          // Glow
          if (!widget.isBroken)
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: effectiveSize * 0.7 + _pulseCtrl.value * 4,
                height: effectiveSize * 0.7 + _pulseCtrl.value * 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [color.withOpacity(0.2 + _pulseCtrl.value * 0.1), Colors.transparent]),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.15 + _pulseCtrl.value * 0.1), blurRadius: 12 + _pulseCtrl.value * 6)],
                ),
              ),
            ),
          // Ring bg
          SizedBox(
            width: effectiveSize * 0.82,
            height: effectiveSize * 0.82,
            child: CircularProgressIndicator(value: 1, strokeWidth: 4.5, backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation(AppColors.divider.withOpacity(0.3))),
          ),
          // Ring progress
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (_, __) => SizedBox(
              width: effectiveSize * 0.82,
              height: effectiveSize * 0.82,
              child: CircularProgressIndicator(value: _progressAnim.value, strokeWidth: 4.5, strokeCap: StrokeCap.round, backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation(color)),
            ),
          ),
          // Sparkles when complete
          if (_isComplete) ..._buildSparkles(effectiveSize, color),
          // Center icon — scales with pulse
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) => Transform.scale(scale: 1.0 + _pulseCtrl.value * 0.06, child: child),
            child: Container(
              width: effectiveSize * 0.55,
              height: effectiveSize * 0.55,
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.isBroken ? AppColors.cardBackground : color.withOpacity(0.12)),
              child: Center(child: widget.isBroken
                  ? Icon(Icons.heart_broken_rounded, size: effectiveSize * 0.24, color: AppColors.textGrey)
                  : Icon(Icons.local_fire_department_rounded, size: effectiveSize * 0.28, color: color)),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 6),
      // Label with day count
      Row(mainAxisSize: MainAxisSize.min, children: [
        if (!widget.isBroken) ...[
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)]),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          widget.isBroken ? 'Streak lost' : '${widget.streakDays} ${widget.streakDays == 1 ? "day" : "days"}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: widget.isBroken ? AppColors.textGrey : color),
        ),
        if (!widget.isBroken && !_isComplete) ...[
          Text(' / ${widget.maxStreak}', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
        ],
        if (_isComplete) ...[
          const SizedBox(width: 4),
          Icon(Icons.verified_rounded, size: 13, color: color),
        ],
      ]),
    ]);
  }

  List<Widget> _buildSparkles(double size, Color color) {
    return List.generate(6, (i) {
      final angle = (i / 6) * pi * 2;
      return AnimatedBuilder(
        animation: _sparkCtrl,
        builder: (_, __) {
          final t = (_sparkCtrl.value + i / 6) % 1.0;
          final r = size * 0.42 + sin(t * pi * 2) * 3;
          final opacity = (0.4 + sin(t * pi * 2) * 0.6).clamp(0.0, 1.0);
          return Positioned(
            left: size / 2 + cos(angle + t * 0.5) * r - 3,
            top: size / 2 + sin(angle + t * 0.5) * r - 3,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 5, height: 5,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 4)]),
              ),
            ),
          );
        },
      );
    });
  }
}
