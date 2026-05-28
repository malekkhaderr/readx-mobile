import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/animations.dart';
import '../../../home/data/datasources/books_service.dart';
import '../../data/datasources/quotes_remote_datasource.dart';
import '../../data/models/quote_model.dart';
import '../bloc/quotes_bloc.dart';
import '../bloc/quotes_event.dart';
import '../bloc/quotes_state.dart';
import 'add_quote_page.dart';

/// Lightweight value classes used by the filter sheet's dropdowns.
class _FilterBook {
  final int id;
  final String title;
  _FilterBook({required this.id, required this.title});
}

class _FilterCategory {
  final int id;
  final String name;
  final String? iconUrl;
  _FilterCategory({required this.id, required this.name, this.iconUrl});
}

/// Module-level cache so the filter sheet (and any future re-open of it)
/// avoids re-fetching the books / categories lists on every open.
class _FilterDataCache {
  static List<_FilterBook>? _books;
  static List<_FilterCategory>? _categories;
  static Future<void>? _booksFuture;
  static Future<void>? _categoriesFuture;

  static List<_FilterBook>? get books => _books;
  static List<_FilterCategory>? get categories => _categories;

  static Future<void> fetchBooks() {
    if (_books != null) return Future.value();
    _booksFuture ??= _fetchBooks();
    return _booksFuture!;
  }

  static Future<void> fetchCategories() {
    if (_categories != null) return Future.value();
    _categoriesFuture ??= _fetchCategories();
    return _categoriesFuture!;
  }

  static Future<void> _fetchBooks() async {
    try {
      final response = await sl<DioClient>().dio.get(
        '/books',
        queryParameters: {'pageNumber': 1, 'pageSize': 100},
      );
      final data = response.data;
      final items = data is Map<String, dynamic>
          ? (data['items'] as List<dynamic>? ?? const [])
          : const [];
      _books = items.map((e) {
        final m = e as Map<String, dynamic>;
        return _FilterBook(
          id: m['id'] as int? ?? 0,
          title: (m['title'] as String?) ?? '',
        );
      }).toList();
    } catch (_) {
      _books = const [];
    } finally {
      _booksFuture = null;
    }
  }

  static Future<void> _fetchCategories() async {
    try {
      final response = await sl<DioClient>().dio.get('/categories');
      final data = response.data;
      // /api/categories returns a raw array, not a paged shape.
      final items = data is List ? data : const [];
      _categories = items.map((e) {
        final m = e as Map<String, dynamic>;
        return _FilterCategory(
          id: m['id'] as int? ?? 0,
          name: (m['name'] as String?) ?? '',
          iconUrl: m['iconUrl'] as String?,
        );
      }).toList();
    } catch (_) {
      _categories = const [];
    } finally {
      _categoriesFuture = null;
    }
  }
}

/// Per-bookId cache of cover URL + (optional) better category name pulled from
/// the book detail endpoint. The quotes API doesn't return cover images, so
/// we lazy-fetch them and reuse the same cover across all quotes for a given
/// book. Lives at module scope so it survives tab switches without re-fetching.
class _BookMetaCache {
  static final Map<int, _BookMeta> _cache = {};
  static final Map<int, Future<_BookMeta?>> _inFlight = {};

  static _BookMeta? get(int bookId) => _cache[bookId];

  static Future<_BookMeta?> fetch(int bookId) {
    if (_cache.containsKey(bookId)) {
      return Future.value(_cache[bookId]);
    }
    if (_inFlight.containsKey(bookId)) {
      return _inFlight[bookId]!;
    }
    final future = sl<BooksService>().getBookDetail(bookId).then((b) {
      final meta = _BookMeta(
        coverUrl: b.coverImageUrl,
        categoryName: b.categoryName,
      );
      _cache[bookId] = meta;
      _inFlight.remove(bookId);
      return meta;
    }).catchError((_) {
      _inFlight.remove(bookId);
      return null as _BookMeta?;
    });
    _inFlight[bookId] = future;
    return future;
  }
}

class _BookMeta {
  final String coverUrl;
  final String categoryName;
  _BookMeta({required this.coverUrl, required this.categoryName});
}

/// Small widget that resolves a book cover by bookId, showing a gradient
/// placeholder while loading or if the URL is bad/empty.
class _BookCoverThumb extends StatefulWidget {
  final int bookId;
  final String fallbackCategory;
  final List<Color> accent;
  final double width;
  final double height;

  const _BookCoverThumb({
    required this.bookId,
    required this.fallbackCategory,
    required this.accent,
    this.width = 44,
    this.height = 60,
  });

  @override
  State<_BookCoverThumb> createState() => _BookCoverThumbState();
}

class _BookCoverThumbState extends State<_BookCoverThumb> {
  _BookMeta? _meta;

  @override
  void initState() {
    super.initState();
    final cached = _BookMetaCache.get(widget.bookId);
    if (cached != null) {
      _meta = cached;
    } else {
      _BookMetaCache.fetch(widget.bookId).then((m) {
        if (mounted && m != null) setState(() => _meta = m);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _meta?.coverUrl ?? '';
    final hasReal = url.startsWith('http');
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: hasReal
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => _placeholder(),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.accent,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.menu_book_rounded, size: 18, color: Colors.white),
      ),
    );
  }
}

class QuotesPage extends StatefulWidget {
  const QuotesPage({super.key});
  @override
  State<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends State<QuotesPage> {
  late final QuotesBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<QuotesBloc>();
    // Dispatch once. The bloc handlers themselves skip if data is already
    // loaded so coming back to this tab won't refetch unnecessarily.
    _bloc.add(const LoadPublicFeedEvent());
    _bloc.add(const LoadMyQuotesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: const _QuotesView(),
    );
  }
}

class _QuotesView extends StatefulWidget {
  const _QuotesView();
  @override
  State<_QuotesView> createState() => _QuotesViewState();
}

class _QuotesViewState extends State<_QuotesView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          _Header(controller: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: const [
                _PublicFeedTab(),
                _MyQuotesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// HEADER (gradient + tabs)
// ─────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final TabController controller;
  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Icon(Icons.format_quote_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quotes',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        )),
                    SizedBox(height: 2),
                    Text('Highlights worth remembering',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ),
              // New Quote button
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => ctx.push('/add-quote',
                      extra: const AddQuoteArgs()),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: controller,
              indicator: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textGrey,
              labelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: 'Community'),
                Tab(text: 'My Quotes'),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// COMMUNITY (PUBLIC FEED) TAB
// ─────────────────────────────────────────────────────────

class _PublicFeedTab extends StatelessWidget {
  const _PublicFeedTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuotesBloc, QuotesState>(
      builder: (context, state) {
        final feedState = state is QuotesCombined ? state.feedState : state;

        if (feedState is PublicFeedLoading || feedState is QuotesInitial) {
          return const _LoadingList();
        }
        if (feedState is PublicFeedError) {
          return _ErrorView(
            message: feedState.message,
            onRetry: () =>
                context.read<QuotesBloc>().add(const RefreshPublicFeedEvent()),
          );
        }
        if (feedState is PublicFeedLoaded) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              context
                  .read<QuotesBloc>()
                  .add(const RefreshPublicFeedEvent());
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: [
                // Sort + result count
                SliverToBoxAdapter(
                  child: _FeedToolbar(state: feedState),
                ),
                if (feedState.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyFeed(
                      isFiltered: feedState.hasActiveFilter,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    sliver: SliverList.builder(
                      itemCount: feedState.items.length,
                      itemBuilder: (ctx, i) => FadeSlideIn(
                        delay: Duration(milliseconds: 40 * i),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PublicQuoteCard(
                            quote: feedState.items[i],
                            index: i,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _FeedToolbar extends StatelessWidget {
  final PublicFeedLoaded state;
  const _FeedToolbar({required this.state});

  String? _resolveBookTitle(int bookId) {
    // Try the filter-data cache first (loaded if the user has opened
    // the filter sheet at least once). Fall back to the book-meta cache
    // populated by the cards themselves.
    final fb = _FilterDataCache.books;
    if (fb != null) {
      for (final b in fb) {
        if (b.id == bookId) return b.title;
      }
    }
    return null;
  }

  String? _resolveCategoryName(int categoryId) {
    final cs = _FilterDataCache.categories;
    if (cs != null) {
      for (final c in cs) {
        if (c.id == categoryId) return c.name;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${state.items.length} ${state.items.length == 1 ? 'quote' : 'quotes'}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Filter button
              GestureDetector(
                onTap: () => showQuotesFilterSheet(
                  context,
                  bookFilter: state.bookFilter,
                  categoryFilter: state.categoryFilter,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: state.hasActiveFilter
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: state.hasActiveFilter
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 12,
                        color: state.hasActiveFilter
                            ? Colors.white
                            : AppColors.textGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Filter',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: state.hasActiveFilter
                              ? Colors.white
                              : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Sort segmented control
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppColors.divider.withOpacity(0.7)),
                ),
                child: Row(
                  children: [
                    _sortChip(context, QuotesSort.popular, 'Popular',
                        Icons.local_fire_department_rounded),
                    _sortChip(context, QuotesSort.newest, 'Newest',
                        Icons.access_time_rounded),
                  ],
                ),
              ),
            ],
          ),
          // Active-filters chip row
          if (state.hasActiveFilter) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: [
                if (state.bookFilter != null)
                  _activeFilterChip(
                    context: context,
                    icon: Icons.menu_book_rounded,
                    label: _resolveBookTitle(state.bookFilter!) ??
                        'Book #${state.bookFilter}',
                    onRemove: () => context
                        .read<QuotesBloc>()
                        .add(const ChangeBookFilterEvent(null)),
                  ),
                if (state.categoryFilter != null)
                  _activeFilterChip(
                    context: context,
                    icon: Icons.local_offer_rounded,
                    label: _resolveCategoryName(state.categoryFilter!) ??
                        'Category #${state.categoryFilter}',
                    onRemove: () => context
                        .read<QuotesBloc>()
                        .add(const ChangeCategoryFilterEvent(null)),
                  ),
                if (state.bookFilter != null || state.categoryFilter != null)
                  GestureDetector(
                    onTap: () => context.read<QuotesBloc>().add(
                        const ApplyFiltersEvent(
                            bookId: null, categoryId: null)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.clear_all_rounded,
                              size: 11, color: AppColors.error),
                          SizedBox(width: 3),
                          Text(
                            'Clear all',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _activeFilterChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.primary),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 12,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(
      BuildContext context, QuotesSort sort, String label, IconData icon) {
    final selected = state.sort == sort;
    return GestureDetector(
      onTap: () => context.read<QuotesBloc>().add(ChangeSortEvent(sort)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 11,
                color: selected ? Colors.white : AppColors.textGrey),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// FILTER BOTTOM SHEET — book + category dropdowns
// ─────────────────────────────────────────────────────────

void showQuotesFilterSheet(
  BuildContext context, {
  int? bookFilter,
  int? categoryFilter,
}) {
  // Read the bloc from the context here (the sheet's own context can't see
  // it because the sheet is hosted at the root navigator).
  final bloc = context.read<QuotesBloc>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuotesFilterSheet(
      bloc: bloc,
      initialBookId: bookFilter,
      initialCategoryId: categoryFilter,
    ),
  );
}

class _QuotesFilterSheet extends StatefulWidget {
  final QuotesBloc bloc;
  final int? initialBookId;
  final int? initialCategoryId;
  const _QuotesFilterSheet({
    required this.bloc,
    this.initialBookId,
    this.initialCategoryId,
  });

  @override
  State<_QuotesFilterSheet> createState() => _QuotesFilterSheetState();
}

class _QuotesFilterSheetState extends State<_QuotesFilterSheet> {
  bool _loading = true;
  int? _selectedBook;
  int? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedBook = widget.initialBookId;
    _selectedCategory = widget.initialCategoryId;
    _loadIfNeeded();
  }

  Future<void> _loadIfNeeded() async {
    await Future.wait([
      _FilterDataCache.fetchBooks(),
      _FilterDataCache.fetchCategories(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 16, 20, MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Filter quotes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Narrow the feed by book or category. Leave both empty to see everything.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 20),
          if (_loading) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ] else ...[
            _label('Book', Icons.menu_book_rounded),
            const SizedBox(height: 8),
            _bookDropdown(),
            const SizedBox(height: 16),
            _label('Category', Icons.local_offer_rounded),
            const SizedBox(height: 8),
            _categoryDropdown(),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedBook = null;
                        _selectedCategory = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppColors.divider.withOpacity(0.7)),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.bloc.add(ApplyFiltersEvent(
                        bookId: _selectedBook,
                        categoryId: _selectedCategory,
                      ));
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Apply filters',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: AppColors.textDark,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _bookDropdown() {
    final books = _FilterDataCache.books ?? const <_FilterBook>[];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withOpacity(0.7)),
      ),
      child: DropdownButtonFormField<int?>(
        value: _selectedBook,
        isExpanded: true,
        icon: Padding(
          padding: EdgeInsets.only(right: 10),
          child: Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textGrey),
        ),
        decoration: InputDecoration(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: 'Any book',
          hintStyle: TextStyle(fontSize: 14, color: AppColors.textGrey),
        ),
        items: <DropdownMenuItem<int?>>[
          DropdownMenuItem<int?>(
            value: null,
            child: Text('Any book',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey)),
          ),
          ...books.map((b) => DropdownMenuItem<int?>(
                value: b.id,
                child: Text(
                  b.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              )),
        ],
        onChanged: (v) => setState(() => _selectedBook = v),
      ),
    );
  }

  Widget _categoryDropdown() {
    final cats = _FilterDataCache.categories ?? const <_FilterCategory>[];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withOpacity(0.7)),
      ),
      child: DropdownButtonFormField<int?>(
        value: _selectedCategory,
        isExpanded: true,
        icon: Padding(
          padding: EdgeInsets.only(right: 10),
          child: Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textGrey),
        ),
        decoration: InputDecoration(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: 'Any category',
          hintStyle: TextStyle(fontSize: 14, color: AppColors.textGrey),
        ),
        items: <DropdownMenuItem<int?>>[
          DropdownMenuItem<int?>(
            value: null,
            child: Text('Any category',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey)),
          ),
          ...cats.map((c) => DropdownMenuItem<int?>(
                value: c.id,
                child: Row(
                  children: [
                    if (c.iconUrl != null && c.iconUrl!.isNotEmpty) ...[
                      Text(c.iconUrl!,
                          style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
        onChanged: (v) => setState(() => _selectedCategory = v),
      ),
    );
  }
}

class _PublicQuoteCard extends StatelessWidget {
  final QuoteDetails quote;
  final int index;
  const _PublicQuoteCard({required this.quote, required this.index});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
    return '${(diff.inDays / 30).floor()}mo';
  }

  void _copy(BuildContext context) {
    final text = '"${quote.content}"\n\n— ${quote.bookTitle}, p.${quote.pageNumber}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quote copied'), backgroundColor: AppColors.successGreen, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    var text = quote.content;
    if (text.startsWith('"') && text.endsWith('"')) text = text.substring(1, text.length - 1);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withOpacity(0.6), width: 0.8),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── QUOTE BODY ──
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Decorative left-border accent line with quote mark
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 3,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.format_quote_rounded, size: 22, color: AppColors.primary.withOpacity(0.35)),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textDark,
                    height: 1.65,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ])),
            ]),
            const SizedBox(height: 14),
            // Source info: book + page
            Row(children: [
              _BookCoverThumb(bookId: quote.bookId, fallbackCategory: quote.categoryName ?? '', accent: [AppColors.primary, AppColors.primary]),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(quote.bookTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text('Page ${quote.pageNumber}', style: TextStyle(fontSize: 10.5, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
              ])),
              // Copy
              GestureDetector(
                onTap: () => _copy(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.cardBackground, shape: BoxShape.circle, border: Border.all(color: AppColors.divider, width: 0.5)),
                  child: Icon(Icons.copy_rounded, size: 13, color: AppColors.textGrey),
                ),
              ),
            ]),
          ]),
        ),
        // ── FOOTER BAR ──
        Container(
          padding: const EdgeInsets.fromLTRB(22, 10, 18, 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
          ),
          child: Row(children: [
            // Reader info — tappable
            GestureDetector(
              onTap: () => context.push('/reader-profile/${quote.userId}'),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
                  child: Center(child: Text(quote.readerName.isNotEmpty ? quote.readerName[0].toUpperCase() : '?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 9))),
                ),
                const SizedBox(width: 6),
                Flexible(child: Text(quote.readerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600, decoration: TextDecoration.underline, decorationColor: AppColors.primary.withOpacity(0.3)))),
              ]),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: Text('·', style: TextStyle(color: AppColors.textLight, fontSize: 12))),
            Text(_timeAgo(quote.createdAt), style: TextStyle(fontSize: 10.5, color: AppColors.textLight, fontWeight: FontWeight.w500)),
            const Spacer(),
            // Upvote — glowing when active
            _GlowVoteBtn(context: context, quoteId: quote.id, count: quote.upvotes, active: quote.hasUpvoted, vote: QuoteVote.upvote),
            const SizedBox(width: 6),
            // Downvote
            _voteBtn(context: context, count: quote.downvotes, active: quote.hasDownvoted, vote: QuoteVote.downvote),
          ]),
        ),
      ]),
    );
  }

  Widget _voteBtn({required BuildContext context, required int count, required bool active, required QuoteVote vote}) {
    return GestureDetector(
      onTap: () => context.read<QuotesBloc>().add(VoteQuoteEvent(quoteId: quote.id, vote: vote)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.error.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? AppColors.error.withOpacity(0.3) : AppColors.divider, width: 0.8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.arrow_downward_rounded, size: 13, color: active ? AppColors.error : AppColors.textGrey),
          const SizedBox(width: 3),
          Text('$count', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: active ? AppColors.error : AppColors.textGrey)),
        ]),
      ),
    );
  }
}

// ── Glowing Upvote Button ───────────────────────────────────────
class _GlowVoteBtn extends StatelessWidget {
  final BuildContext context;
  final int quoteId;
  final int count;
  final bool active;
  final QuoteVote vote;

  const _GlowVoteBtn({required this.context, required this.quoteId, required this.count, required this.active, required this.vote});

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: () => context.read<QuotesBloc>().add(VoteQuoteEvent(quoteId: quoteId, vote: vote)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? AppColors.primary.withOpacity(0.4) : AppColors.divider, width: active ? 1.2 : 0.8),
          boxShadow: active ? [
            BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 10, spreadRadius: 0),
            BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 20, spreadRadius: 2),
          ] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.arrow_upward_rounded, size: 14, color: active ? AppColors.primary : AppColors.textGrey),
          const SizedBox(width: 4),
          Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: active ? AppColors.primary : AppColors.textGrey)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// MY QUOTES TAB
// ─────────────────────────────────────────────────────────

class _MyQuotesTab extends StatelessWidget {
  const _MyQuotesTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuotesBloc, QuotesState>(
      builder: (context, state) {
        final myState = state is QuotesCombined ? state.myState : state;
        if (myState is MyQuotesLoading || myState is QuotesInitial) {
          return const _LoadingList();
        }
        if (myState is MyQuotesError) {
          return _ErrorView(
            message: myState.message,
            onRetry: () =>
                context.read<QuotesBloc>().add(const RefreshMyQuotesEvent()),
          );
        }
        if (myState is MyQuotesLoaded) {
          if (myState.items.isEmpty) return const _EmptyMyQuotes();
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              context
                  .read<QuotesBloc>()
                  .add(const RefreshMyQuotesEvent());
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              itemCount: myState.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => FadeSlideIn(
                delay: Duration(milliseconds: 30 * i),
                child: _MyQuoteCard(quote: myState.items[i], index: i),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _MyQuoteCard extends StatelessWidget {
  final MyQuote quote;
  final int index;
  const _MyQuoteCard({required this.quote, required this.index});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(
      text:
          '"${quote.content}"\n\n— ${quote.bookTitle}, p.${quote.pageNumber}',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quote copied'),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete quote?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          quote.content.length > 80
              ? '${quote.content.substring(0, 80)}…'
              : quote.content,
          style: TextStyle(
              fontStyle: FontStyle.italic, color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textGrey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<QuotesBloc>()
                  .add(DeleteQuoteEvent(quote.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Quote deleted'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Text('Delete',
                style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = [AppColors.primary, AppColors.gradientEnd];
    var text = quote.content;
    if (text.startsWith('"') && text.endsWith('"')) {
      text = text.substring(1, text.length - 1);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accent[0].withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -14, top: 70,
              child: Icon(Icons.format_quote_rounded,
                  size: 120, color: accent[0].withOpacity(0.05)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER STRIP — cover + book title + category + visibility ──
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent[0].withOpacity(0.10),
                        accent[1].withOpacity(0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BookCoverThumb(
                        bookId: quote.bookId,
                        fallbackCategory: '',
                        accent: accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Book title
                            Text(
                              quote.bookTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Category from book detail cache (lazy)
                            _CachedCategoryChip(
                              bookId: quote.bookId,
                              accent: accent[0],
                            ),
                            const SizedBox(height: 6),
                            // "You" reader pill + visibility + time
                            Row(
                              children: [
                                Container(
                                  width: 18, height: 18,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: accent),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.person_rounded,
                                        size: 11, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'You',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Public/Private badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: quote.isPublic
                                        ? AppColors.successGreen.withOpacity(0.15)
                                        : AppColors.warningOrange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        quote.isPublic
                                            ? Icons.public_rounded
                                            : Icons.lock_rounded,
                                        size: 9,
                                        color: quote.isPublic
                                            ? AppColors.successGreen
                                            : AppColors.warningOrange,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        quote.isPublic ? 'Public' : 'Private',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: quote.isPublic
                                              ? AppColors.successGreen
                                              : AppColors.warningOrange,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Top-right action stack
                      Column(
                        children: [
                          InkWell(
                            onTap: () => _copy(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.divider, width: 0.5),
                              ),
                              child: Icon(Icons.copy_rounded,
                                  size: 13, color: AppColors.textGrey),
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _confirmDelete(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.delete_outline_rounded,
                                  size: 14, color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ── QUOTE BODY ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        size: 18,
                        color: accent[0].withOpacity(0.55),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textDark,
                          height: 1.55,
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Footer meta — page + time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bookmark_outline_rounded,
                                    size: 10, color: AppColors.textGrey),
                                const SizedBox(width: 3),
                                Text(
                                  'p. ${quote.pageNumber}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textGrey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeAgo(quote.createdAt),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Looks up a category name asynchronously by bookId via the book-detail
/// cache. While loading or on miss, renders nothing (the title above is
/// already enough info).
class _CachedCategoryChip extends StatefulWidget {
  final int bookId;
  final Color accent;
  const _CachedCategoryChip({required this.bookId, required this.accent});

  @override
  State<_CachedCategoryChip> createState() => _CachedCategoryChipState();
}

class _CachedCategoryChipState extends State<_CachedCategoryChip> {
  String? _category;

  @override
  void initState() {
    super.initState();
    final cached = _BookMetaCache.get(widget.bookId);
    if (cached != null) {
      _category = cached.categoryName;
    } else {
      _BookMetaCache.fetch(widget.bookId).then((m) {
        if (mounted && m != null && m.categoryName.isNotEmpty) {
          setState(() => _category = m.categoryName);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = _category;
    if (cat == null || cat.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: widget.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer_rounded, size: 9, color: widget.accent),
          const SizedBox(width: 3),
          Text(
            cat,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: widget.accent,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// EMPTY / LOADING / ERROR
// ─────────────────────────────────────────────────────────

class _EmptyFeed extends StatelessWidget {
  final bool isFiltered;
  const _EmptyFeed({required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    return _emptyTemplate(
      icon: isFiltered
          ? Icons.search_off_rounded
          : Icons.format_quote_rounded,
      title: isFiltered ? 'No quotes match your filter' : 'No quotes yet',
      subtitle: isFiltered
          ? 'Try removing the filter or change the sort.'
          : 'Be the first to share a highlight!',
    );
  }
}

class _EmptyMyQuotes extends StatelessWidget {
  const _EmptyMyQuotes();
  @override
  Widget build(BuildContext context) {
    return _emptyTemplate(
      icon: Icons.bookmark_outline_rounded,
      title: 'No quotes saved yet',
      subtitle:
          'Tap the + button above to add a quote, or highlight text in the reader.',
      tip: true,
    );
  }
}

Widget _emptyTemplate({
  required IconData icon,
  required String title,
  required String subtitle,
  bool tip = false,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, size: 44, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textGrey,
                height: 1.5,
                fontWeight: FontWeight.w500),
          ),
          if (tip) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_rounded,
                      size: 14, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Tip: highlight text inside the reader',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 80),
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded,
                  size: 36, color: AppColors.error),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 18),
              label: const Text('Try Again',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(160, 46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
