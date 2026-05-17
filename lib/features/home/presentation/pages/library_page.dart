import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/data/book_repository.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String _selectedGenre = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    BookRepository.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    BookRepository.removeListener(_onDataChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<BookModel> get _filteredBooks {
    List<BookModel> books;
    if (_searchQuery.isNotEmpty) {
      books = BookRepository.searchBooks(_searchQuery).where((b) => b.isInLibrary).toList();
    } else if (_selectedGenre == 'All') {
      books = BookRepository.getLibraryBooks();
    } else {
      books = BookRepository.getBooksByGenre(_selectedGenre).where((b) => b.isInLibrary).toList();
    }
    return books;
  }

  void _showAddBookSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AddBookSheet(
        onAdded: () {
          Navigator.pop(ctx);
          setState(() {});
        },
      ),
    );
  }

  void _showBookActions(BookModel book) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(
                children: [
                  _BookCoverMini(coverUrl: book.coverUrl, bookId: book.id),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        const SizedBox(height: 2),
                        Text(book.author, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                        if (book.progress > 0 && book.progress < 1.0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('${(book.progress * 100).toInt()}% complete', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ActionTile(icon: Icons.play_arrow_rounded, label: 'Continue Reading', color: AppColors.primary, onTap: () {
                Navigator.pop(ctx);
                context.push('/reader/${book.id}/${book.currentChapter}');
              }),
              _ActionTile(icon: Icons.info_outline_rounded, label: 'Book Details', color: AppColors.textDark, onTap: () {
                Navigator.pop(ctx);
                context.push('/book/${book.id}');
              }),
              _ActionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Remove from Library',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmRemoveBook(book);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRemoveBook(BookModel book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Book', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Remove "${book.title}" from your library?\n\nYour reading progress will be preserved.', style: const TextStyle(height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textGrey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              BookRepository.removeFromLibrary(book.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${book.title} removed from library'),
                  backgroundColor: AppColors.textDark,
                  action: SnackBarAction(label: 'UNDO', textColor: AppColors.primaryLight, onPressed: () {
                    BookRepository.addToLibrary(book.id);
                  }),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final genres = BookRepository.getAllGenres();
    final books = _filteredBooks;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ─────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Library', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            const SizedBox(height: 2),
                            Text('${BookRepository.getLibraryBooks().length} books', style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                          ],
                        ),
                        GestureDetector(
                          onTap: _showAddBookSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 4),
                                Text('Add Book', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Search your library...',
                          hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textGrey, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(icon: const Icon(Icons.close, size: 18, color: AppColors.textGrey), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Genre chips
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: genres.length,
                      itemBuilder: (context, index) {
                        final genre = genres[index];
                        final isSelected = genre == _selectedGenre;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => setState(() { _selectedGenre = genre; _searchQuery = ''; _searchController.clear(); }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected ? null : Border.all(color: AppColors.divider),
                              ),
                              child: Text(genre, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textGrey)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),

            // ── Book Grid ────────────────────────────────
            books.isEmpty
                ? SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('📭', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty ? 'No books match "$_searchQuery"' : 'No books in this category',
                              style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _showAddBookSheet,
                              icon: const Icon(Icons.add),
                              label: const Text('Browse Books'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _LibraryBookCard(
                          book: books[index],
                          onTap: () => context.push('/book/${books[index].id}'),
                          onLongPress: () => _showBookActions(books[index]),
                        ),
                        childCount: books.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.62,
                      ),
                    ),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ── Add Book Browse Sheet ───────────────────────────────────
class _AddBookSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddBookSheet({required this.onAdded});

  @override
  State<_AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends State<_AddBookSheet> {
  @override
  Widget build(BuildContext context) {
    final available = BookRepository.getAvailableBooks();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Browse & Add Books', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text('${available.length} books available', style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
              const SizedBox(height: 16),
              Expanded(
                child: available.isEmpty
                    ? const Center(child: Text('All books are in your library! 🎉', style: TextStyle(fontSize: 14, color: AppColors.textGrey)))
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: available.length,
                        itemBuilder: (context, index) {
                          final book = available[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Row(
                              children: [
                                _BookCoverMini(coverUrl: book.coverUrl, bookId: book.id),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(book.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                                      const SizedBox(height: 2),
                                      Text(book.author, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 12),
                                        const SizedBox(width: 3),
                                        Text('${book.rating}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 10),
                                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)), child: Text(book.genre, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.primary))),
                                      ]),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    BookRepository.addToLibrary(book.id);
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('✅ ${book.title} added to library!'), backgroundColor: AppColors.successGreen, duration: const Duration(seconds: 2)),
                                    );
                                    if (BookRepository.getAvailableBooks().isEmpty) {
                                      widget.onAdded();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                                    child: const Text('Add', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Action Tile ─────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Book Cover Mini ─────────────────────────────────────────
class _BookCoverMini extends StatelessWidget {
  final String coverUrl;
  final String bookId;
  const _BookCoverMini({required this.coverUrl, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: coverUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Shimmer.fromColors(
            baseColor: AppColors.primaryLight,
            highlightColor: Colors.white,
            child: Container(color: AppColors.primaryLight),
          ),
          errorWidget: (ctx, err, stack) => Container(
            color: AppColors.primaryLight,
            child: const Center(child: Icon(Icons.book, color: AppColors.primary, size: 20)),
          ),
        ),
      ),
    );
  }
}

// ── Library Book Card ───────────────────────────────────────
class _LibraryBookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _LibraryBookCard({
    required this.book,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
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
                    child: CachedNetworkImage(
                      imageUrl: book.coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: AppColors.primaryLight,
                        highlightColor: Colors.white,
                        child: Container(color: AppColors.primaryLight),
                      ),
                      errorWidget: (ctx, err, stack) => Container(
                        color: AppColors.primaryLight,
                        child: const Center(child: Icon(Icons.book, color: AppColors.primary, size: 30)),
                      ),
                    ),
                  ),
                  // Rating badge
                  Positioned(
                    top: 8, right: 8, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star, color: Colors.amber, size: 11), const SizedBox(width: 2), Text('${book.rating}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600))]),
                  )),
                  if (book.isInLibrary && book.progress > 0)
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: LinearProgressIndicator(
                        value: book.progress,
                        minHeight: 4,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(book.progress >= 1.0 ? AppColors.successGreen : Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                    const Spacer(),
                    Row(
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)), child: Text(book.genre, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.primary))),
                        const Spacer(),
                        if (book.progress >= 1.0) const Icon(Icons.check_circle, color: AppColors.successGreen, size: 16),
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
