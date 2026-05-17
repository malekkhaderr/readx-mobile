import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import '../../../../core/constants/app_theme.dart';

/// Full-screen EPUB reader page.
/// Navigated to from BookDetailsPage with an [epubUrl] network link.
class EpubReaderPage extends StatefulWidget {
  final String epubUrl;
  final String bookTitle;

  const EpubReaderPage({
    super.key,
    required this.epubUrl,
    required this.bookTitle,
  });

  @override
  State<EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  late final EpubController _epubController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _showOverlay = false;
  double _readingProgress = 0.0;
  String _currentLocation = '';

  @override
  void initState() {
    super.initState();
    _epubController = EpubController();
    
    // Time out after 30 seconds if the EPUB never loads
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    });
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Reader ────────────────────────────────────────────────
          if (!_hasError)
            SizedBox.expand(
              child: EpubViewer(
                epubSource: EpubSource.fromUrl(widget.epubUrl),
                epubController: _epubController,
                displaySettings: EpubDisplaySettings(
                  flow: EpubFlow.paginated,
                  snap: true, // Re-enabled snap with better constraints
                ),
                onEpubLoaded: () {
                  if (mounted) setState(() => _isLoading = false);
                },
                onChaptersLoaded: (chapters) {
                  if (mounted) setState(() => _isLoading = false);
                },
                onRelocated: (location) {
                  if (mounted) {
                    setState(() {
                      _currentLocation = location.startCfi;
                      _readingProgress = location.progress ?? 0.0;
                    });
                  }
                },
                onTouchUp: (x, y) {
                  // Handling all touch interactions via built-in callback to avoid gesture conflicts
                  // Tap on sides for navigation, center for overlay
                  if (x < 0.2) {
                    _epubController.prev();
                  } else if (x > 0.8) {
                    _epubController.next();
                  } else {
                    _toggleOverlay();
                  }
                },
              ),
            ),

          // ── Top Bar Overlay ───────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showOverlay ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.bookTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.menu_book_outlined),
                      onPressed: () {
                        // Table of contents logic could go here
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom Bar Overlay ────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: _showOverlay ? 0 : -120,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  )
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _NavButton(
                        icon: Icons.navigate_before_rounded,
                        onTap: () => _epubController.prev(),
                      ),
                      const Text(
                        'Swipe or Tap Edges',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      _NavButton(
                        icon: Icons.navigate_next_rounded,
                        onTap: () => _epubController.next(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _readingProgress,
                      minHeight: 4,
                      backgroundColor: AppColors.primaryLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Error View ──────────────────────────────────────────
          if (_hasError)
            _ErrorView(onRetry: () => Navigator.pop(context)),

          // ── Loading overlay ──────────────────────────────────────
          if (_isLoading && !_hasError)
            const _LoadingOverlay(),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 28),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 56, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'Could not load book.\nPlease try again.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textGrey, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Go Back', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Loading book…',
              style: TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
