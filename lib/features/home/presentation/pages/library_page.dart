import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/animations.dart';
import '../../../library/data/models/library_book_model.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../../library/presentation/bloc/library_state.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late final LibraryBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<LibraryBloc>();
    // Dispatch once. The bloc itself early-exits if already loaded.
    _bloc.add(const LoadLibraryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: const _LibraryView(),
    );
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _LibraryHeader(),
          Expanded(
            child: BlocConsumer<LibraryBloc, LibraryState>(
              listener: (context, state) {
                if (state is LibraryError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is LibraryLoading || state is LibraryInitial) {
                  return const _LibrarySkeleton();
                }
                if (state is LibraryLoaded) {
                  return _LibraryContent(state: state);
                }
                if (state is LibraryError) {
                  return _ErrorView(
                    onRetry: () => context
                        .read<LibraryBloc>()
                        .add(const RefreshLibraryEvent()),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────

class _LibraryHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
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
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 16, 22),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Library',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your reading collection',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
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

// ─────────────────────────────────────────────────────────
// CONTENT (loaded state)
// ─────────────────────────────────────────────────────────

class _LibraryContent extends StatelessWidget {
  final LibraryLoaded state;
  const _LibraryContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<LibraryBloc>().add(const RefreshLibraryEvent());
      },
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // Stats strip
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: _StatsRow(state: state),
            ),
          ),
          // Filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _FilterChips(activeFilter: state.activeFilter),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // Book list or empty state
          if (state.books.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyLibrary(isFiltered: state.activeFilter != null),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= state.books.length) return null;
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 50 * index),
                      child: _LibraryBookCard(
                        book: state.books[index],
                      ),
                    );
                  },
                  childCount: state.books.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// STATS ROW
// ─────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final LibraryLoaded state;
  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            icon: Icons.bookmark_added_rounded,
            value: '${state.totalCount}',
            label: 'Total',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon: Icons.auto_stories_rounded,
            value: '${state.readingCount}',
            label: 'Reading',
            color: const Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon: Icons.check_circle_rounded,
            value: '${state.readCount}',
            label: 'Finished',
            color: AppColors.successGreen,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// FILTER CHIPS
// ─────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final ReadingStatus? activeFilter;
  const _FilterChips({this.activeFilter});

  @override
  Widget build(BuildContext context) {
    final filters = <_FilterItem>[
      _FilterItem(label: 'All', status: null, icon: Icons.all_inclusive_rounded),
      _FilterItem(label: 'Want to Read', status: ReadingStatus.wantToRead, icon: Icons.bookmark_outline_rounded),
      _FilterItem(label: 'Reading', status: ReadingStatus.currentlyReading, icon: Icons.auto_stories_rounded),
      _FilterItem(label: 'Finished', status: ReadingStatus.read, icon: Icons.check_circle_outline_rounded),
    ];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = f.status == activeFilter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => context
                  .read<LibraryBloc>()
                  .add(ChangeFilterEvent(filterStatus: f.status)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.divider.withOpacity(0.6)),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f.icon,
                      size: 14,
                      color: isSelected ? Colors.white : AppColors.textGrey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      f.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterItem {
  final String label;
  final ReadingStatus? status;
  final IconData icon;
  _FilterItem({required this.label, required this.status, required this.icon});
}

// ─────────────────────────────────────────────────────────
// BOOK CARD
// ─────────────────────────────────────────────────────────

class _LibraryBookCard extends StatelessWidget {
  final LibraryBook book;
  const _LibraryBookCard({required this.book});

  Color _statusColor(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.wantToRead:
        return AppColors.primary;
      case ReadingStatus.currentlyReading:
        return const Color(0xFFFF6B35);
      case ReadingStatus.read:
        return AppColors.successGreen;
    }
  }

  IconData _statusIcon(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.wantToRead:
        return Icons.bookmark_outline_rounded;
      case ReadingStatus.currentlyReading:
        return Icons.auto_stories_rounded;
      case ReadingStatus.read:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(book.status);

    return ScaleOnTap(
      onTap: () => context.push('/book/${book.bookId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.divider.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            // Cover
            Hero(
              tag: 'book-cover-${book.bookId}',
              child: Container(
                width: 60,
                height: 86,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: book.coverImageUrl != null &&
                          book.coverImageUrl!.isNotEmpty &&
                          book.coverImageUrl!.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: book.coverImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: AppColors.primaryLight,
                            highlightColor: Colors.white,
                            child: Container(color: AppColors.primaryLight),
                          ),
                          errorWidget: (_, __, ___) => _coverFallback(),
                        )
                      : _coverFallback(),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon(book.status),
                                size: 11, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              book.status.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${book.totalPages} pages',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.textGrey, size: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: (value) =>
                  _handleAction(context, value),
              itemBuilder: (_) => [
                if (book.status != ReadingStatus.currentlyReading)
                  const PopupMenuItem(
                    value: 'reading',
                    child: Row(
                      children: [
                        Icon(Icons.auto_stories_rounded,
                            size: 16, color: Color(0xFFFF6B35)),
                        SizedBox(width: 8),
                        Text('Mark as Reading',
                            style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                if (book.status != ReadingStatus.read)
                  const PopupMenuItem(
                    value: 'read',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 16, color: AppColors.successGreen),
                        SizedBox(width: 8),
                        Text('Mark as Finished',
                            style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                if (book.status != ReadingStatus.wantToRead)
                  const PopupMenuItem(
                    value: 'want',
                    child: Row(
                      children: [
                        Icon(Icons.bookmark_outline_rounded,
                            size: 16, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Want to Read',
                            style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 16, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(fontSize: 13, color: AppColors.error)),
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

  void _handleAction(BuildContext context, String action) {
    final bloc = context.read<LibraryBloc>();
    switch (action) {
      case 'reading':
        bloc.add(UpdateBookStatusEvent(
            bookId: book.bookId, newStatus: ReadingStatus.currentlyReading));
        break;
      case 'read':
        bloc.add(UpdateBookStatusEvent(
            bookId: book.bookId, newStatus: ReadingStatus.read));
        break;
      case 'want':
        bloc.add(UpdateBookStatusEvent(
            bookId: book.bookId, newStatus: ReadingStatus.wantToRead));
        break;
      case 'remove':
        _confirmRemove(context);
        break;
    }
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Book',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Remove "${book.title}" from your library?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textGrey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<LibraryBloc>()
                  .add(RemoveFromLibraryEvent(bookId: book.bookId));
            },
            child: const Text('Remove',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
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
      ),
      child: const Center(
        child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────

class _EmptyLibrary extends StatelessWidget {
  final bool isFiltered;
  const _EmptyLibrary({required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isFiltered
                      ? Icons.filter_alt_off_rounded
                      : Icons.menu_book_rounded,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? 'No books in this category' : 'Your library is empty',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try a different filter'
                  : 'Add books from the home page\nto start your collection',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// SKELETON LOADER
// ─────────────────────────────────────────────────────────

class _LibrarySkeleton extends StatelessWidget {
  const _LibrarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmer,
        highlightColor: Colors.white,
        child: Column(
          children: [
            // Stats placeholder
            Row(
              children: List.generate(
                  3,
                  (_) => Expanded(
                        child: Container(
                          height: 80,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      )),
            ),
            const SizedBox(height: 20),
            // Cards placeholder
            ...List.generate(
              4,
              (_) => Container(
                height: 100,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ERROR VIEW
// ─────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: AppColors.error, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load library',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 18),
              label: const Text('Try Again',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
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
