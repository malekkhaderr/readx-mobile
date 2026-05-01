import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../../data/models/mock_book_shop_data.dart';
import '../../data/book_shop_state.dart';

/// Full book detail view — opened when tapping a book card in the Shop.
void showBookDetailSheet(BuildContext context, ShopBook book) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _BookDetailSheet(book: book),
  );
}

class _BookDetailSheet extends StatefulWidget {
  final ShopBook book;
  const _BookDetailSheet({required this.book});

  @override
  State<_BookDetailSheet> createState() => _BookDetailSheetState();
}

class _BookDetailSheetState extends State<_BookDetailSheet> {
  late final BookShopState _state;

  @override
  void initState() {
    super.initState();
    _state = BookShopState.instance;
    BookShopState.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    BookShopState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _addToCart() {
    _state.addToCart(widget.book);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${widget.book.title} added to cart!'),
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _buyNow() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Purchase', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Buy "${widget.book.title}" for \$${widget.book.effectivePrice.toStringAsFixed(2)}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '\$${widget.book.effectivePrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _state.purchaseBook(widget.book);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    const Text('🎉 '),
                    Expanded(child: Text('Purchased "${widget.book.title}"!')),
                  ]),
                  backgroundColor: AppColors.successGreen,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Buy Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _readNow() {
    Navigator.pop(context); // close sheet
    context.push('/shop-reader/${widget.book.id}');
  }

  void _readSample() {
    Navigator.pop(context);
    context.push('/shop-reader/${widget.book.id}');
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final purchased = _state.isPurchased(book.id);
    final inCart = _state.isInCart(book.id);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Cover ─────────────────────────────────
                    Center(
                      child: Container(
                        width: 160,
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            book.coverImage,
                            fit: BoxFit.cover,
                            cacheWidth: 320,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: AppColors.primaryLight,
                              child: const Center(child: Icon(Icons.book, color: AppColors.primary, size: 48)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Title & Author ────────────────────────
                    Center(
                      child: Text(
                        book.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark, height: 1.2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'by ${book.author}',
                        style: const TextStyle(fontSize: 14, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Rating + Reviews ──────────────────────
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(5, (i) {
                            final filled = i < book.rating.floor();
                            final half = i == book.rating.floor() && (book.rating - book.rating.floor()) >= 0.3;
                            return Icon(
                              half ? Icons.star_half_rounded : filled ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                          const SizedBox(width: 6),
                          Text('${book.rating}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                          const SizedBox(width: 6),
                          Text('(${_formatCount(book.reviewCount)} reviews)', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Price ─────────────────────────────────
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (book.isOnSale) ...[
                            Text(
                              '\$${book.price.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14, color: AppColors.textGrey, decoration: TextDecoration.lineThrough),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            purchased ? 'Purchased' : '\$${book.effectivePrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: purchased ? AppColors.successGreen : AppColors.primary,
                            ),
                          ),
                          if (book.isOnSale && !purchased) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                '${((1 - book.discountPrice! / book.price) * 100).round()}% OFF',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accent),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Genre chip ────────────────────────────
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                        child: Text(book.genre, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Stats Row ─────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatCol(icon: Icons.auto_stories_rounded, value: '${book.pageCount}', label: 'Pages'),
                          Container(width: 1, height: 36, color: AppColors.divider),
                          _StatCol(icon: Icons.access_time_rounded, value: book.readingTime, label: 'Read Time'),
                          Container(width: 1, height: 36, color: AppColors.divider),
                          _StatCol(icon: Icons.star_rounded, value: '${book.rating}', label: 'Rating'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Description ───────────────────────────
                    const Text('About this Book', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Text(book.description, style: const TextStyle(fontSize: 14, color: AppColors.textDark, height: 1.6)),
                    ),
                    const SizedBox(height: 24),

                    // ── Action Buttons ────────────────────────
                    if (purchased) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _readNow,
                          icon: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                          label: const Text('Read Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Add to Cart
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: inCart ? null : _addToCart,
                          icon: Icon(inCart ? Icons.check_circle : Icons.add_shopping_cart, color: Colors.white, size: 20),
                          label: Text(inCart ? 'In Cart' : 'Add to Cart', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: inCart ? AppColors.textGrey : AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Buy Now
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _buyNow,
                          icon: const Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 20),
                          label: Text(
                            'Buy Now — \$${book.effectivePrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Read Sample
                      Center(
                        child: TextButton.icon(
                          onPressed: _readSample,
                          icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.textGrey),
                          label: const Text('Read Sample', style: TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}

// ── Stat Column ───────────────────────────────────────────────
class _StatCol extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCol({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
      ],
    );
  }
}
