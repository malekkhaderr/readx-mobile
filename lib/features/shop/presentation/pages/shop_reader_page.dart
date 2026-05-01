import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../data/models/mock_book_shop_data.dart';

/// Placeholder reader for purchased shop books.
/// Styled consistently with the existing ReadingPage (ivory bg, Georgia font).
class ShopReaderPage extends StatelessWidget {
  final String bookId;
  const ShopReaderPage({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    final book = MockBookShopData.allBooks.cast<ShopBook?>().firstWhere(
          (b) => b!.id == bookId,
          orElse: () => null,
        );

    if (book == null) {
      return Scaffold(
        backgroundColor: AppColors.ivory,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📭', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text('Book not found', style: TextStyle(fontSize: 16, color: AppColors.textGrey)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.ivory,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textDark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                        Text(
                          'by ${book.author}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Streak badge (matches existing reader)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('📖', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text('PREVIEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.8)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        fontFamily: 'Georgia',
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'by ${book.author}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textGrey, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 24),

                    // Sample text with drop cap
                    if (book.sampleText.isNotEmpty) ...[
                      _DropCapParagraph(text: book.sampleText),
                    ] else ...[
                      const Text(
                        'This is a preview of the book. The full content will be available after purchase.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textDark,
                          height: 1.75,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // End marker
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '— End of Preview —',
                              style: TextStyle(fontSize: 13, color: AppColors.primary, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '${book.pageCount} pages · ${book.readingTime}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Drop Cap Paragraph (matches existing ReadingPage style) ──
class _DropCapParagraph extends StatelessWidget {
  final String text;
  const _DropCapParagraph({required this.text});

  @override
  Widget build(BuildContext context) {
    final firstChar = text.isNotEmpty ? text[0].toUpperCase() : '';
    final rest = text.isNotEmpty ? text.substring(1) : '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8, top: 2),
          child: Text(
            firstChar,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 0.85,
              fontFamily: 'Georgia',
            ),
          ),
        ),
        Expanded(
          child: Text(
            rest,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textDark,
              height: 1.75,
              fontFamily: 'Georgia',
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
