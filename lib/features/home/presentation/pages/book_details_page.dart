import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../shop/data/book_shop_state.dart';
import '../../../shop/data/models/mock_book_shop_data.dart';
import '../../../../core/data/book_repository.dart';
import '../../data/datasources/books_service.dart';
import '../../data/models/book_detail_model.dart';
import '../../data/models/book_comment_model.dart';
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

class _BookDetailsPageState extends State<BookDetailsPage> {
  BookDetail? _book;
  bool _isLoading = true;
  String? _error;

  // Comments State
  List<CommentItem> _comments = [];
  bool _loadingComments = false;
  String? _commentsError;
  final TextEditingController _commentController = TextEditingController();
  bool _submittingComment = false;

  int? _editingCommentId;
  final TextEditingController _editCommentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBook();
    BookShopState.addListener(_onStateChanged);
    BookRepository.addListener(_onStateChanged);
    // Ensure profile is loaded for comment checking/ownership
    sl<ProfileBloc>().add(const LoadProfileEvent());
  }

  @override
  void dispose() {
    BookShopState.removeListener(_onStateChanged);
    BookRepository.removeListener(_onStateChanged);
    _commentController.dispose();
    _editCommentController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadBook() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      String cleanId = widget.bookId;
      if (cleanId.startsWith('api_')) {
        cleanId = cleanId.replaceFirst('api_', '');
      }
      final bookIdInt = int.tryParse(cleanId);
      if (bookIdInt == null) throw Exception('Invalid Book ID');
      
      final bookDetail = await sl<BooksService>().getBookDetail(bookIdInt);
      
      try {
        final session = await sl<BooksService>().getReadingSession(bookIdInt);
        if (session != null) {
          final currentPage = session['currentPage'] ?? 0;
          await BookRepository.updateProgress(
            widget.bookId,
            1,
            currentPage,
            force: true,
            totalPages: bookDetail.totalPages,
          );
        } else {
          await BookRepository.updateProgress(
            widget.bookId,
            1,
            0,
            force: true,
            totalPages: bookDetail.totalPages,
          );
        }
      } catch (e) {
        debugPrint('DEBUG DETAILS: Failed to sync reading session: $e');
      }

      if (mounted) {
        setState(() {
          _book = bookDetail;
          _isLoading = false;
        });
      }
      _loadComments();
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
      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    if (mounted) {
      setState(() {
        _comments = sorted;
      });
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
          _commentsError = 'Could not load reviews.';
          _loadingComments = false;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _book == null) return;
    setState(() {
      _submittingComment = true;
    });
    try {
      await sl<BooksService>().addComment(_book!.id, text);
      _commentController.clear();
      await _loadComments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit review. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submittingComment = false;
        });
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    if (_book == null) return;
    try {
      await sl<BooksService>().deleteComment(_book!.id, commentId);
      await _loadComments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review deleted.'),
            backgroundColor: AppColors.textGrey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete review.'),
            backgroundColor: AppColors.error,
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
          const SnackBar(
            content: Text('Review updated!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update review.'),
            backgroundColor: AppColors.error,
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
      if (voteType == 0) {
        upvoteDiff = -1;
      } else if (voteType == 1) {
        downvoteDiff = -1;
      }
    } else {
      if (oldComment.currentUserVote == 0) {
        upvoteDiff = -1;
      } else if (oldComment.currentUserVote == 1) {
        downvoteDiff = -1;
      }
      
      if (voteType == 0) {
        upvoteDiff += 1;
      } else if (voteType == 1) {
        downvoteDiff += 1;
      }
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
          const SnackBar(
            content: Text('Failed to register vote.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _addToCart() {
    if (_book == null) return;
    final book = _book!;

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
      description: book.description ?? '',
      pageCount: book.totalPages,
      readingTime: '${(book.totalPages * 1.5).toInt()} mins',
      epubUrl: book.epubFileUrl,
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _book == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(
                        _error ?? 'Book not found',
                        style: const TextStyle(fontSize: 16, color: AppColors.textGrey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBook,
                        child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
    final inCart = BookShopState.instance.isInCart('api_${book.id}');
    final isPurchased = BookShopState.instance.isPurchased('api_${book.id}');

    final profileState = context.watch<ProfileBloc>().state;
    String? currentUserId;
    String? currentUserFullName;
    if (profileState is ProfileLoaded) {
      currentUserId = profileState.profile.id;
      currentUserFullName = profileState.profile.fullName;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Book Cover (Centered with Shadow)
                    Container(
                      width: 220,
                      height: 320,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: book.coverImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: AppColors.primaryLight,
                            highlightColor: Colors.white,
                            child: Container(color: AppColors.primaryLight),
                          ),
                          errorWidget: (ctx, err, stack) => Container(
                            color: AppColors.primaryLight,
                            child: const Center(
                              child: Icon(Icons.book, color: AppColors.primary, size: 60),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // Title & Author & Category
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            book.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'By ${book.authorName}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Category Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0EFFF), // Very light lavender
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              book.categoryName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildReadingProgress(book),

                    const SizedBox(height: 32),

                    // Description / Quote Card
                    if (book.description != null && book.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F9), // Subtle grey-blue
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '“${book.description}”',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF555B6A),
                              fontStyle: FontStyle.italic,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Stats Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _StatRowItem(label: 'Language', value: book.languageName),
                          const SizedBox(height: 12),
                          _StatRowItem(label: 'Pages', value: '${book.totalPages}'),
                          const SizedBox(height: 12),
                          _StatRowItem(label: 'Published', value: '${book.publishedYear}'),
                          const SizedBox(height: 12),
                          _StatRowItem(label: 'Views', value: '${book.viewCount}'),
                          const SizedBox(height: 12),
                          _StatRowItem(label: 'Readers', value: '${book.readCount}'),
                          const SizedBox(height: 12),
                          _StatRowItem(
                            label: 'Rating',
                            value: book.averageRating >= 0
                                ? '${book.averageRating.toStringAsFixed(1)} ★'
                                : 'Not rated yet',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Price Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Price',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textGrey,
                            ),
                          ),
                          _buildPriceDetails(book),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Add to Cart Action Button
                    if (book.isPublished)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton.icon(
                            onPressed: isPurchased
                                ? () {
                                    if (book.epubFileUrl.isNotEmpty) {
                                      context.push('/epub-reader?id=${book.id}&url=${Uri.encodeComponent(book.epubFileUrl)}&title=${Uri.encodeComponent(book.title)}');
                                    } else {
                                      context.push('/reader/api_${book.id}/1');
                                    }
                                  }
                                : inCart
                                    ? null
                                    : _addToCart,
                            icon: Icon(
                              isPurchased
                                  ? Icons.menu_book_rounded
                                  : inCart
                                      ? Icons.shopping_bag_outlined
                                      : Icons.add_shopping_cart_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            label: Text(
                              isPurchased
                                  ? 'READ BOOK'
                                  : inCart
                                      ? 'IN CART'
                                      : 'ADD TO CART',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: inCart
                                  ? AppColors.textGrey
                                  : AppColors.primary,
                              disabledBackgroundColor: AppColors.textGrey,
                              minimumSize: const Size(double.infinity, 58),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: inCart ? 0 : 4,
                              shadowColor: AppColors.primary.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),

                    _buildReviewsSection(currentUserId, currentUserFullName),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetails(BookDetail book) {
    if (book.effectivePrice == 0) {
      return const Text(
        'Free',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.successGreen,
        ),
      );
    }

    final hasDiscount = book.price > book.effectivePrice;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '\$${book.effectivePrice.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 8),
          Text(
            '\$${book.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textGrey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReadingProgress(BookDetail book) {
    final repoBook = BookRepository.getBookById(book.id.toString());
    if (repoBook == null || repoBook.progress <= 0) {
      return const SizedBox.shrink();
    }

    final percent = repoBook.progress;
    final percentString = '${(percent * 100).toStringAsFixed(0)}%';
    final readPages = repoBook.readPages;
    final totalPages = repoBook.totalPages > 0 ? repoBook.totalPages : book.totalPages;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reading Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark.withOpacity(0.8),
                ),
              ),
              Text(
                '$percentString ($readPages of $totalPages pages)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: AppColors.primaryLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const Text(
            'Book Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const Icon(
            Icons.bookmark_border_rounded,
            size: 24,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(String? currentUserId, String? currentUserFullName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 48, thickness: 1, color: Color(0xFFEEEEEE)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reader Reviews (${_comments.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              if (_loadingComments)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Add comment box
          _buildAddCommentInput(),
          
          const SizedBox(height: 24),
          
          if (_commentsError != null && _comments.isEmpty)
            Center(
              child: Column(
                children: [
                  Text(
                    _commentsError!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  TextButton(
                    onPressed: _loadComments,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          else if (_comments.isEmpty && !_loadingComments)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No reviews yet. Be the first to write one!',
                  style: TextStyle(color: AppColors.textGrey, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            Column(
              children: _comments.map((comment) => _buildCommentItem(comment, currentUserId, currentUserFullName)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAddCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBF0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _commentController,
            maxLines: 3,
            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            decoration: const InputDecoration(
              hintText: 'Share your thoughts about this book...',
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
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: _submittingComment ? null : _submitComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _submittingComment
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Post Review', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(width: 6),
                        Icon(Icons.send_rounded, size: 14, color: Colors.white),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentItem comment, String? currentUserId, String? currentUserFullName) {
    final profileState = context.watch<ProfileBloc>().state;
    final profile = profileState is ProfileLoaded ? profileState.profile : null;
    final isOwner = profile != null &&
        (comment.readerProfileId.toString() == profile.id ||
         (profile.fullName.isNotEmpty && comment.readerName.trim().toLowerCase() == profile.fullName.trim().toLowerCase()) ||
         (profile.firstName.isNotEmpty && comment.readerName.trim().toLowerCase() == profile.firstName.trim().toLowerCase()) ||
         (profile.email.isNotEmpty && comment.readerName.trim().toLowerCase() == profile.email.split('@').first.trim().toLowerCase()));
    final isEditingThis = _editingCommentId == comment.id;
    final formattedDate = DateFormat('MMM d, yyyy').format(comment.createdAt);
    
    final hasUpvoted = comment.currentUserVote == 0;
    final hasDownvoted = comment.currentUserVote == 1;

    return Container(
      key: ValueKey(comment.id),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    comment.readerName.isNotEmpty ? comment.readerName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.readerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwner && !isEditingThis) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textGrey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _editingCommentId = comment.id;
                      _editCommentController.text = comment.body;
                    });
                  },
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
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
                  style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                  decoration: InputDecoration(
                    fillColor: const Color(0xFFF7F7F9),
                    filled: true,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
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
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _updateComment(comment.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('Save', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            )
          else ...[
            Text(
              comment.body,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4A4A58),
                height: 1.5,
              ),
            ),
            if (comment.updatedAt != null) ...[
              const SizedBox(height: 4),
              const Text(
                '(Edited)',
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
              GestureDetector(
                onTap: () => _voteComment(comment.id, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasUpvoted ? AppColors.primaryLight : const Color(0xFFF7F7F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                        size: 14,
                        color: hasUpvoted ? AppColors.primary : AppColors.textGrey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${comment.upvoteCount}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: hasUpvoted ? AppColors.primary : AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _voteComment(comment.id, 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasDownvoted ? const Color(0xFFFFECEC) : const Color(0xFFF7F7F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasDownvoted ? Icons.thumb_down : Icons.thumb_down_outlined,
                        size: 14,
                        color: hasDownvoted ? AppColors.error : AppColors.textGrey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${comment.downvoteCount}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: hasDownvoted ? AppColors.error : AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(int commentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textGrey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteComment(commentId);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _StatRowItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatRowItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
