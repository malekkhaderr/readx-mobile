import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/feather_widgets.dart';
import '../../../../core/data/book_repository.dart';
import '../../../library/data/datasources/library_remote_datasource.dart';
import '../../../library/data/models/library_book_model.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_state.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../data/datasources/books_service.dart';
import '../../data/models/book_detail_model.dart';
import '../../data/models/book_comment_model.dart';
import '../../data/models/rating_review_model.dart';
import '../widgets/rate_book_sheet.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Full-screen Book Details page — shows all info about a single book.
/// Route: /book/:bookId
class BookDetailsPage extends StatefulWidget {
  final String bookId;
  const BookDetailsPage({super.key, required this.bookId});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

/// Which engagement tab the user is currently viewing.
enum _EngagementTab { ratings, discussions }

class _BookDetailsPageState extends State<BookDetailsPage> {
  BookDetail? _book;
  bool _isLoading = true;
  String? _error;
  bool _isOwned = false;
  bool _isPurchasing = false;

  // Description expansion
  bool _descriptionExpanded = false;

  // Comments State
  List<CommentItem> _comments = [];
  bool _loadingComments = false;
  String? _commentsError;
  final TextEditingController _commentController = TextEditingController();
  bool _submittingComment = false;
  bool _isSpoiler = false;
  final Set<int> _revealedSpoilers = {};

  // Ratings State
  RatingReviewsResponse? _ratingsResponse;
  bool _loadingRatings = false;

  /// Current user's existing rating for this book — pre-fills the rate sheet
  /// and toggles the rate button between "Rate this book" and "Update rating".
  RatingReviewItem? _myRating;
  bool _loadingMyRating = false;

  /// Active engagement tab (Ratings & Reviews vs Discussions). Defaults to
  /// Ratings because that's the more authoritative signal a buyer wants
  /// when first opening a book.
  _EngagementTab _activeTab = _EngagementTab.ratings;

  int? _editingCommentId;
  final TextEditingController _editCommentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBook();
    sl<ProfileBloc>().add(const LoadProfileEvent());
  }

  @override
  void dispose() {
    _commentController.dispose();
    _editCommentController.dispose();
    super.dispose();
  }

  /// Checks the LibraryBloc state for an entry matching [bookId]. Returns
  /// false if the bloc hasn't loaded yet (so the caller can fall back to
  /// the explicit API check).
  bool _isOwnedFromLibraryBloc(int bookId) {
    final s = sl<LibraryBloc>().state;
    if (s is LibraryLoaded) {
      return s.books.any((b) => b.bookId == bookId);
    }
    return false;
  }

  Future<void> _loadBook() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      String cleanId = widget.bookId;
      if (cleanId.startsWith('api_')) cleanId = cleanId.replaceFirst('api_', '');
      if (cleanId.startsWith('sb')) cleanId = cleanId.replaceFirst('sb', '');
      final bookIdInt = int.tryParse(cleanId);
      if (bookIdInt == null) throw Exception('Invalid Book ID');

      final bookDetail = await sl<BooksService>().getBookDetail(bookIdInt);

      try {
        final session = await sl<BooksService>().getReadingSession(bookIdInt);
        if (session != null) {
          final currentPage = session['currentPage'] ?? 0;
          await BookRepository.updateProgress(
            widget.bookId, 1, currentPage,
            force: true, totalPages: bookDetail.totalPages,
          );
        } else {
          await BookRepository.updateProgress(
            widget.bookId, 1, 0,
            force: true, totalPages: bookDetail.totalPages,
          );
        }
      } catch (e) {
        debugPrint('DEBUG DETAILS: Failed to sync reading session: $e');
      }

      // Check if user owns this book.
      // Source of truth = LibraryBloc (already kept fresh by the home/library
      // tabs). This avoids a separate authenticated request and prevents
      // wrongly showing "Buy Now" for an already-owned book if a transient
      // 401 flips us to false.
      _isOwned = _isOwnedFromLibraryBloc(bookIdInt);
      // If the LibraryBloc hasn't loaded yet, fall back to a fresh API call
      // so the user still sees correct ownership on cold-launch.
      if (!_isOwned && sl<LibraryBloc>().state is! LibraryLoaded) {
        try {
          _isOwned = await sl<BooksService>().isBookInLibrary(bookIdInt);
        } catch (_) {
          _isOwned = false;
        }
      }

      if (mounted) {
        setState(() {
          _book = bookDetail;
          _isLoading = false;
        });
      }
      _loadComments();
      _loadRatings();
      _loadMyRating();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load book details. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _sortComments() {
    final sorted = List<CommentItem>.from(_comments);
    sorted.sort((a, b) {
      final scoreA = a.upvoteCount - a.downvoteCount;
      final scoreB = b.upvoteCount - b.downvoteCount;
      if (scoreA != scoreB) return scoreB.compareTo(scoreA);
      return b.createdAt.compareTo(a.createdAt);
    });
    if (mounted) {
      setState(() => _comments = sorted);
    }
  }

  Future<void> _loadRatings() async {
    if (_book == null) return;
    setState(() => _loadingRatings = true);
    try {
      final res = await sl<BooksService>().getRatings(_book!.id);
      if (mounted) {
        setState(() {
          _ratingsResponse = res;
          _loadingRatings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingRatings = false);
      }
    }
  }

  Future<void> _loadMyRating() async {
    if (_book == null) return;
    setState(() => _loadingMyRating = true);
    try {
      final mine = await sl<BooksService>().getMyRating(_book!.id);
      if (mounted) {
        setState(() {
          _myRating = mine;
          _loadingMyRating = false;
        });
      }
    } catch (_) {
      // 401 is handled by the global Dio interceptor; everything else falls
      // through silently — the user just won't see the "Update" affordance.
      if (mounted) setState(() => _loadingMyRating = false);
    }
  }

  Future<void> _openRateSheet() async {
    final book = _book;
    if (book == null) return;

    final result = await showRateBookSheet(
      context: context,
      bookId: book.id,
      bookTitle: book.title,
      booksService: sl<BooksService>(),
      existingRating: _myRating,
    );
    if (result == null || !mounted) return;

    if (result.deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your rating was removed.'),
          backgroundColor: AppColors.textGrey,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _myRating = null);
      // Reload aggregate + paged list from the server so the new average
      // is reflected; the UI doesn't try to recompute it locally because we
      // don't have ratingsCount client-side.
      await _refreshBookAndRatings();
      return;
    }

    final submitted = result.submitted;
    if (submitted != null) {
      final wasFirstRating = _myRating == null;
      setState(() => _myRating = submitted);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFirstRating ? 'Thanks for rating!' : 'Rating updated.',
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _refreshBookAndRatings();
    }
  }

  /// Re-fetches both the book detail (for the new aggregate `averageRating`)
  /// and the paged review list. Done in parallel so the user isn't waiting
  /// twice.
  Future<void> _refreshBookAndRatings() async {
    final book = _book;
    if (book == null) return;
    try {
      final results = await Future.wait([
        sl<BooksService>().getBookDetail(book.id, incrementView: false),
        sl<BooksService>().getRatings(book.id),
      ]);
      if (!mounted) return;
      setState(() {
        _book = results[0] as BookDetail;
        _ratingsResponse = results[1] as RatingReviewsResponse;
      });
    } catch (_) {
      // The submit already succeeded; if the refresh fails, the next page
      // open will pick up fresh data. Stay silent.
    }
  }

  Future<void> _loadComments() async {
    if (_book == null) return;
    setState(() {
      _loadingComments = true;
      _commentsError = null;
    });
    try {
      final commentsResponse = await sl<BooksService>().getComments(_book!.id);
      if (mounted) {
        setState(() {
          _comments = commentsResponse.items;
          _sortComments();
          _loadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _commentsError = 'Could not load discussions.';
          _loadingComments = false;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _book == null) return;
    setState(() => _submittingComment = true);
    try {
      await sl<BooksService>().addComment(_book!.id, text, isSpoiler: _isSpoiler);
      _commentController.clear();
      _isSpoiler = false;
      await _loadComments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comment posted!'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingComment = false);
    }
  }

  Future<void> _deleteComment(int commentId) async {
    if (_book == null) return;
    try {
      await sl<BooksService>().deleteComment(_book!.id, commentId);
      await _loadComments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comment deleted.'),
            backgroundColor: AppColors.textGrey,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete comment.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateComment(int commentId) async {
    final text = _editCommentController.text.trim();
    if (text.isEmpty || _book == null) return;
    try {
      await sl<BooksService>().updateComment(_book!.id, commentId, text);
      setState(() {
        _editingCommentId = null;
        _editCommentController.clear();
      });
      await _loadComments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comment updated!'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update comment.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _voteComment(int commentId, int voteType) async {
    if (_book == null) return;
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final oldComment = _comments[index];
    int? newVote = voteType;
    int upvoteDiff = 0;
    int downvoteDiff = 0;

    if (oldComment.currentUserVote == voteType) {
      newVote = null;
      if (voteType == 0) upvoteDiff = -1;
      else if (voteType == 1) downvoteDiff = -1;
    } else {
      if (oldComment.currentUserVote == 0) upvoteDiff = -1;
      else if (oldComment.currentUserVote == 1) downvoteDiff = -1;
      if (voteType == 0) upvoteDiff += 1;
      else if (voteType == 1) downvoteDiff += 1;
    }

    setState(() {
      _comments[index] = oldComment.copyWith(
        currentUserVote: newVote,
        upvoteCount: (oldComment.upvoteCount + upvoteDiff).clamp(0, 99999),
        downvoteCount: (oldComment.downvoteCount + downvoteDiff).clamp(0, 99999),
      );
      _sortComments();
    });

    try {
      await sl<BooksService>().voteComment(_book!.id, commentId, voteType);
    } catch (e) {
      if (mounted) {
        setState(() {
          _comments[index] = oldComment;
          _sortComments();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register vote.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Opens the EPUB reader for an owned book.
  ///
  /// We re-fetch the book detail with the auth token attached right before
  /// opening because the backend hides `epubFileUrl` from unauthenticated /
  /// non-owner callers. The cached `_book` may have been loaded earlier in
  /// the page lifecycle when ownership state was different — re-fetching
  /// gives the backend a fresh chance to return the URL now that we know
  /// the user owns the book.
  Future<void> _openReader(BookDetail book) async {
    if (_isPurchasing) return;

    setState(() => _isPurchasing = true);

    String? freshUrl = book.epubFileUrl.trim().isEmpty
        ? null
        : book.epubFileUrl.trim();

    // If the cached detail has no URL, re-hit the backend with auth.
    if (freshUrl == null) {
      try {
        final fresh = await sl<BooksService>().getBookDetail(book.id);
        if (fresh.epubFileUrl.trim().isNotEmpty) {
          freshUrl = fresh.epubFileUrl.trim();
        }
      } catch (e) {
        debugPrint('DEBUG READER: Failed to re-fetch book detail: $e');
      }
    }

    if (!mounted) return;
    setState(() => _isPurchasing = false);

    final isRealUrl = freshUrl != null &&
        (freshUrl.startsWith('http://') || freshUrl.startsWith('https://'));

    if (!isRealUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Could not retrieve book content. The publisher hasn\'t '
                  'uploaded a readable file for this book yet.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    context.push(
      '/epub-reader?id=${book.id}&url=${Uri.encodeComponent(freshUrl)}'
      '&title=${Uri.encodeComponent(book.title)}',
    );
  }

  Future<void> _purchaseBook({required bool withTokens}) async {
    if (_book == null || _isPurchasing) return;
    setState(() => _isPurchasing = true);
    try {
      // Calls the matching real endpoint per backend leader spec:
      //   USD       -> POST /api/books/{id}/buyUSD
      //   Feathers  -> POST /api/books/{id}/buyTokens
      // We don't use the response body because our UI overrides the wording.
      if (withTokens) {
        await sl<BooksService>().buyWithTokens(_book!.id);
      } else {
        await sl<BooksService>().buyWithUSD(_book!.id);
      }

      if (!mounted) return;

      // Refresh profile (token balance updates) and library (so the home
      // page can show the OWNED badge for this book everywhere).
      sl<ProfileBloc>().add(const RefreshProfileEvent());
      sl<LibraryBloc>().add(const RefreshLibraryEvent());

      setState(() {
        _isOwned = true;
        _isPurchasing = false;
      });

      // Use our own message so wording stays consistent ("feathers", not "tokens").
      // The backend may return text like "purchased with tokens" — we override
      // it because the user-facing currency is "feathers".
      final successMessage = withTokens
          ? 'Purchased "${_book!.title}" with feathers — added to your library!'
          : 'Purchased "${_book!.title}" — added to your library!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(successMessage)),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on BuyException catch (e) {
      if (!mounted) return;
      setState(() => _isPurchasing = false);

      String label;
      Color color = AppColors.error;
      if (e.isAlreadyOwned) {
        label = 'You already own this book';
        color = AppColors.warningOrange;
        setState(() => _isOwned = true);
      } else if (e.isInsufficientBalance) {
        label = withTokens
            ? 'Not enough feathers to buy this book'
            : 'Insufficient balance';
      } else if (e.isUnauthorized) {
        label = 'Please log in to buy books';
      } else {
        label = e.message;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(label)),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPurchasing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// For FREE books only — bypasses purchase, adds directly to library.
  /// status=0 (WantToRead) by default, status=1 (CurrentlyReading) if startReading=true.
  Future<void> _addFreeBookToLibrary({bool startReading = false}) async {
    if (_book == null || _isPurchasing) return;
    setState(() => _isPurchasing = true);
    try {
      await sl<LibraryRemoteDataSource>().addToLibrary(
        _book!.id,
        status: startReading
            ? ReadingStatus.currentlyReading
            : ReadingStatus.wantToRead,
      );
      // Refresh the library bloc so home/library tabs reflect the new book.
      sl<LibraryBloc>().add(const RefreshLibraryEvent());
      if (mounted) {
        setState(() {
          _isOwned = true;
          _isPurchasing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(startReading
                      ? 'Started reading "${_book!.title}"'
                      : 'Added "${_book!.title}" to library'),
                ),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPurchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add book to library.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPurchaseOptions() {
    if (_book == null) return;
    final book = _book!;

    // Free books bypass purchase entirely — add directly to library
    if (book.isFree) {
      _addFreeBookToLibrary(startReading: false);
      return;
    }

    // Read user's current feather balance from the loaded profile
    final profileState = sl<ProfileBloc>().state;
    int featherBalance = 0;
    if (profileState is ProfileLoaded) {
      featherBalance =
          profileState.profile.readerDashboard?.cubes ?? 0;
    }
    final hasEnoughFeathers = featherBalance >= book.priceTokens.toInt();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            SizedBox(height: 18),
            Text('Choose Payment Method',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            SizedBox(height: 6),
            Text(
              book.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 18),
            // USD option
            _purchaseOptionTile(
              icon: Icons.attach_money_rounded,
              label: 'Buy with USD',
              subtitle: '\$${book.priceUSD.toStringAsFixed(2)}',
              color: AppColors.successGreen,
              onTap: () {
                Navigator.pop(ctx);
                _purchaseBook(withTokens: false);
              },
            ),
            const SizedBox(height: 10),
            // Feathers option (formerly tokens)
            _purchaseOptionTile(
              iconAsset: 'assets/images/purple_feather.png',
              label: 'Buy with Feathers',
              subtitle: hasEnoughFeathers
                  ? '${book.priceTokens.toInt()} feathers (you have $featherBalance)'
                  : '${book.priceTokens.toInt()} feathers — you have only $featherBalance',
              color: AppColors.primary,
              disabled: !hasEnoughFeathers,
              onTap: hasEnoughFeathers
                  ? () {
                      Navigator.pop(ctx);
                      _purchaseBook(withTokens: true);
                    }
                  : null,
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 12),
          ],
        ),
      ),
    );
  }

  Widget _purchaseOptionTile({
    IconData? icon,
    String? iconAsset,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    bool disabled = false,
  }) {
    final effectiveColor = disabled ? AppColors.textGrey : color;
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: effectiveColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: effectiveColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: effectiveColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: iconAsset != null
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(iconAsset, fit: BoxFit.contain),
                    )
                  : Icon(icon, color: effectiveColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: disabled ? AppColors.textGrey : AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: effectiveColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              disabled
                  ? Icons.lock_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: effectiveColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── BUILD ───────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(transparent: false),
              Expanded(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _book == null) {
      return Scaffold(

        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(transparent: false),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(_error ?? 'Book not found',
                          style: TextStyle(fontSize: 16, color: AppColors.textGrey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBook,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Try Again', style: TextStyle(color: Colors.white)),
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

    final book = _book!;

    final profileState = context.watch<ProfileBloc>().state;
    String? currentUserId;
    String? currentUserFullName;
    if (profileState is ProfileLoaded) {
      currentUserId = profileState.profile.id;
      currentUserFullName = profileState.profile.fullName;
    }

    return Scaffold(

      body: Stack(
        children: [
          // ── Layer 1: Blurred backdrop (cover image) ──
          _buildBlurredBackdrop(book),

          // ── Layer 2: Scrollable content ──
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildTopBar(transparent: true),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        // Hero cover (Hero animation handled inside)
                        _buildHeroCover(book),
                        const SizedBox(height: 28),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 100),
                          child: _buildTitleAndAuthor(book),
                        ),
                        const SizedBox(height: 14),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 200),
                          child: _buildRatingRow(book),
                        ),
                        const SizedBox(height: 22),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 300),
                          child: _buildStatPills(book),
                        ),
                        const SizedBox(height: 22),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 400),
                          child: _buildReadingProgress(book),
                        ),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 500),
                          child: _buildAboutSection(book),
                        ),
                        const SizedBox(height: 8),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 550),
                          child: _buildEngagementSection(
                            currentUserId,
                            currentUserFullName,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Layer 3: Sticky bottom action bar (slides up) ──
          if (book.isPublished)
            Align(
              alignment: Alignment.bottomCenter,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 80 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: _buildBottomActionBar(book),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────── BACKDROP ───────────────────

  Widget _buildBlurredBackdrop(BookDetail book) {
    return Positioned.fill(
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.transparent],
          stops: [0.0, 0.85],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: Stack(
          children: [
            Positioned.fill(
              child: book.coverImageUrl.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: book.coverImageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: AppColors.primaryLight),
                    )
                  : Container(color: AppColors.primaryLight),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: AppColors.background.withOpacity(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── HERO COVER ───────────────────

  Widget _buildHeroCover(BookDetail book) {
    return Hero(
      tag: 'book-cover-${book.id}',
      child: Container(
        width: 200,
        height: 296,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.18),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: book.coverImageUrl.startsWith('http')
              ? CachedNetworkImage(
                  imageUrl: book.coverImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: AppColors.primaryLight,
                    highlightColor: Colors.white,
                    child: Container(color: AppColors.primaryLight),
                  ),
                  errorWidget: (_, __, ___) => _coverFallback(book),
                )
              : _coverFallback(book),
        ),
      ),
    );
  }

  Widget _coverFallback(BookDetail book) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            book.title,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────── TITLE / AUTHOR ───────────────────

  Widget _buildTitleAndAuthor(BookDetail book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Text(
            book.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 1.2,
              letterSpacing: -0.6,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('by ',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textGrey, fontWeight: FontWeight.w400)),
              Flexible(
                child: Text(
                  book.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Category chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_offer_rounded, size: 11, color: AppColors.primary),
                SizedBox(width: 5),
                Text(
                  book.categoryName.isNotEmpty ? book.categoryName : 'Uncategorized',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── RATING ROW ───────────────────

  Widget _buildRatingRow(BookDetail book) {
    final rating = book.averageRating;
    final hasRating = rating > 0;
    // Prefer the book-level count (always present, even before the paged
    // /ratings call returns) and fall back to the response when present.
    final ratingsCount =
        book.ratingsCount > 0 ? book.ratingsCount : _ratingsResponse?.totalCount ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedStars(
            rating: hasRating ? rating : 0,
            size: 18,
            filledColor: AppColors.gold,
            emptyColor: AppColors.textLight,
            duration: Duration(milliseconds: 900),
          ),
          SizedBox(width: 8),
          Text(
            hasRating ? rating.toStringAsFixed(1) : 'No ratings',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          if (ratingsCount > 0) ...[
            SizedBox(width: 6),
            Text(
              '($ratingsCount ${ratingsCount == 1 ? 'rating' : 'ratings'})',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRateButton() {
    final mine = _myRating;
    final hasMyRating = mine != null;
    final loading = _loadingMyRating;

    return GestureDetector(
      onTap: loading ? null : _openRateSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: hasMyRating
              ? AppColors.primaryLight
              : AppColors.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasMyRating
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasMyRating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            SizedBox(width: 6),
            if (loading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              Text(
                hasMyRating
                    ? 'Your rating: ${mine.rating.toStringAsFixed(1)} · Tap to update'
                    : 'Rate this book',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── STAT PILLS ───────────────────

  Widget _buildStatPills(BookDetail book) {
    final pills = <_StatPill>[
      _StatPill(icon: Icons.menu_book_rounded, label: 'Pages', value: '${book.totalPages}'),
      _StatPill(
        icon: Icons.translate_rounded,
        label: 'Language',
        value: book.languageName.isNotEmpty ? book.languageName : '—',
      ),
      _StatPill(
        icon: Icons.calendar_today_rounded,
        label: 'Year',
        value: book.publishedYear > 0 ? '${book.publishedYear}' : '—',
      ),
      _StatPill(
        icon: Icons.visibility_rounded,
        label: 'Views',
        value: _formatCount(book.viewCount),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < pills.length; i++) ...[
              Expanded(child: _buildStatPillWidget(pills[i])),
              if (i < pills.length - 1)
                Container(
                  width: 1,
                  height: 36,
                  color: AppColors.divider.withOpacity(0.6),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatPillWidget(_StatPill pill) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(pill.icon, size: 16, color: AppColors.primary),
        SizedBox(height: 6),
        Text(
          pill.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 2),
        Text(
          pill.label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  // ─────────────────── ABOUT ───────────────────

  Widget _buildAboutSection(BookDetail book) {
    if (book.description == null || book.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    final desc = book.description!;
    final isLong = desc.length > 220;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 10),
              Text(
                'About this book',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: Text(
              desc,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF555B6A),
                height: 1.6,
              ),
            ),
            secondChild: Text(
              desc,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF555B6A),
                height: 1.6,
              ),
            ),
            crossFadeState: _descriptionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          if (isLong)
            GestureDetector(
              onTap: () =>
                  setState(() => _descriptionExpanded = !_descriptionExpanded),
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Text(
                      _descriptionExpanded ? 'Show less' : 'Read more',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _descriptionExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────── READING PROGRESS ───────────────────

  Widget _buildReadingProgress(BookDetail book) {
    final repoBook = BookRepository.getBookById(widget.bookId) ??
        BookRepository.getBookById(book.id.toString());
    if (repoBook == null || repoBook.progress <= 0) {
      return const SizedBox.shrink();
    }

    final percent = repoBook.progress;
    final percentString = '${(percent * 100).toStringAsFixed(0)}%';
    final readPages = repoBook.readPages;
    final totalPages =
        repoBook.totalPages > 0 ? repoBook.totalPages : book.totalPages;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.08),
              AppColors.primary.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_stories_rounded,
                        size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Continue Reading',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Text(
                  percentString,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor: AppColors.primaryLight,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Page $readPages of $totalPages',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── TOP BAR ───────────────────

  Widget _buildTopBar({required bool transparent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          if (!transparent)
            Text(
              'Book Details',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          _circleIconButton(
            icon: Icons.share_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sharing coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: AppColors.textDark),
        ),
      ),
    );
  }

  // ─────────────────── BOTTOM ACTION BAR ───────────────────

  Widget _buildBottomActionBar(BookDetail book) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16, 14, 16, MediaQuery.of(context).padding.bottom + 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.95),
            border: Border(
              top: BorderSide(color: AppColors.divider.withOpacity(0.5)),
            ),
          ),
          child: Row(
            children: [
              // Price
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PRICE',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildPriceWidget(book),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Action button
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isPurchasing
                        ? null
                        : _isOwned
                            ? () => _openReader(book)
                            : _showPurchaseOptions,
                    icon: _isPurchasing
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Icon(
                            _isOwned
                                ? Icons.menu_book_rounded
                                : book.isFree
                                    ? Icons.bookmark_add_rounded
                                    : Icons.shopping_bag_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                    label: Text(
                      _isPurchasing
                          ? (book.isFree ? 'ADDING...' : 'PURCHASING...')
                          : _isOwned
                              ? 'READ NOW'
                              : book.isFree
                                  ? 'ADD TO LIBRARY'
                                  : 'BUY NOW',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isOwned
                          ? AppColors.successGreen
                          : AppColors.primary,
                      disabledBackgroundColor: AppColors.textGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: AppColors.primary.withOpacity(0.4),
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

  Widget _buildPriceWidget(BookDetail book) {
    if (_isOwned) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              color: AppColors.successGreen, size: 18),
          SizedBox(width: 6),
          Text(
            'Owned',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.successGreen,
            ),
          ),
        ],
      );
    }

    if (book.isFree) {
      return Text(
        'Free',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.successGreen,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // USD price
        Row(
          children: [
            Icon(Icons.attach_money_rounded,
                size: 14, color: AppColors.textDark),
            Text(
              book.priceUSD.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Feathers price
        Row(
          children: [
            FeatherIcon(size: 13),
            SizedBox(width: 4),
            Text(
              '${book.priceTokens.toInt()} feathers',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────── REVIEWS ───────────────────

  /// The two-tab section near the bottom of the page. Tab A is the official
  /// star-rating + textual review feed; Tab B is the open discussion thread.
  Widget _buildEngagementSection(
    String? currentUserId,
    String? currentUserFullName,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 32, thickness: 1, color: Color(0xFFEEEEEE)),
          _buildEngagementTabBar(),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_activeTab),
              child: _activeTab == _EngagementTab.ratings
                  ? _buildRatingsTab()
                  : _buildDiscussionsTab(
                      currentUserId, currentUserFullName),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementTabBar() {
    final ratingsCount = _ratingsResponse?.totalCount ?? 0;
    final discussionsCount = _comments.length;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: _engagementTabButton(
              tab: _EngagementTab.ratings,
              icon: Icons.star_rounded,
              label: 'Ratings',
              count: ratingsCount,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _engagementTabButton(
              tab: _EngagementTab.discussions,
              icon: Icons.forum_rounded,
              label: 'Discussions',
              count: discussionsCount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _engagementTabButton({
    required _EngagementTab tab,
    required IconData icon,
    required String label,
    required int count,
  }) {
    final selected = _activeTab == tab;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _activeTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.textDark,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Always show the rate pill at the top of the Ratings tab so the
        // user can act regardless of whether other people have rated yet.
        Align(
          alignment: Alignment.centerLeft,
          child: _buildRateButton(),
        ),
        SizedBox(height: 20),
        if (_loadingRatings)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (_ratingsResponse == null ||
            _ratingsResponse!.reviews.isEmpty)
          _buildEmptyRatings()
        else
          ..._ratingsResponse!.reviews.map(_buildRatingCard),
      ],
    );
  }

  Widget _buildEmptyRatings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star_outline_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'No ratings yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Be the first reader to leave a rating.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  /// Body of Tab B — discussions feed (the existing comments code, now
  /// rendered without the wrapper header since the tab bar provides context).
  Widget _buildDiscussionsTab(
    String? currentUserId,
    String? currentUserFullName,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAddCommentInput(),
        SizedBox(height: 20),
        if (_loadingComments)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (_commentsError != null && _comments.isEmpty)
          Center(
            child: Column(
              children: [
                Text(
                  _commentsError!,
                  style: TextStyle(color: AppColors.error),
                ),
                TextButton(
                  onPressed: _loadComments,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          )
        else if (_comments.isEmpty)
          _buildEmptyDiscussions()
        else
          Column(
            children: _comments
                .map((c) =>
                    _buildCommentItem(c, currentUserId, currentUserFullName))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyDiscussions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.forum_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Start the discussion',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Ask a question or share your thoughts on this book.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(RatingReviewItem review) {
    final isMine = _myRating != null && _myRating!.id == review.id;
    final initial = (review.readerName?.isNotEmpty ?? false)
        ? review.readerName![0].toUpperCase()
        : '?';
    final body = review.reviewText?.trim() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        border: Border.all(
          color: isMine
              ? AppColors.primary.withOpacity(0.45)
              : Colors.grey.withOpacity(0.12),
          width: isMine ? 1.4 : 1,
        ),
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
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.readerName ?? 'Anonymous',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StaticStars(rating: review.rating),
                        SizedBox(width: 8),
                        Text(
                          review.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '· ${DateFormat.yMMMd().format(review.createdAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              body,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _commentController,
            maxLines: 3,
            style: TextStyle(fontSize: 14, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Ask a question or share a thought about this book…',
              hintStyle: TextStyle(color: AppColors.textGrey, fontSize: 14),
              fillColor: Colors.transparent,
              filled: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            // Spoiler toggle
            GestureDetector(
              onTap: () => setState(() => _isSpoiler = !_isSpoiler),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isSpoiler ? AppColors.warningOrange.withOpacity(0.12) : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _isSpoiler ? AppColors.warningOrange : AppColors.divider, width: _isSpoiler ? 1.5 : 0.8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_isSpoiler ? Icons.visibility_off_rounded : Icons.visibility_off_outlined, size: 14, color: _isSpoiler ? AppColors.warningOrange : AppColors.textGrey),
                  const SizedBox(width: 5),
                  Text('Spoiler', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _isSpoiler ? AppColors.warningOrange : AppColors.textGrey)),
                ]),
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 38,
              child: ElevatedButton(
                onPressed: _submittingComment ? null : _submitComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _submittingComment
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Post',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3)),
                          SizedBox(width: 6),
                          Icon(Icons.send_rounded, size: 14, color: Colors.white),
                        ],
                      ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentItem comment, String? currentUserId,
      String? currentUserFullName) {
    final profileState = context.watch<ProfileBloc>().state;
    final profile = profileState is ProfileLoaded ? profileState.profile : null;
    final isOwner = profile != null &&
        (comment.readerProfileId.toString() == profile.id ||
            (profile.fullName.isNotEmpty &&
                comment.readerName.trim().toLowerCase() ==
                    profile.fullName.trim().toLowerCase()) ||
            (profile.firstName.isNotEmpty &&
                comment.readerName.trim().toLowerCase() ==
                    profile.firstName.trim().toLowerCase()) ||
            (profile.email.isNotEmpty &&
                comment.readerName.trim().toLowerCase() ==
                    profile.email.split('@').first.trim().toLowerCase()));
    final isEditingThis = _editingCommentId == comment.id;
    final formattedDate = DateFormat('MMM d, yyyy').format(comment.createdAt);

    final hasUpvoted = comment.currentUserVote == 0;
    final hasDownvoted = comment.currentUserVote == 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      key: ValueKey(comment.id),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => context.push('/reader-profile/${comment.userId}'),
                child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    comment.readerName.isNotEmpty
                        ? comment.readerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () => context.push('/reader-profile/${comment.userId}'),
                            child: Text(
                              comment.readerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),










                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'YOU',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              if (isOwner && !isEditingThis) ...[
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.textGrey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _editingCommentId = comment.id;
                      _editCommentController.text = comment.body;
                    });
                  },
                ),
                SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.error),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showDeleteConfirmation(comment.id),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (isEditingThis)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _editCommentController,
                  maxLines: 3,
                  style: TextStyle(fontSize: 14, color: AppColors.textDark),
                  decoration: InputDecoration(
                    fillColor: AppColors.background,
                    filled: true,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _editingCommentId = null;
                          _editCommentController.clear();
                        });
                      },
                      child: Text('Cancel',
                          style: TextStyle(
                              color: AppColors.textGrey, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _updateComment(comment.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Save',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            )
          else ...[
            if (comment.isSpoiler && !isOwner && !_revealedSpoilers.contains(comment.id))
              GestureDetector(
                onTap: () => setState(() => _revealedSpoilers.add(comment.id)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warningOrange.withOpacity(0.2)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.visibility_off_rounded, size: 16, color: AppColors.warningOrange),
                    const SizedBox(width: 8),
                    Text('Spoiler — Tap to reveal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warningOrange)),
                  ]),
                ),
              )
            else ...[
              if (comment.isSpoiler && !isOwner)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.warningOrange),
                    const SizedBox(width: 4),
                    Text('Spoiler', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warningOrange)),
                  ]),
                ),
              Text(
                comment.body,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textDark,
                  height: 1.5,
                ),
              ),
            ],
            if (comment.updatedAt != null) ...[
              SizedBox(height: 4),
              Text(
                '(edited)',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _voteButton(
                icon: hasUpvoted
                    ? Icons.thumb_up_rounded
                    : Icons.thumb_up_outlined,
                count: comment.upvoteCount,
                isActive: hasUpvoted,
                activeColor: AppColors.primary,
                onTap: () => _voteComment(comment.id, 0),
              ),
              const SizedBox(width: 8),
              _voteButton(
                icon: hasDownvoted
                    ? Icons.thumb_down_rounded
                    : Icons.thumb_down_outlined,
                count: comment.downvoteCount,
                isActive: hasDownvoted,
                activeColor: AppColors.error,
                onTap: () => _voteComment(comment.id, 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _voteButton({
    required IconData icon,
    required int count,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withOpacity(0.12)
              : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? activeColor.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color: isActive ? activeColor : AppColors.textGrey),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? activeColor : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(int commentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Review',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            'Are you sure you want to delete this review? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textGrey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteComment(commentId);
            },
            child: Text('Delete',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _StatPill {
  final IconData icon;
  final String label;
  final String value;
  _StatPill({required this.icon, required this.label, required this.value});
}

/// Compact 5-star row for review cards. Renders full / half / empty stars
/// from a 0–5 double in 0.5 increments. Cheap stateless paint, no animation.
class _StaticStars extends StatelessWidget {
  final double rating;

  const _StaticStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        final IconData icon;
        if (rating >= star) {
          icon = Icons.star_rounded;
        } else if (rating >= star - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, size: 14, color: AppColors.gold);
      }),
    );
  }
}
