import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/feather_widgets.dart';
import '../../../home/data/models/home_response_model.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_state.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Factory: every entry to the tab gets a clean SearchBloc so old
      // searches don't bleed into a fresh visit. We immediately fire the
      // categories + initial-books fetches so the screen is never empty.
      create: (_) => sl<SearchBloc>()
        ..add(const LoadSearchCategoriesEvent())
        ..add(const LoadInitialBooksEvent()),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_maybeLoadMore);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// When the user nears the bottom of the grid, ask the bloc to fetch
  /// the next page. The bloc itself guards against double-fetches.
  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) {
      context.read<SearchBloc>().add(const LoadMoreSearchResultsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: SafeArea(
        child: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<SearchBloc>().add(const RetrySearchEvent());
                // Wait for the in-flight load to settle so the spinner
                // doesn't disappear before the data does.
                await context
                    .read<SearchBloc>()
                    .stream
                    .firstWhere((s) => !s.isLoading);
              },
              color: AppColors.primary,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  _buildHeaderSection(),
                  _buildSearchSection(state),
                  if (state.categories.isNotEmpty) _buildCategoryChips(state),
                  _buildResultsHeader(state),
                  ..._buildBody(state),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────── HEADER ───────────────────────
  SliverToBoxAdapter _buildHeaderSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Books',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Discover your next favorite read',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── SEARCH FIELD ───────────────────────
  SliverToBoxAdapter _buildSearchSection(SearchState state) {
    final hasText = _searchController.text.isNotEmpty;
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
            onChanged: (v) =>
                context.read<SearchBloc>().add(QueryChangedEvent(v)),
            decoration: InputDecoration(
              hintText: 'Search books, authors, genres…',
              hintStyle:
                  TextStyle(color: AppColors.textGrey, fontSize: 14),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.textGrey,
                size: 20,
              ),
              suffixIcon: hasText
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textGrey,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        context
                            .read<SearchBloc>()
                            .add(const QueryChangedEvent(''));
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

  // ─────────────────────── CATEGORY CHIPS ───────────────────────
  SliverToBoxAdapter _buildCategoryChips(SearchState state) {
    final cats = state.categories;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            // +1 for the leading "All" chip.
            itemCount: cats.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _CategoryChip(
                  label: 'All',
                  selected: state.selectedCategoryId == null,
                  onTap: () => context.read<SearchBloc>().add(
                        const ChangeSearchCategoryEvent(
                          categoryId: null,
                          categoryLabel: 'All',
                        ),
                      ),
                );
              }
              final cat = cats[index - 1];
              return _CategoryChip(
                label: cat.name,
                selected: state.selectedCategoryId == cat.id,
                onTap: () => context.read<SearchBloc>().add(
                      ChangeSearchCategoryEvent(
                        categoryId: cat.id,
                        categoryLabel: cat.name,
                      ),
                    ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ─────────────────────── RESULT COUNT HEADER ───────────────────────
  SliverToBoxAdapter _buildResultsHeader(SearchState state) {
    final showHeader =
        state.results.isNotEmpty || state.totalCount > 0 || state.isLoading;
    if (!showHeader) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        child: Row(
          children: [
            Text(
              state.isLoading
                  ? 'Searching…'
                  : '${state.totalCount} '
                      '${state.totalCount == 1 ? 'result' : 'results'}',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (state.selectedCategoryId != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.selectedCategoryLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── BODY (loading / empty / grid) ───────────────────────
  List<Widget> _buildBody(SearchState state) {
    // First load — show the shimmer grid, regardless of query/category.
    if (state.isLoading && state.results.isEmpty) {
      return [SliverToBoxAdapter(child: _buildShimmerGrid())];
    }

    if (state.errorMessage != null && state.results.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: AppColors.textGrey,
                ),
                const SizedBox(height: 12),
                Text(
                  state.errorMessage!,
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context
                      .read<SearchBloc>()
                      .add(const RetrySearchEvent()),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (state.results.isEmpty) {
      // Empty results AFTER a successful load. The wording differs based
      // on whether the user filtered down to nothing or the catalogue is
      // genuinely empty.
      if (state.query.trim().isNotEmpty) {
        return [
          _buildHintSliver(
            'No books match "${state.query.trim()}"',
            icon: '🔍',
          ),
        ];
      }
      if (state.selectedCategoryId != null) {
        return [
          _buildHintSliver(
            'No books in this category yet.',
            icon: '📚',
          ),
        ];
      }
      return [
        _buildHintSliver(
          'No books available right now.',
          icon: '📚',
        ),
      ];
    }

    return [
      // Inline note when the user is mid-typing (1 char). We still show
      // the browse results below so the screen isn't blank.
      if (state.tooShortQuery)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Type at least 2 characters to search the catalogue.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.55,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final book = state.results[index];
              return _SearchBookCard(
                book: book,
                onTap: () => context.push('/book/${book.id}'),
              );
            },
            childCount: state.results.length,
          ),
        ),
      ),
      if (state.isLoadingMore)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ),
      if (!state.hasMore && state.results.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'You\'ve reached the end',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildHintSliver(String message, {String icon = '✨'}) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
            ],
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: selected ? null : Border.all(color: AppColors.divider),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBookCard extends StatelessWidget {
  final BookCard book;
  final VoidCallback onTap;

  const _SearchBookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      bloc: sl<LibraryBloc>(),
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
              color: AppColors.primary.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.divider.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'book-cover-${book.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: book.coverImageUrl.startsWith('http')
                          ? Image.network(
                              book.coverImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) =>
                                  _coverFallback(),
                            )
                          : _coverFallback(),
                    ),
                  ),
                  // Rating badge — search response doesn't include
                  // averageRating today, so most cards will show "—".
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
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
                          Icon(
                            Icons.star_rounded,
                            color: AppColors.gold,
                            size: 11,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            book.averageRating > 0
                                ? book.averageRating.toStringAsFixed(1)
                                : '—',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isOwned)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.successGreen.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 9,
                              color: Colors.white,
                            ),
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
                          horizontal: 6,
                          vertical: 3,
                        ),
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
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
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
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
