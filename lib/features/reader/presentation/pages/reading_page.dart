import 'dart:async';
import 'package:flutter/material.dart';
import 'package:readx/core/di/injection_container.dart';
import 'package:readx/features/home/data/datasources/books_service.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/data/book_repository.dart';
import '../../../../core/data/quotes_repository.dart';

class ReadingProgressState {
  final double scrollProgress;
  final int currentChapter;
  final int currentPage;

  const ReadingProgressState({
    required this.scrollProgress,
    required this.currentChapter,
    required this.currentPage,
  });
}

class ReadingPage extends StatefulWidget {
  final String bookId;
  final int chapterNumber;
  const ReadingPage({super.key, required this.bookId, required this.chapterNumber});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  late int _currentChapter;
  late BookModel? _book;
  List<ChapterModel> _chapters = [];
  bool _isBookmarked = false;
  double _fontSize = 15.0;
  double _scrollProgress = 0.0;
  final ScrollController _scrollController = ScrollController();

  late final ValueNotifier<ReadingProgressState> _progressNotifier = ValueNotifier<ReadingProgressState>(
    ReadingProgressState(scrollProgress: 0.0, currentChapter: _currentChapter, currentPage: 1),
  );

  // Session State
  int _currentPage = 1;
  int _totalPages = 1;
  int _elapsedMinutesOffset = 0;
  DateTime? _sessionStartTime;
  bool _sessionInitialized = false;
  bool _isResuming = false;
  bool _isLoading = true;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.chapterNumber;
    _book = BookRepository.getBookById(widget.bookId);

    final bookIdInt = int.tryParse(widget.bookId.replaceAll('api_', '')) ?? 1;
    _loadBookDetailsAndSession(bookIdInt);

    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadBookDetailsAndSession(int bookIdInt) async {
    // 1. Fetch book detail to resolve totalPages
    try {
      final bookDetail = await sl<BooksService>().getBookDetail(bookIdInt);
      _totalPages = bookDetail.totalPages > 0 ? bookDetail.totalPages : (_book?.totalPages ?? 100);
    } catch (e) {
      debugPrint('DEBUG READING: Failed to fetch book details: $e');
      _totalPages = _book?.totalPages ?? 100;
    }

    // 2. Fetch or start reading session
    try {
      final session = await sl<BooksService>().getReadingSession(bookIdInt);
      if (session == null) {
        await sl<BooksService>().startReadingSession(bookIdInt);
        _currentPage = 1;
        _elapsedMinutesOffset = 0;
        _isResuming = false;
      } else {
        _currentPage = session['currentPage'] ?? 1;
        _elapsedMinutesOffset = session['readingTimeMinutes'] ?? 0;
        _isResuming = _currentPage > 1;
      }
      _sessionStartTime = DateTime.now();
      _sessionInitialized = true;
    } catch (e) {
      debugPrint('DEBUG READING: Failed reading session lifecycle: $e');
      _sessionStartTime = DateTime.now();
      _sessionInitialized = true;
    }

    // 3. Load all chapters for continuous display
    if (_book != null) {
      if (ChapterRepository.getChaptersForBook(widget.bookId).isEmpty) {
        ChapterRepository.addMockChapters(widget.bookId, _book!.title, _book!.totalChapters);
      }
      _chapters = ChapterRepository.getChaptersForBook(widget.bookId);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _progressNotifier.value = ReadingProgressState(
        scrollProgress: _isResuming && _currentPage > 1 ? ((_currentPage - 1) / _totalPages).clamp(0.0, 1.0) : 0.0,
        currentChapter: _currentChapter,
        currentPage: _currentPage,
      );
    }

    // 4. Trigger auto-resume jump once layouts are mounted
    if (_isResuming && _currentPage > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final max = _scrollController.position.maxScrollExtent;
        if (max > 0) {
          final targetOffset = ((_currentPage - 1) / _totalPages) * max;
          _scrollController.jumpTo(targetOffset.clamp(0.0, max));
        }
      });
    }

    // 5. Start timer to save progress every 30s
    _startProgressTimer();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;

    final offset = _scrollController.offset;
    final progressFraction = (offset / max).clamp(0.0, 1.0);

    // Dynamic pagination and chapter resolution
    final resolvedCh = _chapters.isEmpty
        ? 1
        : ((progressFraction * _chapters.length).floor() + 1).clamp(1, _chapters.length);
    final resolvedPage = (progressFraction * _totalPages).round().clamp(1, _totalPages);

    // Update non-UI state variables so they are available for saving
    _scrollProgress = progressFraction;
    _currentChapter = resolvedCh;
    _currentPage = resolvedPage;

    final currentVal = _progressNotifier.value;
    if (currentVal.scrollProgress != progressFraction ||
        currentVal.currentChapter != resolvedCh ||
        currentVal.currentPage != resolvedPage) {
      _progressNotifier.value = ReadingProgressState(
        scrollProgress: progressFraction,
        currentChapter: resolvedCh,
        currentPage: resolvedPage,
      );
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _saveProgress();
    });
  }

  Future<void> _saveProgress() async {
    if (_book == null || !_sessionInitialized) return;

    // Persist progress locally
    await BookRepository.updateProgress(
      _book!.id,
      _currentChapter,
      _currentPage,
      totalPages: _totalPages,
    );

    // Sync to remote API
    if (_sessionStartTime != null) {
      final elapsedMinutes = DateTime.now().difference(_sessionStartTime!).inMinutes;
      final totalMinutes = _elapsedMinutesOffset + elapsedMinutes;
      try {
        final bookIdInt = int.tryParse(widget.bookId.replaceAll('api_', '')) ?? 1;
        await sl<BooksService>().updateReadingProgress(
          bookIdInt,
          _currentPage,
          totalMinutes,
        );
        debugPrint('DEBUG READING: Saved progress. currentPage=$_currentPage, totalMinutes=$totalMinutes');
      } catch (e) {
        debugPrint('DEBUG READING: Failed updating session progress: $e');
      }
    }
  }

  void _showFontSizeSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Reading Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('Aa', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                    Expanded(
                      child: Slider(
                        value: _fontSize,
                        min: 12,
                        max: 24,
                        divisions: 6,
                        activeColor: AppColors.primary,
                        label: '${_fontSize.toInt()}',
                        onChanged: (v) {
                          setSheetState(() {});
                          setState(() => _fontSize = v);
                        },
                      ),
                    ),
                    const Text('Aa', style: TextStyle(fontSize: 20, color: AppColors.textDark, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Font size: ${_fontSize.toInt()}pt', style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _saveQuoteFromBlock(String quoteText) {
    if (_book == null) return;
    final chTitle = _chapters.isNotEmpty && _currentChapter <= _chapters.length
        ? _chapters[_currentChapter - 1].title
        : 'Chapter $_currentChapter';
    QuotesRepository.addQuote(
      text: quoteText,
      bookId: _book!.id,
      bookTitle: _book!.title,
      coverUrl: _book!.coverUrl,
      author: _book!.author,
      chapterTitle: chTitle,
      chapterNumber: _currentChapter,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [Text('💬 '), Text('Quote saved!')]),
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(label: 'VIEW', textColor: Colors.white, onPressed: () {
          // User can go to quotes tab
        }),
      ),
    );
  }

  void _showSaveQuoteDialog() {
    if (_book == null || _chapters.isEmpty) return;
    
    final currentChData = _chapters[_currentChapter - 1];
    final quoteBlocks = currentChData.blocks.where((b) => b.type == ContentBlockType.quote).toList();
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Save a Quote', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text('From ${_book!.title} — ${currentChData.title}', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            const SizedBox(height: 18),

            if (quoteBlocks.isNotEmpty) ...[
              const Text('Quotes in this chapter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              const SizedBox(height: 8),
              ...quoteBlocks.map((q) => GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _saveQuoteFromBlock(q.text);
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(q.text, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textDark, height: 1.4))),
                      const SizedBox(width: 8),
                      const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 12),
            ],

            const Text('Or write your own', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: textController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Type or paste a quote...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (textController.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  _saveQuoteFromBlock(textController.text.trim());
                },
                icon: const Icon(Icons.format_quote_rounded, size: 18, color: Colors.white),
                label: const Text('Save Quote', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _saveProgress();
    _progressTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_book == null) {
      return Scaffold(
        backgroundColor: AppColors.ivory,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Book not found', style: TextStyle(fontSize: 16, color: AppColors.textGrey)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
          ]),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.ivory,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        await _saveProgress();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.ivory,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Top Bar ────────────────────────────────────
              ValueListenableBuilder<ReadingProgressState>(
                valueListenable: _progressNotifier,
                builder: (context, progressState, _) {
                  final chapterTitle = _chapters.isNotEmpty && progressState.currentChapter <= _chapters.length
                      ? _chapters[progressState.currentChapter - 1].title
                      : 'Loading...';
                  return _ReaderTopBar(
                    chapterTitle: chapterTitle,
                    progress: progressState.scrollProgress.clamp(0.0, 1.0),
                    isBookmarked: _isBookmarked,
                    onBack: () async {
                      await _saveProgress();
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    onBookmark: () {
                      setState(() => _isBookmarked = !_isBookmarked);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isBookmarked ? '🔖 Bookmarked!' : 'Bookmark removed'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                },
              ),

              // ── Content ────────────────────────────────────
              Expanded(
                child: _chapters.isEmpty
                    ? const Center(
                        child: Text(
                          'Content loading...',
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      )
                    : SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('🔥', style: TextStyle(fontSize: 12)),
                                    SizedBox(width: 4),
                                    Text(
                                      '12 DAY STREAK',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                        letterSpacing: 0.8,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _book!.title,
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
                              'by ${_book!.author}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textGrey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Render all chapters continuously
                            ..._chapters.expand((chapter) {
                              return [
                                Padding(
                                  padding: const EdgeInsets.only(top: 24, bottom: 12),
                                  child: Text(
                                    chapter.title,
                                    style: TextStyle(
                                      fontSize: _fontSize + 3,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                      fontFamily: 'Georgia',
                                    ),
                                  ),
                                ),
                                ...chapter.blocks.map((block) {
                                  switch (block.type) {
                                    case ContentBlockType.paragraph:
                                      if (block.hasDropCap) {
                                        return _DropCapParagraph(
                                          text: block.text,
                                          fontSize: _fontSize,
                                        );
                                      }
                                      return _BodyParagraph(
                                        text: block.text,
                                        fontSize: _fontSize,
                                      );
                                    case ContentBlockType.quote:
                                      return _BlockQuote(
                                        text: block.text,
                                        fontSize: _fontSize,
                                        onSave: () => _saveQuoteFromBlock(block.text),
                                      );
                                    case ContentBlockType.heading:
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Text(
                                          block.text,
                                          style: TextStyle(
                                            fontSize: _fontSize + 5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textDark,
                                            fontFamily: 'Georgia',
                                          ),
                                        ),
                                      );
                                  }
                                }),
                                const SizedBox(height: 16),
                                const Divider(height: 32, thickness: 1),
                              ];
                            }),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
              ),

              // ── Bottom Bar ─────────────────────────────────
              ValueListenableBuilder<ReadingProgressState>(
                valueListenable: _progressNotifier,
                builder: (context, progressState, _) {
                  return _ReaderBottomBar(
                    progress: progressState.scrollProgress.clamp(0.0, 1.0),
                    currentPage: progressState.currentPage,
                    totalPages: _totalPages,
                    onFont: _showFontSizeSheet,
                    onQuote: _showSaveQuoteDialog,
                    onBookmark: () {
                      setState(() => _isBookmarked = !_isBookmarked);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isBookmarked ? '🔖 Bookmarked!' : 'Bookmark removed'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    isBookmarked: _isBookmarked,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top Bar ─────────────────────────────────────────────────
class _ReaderTopBar extends StatelessWidget {
  final String chapterTitle;
  final double progress;
  final bool isBookmarked;
  final VoidCallback onBack;
  final VoidCallback onBookmark;

  const _ReaderTopBar({required this.chapterTitle, required this.progress, required this.isBookmarked, required this.onBack, required this.onBookmark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: AppColors.ivory, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Column(children: [
        Row(children: [
          GestureDetector(onTap: onBack, child: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))]), child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textDark))),
          const SizedBox(width: 12),
          Expanded(child: Text(chapterTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark))),
          GestureDetector(onTap: onBookmark, child: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, size: 22, color: isBookmarked ? AppColors.primary : AppColors.textGrey)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: progress, minHeight: 3, backgroundColor: AppColors.divider.withOpacity(0.5), valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary))),
      ]),
    );
  }
}

// ── Drop Cap ────────────────────────────────────────────────
class _DropCapParagraph extends StatelessWidget {
  final String text;
  final double fontSize;
  const _DropCapParagraph({required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final firstChar = text.isNotEmpty ? text[0].toUpperCase() : '';
    final rest = text.isNotEmpty ? text.substring(1) : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(margin: const EdgeInsets.only(right: 8, top: 2), child: Text(firstChar, style: TextStyle(fontSize: fontSize * 3.5, fontWeight: FontWeight.w800, color: AppColors.textDark, height: 0.85, fontFamily: 'Georgia'))),
        Expanded(child: Text(rest, style: TextStyle(fontSize: fontSize, color: AppColors.textDark, height: 1.75, fontFamily: 'Georgia', letterSpacing: 0.2))),
      ]),
    );
  }
}

// ── Body Paragraph ──────────────────────────────────────────
class _BodyParagraph extends StatelessWidget {
  final String text;
  final double fontSize;
  const _BodyParagraph({required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(text, style: TextStyle(fontSize: fontSize, color: AppColors.textDark, height: 1.75, fontFamily: 'Georgia', letterSpacing: 0.2)));
  }
}

// ── Block Quote (with save button) ──────────────────────────
class _BlockQuote extends StatelessWidget {
  final String text;
  final double fontSize;
  final VoidCallback? onSave;
  const _BlockQuote({required this.text, required this.fontSize, this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: AppColors.primary, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(text, style: TextStyle(fontSize: fontSize - 1, fontStyle: FontStyle.italic, color: AppColors.textDark.withOpacity(0.8), height: 1.65, fontFamily: 'Georgia'))),
          if (onSave != null)
            GestureDetector(
              onTap: onSave,
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bottom Bar (with Quote action) ──────────────────────────
class _ReaderBottomBar extends StatelessWidget {
  final double progress;
  final int currentPage, totalPages;
  final VoidCallback onFont, onQuote, onBookmark;
  final bool isBookmarked;

  const _ReaderBottomBar({
    required this.progress,
    required this.currentPage,
    required this.totalPages,
    required this.onFont,
    required this.onQuote,
    required this.onBookmark,
    required this.isBookmarked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.ivory, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))]),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Page $currentPage/$totalPages',
                  style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
                ),
              ],
            ),
            _BottomBtn(icon: Icons.text_fields, label: 'Font', onTap: onFont),
            _BottomBtn(icon: Icons.format_quote_rounded, label: 'Quote', onTap: onQuote, isActive: true),
            _BottomBtn(icon: isBookmarked ? Icons.bookmark : Icons.bookmark_outline, label: 'Save', onTap: onBookmark, isActive: isBookmarked),
          ],
        ),
      ),
    );
  }
}

class _BottomBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  const _BottomBtn({required this.icon, required this.label, this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 20, color: isActive ? AppColors.primary : AppColors.textGrey),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
