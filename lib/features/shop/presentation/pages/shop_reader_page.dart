import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/data/book_repository.dart';
import '../../data/models/mock_book_shop_data.dart';
import '../../../home/data/datasources/books_service.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';

/// Interactive reader for purchased shop books / preview books.
/// Styled consistently with the existing ReadingPage (ivory bg, Georgia font).
class ShopReaderPage extends StatefulWidget {
  final String bookId;
  const ShopReaderPage({super.key, required this.bookId});

  @override
  State<ShopReaderPage> createState() => _ShopReaderPageState();
}

class _ShopReaderPageState extends State<ShopReaderPage> {
  static const MethodChannel _secureChannel = MethodChannel('com.readx.readx/secure');
  
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  /// Anchor for the delta minutes we send on each save.
  DateTime? _lastSaveAt;
  bool _sessionInitialized = false;
  bool _isResuming = false;
  Timer? _progressTimer;
  int _tokensEarnedThisSession = 0;
  bool _saveInFlight = false;
  bool _sessionCompleted = false;

  @override
  void initState() {
    super.initState();
    _enableSecureWindow();
    
    final cleanId = widget.bookId.replaceAll('api_', '').replaceAll('sb', '');
    final bookIdInt = int.tryParse(cleanId) ?? 1;
    _loadBookAndSession(bookIdInt);
    
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _saveProgress();
    _progressTimer?.cancel();
    _disableSecureWindow();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _enableSecureWindow() async {
    try {
      await _secureChannel.invokeMethod('enableSecure');
      debugPrint('Secure window enabled.');
    } catch (e) {
      debugPrint('Failed to enable secure window: $e');
    }
  }

  Future<void> _disableSecureWindow() async {
    try {
      await _secureChannel.invokeMethod('disableSecure');
      debugPrint('Secure window disabled.');
    } catch (e) {
      debugPrint('Failed to disable secure window: $e');
    }
  }

  Future<void> _loadBookAndSession(int bookIdInt) async {
    // 1. Fetch book detail to resolve totalPages
    try {
      final bookDetail = await sl<BooksService>().getBookDetail(bookIdInt);
      _totalPages = bookDetail.totalPages > 0 ? bookDetail.totalPages : 100;
    } catch (e) {
      debugPrint('DEBUG SHOP READER: Failed to fetch book details: $e');
      _totalPages = 100;
    }

    // 2. Fetch or start reading session.
    // Backend tracks the cumulative time server-side; we only need
    // `currentPage` to resume. The local stopwatch starts fresh.
    try {
      final session = await sl<BooksService>().getReadingSession(bookIdInt);
      if (session == null) {
        await sl<BooksService>().startReadingSession(bookIdInt);
        _currentPage = 1;
        _isResuming = false;
      } else {
        _currentPage = session['currentPage'] ?? 1;
        _isResuming = _currentPage > 1;
        if (session['isCompleted'] == true) {
          try {
            await sl<BooksService>().startReadingSession(bookIdInt);
          } catch (_) {
            _sessionCompleted = true;
          }
        }
      }
      _lastSaveAt = DateTime.now();
      _sessionInitialized = true;
    } catch (e) {
      debugPrint('DEBUG SHOP READER: Failed reading session lifecycle: $e');
      _lastSaveAt = DateTime.now();
      _sessionInitialized = true;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _startProgressTimer();
    }

    // 3. Trigger auto-resume jump once layouts are mounted
    if (_isResuming && _currentPage > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final max = _scrollController.position.maxScrollExtent;
        if (max > 0) {
          final targetOffset = ((_currentPage - 1) / _totalPages) * max;
          _scrollController.jumpTo(targetOffset);
          debugPrint('DEBUG SHOP READER: Resumed and jumped to offset $targetOffset (page $_currentPage)');
        }
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;

    final offset = _scrollController.offset;
    final progressFraction = (offset / max).clamp(0.0, 1.0);

    // Calculate current page based on total pages
    final resolvedPage = (progressFraction * _totalPages).round().clamp(1, _totalPages);
    
    if (_currentPage != resolvedPage) {
      setState(() {
        _currentPage = resolvedPage;
      });
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _sessionInitialized) {
        _saveProgress();
      }
    });
  }

  Future<void> _saveProgress() async {
    if (!_sessionInitialized) return;
    if (_saveInFlight) return;

    // Always mirror progress locally regardless of network outcome.
    try {
      await BookRepository.updateProgress(
        widget.bookId,
        1,
        _currentPage,
        totalPages: _totalPages,
      );
    } catch (e) {
      debugPrint('DEBUG SHOP READER: Failed to update local progress: $e');
    }

    if (_sessionCompleted || _lastSaveAt == null) return;

    final now = DateTime.now();
    final deltaMinutes = now.difference(_lastSaveAt!).inMinutes;
    if (deltaMinutes <= 0) return;

    _saveInFlight = true;
    try {
      final cleanId =
          widget.bookId.replaceAll('api_', '').replaceAll('sb', '');
      final bookIdInt = int.tryParse(cleanId) ?? 1;
      final result = await sl<BooksService>().updateReadingProgress(
        bookIdInt,
        _currentPage,
        deltaMinutes,
      );

      _lastSaveAt = now;
      if (result.tokensEarned > 0) {
        _tokensEarnedThisSession += result.tokensEarned;
      }
      if (result.isCompleted) {
        _sessionCompleted = true;
        _progressTimer?.cancel();
      }
      debugPrint(
          'DEBUG SHOP READER: Saved progress delta=${deltaMinutes}m, tokensEarned=${result.tokensEarned}.');
    } catch (e) {
      debugPrint('DEBUG SHOP READER: Failed updating session progress: $e');
    } finally {
      _saveInFlight = false;
    }
  }

  /// Final flush + side-effects when the user is leaving the reader.
  Future<void> _handleExit() async {
    await _saveProgress();
    try {
      sl<ProfileBloc>().add(const RefreshProfileEvent());
    } catch (_) {/* bloc not registered yet — ignore */}

    if (!mounted) return;
    final earned = _tokensEarnedThisSession;
    if (earned <= 0) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          earned == 1
              ? 'Great job! You earned 1 token this session.'
              : 'Great job! You earned $earned tokens this session.',
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = MockBookShopData.allBooks.cast<ShopBook?>().firstWhere(
          (b) => b!.id == widget.bookId,
          orElse: () => null,
        );

    if (book == null) {
      return Scaffold(
        backgroundColor: AppColors.ivory,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📭', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text('Book not found', style: TextStyle(fontSize: 16, color: AppColors.textGrey)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.ivory,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        await _handleExit();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.ivory,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.ivory,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await _handleExit();
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textDark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                          ),
                          Text(
                            'by ${book.author} · Page $_currentPage of $_totalPages',
                            style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
  
              // ── Content ─────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Streak badge (matches existing reader)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('📖', style: TextStyle(fontSize: 12)),
                              SizedBox(width: 4),
                              Text('PREVIEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.8)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
  
                      // Title
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontFamily: 'Georgia',
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'by ${book.author}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textGrey, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 24),
  
                      // Sample text with drop cap
                      if (book.sampleText.isNotEmpty) ...[
                        _DropCapParagraph(text: book.sampleText),
                      ] else ...[
                        const Text(
                          'This is a preview of the book. The full content will be available after purchase.',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textDark,
                            height: 1.75,
                            fontFamily: 'Georgia',
                          ),
                        ),
                      ],
  
                      const SizedBox(height: 32),
  
                      // End marker
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '— End of Preview —',
                                style: TextStyle(fontSize: 13, color: AppColors.primary, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '$_totalPages pages · ${book.readingTime}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Drop Cap Paragraph (matches existing ReadingPage style) ──
class _DropCapParagraph extends StatelessWidget {
  final String text;
  const _DropCapParagraph({required this.text});

  @override
  Widget build(BuildContext context) {
    final firstChar = text.isNotEmpty ? text[0].toUpperCase() : '';
    final rest = text.isNotEmpty ? text.substring(1) : '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8, top: 2),
          child: Text(
            firstChar,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 0.85,
              fontFamily: 'Georgia',
            ),
          ),
        ),
        Expanded(
          child: Text(
            rest,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textDark,
              height: 1.75,
              fontFamily: 'Georgia',
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
