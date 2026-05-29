import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_theme.dart';
import '../data/curated_quotes.dart';
import '../data/splash_bookmarks.dart';
import '../di/injection_container.dart';
import '../network/dio_client.dart';

class DailyQuoteSplash {
  static const _lastShownKey = 'daily_quote_last_shown';

  static Future<bool> shouldShow() async {
    final prefs = sl<SharedPreferences>();
    final lastShown = prefs.getString(_lastShownKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return lastShown != today;
  }

  static Future<void> markShown() async {
    final prefs = sl<SharedPreferences>();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_lastShownKey, today);
  }

  static Future<Map<String, String>> getQuote() async {
    final rng = Random();

    // Get reader's bookmarked quotes (saved locally)
    final bookmarked = await SplashBookmarks.getAll();

    // If reader has bookmarked quotes: 60% chance bookmarked, 40% curated
    // If no bookmarks: always curated
    if (bookmarked.isNotEmpty && rng.nextDouble() < 0.6) {
      final picked = bookmarked[rng.nextInt(bookmarked.length)];
      return {
        'text': picked.text,
        'author': picked.readerName,
        'book': picked.bookTitle,
      };
    }

    // Curated quote
    final curated = curatedQuotes[rng.nextInt(curatedQuotes.length)];
    return {'text': curated.text, 'author': curated.author, 'book': curated.book};
  }

  static Future<void> show(BuildContext context) async {
    final quote = await getQuote();
    if (quote['text']!.isEmpty) return;
    if (!context.mounted) return;

    await markShown();

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'quote',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, __) => _QuoteSplashDialog(
        text: quote['text']!,
        author: quote['author']!,
        book: quote['book']!,
      ),
    );
  }

  /// Test mode — shows a specific curated quote by index
  static Future<void> showByIndex(BuildContext context, int index) async {
    final quote = curatedQuotes[index % curatedQuotes.length];
    if (!context.mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'quote',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, __) => _QuoteSplashDialog(
        text: quote.text,
        author: quote.author,
        book: quote.book,
        testIndex: index,
        testTotal: curatedQuotes.length,
      ),
    );
  }
}

class _QuoteSplashDialog extends StatelessWidget {
  final String text;
  final String author;
  final String book;
  final int? testIndex;
  final int? testTotal;

  const _QuoteSplashDialog({
    required this.text,
    required this.author,
    required this.book,
    this.testIndex,
    this.testTotal,
  });

  bool get _isArabic => text.contains(RegExp(r'[؀-ۿ]'));

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 30, spreadRadius: 2),
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Owl peek + quote icon
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Icon(Icons.format_quote_rounded, size: 28, color: AppColors.primary.withOpacity(0.3)),
                Image.asset('assets/images/owl.png', width: 36, height: 36, fit: BoxFit.contain),
              ]),
              const SizedBox(height: 16),
              // Quote text — Arabic gets RTL + larger + bolder
              Directionality(
                textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _isArabic ? 21 : 16,
                    fontStyle: _isArabic ? FontStyle.normal : FontStyle.italic,
                    fontFamily: _isArabic ? null : 'Georgia',
                    color: AppColors.textDark,
                    height: _isArabic ? 1.9 : 1.6,
                    fontWeight: _isArabic ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Divider
              Container(width: 40, height: 2, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.3), borderRadius: BorderRadius.circular(1))),
              const SizedBox(height: 14),
              // Author + book — RTL for Arabic
              if (author.isNotEmpty)
                Directionality(
                  textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
                  child: Text(_isArabic ? author : '— $author', style: TextStyle(fontSize: _isArabic ? 13 : 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                ),
              if (book.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Directionality(
                    textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
                    child: Text(book, style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                  ),
                ),
              const SizedBox(height: 20),
              // Dismiss hint
              Text('Tap anywhere to dismiss', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
              // Test info
              if (testIndex != null) ...[
                const SizedBox(height: 8),
                Text('${testIndex! + 1} / $testTotal', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
