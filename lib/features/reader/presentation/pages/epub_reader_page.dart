import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:universal_file/universal_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:epub_view/epub_view.dart' hide Image;
import 'package:epub_view/src/data/models/paragraph.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:readx/core/di/injection_container.dart';
import 'package:readx/features/home/data/datasources/books_service.dart';
import 'package:readx/features/home/data/models/book_detail_model.dart';
import 'package:readx/features/library/presentation/bloc/library_bloc.dart';
import 'package:readx/features/library/presentation/bloc/library_event.dart';
import 'package:readx/features/library/presentation/bloc/library_state.dart';
import 'package:readx/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:readx/features/profile/presentation/bloc/profile_event.dart';
import 'package:readx/features/quotes/presentation/pages/add_quote_page.dart';
import 'package:readx/core/data/book_repository.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;
class EpubReaderPage extends StatefulWidget {
  final int bookId;
  final String epubUrl;
  final String bookTitle;

  const EpubReaderPage({
    super.key,
    required this.bookId,
    required this.epubUrl,
    required this.bookTitle,
  });

  @override
  State<EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  static const MethodChannel _secureChannel = MethodChannel('com.readx.readx/secure');
  EpubController? _epubController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _downloadProgress = 0.0;
  String _progressText = 'Initializing...';
  io.File? _localFile;

  // Reading Session State
  int _currentPage = 0;
  /// Timestamp of the last successful progress save. We send DELTAS to the
  /// backend (`readingTimeMinutes` since this anchor), then reset it on a
  /// successful save so we don't double-count minutes already credited.
  DateTime? _lastSaveAt;
  bool _sessionInitialized = false;
  bool _isResuming = false;
  // Latched once the backend returns 409 ("session already completed").
  // After that we stop calling the /progress endpoint to avoid a retry storm.
  bool _sessionCompleted = false;
  Timer? _progressTimer;
  /// Tokens earned across all `/progress` calls in this reader visit. Used
  /// to show the "Great job! +N tokens" snackbar on exit.
  int _tokensEarnedThisSession = 0;
  /// In-flight guard so the 30-second timer can't pile up if the network
  /// hiccups and a save takes longer than the interval.
  bool _saveInFlight = false;
  final ValueNotifier<dynamic> _progressNotifier = ValueNotifier<dynamic>(null);
  int _totalPages = 1;
  int _totalParagraphs = 100;
  double _paragraphsPerPage = 1.0;

  // Settings State Variables
  double _fontSize = 18.0;
  String _fontFamily = 'serif';
  String _theme = 'ivory'; // ivory, ebony, sepia

  bool _isTextSelected = false;
  String _selectedText = '';

  // Themes Color Palette
  Color get _backgroundColor {
    switch (_theme) {
      case 'ebony':
        return const Color(0xFF0E0F14);
      case 'sepia':
        return const Color(0xFFF7F0E3);
      case 'ivory':
      default:
        return const Color(0xFFFAF9FC);
    }
  }

  Color get _appBarBg => _backgroundColor;

  Color get _textColor {
    switch (_theme) {
      case 'ebony':
        return const Color(0xFFFAF9FC);
      case 'sepia':
        return const Color(0xFF3C2F2F);
      case 'ivory':
      default:
        return const Color(0xFF1C1E2A);
    }
  }

  Color get _mutedTextColor {
    switch (_theme) {
      case 'ebony':
        return const Color(0xFF8E95A5);
      case 'sepia':
        return const Color(0xFF7C6C6C);
      case 'ivory':
      default:
        return const Color(0xFF5E6577);
    }
  }

  Color get _accentColor {
    switch (_theme) {
      case 'sepia':
        return const Color(0xFF8B5E3C);
      case 'ebony':
        return const Color(0xFF8E7CFF);
      case 'ivory':
      default:
        return const Color(0xFF7C6AFF);
    }
  }

  Color get _cardBg {
    switch (_theme) {
      case 'ebony':
        return const Color(0xFF1E2030);
      case 'sepia':
        return const Color(0xFFEFE6D5);
      case 'ivory':
      default:
        return const Color(0xFFF1EEF5);
    }
  }

  Color get _progressTrackBg {
    switch (_theme) {
      case 'ebony':
        return const Color(0xFF2E3148);
      case 'sepia':
        return const Color(0xFFDFD4C0);
      case 'ivory':
      default:
        return const Color(0xFFE2DDF0);
    }
  }

  Color get _bottomNavBg {
    switch (_theme) {
      case 'ebony':
        return const Color(0xFF161822);
      case 'sepia':
        return const Color(0xFFEFE6D5);
      case 'ivory':
      default:
        return const Color(0xFFFFFFFF);
    }
  }

  Color get _bottomNavUnselected {
    switch (_theme) {
      case 'ebony':
        return const Color(0xFF5E6577);
      case 'sepia':
        return const Color(0xFF7C6C6C);
      case 'ivory':
      default:
        return const Color(0xFF8A8F9F);
    }
  }

  Future<void> _enableSecureWindow() async {
    try {
      if (io.Platform.isAndroid) {
        await _secureChannel.invokeMethod('enableSecure');
        debugPrint('Secure window enabled.');
      }
    } catch (e) {
      debugPrint('Failed to enable secure window: $e');
    }
  }

  Future<void> _disableSecureWindow() async {
    try {
      if (io.Platform.isAndroid) {
        await _secureChannel.invokeMethod('disableSecure');
        debugPrint('Secure window disabled.');
      }
    } catch (e) {
      debugPrint('Failed to disable secure window: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _enableSecureWindow();
    _loadSettings();
    _initReader();
  }

  @override
  void dispose() {
    _saveProgress();
    _progressTimer?.cancel();
    _disableSecureWindow();
    _epubController?.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _fontSize = prefs.getDouble('reader_font_size') ?? 18.0;
        _fontFamily = prefs.getString('reader_font_family') ?? 'serif';
        _theme = prefs.getString('reader_theme') ?? 'ivory';
      });
    } catch (e) {
      debugPrint('Error loading reader settings: $e');
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (e) {
      debugPrint('Error saving reader setting: $key -> $e');
    }
  }

  Future<void> _initReader() async {
    final String rawUrl = widget.epubUrl.trim();
    debugPrint('DEBUG READER: Initializing reader for: $rawUrl');

    // ── Guard 1: validate the URL is a real http(s) link ──
    // The backend stores nullable epub URLs; many books have garbage like
    // "test.com" / "1234" / null. Bail out immediately so we don't waste
    // 45 seconds in Dio timeout — show the existing error UI right away.
    final isRealUrl =
        rawUrl.startsWith('http://') || rawUrl.startsWith('https://');
    if (!isRealUrl) {
      _showError(
        'Book content not available',
        'This book does not have a readable file uploaded yet. '
            'Please contact the publisher or try another book.',
      );
      return;
    }

    // ── Guard 2: ownership check ──
    // The reader should never open for a book the user does not own.
    // The book details page already enforces this on the way in, but in
    // case someone reaches /epub-reader directly, we re-verify against
    // LibraryBloc state (already kept fresh by home/library tabs).
    final libState = sl<LibraryBloc>().state;
    final isOwned = libState is LibraryLoaded &&
        libState.books.any((b) => b.bookId == widget.bookId);
    if (!isOwned) {
      // If the bloc hasn't loaded yet (deep-link case), fire a load and
      // skip the gate this once. Otherwise reject.
      if (libState is! LibraryLoaded) {
        sl<LibraryBloc>().add(const LoadLibraryEvent());
      } else {
        _showError(
          'Access denied',
          'You need to add this book to your library before reading it.',
        );
        return;
      }
    }

    // Note: we no longer fetch the backend's `totalPages` here. EPUBs are
    // reflowable so the canonical "total" comes from the file itself —
    // we count the paragraphs in the parsed EPUB and use that as the
    // page total in onDocumentLoaded(). The backend's totalPages was
    // inconsistent with the actual content for many books.

    // Initialize session with backend.
    //
    // Resume note: the backend tracks the cumulative time server-side, so we
    // only need to know `currentPage` to resume the right place. The local
    // stopwatch starts fresh from the moment the page opens.
    try {
      final session = await sl<BooksService>().getReadingSession(widget.bookId);
      if (session == null) {
        await sl<BooksService>().startReadingSession(widget.bookId);
        _currentPage = 1;
        _isResuming = false;
      } else {
        _currentPage = session['currentPage'] ?? 1;
        _isResuming = _currentPage > 1;
        // If the backend already marked this session as completed, the
        // /progress endpoint will reject every save with 409. Try to start
        // a fresh session so progress saving works again — if that also
        // fails (e.g. the backend disallows it), latch _sessionCompleted
        // and just keep reading without server-side progress.
        if (session['isCompleted'] == true) {
          try {
            await sl<BooksService>().startReadingSession(widget.bookId);
            debugPrint(
                'DEBUG READER: Restarted reading session after server marked it completed.');
          } catch (e) {
            debugPrint(
                'DEBUG READER: Could not restart completed session: $e — disabling future progress saves.');
            _sessionCompleted = true;
          }
        }
      }
      _lastSaveAt = DateTime.now();
      _sessionInitialized = true;
      await BookRepository.updateProgress(
        widget.bookId.toString(),
        1,
        _currentPage,
        totalPages: _totalPages > 1 ? _totalPages : null,
      );
      debugPrint(
          'DEBUG READER: Initialized backend session. currentPage: $_currentPage, isResuming: $_isResuming');
    } catch (e) {
      debugPrint('DEBUG READER: Failed to initialize backend session: $e');
      _lastSaveAt = DateTime.now();
      _isResuming = _currentPage > 1;
      _sessionInitialized = true;
      try {
        await BookRepository.updateProgress(
          widget.bookId.toString(),
          1,
          _currentPage,
          totalPages: _totalPages > 1 ? _totalPages : null,
        );
      } catch (_) {}
    }
    
    _startProgressTimer();
    
    try {
      final tempDir = await getTemporaryDirectory();
      final cleanTitle = widget.bookTitle.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
      final localFilePath = '${tempDir.path}/$cleanTitle.epub';
      _localFile = io.File(localFilePath);
      debugPrint('DEBUG READER: Resolved local file path: ${_localFile!.path}');
    } catch (e) {
      debugPrint('DEBUG READER: ERROR resolving local directory: $e');
      _showError('Initialization Error', 'Failed to initialize local directory: $e');
      return;
    }

    if (await _localFile!.exists()) {
      final cacheSize = await _localFile!.length();
      debugPrint('DEBUG READER: Cache hit! Local file size: $cacheSize bytes');
      if (cacheSize > 0) {
        setState(() {
          _progressText = 'Opening local copy...';
          _downloadProgress = 1.0;
        });
        await Future.delayed(const Duration(milliseconds: 300));
        _loadDocument();
        return;
      }
    }

    debugPrint('DEBUG READER: Cache miss or empty. Starting download from network...');
    setState(() {
      _progressText = 'Connecting to server...';
      _downloadProgress = 0.0;
    });

    final dio = Dio();
    try {
      final response = await dio.get<List<int>>(
        rawUrl,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 45),
          sendTimeout: const Duration(seconds: 45),
        ),
        onReceiveProgress: (received, total) {
          if (!mounted) return;
          if (total != -1) {
            final progress = received / total;
            final percent = (progress * 100).toStringAsFixed(0);
            final downloadedStr = _formatBytes(received);
            final totalStr = _formatBytes(total);
            setState(() {
              _downloadProgress = progress;
              _progressText = 'Downloading: $percent% ($downloadedStr / $totalStr)';
            });
          } else {
            setState(() {
              _progressText = 'Downloading: ${_formatBytes(received)} (size unknown)';
            });
          }
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Server returned status ${response.statusCode}');
      }

      await _localFile!.writeAsBytes(response.data!);
      _loadDocument();
    } catch (e) {
      debugPrint('DEBUG READER: ERROR downloading book: $e');
      _showError('Download Failed', 'Could not retrieve book content. Details: $e');
    }
  }

  void _loadDocument() {
    if (!mounted) return;
    debugPrint('DEBUG READER: Initializing EpubController...');
    try {
      setState(() {
        _epubController = EpubController(
          document: EpubDocument.openFile(File(_localFile!.path)),
        );
        _isLoading = false;
      });
      debugPrint('DEBUG READER: EpubController successfully initialized!');
    } catch (e) {
      debugPrint('DEBUG READER: ERROR parsing/opening EPUB file: $e');
      _showError('Opening Error', 'Failed to open local EPUB file: $e');
    }
  }

  Future<void> _saveProgress() async {
    if (_lastSaveAt == null) return;
    if (_saveInFlight) return;

    // If the backend already told us the session is finished, stop hitting
    // the endpoint — otherwise every 30-second tick spams a 409 forever.
    if (_sessionCompleted) {
      await BookRepository.updateProgress(
        widget.bookId.toString(),
        1,
        _currentPage,
        totalPages: _totalPages > 1 ? _totalPages : null,
      );
      return;
    }

    // Compute the *delta* — minutes read since the last successful save —
    // and snapshot `now` BEFORE the network call so any minutes that
    // accumulate while the request is in flight roll into the next batch.
    final now = DateTime.now();
    final deltaMinutes = now.difference(_lastSaveAt!).inMinutes;

    if (deltaMinutes <= 0) {
      // Nothing to credit yet, but still mirror the page locally so the
      // home/library "Continue reading" stays in sync after page turns.
      await BookRepository.updateProgress(
        widget.bookId.toString(),
        1,
        _currentPage,
        totalPages: _totalPages > 1 ? _totalPages : null,
      );
      return;
    }

    _saveInFlight = true;
    try {
      debugPrint(
          'Saving reading progress: currentPage=$_currentPage, deltaMinutes=$deltaMinutes');
      final result = await sl<BooksService>().updateReadingProgress(
        widget.bookId,
        _currentPage,
        deltaMinutes,
      );

      // Reset the stopwatch only after a successful credit so a failed
      // save doesn't lose the user's reading time.
      _lastSaveAt = now;
      if (result.tokensEarned > 0) {
        _tokensEarnedThisSession += result.tokensEarned;
        debugPrint(
            'Earned ${result.tokensEarned} tokens (session total: $_tokensEarnedThisSession).');
      }
      if (result.isCompleted) {
        _sessionCompleted = true;
        _progressTimer?.cancel();
      }

      await BookRepository.updateProgress(
        widget.bookId.toString(),
        1,
        _currentPage,
        totalPages: _totalPages > 1 ? _totalPages : null,
      );
    } on DioException catch (e) {
      // 409 = backend completed the session. Latch our flag so we stop
      // calling progress for the rest of this reader session.
      if (e.response?.statusCode == 409) {
        debugPrint(
            'Reading session already completed on the server — disabling further progress saves.');
        _sessionCompleted = true;
        _progressTimer?.cancel();
      } else {
        debugPrint('Failed to save reading progress: $e');
      }
      // Still update the local cache so the UI reflects the latest page.
      await BookRepository.updateProgress(
        widget.bookId.toString(),
        1,
        _currentPage,
        totalPages: _totalPages > 1 ? _totalPages : null,
      );
    } catch (e) {
      debugPrint('Failed to save reading progress: $e');
    } finally {
      _saveInFlight = false;
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

  /// Final flush + side-effects when the user is leaving the reader. Called
  /// from the back button and the system pop. After the last save we ask
  /// the ProfileBloc to refetch /users/me so the dashboard's streak +
  /// token balance reflect what the backend just credited, and we surface
  /// the cumulative tokens earned from this visit as a snackbar.
  Future<void> _handleExit() async {
    await _saveProgress();
    // Fire-and-forget profile refresh so the dashboard tile updates the
    // moment the user lands back on it.
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
        backgroundColor: const Color(0xFF6B5BFF),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String title, String details) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = '$title: $details';
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  // Highlight Action Handlers
  // _handleQuote removed — the SAVE QUOTE selection button has been taken
  // out of the reader toolbar. Quotes are added via the Quotes tab now.

  /// Send the user to the Add Quote page with the highlighted text, current
  /// book, and current page already filled in. The Add Quote page also
  /// auto-fills the category from the chosen book. Content stays editable.
  void _handleQuote() {
    if (_selectedText.isEmpty) return;
    final cleaned = _selectedText.trim();
    // Capture before any state changes / pops
    final bookId = widget.bookId;
    final bookTitle = widget.bookTitle;
    final pageNumber = _currentPage > 0 ? _currentPage : 1;

    // Clear the selection state so the toolbar collapses while we navigate.
    setState(() {
      _isTextSelected = false;
      _selectedText = '';
    });

    context.push(
      '/add-quote',
      extra: AddQuoteArgs(
        bookId: bookId,
        bookTitle: bookTitle,
        content: cleaned,
        pageNumber: pageNumber,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleExit();
        return true;
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: _appBarBg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: _textColor, size: 20),
            onPressed: () async {
              await _handleExit();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: _isLoading || _hasError
            ? Text(
                widget.bookTitle,
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _textColor,
                ),
              )
            : EpubViewActualChapter(
                controller: _epubController!,
                builder: (chapterValue) {
                  final rawTitle = chapterValue?.chapter?.Title?.replaceAll('\n', '').trim() ?? widget.bookTitle;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        rawTitle,
                        style: TextStyle(
                          fontFamily: 'Lora',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ARCANE CHRONICLES',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          color: _accentColor,
                          letterSpacing: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
        centerTitle: true,
        actions: [
          if (!_isLoading && !_hasError) ...[
            Builder(
              builder: (ctx) => IconButton(
                icon: Icon(Icons.menu_book_rounded, color: _textColor, size: 22),
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              ),
            ),
            IconButton(
              icon: Icon(Icons.settings_rounded, color: _textColor, size: 22),
              onPressed: () => _showSettingsBottomSheet(context),
            ),
          ],
        ],
      ),
      endDrawer: _isLoading || _hasError
          ? null
          : Theme(
              data: ThemeData.dark().copyWith(
                canvasColor: const Color(0xFF161822),
              ),
              child: Drawer(
                backgroundColor: const Color(0xFF161822),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'Table of Contents',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Divider(color: Color(0xFF2C2F3E), height: 1),
                      Expanded(
                        child: EpubViewTableOfContents(
                          controller: _epubController!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      body: _buildBody(),
    ),
  );
}

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1E2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Could Not Open Book',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                    _errorMessage = '';
                  });
                  _initReader();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C6AFF)),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _progressText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              if (_downloadProgress > 0.0 && _downloadProgress <= 1.0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _downloadProgress,
                    backgroundColor: const Color(0xFF1C1E2A),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C6AFF)),
                    minHeight: 6,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Fully loaded ebook reader layout!
    return SafeArea(
      child: Column(
        children: [
          // Streak card removed — progress is communicated via the
          // page-number bar at the bottom of the screen instead.
          // Main scrollable EpubView in SelectionArea
          Expanded(
            child: SelectionArea(
              contextMenuBuilder: (context, selectableRegionState) {
                final List<ContextMenuButtonItem> buttonItems =
                    List.from(selectableRegionState.contextMenuButtonItems);
                // Exclude Copy and Share context menu items to protect copyright
                buttonItems.removeWhere((item) =>
                    item.type == ContextMenuButtonType.copy ||
                    item.type == ContextMenuButtonType.share);
                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: selectableRegionState.contextMenuAnchors,
                  buttonItems: buttonItems,
                );
              },
              onSelectionChanged: (selection) {
                final text = selection?.plainText.trim() ?? '';
                if (text.isNotEmpty) {
                  if (!_isTextSelected || _selectedText != text) {
                    setState(() {
                      _isTextSelected = true;
                      _selectedText = text;
                    });
                  }
                } else {
                  if (_isTextSelected) {
                    setState(() {
                      _isTextSelected = false;
                      _selectedText = '';
                    });
                  }
                }
              },
              child: EpubView(
                controller: _epubController!,
                onChapterChanged: (value) {
                  // Track scroll position so the bottom progress bar updates,
                  // but DO NOT clamp the page number — the book is shown as
                  // one continuous flow and the user can scroll anywhere.
                  // While we're auto-jumping to the saved page on first
                  // load (_isResuming = true), ignore notifications so we
                  // don't fight our own seek.
                  // 1:1 mapping — every paragraph counts as one page-unit.
                  // _totalPages is set in onDocumentLoaded once we've counted
                  // the EPUB's paragraphs.
                  if (value == null || _isResuming) return;
                  final newPage = value.position.index + 1;
                  if (newPage > 0 && newPage != _currentPage) {
                    _currentPage = newPage;
                    _progressNotifier.value = value;
                  }
                },
                onDocumentLoaded: (document) {
                  // Total = number of paragraphs in the actual EPUB. The
                  // backend's totalPages metadata is intentionally ignored
                  // because it was inaccurate for many books — the canonical
                  // total now lives in the file we just parsed.
                  final totalParagraphs = _calculateTotalParagraphs(document);
                  setState(() {
                    _totalParagraphs = totalParagraphs;
                    _totalPages = totalParagraphs > 0 ? totalParagraphs : 1;
                    _paragraphsPerPage = 1.0;
                  });
                  debugPrint(
                      'DEBUG READER: Document loaded! _totalPages = $_totalPages (paragraphs)');

                  // Auto-resume to the last saved page so the user picks up
                  // exactly where they left off. The book is still rendered
                  // as one continuous flow — we only seek the scroll position
                  // once on first load. While the jumpTo is in flight,
                  // _isResuming = true so onChapterChanged ignores its own
                  // updates. After 500ms we clear _isResuming so user
                  // scrolling is tracked normally.
                  if (_currentPage > 1) {
                    Future.delayed(const Duration(milliseconds: 350), () {
                      if (!mounted || _epubController == null) return;
                      // 1 paragraph = 1 page; resume index is page-1.
                      final safeTarget = (_currentPage - 1)
                          .clamp(0, (_totalParagraphs - 1).clamp(0, 1 << 30));
                      debugPrint(
                          'DEBUG READER: Auto-resuming to page $_currentPage (paragraph index $safeTarget)');
                      try {
                        _epubController!.jumpTo(index: safeTarget);
                      } catch (e) {
                        debugPrint(
                            'DEBUG READER: Error during page resume jumpTo: $e');
                      } finally {
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            setState(() => _isResuming = false);
                          }
                        });
                      }
                    });
                  } else {
                    setState(() => _isResuming = false);
                  }
                },
                builders: EpubViewBuilders<DefaultBuilderOptions>(
                  options: const DefaultBuilderOptions(
                    textStyle: TextStyle(
                      height: 1.75,
                    ),
                  ),
                  chapterDividerBuilder: _buildChapterDivider,
                  chapterBuilder: _buildChapterItem,
                ),
              ),
            ),
          ),
          
          // 3. Dynamic Slide-Open Interaction controls on text selection
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _isTextSelected
                ? _buildInteractionRow()
                : const SizedBox.shrink(),
          ),

          // 4. Premium Bottom Page Progress Indicator Bar
          _buildBottomProgressBar(),
        ],
      ),
    );
  }

  Widget _buildChapterDivider(EpubChapter chapter) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 1,
            color: _accentColor.withOpacity(0.3),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              Icons.auto_awesome, // Sparkle ornament icon
              color: _accentColor,
              size: 20,
            ),
          ),
          Container(
            width: 48,
            height: 1,
            color: _accentColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterItem(
    BuildContext context,
    EpubViewBuilders builders,
    EpubBook document,
    List<EpubChapter> chapters,
    List<Paragraph> paragraphs,
    int index,
    int chapterIndex,
    int paragraphIndex,
    ExternalLinkPressed onExternalLinkPressed,
  ) {
    if (paragraphs.isEmpty) {
      return const SizedBox();
    }

    String htmlData = paragraphs[index].element.outerHtml;
    
    // First paragraph Drop Cap Compiler
    if (paragraphIndex == 0) {
      final pMatch = RegExp(r'^(<p[^>]*>)\s*([a-zA-Z])(.*)$', dotAll: true).firstMatch(htmlData);
      if (pMatch != null) {
        final startTag = pMatch.group(1) ?? '<p>';
        final firstLetter = pMatch.group(2) ?? '';
        final restOfText = pMatch.group(3) ?? '';
        htmlData = '$startTag<span class="dropcap">$firstLetter</span>$restOfText';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chapterIndex >= 0 && paragraphIndex == 0)
          builders.chapterDividerBuilder(chapters[chapterIndex]),
        Html(
          data: htmlData,
          // href can be null for in-document anchors (<a name="x">) or
          // malformed links — guard so the reader doesn't crash if the
          // user taps one of them.
          onLinkTap: (href, _, __) {
            if (href != null && href.isNotEmpty) {
              onExternalLinkPressed(href);
            }
          },
          style: {
            'html': Style(
              fontFamily: _fontFamily,
              fontSize: FontSize(_fontSize),
              lineHeight: const LineHeight(1.75),
              color: _textColor,
              padding: HtmlPaddings.symmetric(horizontal: 24, vertical: 8),
            ),
            'p': Style(
              fontFamily: _fontFamily,
              fontSize: FontSize(_fontSize),
              lineHeight: const LineHeight(1.75),
              color: _textColor,
              margin: Margins.only(bottom: 16),
            ),
            'h1': Style(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.bold,
              fontSize: FontSize(_fontSize * 1.55),
              color: _textColor,
              margin: Margins.only(top: 24, bottom: 12),
              textDecoration: TextDecoration.underline,
              textDecorationColor: _accentColor.withOpacity(0.4),
              textDecorationThickness: 2,
            ),
            'h2': Style(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.bold,
              fontSize: FontSize(_fontSize * 1.35),
              color: _textColor,
              margin: Margins.only(top: 20, bottom: 10),
            ),
            'blockquote': Style(
              fontStyle: FontStyle.italic,
              color: _textColor.withOpacity(0.85),
              backgroundColor: _accentColor.withOpacity(0.05),
              padding: HtmlPaddings.only(left: 16, top: 12, bottom: 12, right: 12),
              border: Border(
                left: BorderSide(
                  color: _accentColor,
                  width: 4,
                ),
              ),
              margin: Margins.symmetric(vertical: 20, horizontal: 8),
            ),
            'span.dropcap': Style(
              fontSize: FontSize(_fontSize * 2.8),
              fontWeight: FontWeight.bold,
              color: _accentColor,
              margin: Margins.only(right: 10, bottom: 2, top: 4),
              fontFamily: _fontFamily,
            ),
            'span.first-letter': Style(
              fontSize: FontSize(_fontSize * 2.8),
              fontWeight: FontWeight.bold,
              color: _accentColor,
              margin: Margins.only(right: 10, bottom: 2, top: 4),
              fontFamily: _fontFamily,
            ),
            'a': Style(
              color: _accentColor,
              textDecoration: TextDecoration.underline,
            ),
          },
          extensions: [
            TagExtension(
              tagsToExtend: {"img"},
              builder: (imageContext) {
                // Defensive lookup: an EPUB's <img src=...> can point at
                // images that aren't bundled, use unexpected path prefixes,
                // or simply not exist. The previous chained ! operators
                // crashed the whole reader on the first missing asset
                // (Null check operator used on a null value).
                try {
                  final rawSrc = imageContext.attributes['src'];
                  if (rawSrc == null || rawSrc.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  // Try a few common path variants. EPUB packages sometimes
                  // store images under just the filename, sometimes under
                  // the relative path.
                  final candidates = <String>{
                    rawSrc,
                    rawSrc.replaceAll('../', ''),
                    rawSrc.split('/').last,
                  };

                  final images = document.Content?.Images;
                  if (images == null) return const SizedBox.shrink();

                  EpubByteContentFile? file;
                  for (final key in candidates) {
                    if (images.containsKey(key)) {
                      file = images[key];
                      if (file != null) break;
                    }
                  }
                  if (file?.Content == null) {
                    return const SizedBox.shrink();
                  }

                  final content = Uint8List.fromList(file!.Content!);
                  return Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        content,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  );
                } catch (e) {
                  // Never let one broken image take down the reader.
                  debugPrint('DEBUG READER: Image rendering error: $e');
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildInteractionRow() {
    // Only QUOTE is exposed when the user highlights text. NOTE and DEFINE
    // were removed — the Notes feature lives outside the reader and the
    // Define popover was a placeholder with hardcoded text.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildInteractionButton(
              'QUOTE', Icons.format_quote_rounded, _handleQuote),
        ],
      ),
    );
  }

  Widget _buildBottomProgressBar() {
    return ValueListenableBuilder<dynamic>(
      valueListenable: _progressNotifier,
      builder: (context, value, child) {
        // Wait until the EPUB has been parsed and we know the real total.
        // _totalPages defaults to 1; we only render after onDocumentLoaded
        // sets it to the actual paragraph count from the file.
        if (_epubController == null || _totalPages <= 1) {
          return const SizedBox.shrink();
        }

        final pageNum = _currentPage > 0 ? _currentPage : 1;
        final progressPercent = (pageNum / _totalPages).clamp(0.0, 1.0);
        final percentageString = '${(progressPercent * 100).toStringAsFixed(0)}%';
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _appBarBg,
            border: Border(
              top: BorderSide(
                color: _textColor.withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page $pageNum of $_totalPages',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _mutedTextColor,
                ),
              ),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        backgroundColor: _progressTrackBg,
                        valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    percentageString,
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  int _calculateTotalParagraphs(EpubBook book) {
    try {
      final chapters = _parseChapters(book);
      int total = 0;
      String? filename = '';
      
      for (final next in chapters) {
        if (filename != next.ContentFileName) {
          filename = next.ContentFileName;
          final contentFile = book.Content?.Html?[filename];
          if (contentFile != null) {
            final document = parse(contentFile.Content);
            final bodies = document.getElementsByTagName('body');
            if (bodies.isNotEmpty) {
              final elements = _removeAllDiv(bodies.first.children);
              total += elements.length;
            }
          }
        }
      }
      return total > 0 ? total : 100;
    } catch (e) {
      debugPrint('DEBUG READER: Error calculating total paragraphs: $e');
      return 100;
    }
  }

  List<EpubChapter> _parseChapters(EpubBook epubBook) {
    final chapters = epubBook.Chapters;
    if (chapters == null || chapters.isEmpty) return const [];
    return chapters.fold<List<EpubChapter>>(
      [],
      (acc, next) {
        acc.add(next);
        // SubChapters can legitimately be null/empty in many EPUBs.
        final subs = next.SubChapters;
        if (subs != null) {
          for (final sub in subs) {
            acc.add(sub);
          }
        }
        return acc;
      },
    );
  }

  List<dom.Element> _removeAllDiv(List<dom.Element> elements) {
    final List<dom.Element> result = [];
    for (final node in elements) {
      if (node.localName == 'div' && node.children.length > 1) {
        result.addAll(_removeAllDiv(node.children));
      } else {
        result.add(node);
      }
    }
    return result;
  }

  Widget _buildInteractionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: _accentColor.withOpacity(0.15), width: 1),
            ),
            child: Icon(
              icon,
              color: _accentColor,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _accentColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: _bottomNavBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem('READ', Icons.book_rounded, true),
              _buildNavItem('LIBRARY', Icons.explore_rounded, false),
              const SizedBox(width: 48), // Spacer for central overlapping diamond FAB
              _buildNavItem('RANKS', Icons.emoji_events_rounded, false),
              _buildNavItem('PROFILE', Icons.person_rounded, false),
            ],
          ),
          Positioned(
            top: 0,
            child: Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/images/purple_feather.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon, bool isActive) {
    final color = isActive ? _accentColor : _bottomNavUnselected;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _mutedTextColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Reader Settings',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Font Size Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Font Size',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      Text(
                        '${_fontSize.toInt()} px',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _accentColor,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _fontSize,
                    min: 14.0,
                    max: 26.0,
                    divisions: 6,
                    activeColor: _accentColor,
                    inactiveColor: _mutedTextColor.withOpacity(0.3),
                    onChanged: (val) {
                      setModalState(() {
                        _fontSize = val;
                      });
                      setState(() {
                        _fontSize = val;
                      });
                      _saveSetting('reader_font_size', val);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Font Family Options
                  Text(
                    'Font Family',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildFontOptionButton('Serif', 'serif', setModalState),
                      const SizedBox(width: 16),
                      _buildFontOptionButton('Sans-Serif', 'sans-serif', setModalState),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Theme Options
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildThemeCircleOption('Ivory', 'ivory', const Color(0xFFFAF9FC), setModalState),
                      const SizedBox(width: 24),
                      _buildThemeCircleOption('Ebony', 'ebony', const Color(0xFF0E0F14), setModalState),
                      const SizedBox(width: 24),
                      _buildThemeCircleOption('Sepia', 'sepia', const Color(0xFFF7F0E3), setModalState),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFontOptionButton(String label, String fontVal, StateSetter setModalState) {
    final isSelected = _fontFamily == fontVal;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setModalState(() {
            _fontFamily = fontVal;
          });
          setState(() {
            _fontFamily = fontVal;
          });
          _saveSetting('reader_font_family', fontVal);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _accentColor : _cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _accentColor : _mutedTextColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: fontVal == 'serif' ? 'Lora' : 'Sora',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : _textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCircleOption(String label, String themeVal, Color color, StateSetter setModalState) {
    final isSelected = _theme == themeVal;
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _theme = themeVal;
        });
        setState(() {
          _theme = themeVal;
        });
        _saveSetting('reader_theme', themeVal);
      },
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _accentColor : _mutedTextColor.withOpacity(0.3),
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: _accentColor.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
              ],
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: themeVal == 'ivory' ? const Color(0xFF7C6AFF) : Colors.white,
                    size: 20,
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }
}
