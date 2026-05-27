import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_theme.dart';
import '../../data/models/author_book_model.dart';

class AuthorBookListCard extends StatelessWidget {
  final AuthorBook book;
  final int? quotesCount;
  final VoidCallback onTap;

  const AuthorBookListCard({
    super.key,
    required this.book,
    this.quotesCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              SizedBox(
                width: 90,
                height: 130,
                child: book.coverImageUrl != null &&
                        book.coverImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: book.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _coverPlaceholder(),
                        errorWidget: (_, __, ___) => _coverPlaceholder(),
                      )
                    : _coverPlaceholder(),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + status badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              book.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(isPublished: book.isPublished),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Category
                      if (book.categoryName != null &&
                          book.categoryName!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            book.categoryName!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Metrics Row
                      Row(
                        children: [
                          _MetricChip(
                            icon: Icons.visibility_rounded,
                            value: _formatCount(book.viewCount),
                            color: const Color(0xFF2196F3),
                          ),
                          const SizedBox(width: 8),
                          _MetricChip(
                            icon: Icons.auto_stories_rounded,
                            value: _formatCount(book.readCount),
                            color: AppColors.successGreen,
                          ),
                          const SizedBox(width: 8),
                          _MetricChip(
                            icon: Icons.star_rounded,
                            value: book.averageRating.toStringAsFixed(1),
                            color: AppColors.warningOrange,
                          ),
                          if (quotesCount != null && quotesCount! > 0) ...[
                            const SizedBox(width: 8),
                            _MetricChip(
                              icon: Icons.format_quote_rounded,
                              value: _formatCount(quotesCount!),
                              color: Colors.purpleAccent,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Tap hint
                      Row(
                        children: [
                          Text(
                            'View details & comments',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: AppColors.primary.withOpacity(0.8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(Icons.menu_book_rounded,
            color: AppColors.primary, size: 32),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isPublished;
  const _StatusBadge({required this.isPublished});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPublished
            ? AppColors.successGreen.withOpacity(0.12)
            : AppColors.warningOrange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPublished ? 'Published' : 'Draft',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isPublished ? AppColors.successGreen : AppColors.warningOrange,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _MetricChip(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
