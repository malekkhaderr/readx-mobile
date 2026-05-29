import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../bloc/quotes_bloc.dart';
import '../bloc/quotes_event.dart';
import '../bloc/quotes_state.dart';

/// Args used when navigating to the Add Quote page from anywhere.
/// All fields are optional — when nothing is provided the user picks a book
/// manually from the dropdown.
class AddQuoteArgs {
  final int? bookId;
  final String? bookTitle;
  final String? categoryName;
  final String? content;
  final int? pageNumber;

  const AddQuoteArgs({
    this.bookId,
    this.bookTitle,
    this.categoryName,
    this.content,
    this.pageNumber,
  });
}

class _BookOption {
  final int id;
  final String title;
  final String authorName;
  final String categoryName;
  final String? coverImageUrl;
  _BookOption({
    required this.id,
    required this.title,
    required this.authorName,
    required this.categoryName,
    this.coverImageUrl,
  });
}

class AddQuotePage extends StatefulWidget {
  final AddQuoteArgs args;
  const AddQuotePage({super.key, this.args = const AddQuoteArgs()});

  @override
  State<AddQuotePage> createState() => _AddQuotePageState();
}

class _AddQuotePageState extends State<AddQuotePage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _pageController = TextEditingController();

  bool _isPublic = true;
  bool _submitting = false;
  bool _loadingBooks = true;
  String? _booksError;

  List<_BookOption> _books = const [];
  _BookOption? _selectedBook;

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.args.content ?? '';
    if (widget.args.pageNumber != null) {
      _pageController.text = '${widget.args.pageNumber}';
    }
    _loadBooks();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _loadingBooks = true;
      _booksError = null;
    });
    try {
      final dio = sl<DioClient>().dio;
      final response = await dio.get('/books',
          queryParameters: {'pageNumber': 1, 'pageSize': 100});
      final data = response.data;
      final items = data is Map<String, dynamic>
          ? (data['items'] as List<dynamic>? ?? const [])
          : const [];
      final list = items.map((e) {
        final m = e as Map<String, dynamic>;
        return _BookOption(
          id: m['id'] as int? ?? 0,
          title: (m['title'] as String?) ?? '',
          authorName: (m['authorName'] as String?) ?? '',
          categoryName: (m['categoryName'] as String?) ?? '',
          coverImageUrl: m['coverImageUrl'] as String?,
        );
      }).toList();

      _BookOption? preselected;
      if (widget.args.bookId != null) {
        for (final b in list) {
          if (b.id == widget.args.bookId) {
            preselected = b;
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _books = list;
          _selectedBook = preselected;
          _loadingBooks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _booksError = 'Could not load books. Try again.';
          _loadingBooks = false;
        });
      }
    }
  }

  String? _validateContent(String? v) {
    if (v == null || v.trim().isEmpty) return 'Quote text is required';
    if (v.trim().length < 5) return 'Quote is too short';
    return null;
  }

  String? _validatePage(String? v) {
    if (v == null || v.trim().isEmpty) return 'Page number is required';
    final n = int.tryParse(v.trim());
    if (n == null || n <= 0) return 'Enter a valid page number';
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_isFromReader && !(_formKey.currentState?.validate() ?? false)) return;
    if (!_isFromReader && _selectedBook == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pick a book first'),
          backgroundColor: AppColors.warningOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _submitting = true);

    final bloc = context.read<QuotesBloc>();

    // Build the content: if from reader, use the selected text + optional thoughts
    String newContent;
    if (_isFromReader) {
      final thoughts = _contentController.text.trim();
      newContent = thoughts.isNotEmpty
          ? '${widget.args.content}\n\n— ${thoughts}'
          : widget.args.content!;
    } else {
      newContent = _contentController.text.trim();
    }

    final pageNumber = _isFromReader
        ? (widget.args.pageNumber ?? 1)
        : int.parse(_pageController.text.trim());

    final bookId = _isFromReader ? widget.args.bookId! : _selectedBook!.id;

    bloc.add(AddQuoteEvent(
      bookId: bookId,
      content: newContent,
      pageNumber: pageNumber,
      isPublic: _isPublic,
    ));

    bool succeeded = false;
    try {
      await bloc.stream
          .where((s) {
            if (s is! QuotesCombined) return false;
            final my = s.myState;
            if (my is MyQuotesError) return true; // failure detected
            if (my is MyQuotesLoaded) {
              return my.items.any((q) => q.content.trim() == newContent);
            }
            return false;
          })
          .first
          .timeout(const Duration(seconds: 12));

      // Determine success vs error from the latest state.
      final s = bloc.state;
      if (s is QuotesCombined && s.myState is MyQuotesLoaded) {
        final my = s.myState as MyQuotesLoaded;
        succeeded = my.items.any((q) => q.content.trim() == newContent);
      } else {
        succeeded = false;
      }
    } catch (_) {
      succeeded = false;
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (succeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Quote saved'),
          ]),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save the quote. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool get _isFromReader => widget.args.content != null && widget.args.content!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          _Header(onBack: () => context.pop()),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book — locked if from reader
                    _label('Book', Icons.menu_book_rounded),
                    const SizedBox(height: 8),
                    if (_isFromReader)
                      _lockedBookDisplay()
                    else ...[
                      _bookSelector(),
                      if (_selectedBook != null) ...[
                        const SizedBox(height: 10),
                        _categoryChip(_selectedBook!.categoryName),
                      ],
                    ],
                    const SizedBox(height: 18),
                    // Selected text — shown as read-only when from reader
                    if (_isFromReader) ...[
                      _label('Selected Text', Icons.format_quote_rounded),
                      const SizedBox(height: 8),
                      _lockedQuoteDisplay(),
                      const SizedBox(height: 18),
                      _label('Your Thoughts (optional)', Icons.edit_note_rounded),
                      const SizedBox(height: 8),
                      _thoughtsField(),
                    ] else ...[
                      _label('Quote', Icons.format_quote_rounded),
                      const SizedBox(height: 8),
                      _contentField(),
                    ],
                    const SizedBox(height: 18),
                    // Page — locked if from reader
                    _label('Page Number', Icons.bookmark_outline_rounded),
                    const SizedBox(height: 8),
                    if (_isFromReader)
                      _lockedPageDisplay()
                    else
                      _pageField(),
                    const SizedBox(height: 18),
                    _label('Visibility',
                        _isPublic ? Icons.public_rounded : Icons.lock_rounded),
                    const SizedBox(height: 8),
                    _visibilityToggle(),
                    const SizedBox(height: 26),
                    _submitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockedBookDisplay() {
    final title = widget.args.bookTitle ?? 'Unknown Book';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        Icon(Icons.menu_book_rounded, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark))),
        Icon(Icons.lock_rounded, size: 14, color: AppColors.textLight),
      ]),
    );
  }

  Widget _lockedQuoteDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.format_quote_rounded, size: 18, color: AppColors.primary.withOpacity(0.4)),
        const SizedBox(height: 6),
        Text(
          widget.args.content ?? '',
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.textDark, height: 1.5, fontFamily: 'Georgia'),
        ),
      ]),
    );
  }

  Widget _lockedPageDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        Icon(Icons.bookmark_rounded, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 10),
        Text('Page ${widget.args.pageNumber ?? "?"}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        const Spacer(),
        Icon(Icons.lock_rounded, size: 14, color: AppColors.textLight),
      ]),
    );
  }

  Widget _thoughtsField() {
    return TextFormField(
      controller: _contentController,
      maxLines: 3,
      style: TextStyle(fontSize: 14, color: AppColors.textDark, height: 1.5),
      decoration: InputDecoration(
        hintText: 'Add your thoughts about this passage...',
        hintStyle: TextStyle(fontSize: 13, color: AppColors.textGrey.withOpacity(0.7)),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.divider.withOpacity(0.7))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }

  // ─── widgets ───

  Widget _label(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.textDark,
              letterSpacing: 0.2,
            )),
      ],
    );
  }

  Widget _bookSelector() {
    if (_loadingBooks) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider.withOpacity(0.7)),
        ),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppColors.primary),
          ),
        ),
      );
    }
    if (_booksError != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_booksError!,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textDark)),
            ),
            TextButton(
                onPressed: _loadBooks,
                child: Text('Retry',
                    style: TextStyle(color: AppColors.primary))),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withOpacity(0.7)),
      ),
      child: DropdownButtonFormField<int>(
        value: _selectedBook?.id,
        isExpanded: true,
        icon: Padding(
          padding: EdgeInsets.only(right: 10),
          child: Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textGrey),
        ),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: 'Select a book',
          hintStyle: TextStyle(
              fontSize: 14, color: AppColors.textGrey),
        ),
        items: _books.map((b) {
          return DropdownMenuItem<int>(
            value: b.id,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 22,
                    height: 30,
                    child: b.coverImageUrl != null &&
                            b.coverImageUrl!.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: b.coverImageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                Container(color: AppColors.primaryLight),
                          )
                        : Container(color: AppColors.primaryLight),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    b.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (id) {
          setState(() {
            _selectedBook = _books.firstWhere(
              (b) => b.id == id,
              orElse: () => _books.first,
            );
          });
        },
      ),
    );
  }

  Widget _categoryChip(String category) {
    if (category.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer_rounded,
              size: 11, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            category,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 6),
          Text(
            'auto-filled',
            style: TextStyle(
              fontSize: 9.5,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentField() {
    return TextFormField(
      controller: _contentController,
      maxLines: 5,
      validator: _validateContent,
      style: TextStyle(
        fontSize: 14,
        color: AppColors.textDark,
        fontStyle: FontStyle.italic,
        fontFamily: 'Georgia',
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: 'Type the highlight you want to remember…',
        hintStyle: TextStyle(
          fontSize: 13,
          color: AppColors.textGrey.withOpacity(0.8),
          fontStyle: FontStyle.normal,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.divider.withOpacity(0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }

  Widget _pageField() {
    return TextFormField(
      controller: _pageController,
      keyboardType: TextInputType.number,
      validator: _validatePage,
      style: TextStyle(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: 'e.g. 42',
        hintStyle: TextStyle(fontSize: 13, color: AppColors.textGrey),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 14, right: 10),
          child: Icon(Icons.numbers_rounded,
              size: 18, color: AppColors.textGrey),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.divider.withOpacity(0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }

  Widget _visibilityToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isPublic = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _isPublic
                    ? AppColors.successGreen.withOpacity(0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isPublic
                      ? AppColors.successGreen
                      : AppColors.divider.withOpacity(0.7),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.public_rounded,
                    size: 16,
                    color: _isPublic
                        ? AppColors.successGreen
                        : AppColors.textGrey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Public',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _isPublic
                          ? AppColors.successGreen
                          : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isPublic = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: !_isPublic
                    ? AppColors.warningOrange.withOpacity(0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: !_isPublic
                      ? AppColors.warningOrange
                      : AppColors.divider.withOpacity(0.7),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 16,
                    color: !_isPublic
                        ? AppColors.warningOrange
                        : AppColors.textGrey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Private',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: !_isPublic
                          ? AppColors.warningOrange
                          : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: _submitting ? 0 : 4,
          shadowColor: AppColors.primary.withOpacity(0.4),
        ),
        child: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_add_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Save Quote',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
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
      padding: EdgeInsets.fromLTRB(12, topPadding + 12, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.bookmark_add_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add a Quote',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          )),
                      SizedBox(height: 2),
                      Text('Save a highlight from your reading',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
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
