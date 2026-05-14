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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: AppColors.textDark,
            ),
          ),
        ),
        title: Text(
          widget.bookTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 56, color: AppColors.error),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not load book.\nPlease try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textGrey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Go Back',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          else
            EpubViewer(
              epubSource: EpubSource.fromUrl(widget.epubUrl),
              epubController: _epubController,
              displaySettings: EpubDisplaySettings(
                flow: EpubFlow.paginated,
                snap: true,
              ),
              onEpubLoaded: () {
                if (mounted) setState(() => _isLoading = false);
              },
              onChaptersLoaded: (chapters) {
                if (mounted) setState(() => _isLoading = false);
              },
            ),

          // Loading overlay
          if (_isLoading && !_hasError)
            Container(
              color: AppColors.background,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Loading book…',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
