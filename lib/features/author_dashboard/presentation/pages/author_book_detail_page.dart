import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/models/author_book_model.dart';
import '../../data/models/author_quote_model.dart';
import '../../data/datasources/author_dashboard_remote_datasource.dart';
import '../../../home/data/datasources/books_service.dart';
import '../../../home/data/models/book_comment_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class AuthorBookDetailPage extends StatefulWidget {
  final AuthorBook book;
  final int? quotesCount;

  const AuthorBookDetailPage({super.key, required this.book, this.quotesCount});

  @override
  State<AuthorBookDetailPage> createState() => _AuthorBookDetailPageState();
}

class _AuthorBookDetailPageState extends State<AuthorBookDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Statistics
  bool _statsLoading = true;
  int _totalPurchases = 0;
  int _totalReadingTimeMinutes = 0;
  bool _statsHadError = false;

  // Book Details
  AuthorBook? _detailedBook;
  bool _bookDetailsLoading = true;

  // Comments
  bool _commentsLoading = true;
  String? _commentsError;
  List<CommentItem> _comments = [];
  int _commentsPage = 1;
  bool _hasMoreComments = true;
  bool _loadingMore = false;
  final ScrollController _commentsScrollController = ScrollController();

  // Quotes
  bool _quotesLoading = true;
  String? _quotesError;
  List<AuthorQuoteModel> _quotes = [];
  int _quotesPage = 1;
  bool _hasMoreQuotes = true;
  bool _loadingMoreQuotes = false;
  final ScrollController _quotesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDetailedBook();
    _loadStatistics();
    _loadComments();
    _loadQuotes();
    _commentsScrollController.addListener(_onCommentsScroll);
    _quotesScrollController.addListener(_onQuotesScroll);
  }

  Future<void> _loadDetailedBook() async {
    try {
      final response = await sl<DioClient>().dio.get('${ApiConstants.books}/${widget.book.id}');
      if (mounted && response.data != null) {
        setState(() {
          _detailedBook = AuthorBook.fromJson(response.data);
          _bookDetailsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bookDetailsLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentsScrollController.dispose();
    _quotesScrollController.dispose();
    super.dispose();
  }

  void _onQuotesScroll() {
    if (_quotesScrollController.position.pixels >=
            _quotesScrollController.position.maxScrollExtent - 200 &&
        !_loadingMoreQuotes &&
        _hasMoreQuotes) {
      _loadMoreQuotes();
    }
  }

  void _onCommentsScroll() {
    if (_commentsScrollController.position.pixels >=
            _commentsScrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMoreComments) {
      _loadMoreComments();
    }
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _statsLoading = true;
      _statsHadError = false;
    });
    try {
      final stats = await sl<AuthorDashboardRemoteDataSource>()
          .getStatistics(bookId: widget.book.id);
      if (mounted) {
        // Try per-book stats first, fall back to top-level totals
        final bookStat = stats.books
            .where((b) => b.bookId == widget.book.id)
            .firstOrNull;
        setState(() {
          _totalPurchases =
              bookStat?.purchaseCount ?? stats.totalPurchases;
          _totalReadingTimeMinutes =
              bookStat?.totalReadingTimeMinutes ?? stats.totalReadingTimeMinutes;
          _statsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statsHadError = true;
          _statsLoading = false;
        });
      }
    }
  }


  Future<void> _loadComments({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _commentsPage = 1;
        _hasMoreComments = true;
        _comments = [];
        _commentsLoading = true;
        _commentsError = null;
      });
    }

    try {
      final res = await sl<BooksService>()
          .getComments(widget.book.id, page: _commentsPage);
      if (mounted) {
        setState(() {
          _comments.addAll(res.items);
          _hasMoreComments = _commentsPage < res.totalPages;
          _commentsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _commentsError = 'Failed to load comments.';
          _commentsLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreComments() async {
    if (_loadingMore || !_hasMoreComments) return;
    setState(() {
      _loadingMore = true;
      _commentsPage++;
    });
    try {
      final res = await sl<BooksService>()
          .getComments(widget.book.id, page: _commentsPage);
      if (mounted) {
        setState(() {
          _comments.addAll(res.items);
          _hasMoreComments = _commentsPage < res.totalPages;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _loadQuotes({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _quotesPage = 1;
        _hasMoreQuotes = true;
        _quotes = [];
        _quotesLoading = true;
        _quotesError = null;
      });
    }

    try {
      final res = await sl<AuthorDashboardRemoteDataSource>()
          .getBookQuotes(widget.book.id, page: _quotesPage);
      if (mounted) {
        setState(() {
          final filtered = res.items.where((q) => q.bookId == widget.book.id).toList();
          _quotes.addAll(filtered);
          _hasMoreQuotes = _quotesPage < res.totalPages;
          _quotesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _quotesError = 'Failed to load quotes.';
          _quotesLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreQuotes() async {
    if (_loadingMoreQuotes || !_hasMoreQuotes) return;
    setState(() {
      _loadingMoreQuotes = true;
      _quotesPage++;
    });
    try {
      final res = await sl<AuthorDashboardRemoteDataSource>()
          .getBookQuotes(widget.book.id, page: _quotesPage);
      if (mounted) {
        setState(() {
          final filtered = res.items.where((q) => q.bookId == widget.book.id).toList();
          _quotes.addAll(filtered);
          _hasMoreQuotes = _quotesPage < res.totalPages;
          _loadingMoreQuotes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMoreQuotes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Scaffold(

      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image or gradient
                  if (book.coverImageUrl != null &&
                      book.coverImageUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: book.coverImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _gradientPlaceholder(),
                      errorWidget: (_, __, ___) => _gradientPlaceholder(),
                    )
                  else
                    _gradientPlaceholder(),
                  // Dark overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.75),
                        ],
                      ),
                    ),
                  ),
                  // Book info at bottom
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (book.categoryName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  book.categoryName!,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: book.isPublished
                                    ? AppColors.successGreen.withOpacity(0.85)
                                    : AppColors.warningOrange.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                book.isPublished ? '✓ Published' : 'Draft',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Quick metrics row
                        Row(
                          children: [
                            _HeroMetric(
                                Icons.visibility_rounded,
                                '${book.viewCount} views'),
                            const SizedBox(width: 16),
                            _HeroMetric(
                                Icons.auto_stories_rounded,
                                '${book.readCount} reads'),
                            const SizedBox(width: 16),
                            _HeroMetric(
                                Icons.star_rounded,
                                book.averageRating.toStringAsFixed(1)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textGrey,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Comments'),
                  Tab(text: 'Quotes'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildCommentsTab(),
            _buildQuotesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final book = _detailedBook ?? widget.book;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Metrics
          _SectionHeader(title: 'Performance Metrics', icon: Icons.analytics_rounded),
          const SizedBox(height: 16),
          _buildPerformanceGrid(book),
          const SizedBox(height: 24),

          // Statistics (from /statistics endpoint)
          _SectionHeader(title: 'Book Statistics', icon: Icons.bar_chart_rounded),
          const SizedBox(height: 12),
          _buildStatisticsSection(),

          const SizedBox(height: 24),

          // Description
          if (book.description != null && book.description!.isNotEmpty) ...[
            _SectionHeader(title: 'Description', icon: Icons.description_rounded),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                book.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          _SectionHeader(title: 'Book Details', icon: Icons.info_outline_rounded),
          const SizedBox(height: 16),
          if (_bookDetailsLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildDetailsCard(book),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPerformanceGrid(AuthorBook book) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _PerformanceTile(
          icon: Icons.visibility_rounded,
          label: 'Total Views',
          value: book.viewCount.toString(),
          color: const Color(0xFF2196F3),
        ),
        _PerformanceTile(
          icon: Icons.auto_stories_rounded,
          label: 'Total Reads',
          value: book.readCount.toString(),
          color: AppColors.successGreen,
        ),
        _PerformanceTile(
          icon: Icons.star_rounded,
          label: 'Avg Rating',
          value: book.averageRating.toStringAsFixed(1),
          color: AppColors.warningOrange,
        ),
        _PerformanceTile(
          icon: Icons.attach_money_rounded,
          label: 'Price',
          value: book.price > 0 ? '\$${book.price.toStringAsFixed(2)}' : 'Free',
          color: const Color(0xFF9C27B0),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    if (_statsLoading) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_statsHadError) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.textGrey, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Statistics unavailable for this book.',
                style: TextStyle(color: AppColors.textGrey, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            icon: Icons.shopping_bag_rounded,
            label: 'Purchases',
            value: _totalPurchases.toString(),
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBox(
            icon: Icons.timer_rounded,
            label: 'Reading Time',
            value: '${_totalReadingTimeMinutes}m',
            color: const Color(0xFF9C27B0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBox(
            icon: Icons.format_quote_rounded,
            label: 'Total Quotes',
            value: widget.quotesCount?.toString() ?? '0',
            color: Colors.purpleAccent,
          ),
        ),
      ],
    );
  }


  Widget _buildDetailsCard(AuthorBook book) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _DetailRow('Pages', book.totalPages > 0 ? '${book.totalPages}' : 'N/A'),
          _DetailRow('Category', book.categoryName ?? 'N/A'),
          _DetailRow('Language', book.languageName ?? 'N/A'),
          if (book.isbn != null && book.isbn != 'string' && book.isbn!.isNotEmpty)
            _DetailRow('ISBN', book.isbn!),
          _DetailRow('Status', book.isPublished ? 'Published' : 'Draft'),
          if (book.publishedYear != null)
            _DetailRow('Year', book.publishedYear.toString()),
          if (book.createdAt != null)
            _DetailRow('Added', DateFormat.yMMMd().format(book.createdAt!)),
          _DetailRow('Tokens', book.priceTokens != null ? '${book.priceTokens!.toInt()} 🪙' : 'N/A'),
          _DetailRow('Book ID', '#${book.id}'),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    if (_commentsLoading && _comments.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_commentsError != null && _comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(_commentsError!,
                style: TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadComments(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(140, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble_outline_rounded,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'No comments yet',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark),
            ),
            SizedBox(height: 8),
            Text(
              'Readers haven\'t commented on this book yet.',
              style: TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadComments(refresh: true),
      color: AppColors.primary,
      child: ListView.builder(
        controller: _commentsScrollController,
        padding: const EdgeInsets.all(20),
        itemCount: _comments.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _comments.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child:
                  Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }
          return _CommentCard(comment: _comments[index]);
        },
      ),
    );
  }

  Widget _buildQuotesTab() {
    if (_quotesLoading && _quotes.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_quotesError != null && _quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(_quotesError!,
                style: TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadQuotes(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(140, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    if (_quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.format_quote_rounded,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'No quotes yet',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark),
            ),
            SizedBox(height: 8),
            Text(
              'Readers haven\'t added any quotes for this book yet.',
              style: TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadQuotes(refresh: true),
      color: AppColors.primary,
      child: ListView.builder(
        controller: _quotesScrollController,
        padding: const EdgeInsets.all(20),
        itemCount: _quotes.length + (_loadingMoreQuotes ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _quotes.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child:
                  Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }
          final quote = _quotes[index];
          return _buildQuoteCard(quote);
        },
      ),
    );
  }

  Widget _buildQuoteCard(AuthorQuoteModel quote) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  quote.readerName.isNotEmpty ? quote.readerName[0].toUpperCase() : '?',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quote.readerName,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (quote.createdAt != null)
                Text(
                  DateFormat.yMMMd().format(quote.createdAt!),
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"${quote.content}"',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Page ${quote.pageNumber}',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              Icon(Icons.thumb_up_alt_rounded, size: 14, color: AppColors.primary.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text(quote.upvotes.toString(), style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
              const SizedBox(width: 12),
              Icon(Icons.thumb_down_alt_rounded, size: 14, color: AppColors.textGrey.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text(quote.downvotes.toString(), style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gradientPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.menu_book_rounded, color: Colors.white54, size: 64),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeroMetric(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _PerformanceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _PerformanceTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textGrey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatBox(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final CommentItem comment;
  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final initial = comment.readerName.isNotEmpty
        ? comment.readerName[0].toUpperCase()
        : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  initial,
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.readerName.isNotEmpty
                          ? comment.readerName
                          : 'Anonymous',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textDark),
                    ),
                    Text(
                      DateFormat.yMMMd().add_jm().format(comment.createdAt),
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              // Votes
              Row(
                children: [
                  _VotePill(
                      icon: Icons.thumb_up_alt_rounded,
                      count: comment.upvoteCount,
                      color: AppColors.successGreen),
                  const SizedBox(width: 6),
                  _VotePill(
                      icon: Icons.thumb_down_alt_rounded,
                      count: comment.downvoteCount,
                      color: AppColors.accent),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment.body,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _VotePill extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  const _VotePill(
      {required this.icon, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(count.toString(),
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          tabBar,
          Container(height: 1, color: const Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
