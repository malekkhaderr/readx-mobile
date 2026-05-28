import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';

// ── Reader Top Bar ──────────────────────────────────────────
class ReaderTopBar extends StatelessWidget {
  final String chapterTitle;
  final double progress;
  final VoidCallback onBack;

  const ReaderTopBar({
    super.key,
    required this.chapterTitle,
    required this.progress,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  chapterTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.bookmark_border, size: 22, color: AppColors.textGrey),
              const SizedBox(width: 12),
              Icon(Icons.more_horiz, size: 22, color: AppColors.textGrey),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: AppColors.divider.withOpacity(0.5),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Streak Badge ────────────────────────────────────────────
class StreakBadge extends StatelessWidget {
  final int days;
  const StreakBadge({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$days DAY STREAK',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drop Cap Paragraph ──────────────────────────────────────
class DropCapParagraph extends StatelessWidget {
  final String text;
  const DropCapParagraph({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final firstChar = text.isNotEmpty ? text[0].toUpperCase() : '';
    final rest = text.isNotEmpty ? text.substring(1) : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drop cap
          Container(
            margin: const EdgeInsets.only(right: 8, top: 2),
            child: Text(
              firstChar,
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                height: 0.85,
                fontFamily: 'Georgia',
              ),
            ),
          ),
          // Rest of text
          Expanded(
            child: Text(
              rest,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textDark,
                height: 1.75,
                fontFamily: 'Georgia',
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Block Quote ─────────────────────────────────────────────
class ReaderBlockQuote extends StatelessWidget {
  final String text;
  const ReaderBlockQuote({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: AppColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: AppColors.textDark.withOpacity(0.8),
          height: 1.65,
          fontFamily: 'Georgia',
        ),
      ),
    );
  }
}

// ── Body Paragraph ──────────────────────────────────────────
class ReaderParagraph extends StatelessWidget {
  final String text;
  const ReaderParagraph({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          color: AppColors.textDark,
          height: 1.75,
          fontFamily: 'Georgia',
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Reader Bottom Bar ───────────────────────────────────────
class ReaderBottomBar extends StatelessWidget {
  final double progress;
  const ReaderBottomBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous
            _BottomAction(
              icon: Icons.arrow_back_ios_new,
              label: 'Prev',
              onTap: () {},
            ),
            // Progress
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'read',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
            // Font size
            _BottomAction(
              icon: Icons.text_fields,
              label: 'Font',
              onTap: () {},
            ),
            // Bookmark
            _BottomAction(
              icon: Icons.bookmark_outline,
              label: 'Save',
              onTap: () {},
            ),
            // Next
            _BottomAction(
              icon: Icons.arrow_forward_ios,
              label: 'Next',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppColors.textGrey),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
