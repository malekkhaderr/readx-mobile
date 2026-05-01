import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../data/models/mock_profile_data.dart';

// ── Profile Header ──────────────────────────────────────────
class ProfileHeader extends StatelessWidget {
  final MockUserProfile profile;
  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Avatar
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text('👩‍💼', style: TextStyle(fontSize: 40)),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          profile.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          profile.level,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ProfileActionButton(
              label: 'Edit Profile',
              icon: Icons.edit_outlined,
              onTap: () {},
            ),
            const SizedBox(width: 10),
            _ProfileActionButton(
              label: 'Summaries',
              icon: Icons.summarize_outlined,
              isPrimary: true,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ProfileActionButton({
    required this.label,
    required this.icon,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: AppColors.divider),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary ? Colors.white : AppColors.textDark,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile Stats Row ───────────────────────────────────────
class ProfileStatsRow extends StatelessWidget {
  final MockUserProfile profile;
  const ProfileStatsRow({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ProfileStat(
            value: '${profile.booksRead}',
            label: 'Books',
            emoji: '📚',
          ),
          Container(width: 1, height: 36, color: AppColors.divider),
          _ProfileStat(
            value: '${profile.streakDays}',
            label: 'Day Streak',
            emoji: '🔥',
          ),
          Container(width: 1, height: 36, color: AppColors.divider),
          _ProfileStat(
            value: profile.cubes >= 1000
                ? '${(profile.cubes / 1000).toStringAsFixed(1)}k'
                : '${profile.cubes}',
            label: 'Cubes',
            emoji: '🧊',
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  final String emoji;

  const _ProfileStat({
    required this.value,
    required this.label,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Reading Rituals ─────────────────────────────────────────
class ReadingRitualsSection extends StatelessWidget {
  final List<ReadingRitual> rituals;
  const ReadingRitualsSection({super.key, required this.rituals});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reading Rituals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'VIEW HISTORY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Summary row
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Text(
                MockProfileData.totalReadingTime,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.trending_up, size: 14, color: AppColors.successGreen),
              const SizedBox(width: 4),
              Text(
                MockProfileData.avgSessionTime,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Day circles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: rituals.map((r) => _RitualDay(ritual: r)).toList(),
          ),
        ],
      ),
    );
  }
}

class _RitualDay extends StatelessWidget {
  final ReadingRitual ritual;
  const _RitualDay({required this.ritual});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ritual.completed
                ? AppColors.primary
                : AppColors.primaryLight.withOpacity(0.5),
            border: Border.all(
              color: ritual.completed
                  ? AppColors.primary
                  : AppColors.divider,
              width: 2,
            ),
          ),
          child: Center(
            child: ritual.completed
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '${ritual.minutesRead}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          ritual.day,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: ritual.completed ? AppColors.primary : AppColors.textGrey,
          ),
        ),
      ],
    );
  }
}

// ── Trophy Grid ─────────────────────────────────────────────
class TrophyGridSection extends StatelessWidget {
  final List<Trophy> trophies;
  const TrophyGridSection({super.key, required this.trophies});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trophies & Runes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: trophies.map((t) => _TrophyItem(trophy: t)).toList(),
          ),
        ],
      ),
    );
  }
}

class _TrophyItem extends StatelessWidget {
  final Trophy trophy;
  const _TrophyItem({required this.trophy});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: trophy.unlocked
                ? AppColors.primaryLight
                : AppColors.divider.withOpacity(0.5),
            border: Border.all(
              color: trophy.unlocked
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.divider,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              trophy.emoji,
              style: TextStyle(
                fontSize: 22,
                color: trophy.unlocked ? null : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          trophy.name,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: trophy.unlocked ? AppColors.textDark : AppColors.textGrey,
          ),
        ),
      ],
    );
  }
}
