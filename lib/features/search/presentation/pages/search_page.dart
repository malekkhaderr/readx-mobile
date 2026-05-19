import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_state.dart';
import '../../../home/data/models/home_response_model.dart';
import '../../../shop/data/book_shop_state.dart';
import '../../../shop/data/models/mock_book_shop_data.dart';
import '../../../shop/presentation/widgets/cart_sheet.dart';

enum SearchSortOption {
  popularity('Popularity'),
  rating('Top Rated'),
  priceLowHigh('Price: Low to High'),
  priceHighLow('Price: High to Low');

  final String label;
  const SearchSortOption(this.label);
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  SearchSortOption _selectedSort = SearchSortOption.popularity;

  @override
  void initState() {
    super.initState();
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

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
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
                ...SearchSortOption.values.map(
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
      ),
    );
  }

  void _addToCart(BookCard book) {
    final shopBook = ShopBook(
      id: 'api_${book.id}',
      title: book.title,
      author: book.authorName,
      coverImage: book.coverImageUrl,
      price: book.price,
      discountPrice: book.price > book.effectivePrice ? book.effectivePrice : null,
      rating: book.averageRating,
      reviewCount: book.viewCount,
      genre: book.categoryName,
      description: '',
      pageCount: book.totalPages,
      readingTime: '${(book.totalPages * 1.5).toInt()} mins',
    );

    BookShopState.instance.addToCart(shopBook);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Added "${book.title}" to cart!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopState = BookShopState.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state is HomeInitial || state is HomeLoading) {
              return CustomScrollView(
                slivers: [
                  _buildHeaderSection(shopState.cartCount),
                  _buildSearchSection(),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(child: _buildShimmerGrid()),
                ],
              );
            }

            if (state is HomeError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(state.message, style: const TextStyle(color: AppColors.textGrey)),
                  ],
                ),
              );
            }

            if (state is HomeLoaded) {
              // Deduplicate books from all sections
              final allBooksMap = <int, BookCard>{};
              final bookCategoriesMap = <int, Set<String>>{};

              for (final b in state.data.trendingBooks) {
                allBooksMap[b.id] = b;
                if (b.categoryName.isNotEmpty) {
                  bookCategoriesMap.putIfAbsent(b.id, () => {}).add(b.categoryName.toLowerCase());
                }
              }
              for (final b in state.data.recommendedBooks) {
                allBooksMap[b.id] = b;
                if (b.categoryName.isNotEmpty) {
                  bookCategoriesMap.putIfAbsent(b.id, () => {}).add(b.categoryName.toLowerCase());
                }
              }
              for (final cat in state.data.categories) {
                for (final b in cat.books) {
                  final catName = b.categoryName.isNotEmpty ? b.categoryName : cat.categoryName;
                  final enrichedBook = BookCard(
                    id: b.id,
                    title: b.title,
                    authorName: b.authorName,
                    categoryName: catName,
                    totalPages: b.totalPages,
                    coverImageUrl: b.coverImageUrl,
                    isPublished: b.isPublished,
                    viewCount: b.viewCount,
                    price: b.price,
                    effectivePrice: b.effectivePrice,
                    discountPercentage: b.discountPercentage,
                    discountType: b.discountType,
                    averageRating: b.averageRating,
                  );
                  allBooksMap[b.id] = enrichedBook;
                  bookCategoriesMap.putIfAbsent(b.id, () => {}).add(cat.categoryName.toLowerCase());
                }
              }
              final books = allBooksMap.values.toList();

              // Get all categories for filter chips
              final categoriesList = ['All', ...state.data.categories.map((c) => c.categoryName)];

              // Filter books
              final filteredBooks = books.where((book) {
                final query = _searchQuery.toLowerCase();
                final matchesQuery = book.title.toLowerCase().contains(query) ||
                    book.authorName.toLowerCase().contains(query);

                final matchesCategory = _selectedCategory == 'All' ||
                    book.categoryName.toLowerCase() == _selectedCategory.toLowerCase() ||
                    (bookCategoriesMap[book.id]?.contains(_selectedCategory.toLowerCase()) ?? false);

                return matchesQuery && matchesCategory;
              }).toList();

              // Sort books
              switch (_selectedSort) {
                case SearchSortOption.popularity:
                  filteredBooks.sort((a, b) => b.viewCount.compareTo(a.viewCount));
                  break;
                case SearchSortOption.rating:
                  filteredBooks.sort((a, b) => b.averageRating.compareTo(a.averageRating));
                  break;
                case SearchSortOption.priceLowHigh:
                  filteredBooks.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
                  break;
                case SearchSortOption.priceHighLow:
                  filteredBooks.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
                  break;
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeaderSection(shopState.cartCount),
                  _buildSearchSection(),
                  
                  // Category Chips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: categoriesList.length,
                          itemBuilder: (context, index) {
                            final cat = categoriesList[index];
                            final isSelected = cat == _selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _selectedCategory = cat;
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
                                    cat,
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

                  // Results & Sort Row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: Row(
                        children: [
                          Text(
                            '${filteredBooks.length} results',
                            style: const TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w500),
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
                                  Text(
                                    _selectedSort.label,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Book Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: filteredBooks.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🔍', style: TextStyle(fontSize: 48)),
                                    const SizedBox(height: 12),
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
                              childAspectRatio: 0.55,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final book = filteredBooks[index];
                                final isPurchased = shopState.isPurchased('api_${book.id}');
                                final isInCart = shopState.isInCart('api_${book.id}');

                                return _SearchBookCard(
                                  book: book,
                                  isPurchased: isPurchased,
                                  isInCart: isInCart,
                                  onTap: () => context.push('/book/${book.id}'),
                                  onAddToCart: () => _addToCart(book),
                                );
                              },
                              childCount: filteredBooks.length,
                            ),
                          ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeaderSection(int cartCount) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search Books', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  SizedBox(height: 2),
                  Text('Discover your next favorite read', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
                ],
              ),
            ),
            _CartIconBadge(
              count: cartCount,
              onTap: () => showCartSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.55,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
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

class _SearchBookCard extends StatelessWidget {
  final BookCard book;
  final bool isPurchased;
  final bool isInCart;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const _SearchBookCard({
    required this.book,
    required this.isPurchased,
    required this.isInCart,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = book.price > book.effectivePrice;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      book.coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: AppColors.primaryLight,
                        child: const Center(
                          child: Icon(Icons.book, color: AppColors.primary, size: 28),
                        ),
                      ),
                    ),
                  ),
                  // Rating Badge (Top-Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            book.averageRating > 0
                                ? book.averageRating.toStringAsFixed(1)
                                : '0.0',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Purchased/Owned Badge (Top-Left)
                  if (isPurchased)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'OWNED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Price Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (book.effectivePrice == 0)
                              const Text(
                                'Free',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.successGreen,
                                ),
                              )
                            else ...[
                              if (hasDiscount)
                                Text(
                                  '\$${book.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textGrey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                '\$${book.effectivePrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Add to Cart Button
                      if (!isPurchased)
                        GestureDetector(
                          onTap: isInCart ? null : onAddToCart,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isInCart ? AppColors.textGrey : AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isInCart
                                  ? Icons.shopping_bag_outlined
                                  : Icons.add_shopping_cart_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
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
    );
  }
}
