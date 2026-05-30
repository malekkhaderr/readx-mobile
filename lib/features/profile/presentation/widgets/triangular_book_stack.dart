import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../author_dashboard/data/models/author_book_model.dart';

class TriangularBookStack extends StatefulWidget {
  final List<AuthorBook> books;
  final Widget Function(BuildContext context, int index) gridItemBuilder;

  const TriangularBookStack({
    super.key,
    required this.books,
    required this.gridItemBuilder,
  });

  @override
  State<TriangularBookStack> createState() => _TriangularBookStackState();
}

class _TriangularBookStackState extends State<TriangularBookStack> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Widget _buildBookCover(
    String? url, {
    double width = 110,
    double height = 160,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _buildFallbackCover(),
              )
            : _buildFallbackCover(),
      ),
    );
  }

  Widget _buildFallbackCover() {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          color: Colors.white.withOpacity(0.5),
          size: 40,
        ),
      ),
    );
  }

  Widget _buildCollapsedStack() {
    final books = widget.books;
    if (books.isEmpty) return const SizedBox.shrink();

    // Display up to 3 books in the stack
    final book1 = books.isNotEmpty ? books[0] : null;
    final book2 = books.length > 1 ? books[1] : null;
    final book3 = books.length > 2 ? books[2] : null;

    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Right Book (Bottom layer, rotated right)
                  if (book3 != null)
                    Transform.translate(
                      offset: const Offset(60, 20),
                      child: Transform.rotate(
                        angle: 15 * (pi / 180),
                        child: Transform.scale(
                          scale: 0.85,
                          child: _buildBookCover(book3.coverImageUrl),
                        ),
                      ),
                    ),

                  // Left Book (Middle layer, rotated left)
                  if (book2 != null)
                    Transform.translate(
                      offset: const Offset(-60, 20),
                      child: Transform.rotate(
                        angle: -15 * (pi / 180),
                        child: Transform.scale(
                          scale: 0.85,
                          child: _buildBookCover(book2.coverImageUrl),
                        ),
                      ),
                    ),

                  // Center Book (Top layer, straight)
                  if (book1 != null) _buildBookCover(book1.coverImageUrl),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tap to expand library (${books.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Collapse Button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _toggleExpanded,
            icon: Icon(
              Icons.close_fullscreen_rounded,
              size: 18,
              color: AppColors.textGrey,
            ),
            label: Text(
              'Collapse Stack',
              style: TextStyle(color: AppColors.textGrey),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.62,
          ),
          itemCount: widget.books.length,
          itemBuilder: widget.gridItemBuilder,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: _buildCollapsedStack(),
      secondChild: _buildExpandedGrid(),
      crossFadeState: _isExpanded
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 350),
      layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              key: bottomChildKey,
              left: 0,
              top: 0,
              right: 0,
              child: bottomChild,
            ),
            Positioned(key: topChildKey, child: topChild),
          ],
        );
      },
    );
  }
}
