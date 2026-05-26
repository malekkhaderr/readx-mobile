import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/feather_widgets.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_state.dart';
import '../../../home/data/models/home_response_model.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_state.dart';

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
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<LibraryBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              if (state is HomeInitial || state is HomeLoading) {
                return CustomScrollView(
                  slivers: [
                    _buildHeaderSection(),
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
                    priceUSD: b.priceUSD,
                    priceTokens: b.priceTokens,
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
                  _buildHeaderSection(),
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
                                return _SearchBookCard(
                                  book: book,
                                  onTap: () =>
                                      context.push('/book/${book.id}'),
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
      ),
    );
  }

  SliverToBoxAdapter _buildHeaderSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search Books',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            SizedBox(height: 2),
            Text('Discover your next favorite read',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
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

// _CartIconBadge removed — purchase happens on the book details page now.

class _SearchBookCard extends StatelessWidget {
  final BookCard book;
  final VoidCallback onTap;

  const _SearchBookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        final isOwned = state is LibraryLoaded &&
            state.books.any((b) => b.bookId == book.id);
        return _buildCard(context, isOwned);
      },
    );
  }

  Widget _buildCard(BuildContext context, bool isOwned) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.divider.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover Image with badges ──
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'book-cover-${book.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                      child: book.coverImageUrl.isNotEmpty
                          ? Image.network(
                              book.coverImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) =>
                                  _coverFallback(),
                            )
                          : _coverFallback(),
                    ),
                  ),
                  // Rating Badge (top-LEFT now, since OWNED takes top-right)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.gold, size: 11),
                          const SizedBox(width: 2),
                          Text(
                            book.averageRating > 0
                                ? book.averageRating.toStringAsFixed(1)
                                : '—',
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // OWNED / FREE badge (top-RIGHT)
                  if (isOwned)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.successGreen.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 9, color: Colors.white),
                            SizedBox(width: 3),
                            Text(
                              'OWNED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (book.isFree)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'FREE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ── Info section ──
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Price ALWAYS visible — even when owned, so the user can
                  // recall what they paid. Ownership is shown above as a badge.
                  PriceTag(
                    priceUSD: book.priceUSD,
                    priceFeathers: book.priceTokens,
                    isFree: book.isFree,
                    compact: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            book.title,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
