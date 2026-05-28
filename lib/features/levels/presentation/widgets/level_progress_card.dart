import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../data/models/reader_level_model.dart';

class LevelProgressCard extends StatelessWidget {
  final ReaderLevel currentLevel;
  final ReaderLevel? nextLevel;
  final double progress;
  final int totalTokens;

  const LevelProgressCard({
    super.key,
    required this.currentLevel,
    this.nextLevel,
    required this.progress,
    required this.totalTokens,
  });

  bool get isMaxLevel => nextLevel == null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Center(child: Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level ${currentLevel.levelNumber}', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(currentLevel.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                  ],
                ),
              ),
              // Token count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.toll_rounded, size: 14, color: Colors.white.withOpacity(0.9)),
                  const SizedBox(width: 4),
                  Text('$totalTokens', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          if (isMaxLevel) ...[
            // Max level — full bar with gold
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFFFFD700), const Color(0xFFFFA726), const Color(0xFFFFD700)]),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(child: Text('Max Level Reached', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w700))),
          ] else ...[
            // Progress to next level
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Progress to Level ${nextLevel!.levelNumber}', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 6)],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('$totalTokens tokens', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500)),
              Text('${nextLevel!.minTokens} needed', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500)),
            ]),
          ],
        ],
      ),
    );
  }
}
