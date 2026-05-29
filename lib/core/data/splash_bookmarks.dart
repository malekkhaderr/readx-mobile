import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../di/injection_container.dart';

class SplashQuote {
  final String text;
  final String bookTitle;
  final String readerName;

  const SplashQuote({required this.text, required this.bookTitle, this.readerName = ''});

  Map<String, dynamic> toJson() => {'text': text, 'bookTitle': bookTitle, 'readerName': readerName};
  factory SplashQuote.fromJson(Map<String, dynamic> json) => SplashQuote(
    text: json['text'] as String? ?? '',
    bookTitle: json['bookTitle'] as String? ?? '',
    readerName: json['readerName'] as String? ?? '',
  );
}

class SplashBookmarks {
  static const _key = 'splash_bookmarked_quotes';

  static List<SplashQuote> _cache = [];
  static bool _loaded = false;

  static Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = sl<SharedPreferences>();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final List<dynamic> decoded = json.decode(raw);
      _cache = decoded.map((e) => SplashQuote.fromJson(e as Map<String, dynamic>)).toList();
    }
    _loaded = true;
  }

  static Future<void> _save() async {
    final prefs = sl<SharedPreferences>();
    await prefs.setString(_key, json.encode(_cache.map((e) => e.toJson()).toList()));
  }

  static Future<List<SplashQuote>> getAll() async {
    await _ensureLoaded();
    return _cache;
  }

  static Future<bool> isBookmarked(String text) async {
    await _ensureLoaded();
    return _cache.any((q) => q.text == text);
  }

  static Future<void> toggle(String text, String bookTitle, {String readerName = ''}) async {
    await _ensureLoaded();
    final exists = _cache.any((q) => q.text == text);
    if (exists) {
      _cache.removeWhere((q) => q.text == text);
    } else {
      _cache.add(SplashQuote(text: text, bookTitle: bookTitle, readerName: readerName));
    }
    await _save();
  }

  static Future<void> add(String text, String bookTitle, {String readerName = ''}) async {
    await _ensureLoaded();
    if (!_cache.any((q) => q.text == text)) {
      _cache.add(SplashQuote(text: text, bookTitle: bookTitle, readerName: readerName));
      await _save();
    }
  }

  static Future<void> remove(String text) async {
    await _ensureLoaded();
    _cache.removeWhere((q) => q.text == text);
    await _save();
  }
}
