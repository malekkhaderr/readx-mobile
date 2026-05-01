import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../data/models/mock_book_shop_data.dart';
import '../../data/book_shop_state.dart';
import '../widgets/book_detail_sheet.dart';
import '../widgets/cart_sheet.dart';

class BookShopPage extends StatefulWidget {
  const BookShopPage({super.key});

  @override
  State<BookShopPage> createState() => _BookShopPageState();
}

class _BookShopPageState extends State<BookShopPage> {
  BookCategory _selectedCategory = BookCategory.all;
  BookSortOption _selectedSort = BookSortOption.popular;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  late final BookShopState _shopState;

  @override
  void initState() {
    super.initState();
    _shopState = BookShopState.instance;
    BookShopState.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    BookShopState.removeListener(_onStateChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<ShopBook> get _filteredBooks {
    List<ShopBook> books;
    if (_searchQuery.isNotEmpty) {
      books = MockBookShopData.searchBooks(_searchQuery);
    } else {
      books = MockBookShopData.getByCategory(_selectedCategory);
    }
    return MockBookShopData.sortBooks(books, _selectedSort);
  }

  bool get _showShelves =>
      _searchQuery.isEmpty && _selectedCategory == BookCategory.all;

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sort By',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 12),
              ...BookSortOption.values.map(
                (opt) => InkWell(
                  onTap: () {
                    setState(() => _selectedSort = opt);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          opt == _selectedSort
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: opt == _selectedSort ? AppColors.primary : AppColors.textGrey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: opt == _selectedSort ? FontWeight.w600 : FontWeight.w400,
                            color: opt == _selectedSort ? AppColors.primary : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Book Shop', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          SizedBox(height: 2),
                          Text('Find your next favorite read', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                    _CartIconBadge(
                      count: _shopState.cartCount,
                      onTap: () => showCartSheet(context),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search Bar ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search books, authors, genres...',
                      hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textGrey, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18, color: AppColors.textGrey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),

            // ── Category Chips ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: BookCategory.values.length,
                    itemBuilder: (context, index) {
                      final cat = BookCategory.values[index];
                      final isSelected = cat == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedCategory = cat;
                            _searchQuery = '';
                            _searchController.clear();
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected ? null : Border.all(color: AppColors.divider),
                            ),
                            child: Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.textGrey,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // ── Sort Row ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    Text(
                      _searchQuery.isNotEmpty
                          ? '${_filteredBooks.length} results'
                          : _selectedCategory == BookCategory.all
                              ? '${MockBookShopData.allBooks.length} books'
                              : '${_filteredBooks.length} books',
                      style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _showSortSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sort, size: 14, color: AppColors.textGrey),
                            const SizedBox(width: 4),
                            Text(_selectedSort.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Content: Shelves or Filtered Grid ───────────
            if (_showShelves) ...[
              // Featured Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _FeaturedBookBanner(
                    book: MockBookShopData.featuredBook,
                    onTap: () => showBookDetailSheet(context, MockBookShopData.featuredBook),
                  ),
                ),
              ),

              // Horizontal shelves — limit each to 6 items to reduce image loading
              _buildShelf('🔥 Trending Now', MockBookShopData.getTrending().take(6).toList()),
              _buildShelf('⭐ Best Sellers', MockBookShopData.getBestsellers().take(6).toList()),
              _buildShelf('✨ New Releases', MockBookShopData.getNewReleases().take(6).toList()),
              _buildShelf('💡 Recommended For You', MockBookShopData.getRecommended().take(6).toList()),
              _buildShelf('📚 Classics You May Love', MockBookShopData.getClassics().take(6).toList()),

              // All Books header
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text('All Books', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                ),
              ),
            ],

            // ── All Books / Search Results Grid ─────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: _filteredBooks.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              const Text('📚', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No books match "$_searchQuery"'
                                    : 'No books in this category',
                                style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.52,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ShopBookCard(
                          book: _filteredBooks[index],
                          isPurchased: _shopState.isPurchased(_filteredBooks[index].id),
                          onTap: () => showBookDetailSheet(context, _filteredBooks[index]),
                          onAddToCart: () {
                            _shopState.addToCart(_filteredBooks[index]);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Added to cart!'),
                                backgroundColor: AppColors.successGreen,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        childCount: _filteredBooks.length,
                      ),
                    ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildShelf(String title, List<ShopBook> books) {
    if (books.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ),
          SizedBox(
            height: 245,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ShopBookCard(
                    book: book,
                    isPurchased: _shopState.isPurchased(book.id),
                    onTap: () => showBookDetailSheet(context, book),
                    onAddToCart: () {
                      _shopState.addToCart(book);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Added to cart!'),
                          backgroundColor: AppColors.successGreen,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cart Icon Badge ─────────────────────────────────────────
class _CartIconBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _CartIconBadge({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.shopping_cart_outlined, color: AppColors.textDark, size: 22),
            ),
            if (count > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Featured Book Banner ────────────────────────────────────
class _FeaturedBookBanner extends StatelessWidget {
  final ShopBook book;
  final VoidCallback onTap;
  const _FeaturedBookBanner({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    // Cover
                    Container(
                      width: 90,
                      height: 130,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _CachedNetworkImage(
                          url: book.coverImage,
                          fit: BoxFit.cover,
                          fallbackIcon: Icons.book,
                          fallbackColor: Colors.white24,
                          fallbackIconColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                            child: const Text('⭐ Featured', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.author,
                            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text('${book.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                                child: const Text(
                                  'View Details',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Optimized Network Image (with caching/sizing/fade-in) ───
class _CachedNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final IconData fallbackIcon;
  final Color? fallbackColor;
  final Color? fallbackIconColor;
  final double? fallbackIconSize;

  const _CachedNetworkImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.book,
    this.fallbackColor,
    this.fallbackIconColor,
    this.fallbackIconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      cacheWidth: 200, // Downscale decoded image to max 200px wide in memory
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: frame != null
              ? child
              : Container(
                  color: fallbackColor ?? AppColors.primaryLight,
                  child: Center(
                    child: Icon(
                      fallbackIcon,
                      color: fallbackIconColor ?? AppColors.primary,
                      size: fallbackIconSize ?? 24,
                    ),
                  ),
                ),
        );
      },
      errorBuilder: (ctx, err, stack) => Container(
        color: fallbackColor ?? AppColors.primaryLight,
        child: Center(
          child: Icon(
            fallbackIcon,
            color: fallbackIconColor ?? AppColors.primary,
            size: fallbackIconSize ?? 24,
          ),
        ),
      ),
    );
  }
}

// ── Shop Book Card (for shelves and grid) ───────────────────
class _ShopBookCard extends StatelessWidget {
  final ShopBook book;
  final bool isPurchased;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  const _ShopBookCard({required this.book, required this.isPurchased, required this.onTap, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: _CachedNetworkImage(
                      url: book.coverImage,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.book,
                      fallbackIconSize: 30,
                    ),
                  ),
                  // Badge
                  if (book.badge != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: book.badge == 'Sale'
                              ? AppColors.accent
                              : book.badge == 'Trending'
                                  ? AppColors.warningOrange
                                  : book.badge == 'Bestseller'
                                      ? AppColors.gold
                                      : AppColors.successGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          book.badge!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: book.badge == 'Bestseller' ? AppColors.textDark : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Rating
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 11),
                          const SizedBox(width: 2),
                          Text('${book.rating}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  // Purchased indicator
                  if (isPurchased)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark, height: 1.2)),
                    const SizedBox(height: 2),
                    Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (book.isOnSale)
                                Text(
                                  '\$${book.price.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 9, color: AppColors.textGrey, decoration: TextDecoration.lineThrough),
                                ),
                              Text(
                                isPurchased ? 'Owned' : '\$${book.effectivePrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isPurchased ? AppColors.successGreen : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isPurchased)
                          GestureDetector(
                            onTap: onAddToCart,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 18),
                            ),
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
    );
  }
}
