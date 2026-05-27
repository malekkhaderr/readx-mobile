import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../data/datasources/books_service.dart';
import '../../data/models/rating_review_model.dart';

/// Result returned from the bottom sheet.
///
/// - `submitted`: a new or updated review (caller updates the book aggregate).
/// - `deleted`: the user removed their existing review.
/// - `null`: the sheet was dismissed without any change.
class RateBookSheetResult {
  final RatingReviewItem? submitted;
  final bool deleted;

  const RateBookSheetResult._({this.submitted, this.deleted = false});

  const RateBookSheetResult.submitted(RatingReviewItem r)
      : this._(submitted: r);
  const RateBookSheetResult.deleted() : this._(deleted: true);
}

/// Opens the rate-book bottom sheet.
///
/// `existingRating` is non-null when the user already has a review and we want
/// to pre-fill the stars + review text + show a "Remove rating" button.
Future<RateBookSheetResult?> showRateBookSheet({
  required BuildContext context,
  required int bookId,
  required String bookTitle,
  required BooksService booksService,
  RatingReviewItem? existingRating,
}) {
  return showModalBottomSheet<RateBookSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => _RateBookSheet(
      bookId: bookId,
      bookTitle: bookTitle,
      booksService: booksService,
      existingRating: existingRating,
    ),
  );
}

class _RateBookSheet extends StatefulWidget {
  final int bookId;
  final String bookTitle;
  final BooksService booksService;
  final RatingReviewItem? existingRating;

  const _RateBookSheet({
    required this.bookId,
    required this.bookTitle,
    required this.booksService,
    required this.existingRating,
  });

  @override
  State<_RateBookSheet> createState() => _RateBookSheetState();
}

class _RateBookSheetState extends State<_RateBookSheet> {
  /// Backend caps the textual review at a sane size. Keep client + server in
  /// agreement so we don't silently truncate something the server accepts.
  static const int _maxTextLength = 1000;

  /// Currently-selected rating, in 0.5-step increments. 0 means "not chosen".
  late double _rating;
  late final TextEditingController _textController;
  late final String _initialText;

  bool _submitting = false;
  bool _deleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingRating?.rating ?? 0;
    _initialText = widget.existingRating?.reviewText ?? '';
    _textController = TextEditingController(text: _initialText);
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Trigger a rebuild so the submit button re-evaluates `_canSubmit`
    // when the user types into the review text field.
    setState(() {});
  }

  String get _trimmedText => _textController.text.trim();

  /// True if the form has anything that differs from the user's existing
  /// review — either the rating or the text. We require at least one star to
  /// be selected; the text alone isn't enough since rating is mandatory.
  bool get _canSubmit {
    if (_rating <= 0) return false;
    if (_submitting || _deleting) return false;

    final existingRating = widget.existingRating?.rating;
    final ratingChanged =
        existingRating == null || existingRating != _rating;
    final textChanged = _trimmedText != _initialText.trim();
    return ratingChanged || textChanged;
  }

  /// Tap on the i-th star (1..5) toggles between half and full to match the
  /// 0.5-step granularity the backend accepts. First tap on a fresh star
  /// gives a full star; repeated taps on the same star cycle full → half.
  void _onTapStar(int index) {
    final tappedValue = index.toDouble();
    setState(() {
      if (_rating == tappedValue) {
        _rating = tappedValue - 0.5;
      } else if (_rating == tappedValue - 0.5) {
        _rating = tappedValue;
      } else {
        _rating = tappedValue;
      }
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final result = await widget.booksService.upsertRating(
        widget.bookId,
        _rating,
        text: _trimmedText.isEmpty ? null : _trimmedText,
      );
      if (!mounted) return;
      Navigator.of(context).pop(RateBookSheetResult.submitted(result));
    } on RatingException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _delete() async {
    if (widget.existingRating == null || _deleting || _submitting) return;
    setState(() {
      _deleting = true;
      _errorMessage = null;
    });
    try {
      await widget.booksService.deleteMyRating(widget.bookId);
      if (!mounted) return;
      Navigator.of(context).pop(const RateBookSheetResult.deleted());
    } on RatingException catch (e) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _errorMessage = 'Could not remove your rating. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingRating != null;
    final ratingLabel = _ratingLabel(_rating);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isEditing ? 'Update your review' : 'Rate this book',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.bookTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            _buildStars(),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                ratingLabel,
                key: ValueKey(ratingLabel),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildReviewField(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorBanner(),
            ],
            const SizedBox(height: 24),
            _buildSubmitButton(isEditing: isEditing),
            if (isEditing) ...[
              const SizedBox(height: 8),
              _buildDeleteButton(),
            ],
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final starIndex = i + 1;
        final filled = _rating >= starIndex;
        final half = !filled && _rating >= starIndex - 0.5;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onTapStar(starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              filled
                  ? Icons.star_rounded
                  : half
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded,
              size: 44,
              color: (filled || half) ? AppColors.gold : AppColors.textLight,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildReviewField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Write a review',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(optional)',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGrey.withOpacity(0.9),
              ),
            ),
            const Spacer(),
            Text(
              '${_textController.text.length}/$_maxTextLength',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          maxLength: _maxTextLength,
          maxLines: 4,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText:
                'Share what stood out — characters, pacing, ideas you took away…',
            hintStyle:
                const TextStyle(fontSize: 13, color: AppColors.textGrey),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.6),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textDark,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    const color = AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: const TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton({required bool isEditing}) {
    return ElevatedButton(
      onPressed: _canSubmit ? _submit : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.divider,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _submitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          : Text(
              isEditing ? 'Update Review' : 'Submit Review',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    );
  }

  Widget _buildDeleteButton() {
    return TextButton(
      onPressed: _deleting || _submitting ? null : _delete,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.error,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: _deleting
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.error,
              ),
            )
          : const Text(
              'Remove my review',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
    );
  }

  String _ratingLabel(double rating) {
    if (rating <= 0) return 'Tap a star to rate';
    if (rating <= 1.0) return 'Hated it';
    if (rating <= 2.0) return 'Disliked it';
    if (rating <= 3.0) return 'It was okay';
    if (rating <= 4.0) return 'Liked it';
    return 'Loved it';
  }
}
