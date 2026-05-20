import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:epub_view/epub_view.dart' hide Image;
import 'package:epub_view/src/data/models/paragraph.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:readx/core/di/injection_container.dart';
import 'package:readx/features/home/data/datasources/books_service.dart';
import 'package:readx/features/home/data/models/book_detail_model.dart';
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
  File? _localFile;

  // Reading Session State
  int _currentPage = 0;
  DateTime? _sessionStartTime;
  int _elapsedMinutesOffset = 0;
  bool _sessionInitialized = false;
  bool _isResuming = false;
  Timer? _progressTimer;
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
      if (Platform.isAndroid) {
        await _secureChannel.invokeMethod('enableSecure');
        debugPrint('Secure window enabled.');
      }
    } catch (e) {
      debugPrint('Failed to enable secure window: $e');
    }
  }

  Future<void> _disableSecureWindow() async {
    try {
      if (Platform.isAndroid) {
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
    final String rawUrl = widget.epubUrl;
    debugPrint('DEBUG READER: Initializing reader for: $rawUrl');

    // Fetch Book Detail to get totalPages
    try {
      final bookDetail = await sl<BooksService>().getBookDetail(widget.bookId);
      setState(() {
        _totalPages = bookDetail.totalPages > 0 ? bookDetail.totalPages : 1;
      });
      debugPrint('DEBUG READER: Fetched book details. totalPages: $_totalPages');
    } catch (e) {
      debugPrint('DEBUG READER: Failed to fetch book details: $e');
    }

    // Initialize session with backend
    try {
      final session = await sl<BooksService>().getReadingSession(widget.bookId);
      if (session == null) {
        await sl<BooksService>().startReadingSession(widget.bookId);
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
      await BookRepository.updateProgress(
        widget.bookId.toString(),
        1,
        _currentPage,
        totalPages: _totalPages,
      );
      debugPrint('DEBUG READER: Initialized backend session. currentPage: $_currentPage, isResuming: $_isResuming');
    } catch (e) {
      debugPrint('DEBUG READER: Failed to initialize backend session: $e');
      _sessionStartTime = DateTime.now();
      _isResuming = _currentPage > 1;
      _sessionInitialized = true;
      try {
        await BookRepository.updateProgress(
          widget.bookId.toString(),
          1,
          _currentPage,
          totalPages: _totalPages,
        );
      } catch (_) {}
    }
    
    _startProgressTimer();
    
    try {
      final tempDir = await getTemporaryDirectory();
      final cleanTitle = widget.bookTitle.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
      final localFilePath = '${tempDir.path}/$cleanTitle.epub';
      _localFile = File(localFilePath);
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
          document: EpubDocument.openFile(_localFile!),
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
    if (_sessionStartTime == null) return;
    final elapsedMinutes = DateTime.now().difference(_sessionStartTime!).inMinutes;
    final totalMinutes = _elapsedMinutesOffset + elapsedMinutes;
    try {
      debugPrint('Saving reading progress: currentPage=$_currentPage, readingTimeMinutes=$totalMinutes');
      await sl<BooksService>().updateReadingProgress(
        widget.bookId,
        _currentPage,
        totalMinutes,
      );
      await BookRepository.updateProgress(
        widget.bookId.toString(),
        1,
        _currentPage,
        totalPages: _totalPages,
      );
      debugPrint('Updated local BookRepository progress to $_currentPage pages.');
    } catch (e) {
      debugPrint('Failed to save reading progress: $e');
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
  void _handleQuote() {
    if (_selectedText.isEmpty) return;
    
    // Copying and sharing restricted to preserve copyright and publishing rights
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Copying or sharing book content is restricted to preserve copyright and publishing rights.',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w600,
                  color: _theme == 'sepia' ? const Color(0xFF3C2F2F) : Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleDefine() {
    if (_selectedText.isEmpty) return;
    
    final word = _selectedText.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    final cleanWord = word.split(' ').first;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: _backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
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
              Row(
                children: [
                  Icon(Icons.g_translate_rounded, color: _accentColor, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Define: "$cleanWord"',
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Noun / Verb',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _accentColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '1. To mark or express with accuracy; to explain or define elements of significance found within standard textual interfaces.\n\n2. (Figurative) To illuminate and explore the mysteries of ancient volumes and scrolls.',
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 14,
                        height: 1.5,
                        color: _textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _handleNote() {
    if (_selectedText.isEmpty) return;
    
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.edit_note_rounded, color: _accentColor, size: 24),
              const SizedBox(width: 10),
              Text(
                'Add Note',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For highlighted text:',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _mutedTextColor,
                ),
              ),
               const SizedBox(height: 6),
               Container(
                 constraints: const BoxConstraints(maxHeight: 60),
                 width: double.infinity,
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(
                   color: _cardBg,
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: SingleChildScrollView(
                   child: Text(
                     '"$_selectedText"',
                     style: TextStyle(
                       fontFamily: 'Lora',
                       fontSize: 13,
                       fontStyle: FontStyle.italic,
                       color: _textColor.withOpacity(0.8),
                     ),
                   ),
                 ),
               ),
               const SizedBox(height: 16),
               TextField(
                 controller: textController,
                 maxLines: 3,
                 style: TextStyle(
                   fontFamily: 'Lora',
                   fontSize: 14,
                   color: _textColor,
                 ),
                 decoration: InputDecoration(
                   hintText: 'Write your thoughts...',
                   hintStyle: TextStyle(
                     color: _mutedTextColor.withOpacity(0.7),
                   ),
                   filled: true,
                   fillColor: _cardBg,
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                     borderSide: BorderSide.none,
                   ),
                   focusedBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                     borderSide: BorderSide(color: _accentColor, width: 1.5),
                   ),
                 ),
               ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Sora',
                  color: _mutedTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Note saved successfully!',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        color: _theme == 'sepia' ? const Color(0xFF3C2F2F) : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: _accentColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save',
                style: TextStyle(
                  fontFamily: 'Sora',
                  color: _theme == 'sepia' ? const Color(0xFF3C2F2F) : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _saveProgress();
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
              await _saveProgress();
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
          // 1. Floating Streak progress card
          _buildStreakCard(),
          
          // 2. Main scrollable EpubView in SelectionArea
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
                  if (!_sessionInitialized || _isResuming) {
                    return;
                  }
                  if (value != null && _paragraphsPerPage > 0) {
                    final currentIndex = value.position.index;
                    final computedPage = (currentIndex / _paragraphsPerPage).floor() + 1;
                    final newPage = computedPage.clamp(1, _totalPages);
                    if (_currentPage != newPage) {
                      _currentPage = newPage;
                      _progressNotifier.value = value;
                    }
                  }
                },
                onDocumentLoaded: (document) {
                  final totalParagraphs = _calculateTotalParagraphs(document);
                  setState(() {
                    _totalParagraphs = totalParagraphs;
                    _paragraphsPerPage = (_totalParagraphs / _totalPages).clamp(1.0, double.infinity);
                  });
                  debugPrint('DEBUG READER: Document loaded! totalParagraphs: $_totalParagraphs, totalPages: $_totalPages, paragraphsPerPage: $_paragraphsPerPage');
                  
                  // Auto-resume to the saved page index
                  if (_currentPage > 1) {
                    Future.delayed(const Duration(milliseconds: 350), () {
                      if (!mounted || _epubController == null) return;
                      final targetParagraph = ((_currentPage - 1) * _paragraphsPerPage).round();
                      debugPrint('DEBUG READER: Auto-resuming to page $_currentPage (paragraph index $targetParagraph)');
                      try {
                        _epubController!.jumpTo(index: targetParagraph.clamp(0, _totalParagraphs - 1));
                      } catch (e) {
                        debugPrint('DEBUG READER: Error during page resume jumpTo: $e');
                      } finally {
                        Future.delayed(const Duration(milliseconds: 150), () {
                          if (mounted) {
                            setState(() {
                              _isResuming = false;
                            });
                          }
                        });
                      }
                    });
                  } else {
                    setState(() {
                      _isResuming = false;
                    });
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
          onLinkTap: (href, _, __) => onExternalLinkPressed(href!),
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
                final url = imageContext.attributes['src']!.replaceAll('../', '');
                final content = Uint8List.fromList(
                    document.Content!.Images![url]!.Content!);
                return Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image(
                      image: MemoryImage(content),
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStreakCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '🔥',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '12 DAY STREAK',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: _textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                '850 / 1000 XP',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: _accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.85,
              backgroundColor: _progressTrackBg,
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Reward: Golden Bookmark',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _mutedTextColor,
                ),
              ),
              Row(
                children: [
                  _buildSmallBadge(Icons.star_rounded),
                  const SizedBox(width: 6),
                  _buildSmallBadge(Icons.bolt_rounded),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSmallBadge(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 14,
        color: _accentColor,
      ),
    );
  }

  Widget _buildInteractionRow() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildInteractionButton('NOTE', Icons.edit_note_rounded, _handleNote),
          const SizedBox(width: 32),
          _buildInteractionButton('DEFINE', Icons.g_translate_rounded, _handleDefine),
          const SizedBox(width: 32),
          _buildInteractionButton('QUOTE', Icons.share_rounded, _handleQuote),
        ],
      ),
    );
  }

  Widget _buildBottomProgressBar() {
    return ValueListenableBuilder<dynamic>(
      valueListenable: _progressNotifier,
      builder: (context, value, child) {
        if (_epubController == null) {
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
    return epubBook.Chapters!.fold<List<EpubChapter>>(
      [],
      (acc, next) {
        acc.add(next);
        next.SubChapters!.forEach(acc.add);
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
                child: const Icon(
                  Icons.diamond_rounded,
                  color: Colors.white,
                  size: 24,
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
