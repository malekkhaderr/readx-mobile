/// Central book data source — structured to match a REST API response.
/// Replace the static lists with API calls when ready.
///
/// Usage:
///   final books = BookRepository.getAllBooks();
///   final book = BookRepository.getBookById('1');
///   final chapters = BookRepository.getChapters('1');

import 'package:shared_preferences/shared_preferences.dart';

typedef _VoidCb = void Function();

class BookModel {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final String genre;
  final String description;
  final double rating;
  final int totalPages;
  final int readPages;
  final int currentChapter;
  final int totalChapters;
  final bool isInLibrary;
  final bool isBookmarked;
  final DateTime? lastReadAt;

  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.genre,
    this.description = '',
    this.rating = 4.5,
    this.totalPages = 300,
    this.readPages = 0,
    this.currentChapter = 1,
    this.totalChapters = 20,
    this.isInLibrary = false,
    this.isBookmarked = false,
    this.lastReadAt,
  });

  double get progress => totalPages > 0 ? (readPages / totalPages).clamp(0.0, 1.0) : 0.0;

  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? coverUrl,
    String? genre,
    String? description,
    double? rating,
    int? totalPages,
    int? readPages,
    int? currentChapter,
    int? totalChapters,
    bool? isInLibrary,
    bool? isBookmarked,
    DateTime? lastReadAt,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      genre: genre ?? this.genre,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      totalPages: totalPages ?? this.totalPages,
      readPages: readPages ?? this.readPages,
      currentChapter: currentChapter ?? this.currentChapter,
      totalChapters: totalChapters ?? this.totalChapters,
      isInLibrary: isInLibrary ?? this.isInLibrary,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }
}

class ChapterModel {
  final String bookId;
  final int chapterNumber;
  final String title;
  final List<ContentBlock> blocks;

  const ChapterModel({
    required this.bookId,
    required this.chapterNumber,
    required this.title,
    required this.blocks,
  });
}

enum ContentBlockType { paragraph, quote, heading }

class ContentBlock {
  final ContentBlockType type;
  final String text;
  final bool hasDropCap;

  const ContentBlock({
    required this.type,
    required this.text,
    this.hasDropCap = false,
  });
}

// ── Book Repository (swap with API later) ───────────────────
class BookRepository {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    for (int i = 0; i < _books.length; i++) {
      final b = _books[i];
      final savedChapter = _prefs.getInt('book_${b.id}_chapter');
      final savedReadPages = _prefs.getInt('book_${b.id}_readPages');
      final savedLastReadStr = _prefs.getString('book_${b.id}_lastRead');
      
      if (savedChapter != null || savedReadPages != null) {
        _books[i] = b.copyWith(
          currentChapter: savedChapter ?? b.currentChapter,
          readPages: savedReadPages ?? b.readPages,
          lastReadAt: savedLastReadStr != null ? DateTime.tryParse(savedLastReadStr) : b.lastReadAt,
        );
      }
    }
  }

  static Future<void> updateProgress(String bookId, int currentChapter, int readPages) async {
    final idx = _books.indexWhere((b) => b.id == bookId);
    if (idx == -1) return;
    
    final b = _books[idx];
    final lastRead = DateTime.now();
    // Only allow readPages to grow, so they don't lose progress if they revisit chapters
    final maxReadPages = readPages > b.readPages ? readPages : b.readPages;

    _books[idx] = b.copyWith(
      currentChapter: currentChapter,
      readPages: maxReadPages,
      lastReadAt: lastRead,
    );
    
    await _prefs.setInt('book_${bookId}_chapter', currentChapter);
    await _prefs.setInt('book_${bookId}_readPages', maxReadPages);
    await _prefs.setString('book_${bookId}_lastRead', lastRead.toIso8601String());
    
    _notifyListeners();
  }

  static final List<BookModel> _books = [
    BookModel(
      id: '1',
      title: 'The Midnight Library',
      author: 'Matt Haig',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780525559474-L.jpg',
      genre: 'Fiction',
      description: 'Between life and death there is a library that contains infinite books, each telling a different version of your life.',
      rating: 4.7,
      totalPages: 304,
      readPages: 198,
      currentChapter: 14,
      totalChapters: 22,
      isInLibrary: true,
      lastReadAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    BookModel(
      id: '2',
      title: 'Circe',
      author: 'Madeline Miller',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780316556347-L.jpg',
      genre: 'Mythology',
      description: 'In the house of Helios, god of the sun, a daughter is born. Circe is a strange child, not powerful like her father.',
      rating: 4.6,
      totalPages: 385,
      readPages: 120,
      currentChapter: 8,
      totalChapters: 27,
      isInLibrary: true,
      lastReadAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    BookModel(
      id: '3',
      title: 'Project Hail Mary',
      author: 'Andy Weir',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780593135204-L.jpg',
      genre: 'Sci-Fi',
      description: 'Ryland Grace is the sole survivor on a desperate, last-chance mission to save Earth from extinction.',
      rating: 4.8,
      totalPages: 476,
      readPages: 0,
      currentChapter: 1,
      totalChapters: 30,
      isInLibrary: true,
    ),
    BookModel(
      id: '4',
      title: 'Klara and the Sun',
      author: 'Kazuo Ishiguro',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780593318171-L.jpg',
      genre: 'Literary',
      description: 'A thrilling book that offers a look at our changing world through the eyes of an unforgettable narrator.',
      rating: 4.3,
      totalPages: 307,
      readPages: 307,
      currentChapter: 20,
      totalChapters: 20,
      isInLibrary: true,
      lastReadAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    BookModel(
      id: '5',
      title: 'The Song of Achilles',
      author: 'Madeline Miller',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780062060624-L.jpg',
      genre: 'Mythology',
      description: 'A tale of gods, kings, immortal fame, and the human heart. The story of Achilles and Patroclus.',
      rating: 4.7,
      totalPages: 352,
      readPages: 0,
      currentChapter: 1,
      totalChapters: 25,
      isInLibrary: false,
    ),
    BookModel(
      id: '6',
      title: 'Dune',
      author: 'Frank Herbert',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780441172719-L.jpg',
      genre: 'Sci-Fi',
      description: 'Set on the desert planet Arrakis, the story follows Paul Atreides, whose family accepts control of the spice melange.',
      rating: 4.6,
      totalPages: 412,
      readPages: 82,
      currentChapter: 5,
      totalChapters: 28,
      isInLibrary: true,
      lastReadAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    BookModel(
      id: '7',
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780743273565-L.jpg',
      genre: 'Classic',
      description: 'A portrait of the Jazz Age in all of its decadence and excess, and a cautionary tale of the American Dream.',
      rating: 4.4,
      totalPages: 180,
      readPages: 180,
      currentChapter: 12,
      totalChapters: 12,
      isInLibrary: true,
      lastReadAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    BookModel(
      id: '8',
      title: 'Atomic Habits',
      author: 'James Clear',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780735211292-L.jpg',
      genre: 'Self-Help',
      description: 'Tiny changes, remarkable results. A proven framework for improving every day.',
      rating: 4.8,
      totalPages: 320,
      readPages: 160,
      currentChapter: 10,
      totalChapters: 20,
      isInLibrary: true,
      lastReadAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    BookModel(
      id: '9',
      title: 'Norwegian Wood',
      author: 'Haruki Murakami',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780375704024-L.jpg',
      genre: 'Literary',
      description: 'A nostalgic story of loss and sexuality set in Tokyo during the late 1960s.',
      rating: 4.2,
      totalPages: 296,
      readPages: 0,
      currentChapter: 1,
      totalChapters: 18,
      isInLibrary: false,
    ),
    BookModel(
      id: '10',
      title: 'The Alchemist',
      author: 'Paulo Coelho',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780061122415-L.jpg',
      genre: 'Fiction',
      description: 'A magical fable about following your dream, from the world\'s most-read living author.',
      rating: 4.5,
      totalPages: 208,
      readPages: 0,
      currentChapter: 1,
      totalChapters: 15,
      isInLibrary: false,
    ),
    BookModel(
      id: '11',
      title: 'Sapiens',
      author: 'Yuval Noah Harari',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780062316097-L.jpg',
      genre: 'Non-Fiction',
      description: 'A brief history of humankind exploring how Homo sapiens came to dominate the world.',
      rating: 4.6,
      totalPages: 443,
      readPages: 221,
      currentChapter: 12,
      totalChapters: 24,
      isInLibrary: true,
      lastReadAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    BookModel(
      id: '12',
      title: '1984',
      author: 'George Orwell',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780451524935-L.jpg',
      genre: 'Classic',
      description: 'A dystopian social science fiction novel set in a totalitarian society ruled by Big Brother.',
      rating: 4.7,
      totalPages: 328,
      readPages: 328,
      currentChapter: 23,
      totalChapters: 23,
      isInLibrary: true,
      lastReadAt: DateTime.now().subtract(const Duration(days: 21)),
    ),
  ];

  /// Swap this with: `final response = await dio.get('/books');`
  static List<BookModel> getAllBooks() => List.from(_books);

  /// Swap this with: `final response = await dio.get('/books/$id');`
  static BookModel? getBookById(String id) {
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Swap this with: `final response = await dio.get('/books?genre=$genre');`
  static List<BookModel> getBooksByGenre(String genre) {
    if (genre == 'All') return getAllBooks();
    return _books.where((b) => b.genre == genre).toList();
  }

  /// Swap this with: `final response = await dio.get('/books?inLibrary=true');`
  static List<BookModel> getLibraryBooks() {
    return _books.where((b) => b.isInLibrary).toList();
  }

  /// Swap this with: `final response = await dio.get('/books?query=$query');`
  static List<BookModel> searchBooks(String query) {
    final q = query.toLowerCase();
    return _books.where((b) =>
        b.title.toLowerCase().contains(q) ||
        b.author.toLowerCase().contains(q) ||
        b.genre.toLowerCase().contains(q)).toList();
  }

  /// Swap this with: `final response = await dio.get('/books/recommended');`
  static List<BookModel> getRecommended() {
    return _books.where((b) => !b.isInLibrary || b.readPages == 0).take(5).toList();
  }

  /// Swap this with: `final response = await dio.get('/books/current');`
  static BookModel? getCurrentRead() {
    final reading = _books.where((b) => b.isInLibrary && b.readPages > 0 && b.progress < 1.0).toList();
    if (reading.isEmpty) return null;
    reading.sort((a, b) => (b.lastReadAt ?? DateTime(2000)).compareTo(a.lastReadAt ?? DateTime(2000)));
    return reading.first;
  }

  static List<String> getAllGenres() {
    final genres = _books.map((b) => b.genre).toSet().toList();
    genres.sort();
    return ['All', ...genres];
  }

  static int getCompletedBooksCount() {
    return _books.where((b) => b.progress >= 1.0).length;
  }

  /// Get completed books (for profile display)
  /// Swap this with: `final response = await dio.get('/books?completed=true');`
  static List<BookModel> getCompletedBooks() {
    return _books.where((b) => b.progress >= 1.0 && b.isInLibrary).toList();
  }

  /// Get books NOT in library (for "Add Book" browse)
  /// Swap this with: `final response = await dio.get('/books/browse');`
  static List<BookModel> getAvailableBooks() {
    return _books.where((b) => !b.isInLibrary).toList();
  }

  /// Swap this with: `await dio.post('/library/add', data: {'bookId': id});`
  static bool addToLibrary(String id) {
    final idx = _books.indexWhere((b) => b.id == id);
    if (idx == -1) return false;
    _books[idx] = _books[idx].copyWith(isInLibrary: true);
    _notifyListeners();
    return true;
  }

  /// Swap this with: `await dio.delete('/library/$id');`
  static bool removeFromLibrary(String id) {
    final idx = _books.indexWhere((b) => b.id == id);
    if (idx == -1) return false;
    _books[idx] = _books[idx].copyWith(isInLibrary: false);
    _notifyListeners();
    return true;
  }

  // ── Simple listener system for cross-widget rebuilds ──────
  static final List<_VoidCb> _listeners = [];
  static void addListener(_VoidCb listener) => _listeners.add(listener);
  static void removeListener(_VoidCb listener) => _listeners.remove(listener);
  static void _notifyListeners() {
    for (final l in _listeners) {
      l();
    }
  }
}

// ── Chapter Repository (swap with API later) ────────────────
class ChapterRepository {
  static final Map<String, List<ChapterModel>> _chapters = {
    '1': _generateChapters('1', 'The Midnight Library', 22),
    '2': _generateChapters('2', 'Circe', 27),
    '3': _generateChapters('3', 'Project Hail Mary', 30),
    '4': _generateChapters('4', 'Klara and the Sun', 20),
    '5': _generateChapters('5', 'The Song of Achilles', 25),
    '6': _generateChapters('6', 'Dune', 28),
    '7': _generateChapters('7', 'The Great Gatsby', 12),
    '8': _generateChapters('8', 'Atomic Habits', 20),
    '9': _generateChapters('9', 'Norwegian Wood', 18),
    '10': _generateChapters('10', 'The Alchemist', 15),
    '11': _generateChapters('11', 'Sapiens', 24),
    '12': _generateChapters('12', '1984', 23),
  };

  // Full content for first book's chapter 14 (the current read)
  static final ChapterModel _midnightLibraryCh14 = ChapterModel(
    bookId: '1',
    chapterNumber: 14,
    title: 'Chapter 14: The Whispering Gallery',
    blocks: const [
      ContentBlock(
        type: ContentBlockType.paragraph,
        hasDropCap: true,
        text:
            'he air in the gallery was thick with the scent of old parchment and beeswax. Lyra stepped softly, her eyes tracing the intricate patterns of gold leaf that adorned the vaulted ceiling. Every footstep echoed like a whispered memory against the polished marble floor.',
      ),
      ContentBlock(
        type: ContentBlockType.quote,
        text:
            '"In the silence of the archive, the truth finds its voice." The Master had told her. Now, standing before the Great Seal, she finally understood what he meant.',
      ),
      ContentBlock(
        type: ContentBlockType.paragraph,
        text:
            'She reached out a trembling hand, her fingers hovering just inches from the ancient stonework. It pulsed with a faint, rhythmic warmth, a heartbeat of magic that had survived centuries of neglect. Outside, the storm raged, but here, within the heart of the Citadel, there was only the steady hum of history waiting to be rediscovered.',
      ),
      ContentBlock(
        type: ContentBlockType.paragraph,
        text:
            'With a soft click that resonated through her very bones, the seal began to rotate. Light, pure and silver as moonlight, bled from the seams, illuminating the dusty corners of the room. Lyra held her breath. The game was no longer a game; the story was writing itself through her very actions.',
      ),
      ContentBlock(
        type: ContentBlockType.paragraph,
        text:
            'The shelves stretched infinitely in every direction, each one laden with books that seemed to breathe with their own inner light. Some pulsed gently with warm amber, others glowed with a cool, ethereal blue. Lyra understood, in that moment, that each book contained not just words, but entire lifetimes.',
      ),
      ContentBlock(
        type: ContentBlockType.quote,
        text:
            '"Every book is a door," she whispered to herself, recalling the first lesson her grandmother had taught her. "And every reader holds the key."',
      ),
      ContentBlock(
        type: ContentBlockType.paragraph,
        text:
            'She chose a volume bound in deep burgundy leather, its spine embossed with characters she could not read but somehow understood. As her fingertips brushed the cover, the library seemed to sigh, a long-held breath finally released. The pages fell open, and Lyra began to read the story that had been waiting for her all along.',
      ),
    ],
  );

  /// Swap this with: `final response = await dio.get('/books/$bookId/chapters/$num');`
  static ChapterModel? getChapter(String bookId, int chapterNumber) {
    if (bookId == '1' && chapterNumber == 14) {
      return _midnightLibraryCh14;
    }
    final bookChapters = _chapters[bookId];
    if (bookChapters == null) return null;
    try {
      return bookChapters.firstWhere((c) => c.chapterNumber == chapterNumber);
    } catch (_) {
      return null;
    }
  }

  /// Swap this with: `final response = await dio.get('/books/$bookId/chapters');`
  static List<ChapterModel> getChaptersForBook(String bookId) {
    return _chapters[bookId] ?? [];
  }

  static List<ChapterModel> _generateChapters(String bookId, String bookTitle, int count) {
    final chapterNames = [
      'The Beginning', 'A New Dawn', 'Shadows and Light', 'The Hidden Path',
      'Crossroads', 'Into the Unknown', 'The Gathering Storm', 'Revelations',
      'The Test', 'Breaking Point', 'Echoes of the Past', 'The Turning Tide',
      'A Fragile Alliance', 'The Whispering Gallery', 'Beneath the Surface',
      'The Price of Truth', 'Convergence', 'The Final Stand', 'Aftermath',
      'New Horizons', 'The Last Chapter', 'Epilogue', 'The Return',
      'Uncharted Waters', 'The Reckoning', 'Beyond the Veil', 'Redemption',
      'The Circle Closes', 'A World Renewed', 'The End of All Things',
    ];

    final paragraphs = [
      'The morning light filtered through the tall windows, casting long golden rectangles across the wooden floor. Dust motes danced in the shafts of light like tiny galaxies spinning in slow motion. Everything felt suspended, timeless, as though the world outside had simply ceased to exist.',
      'She paused at the threshold, one hand resting on the cool stone of the doorframe. The corridor beyond stretched into shadow, lit only by the occasional flicker of a wall sconce. The air smelled of old wood and something else—something sharp and electric, like the moment before a storm.',
      'The pages of the journal were brittle with age, their edges crumbling at the slightest touch. But the ink was still sharp, still bold, as though the words had been written yesterday rather than a century ago. Each sentence revealed another layer of a truth long buried.',
      'Rain hammered against the windows with a ferocity that made the glass shudder in its frames. Inside, the fire crackled and popped, sending small showers of sparks up the chimney. The contrast between the wild world outside and the warm sanctuary within felt almost theatrical.',
      'He closed the book slowly, carefully, as though it contained something fragile that might shatter with too much force. For a long moment he sat perfectly still, his eyes focused on something far beyond the walls of the room, seeing a landscape that existed only in his memory.',
    ];

    return List.generate(count, (i) {
      final chIndex = i % chapterNames.length;
      return ChapterModel(
        bookId: bookId,
        chapterNumber: i + 1,
        title: 'Chapter ${i + 1}: ${chapterNames[chIndex]}',
        blocks: [
          ContentBlock(
            type: ContentBlockType.paragraph,
            hasDropCap: true,
            text: paragraphs[i % paragraphs.length],
          ),
          ContentBlock(
            type: ContentBlockType.quote,
            text: '"Every story has its turning point. This was theirs." — The Narrator',
          ),
          ContentBlock(
            type: ContentBlockType.paragraph,
            text: paragraphs[(i + 1) % paragraphs.length],
          ),
          ContentBlock(
            type: ContentBlockType.paragraph,
            text: paragraphs[(i + 2) % paragraphs.length],
          ),
          ContentBlock(
            type: ContentBlockType.quote,
            text: '"Sometimes the only way forward is to look back and understand where you have been."',
          ),
          ContentBlock(
            type: ContentBlockType.paragraph,
            text: paragraphs[(i + 3) % paragraphs.length],
          ),
        ],
      );
    });
  }
}
