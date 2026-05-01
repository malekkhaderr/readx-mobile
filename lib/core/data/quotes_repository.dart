/// Central quotes data source — in-memory mock for now.
/// Swap with: `await dio.post('/quotes')` / `await dio.get('/quotes')` when backend is ready.

class SavedQuote {
  final String id;
  final String text;
  final String bookId;
  final String bookTitle;
  final String coverUrl;
  final String author;
  final String chapterTitle;
  final int chapterNumber;
  final DateTime savedAt;

  const SavedQuote({
    required this.id,
    required this.text,
    required this.bookId,
    required this.bookTitle,
    required this.coverUrl,
    required this.author,
    required this.chapterTitle,
    required this.chapterNumber,
    required this.savedAt,
  });
}

class QuotesRepository {
  static final List<SavedQuote> _quotes = [
    // Pre-seeded quotes so the page isn't empty on first visit
    SavedQuote(
      id: 'q1',
      text: '"In the silence of the archive, the truth finds its voice."',
      bookId: '1',
      bookTitle: 'The Midnight Library',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780525559474-L.jpg',
      author: 'Matt Haig',
      chapterTitle: 'Chapter 14: The Whispering Gallery',
      chapterNumber: 14,
      savedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    SavedQuote(
      id: 'q2',
      text: '"Every book is a door, and every reader holds the key."',
      bookId: '1',
      bookTitle: 'The Midnight Library',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780525559474-L.jpg',
      author: 'Matt Haig',
      chapterTitle: 'Chapter 14: The Whispering Gallery',
      chapterNumber: 14,
      savedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    SavedQuote(
      id: 'q3',
      text: '"Every story has its turning point. This was theirs."',
      bookId: '6',
      bookTitle: 'Dune',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780441172719-L.jpg',
      author: 'Frank Herbert',
      chapterTitle: 'Chapter 5: Into the Unknown',
      chapterNumber: 5,
      savedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static int _nextId = 4;

  /// Swap this with: `final response = await dio.get('/quotes');`
  static List<SavedQuote> getAllQuotes() => List.from(_quotes);

  /// Swap this with: `final response = await dio.get('/quotes?bookId=$bookId');`
  static List<SavedQuote> getQuotesByBook(String bookId) {
    return _quotes.where((q) => q.bookId == bookId).toList();
  }

  /// Swap this with: `final response = await dio.post('/quotes', data: {...});`
  static SavedQuote addQuote({
    required String text,
    required String bookId,
    required String bookTitle,
    required String coverUrl,
    required String author,
    required String chapterTitle,
    required int chapterNumber,
  }) {
    final quote = SavedQuote(
      id: 'q${_nextId++}',
      text: text,
      bookId: bookId,
      bookTitle: bookTitle,
      coverUrl: coverUrl,
      author: author,
      chapterTitle: chapterTitle,
      chapterNumber: chapterNumber,
      savedAt: DateTime.now(),
    );
    _quotes.insert(0, quote);
    return quote;
  }

  /// Swap this with: `await dio.delete('/quotes/$id');`
  static bool removeQuote(String id) {
    final idx = _quotes.indexWhere((q) => q.id == id);
    if (idx != -1) {
      _quotes.removeAt(idx);
      return true;
    }
    return false;
  }

  static int get count => _quotes.length;
}
