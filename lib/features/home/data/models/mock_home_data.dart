class MockBook {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final double progress;
  final int currentChapter;
  final int totalChapters;
  final String genre;

  const MockBook({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    this.progress = 0.0,
    this.currentChapter = 1,
    this.totalChapters = 20,
    this.genre = 'Fiction',
  });
}

class MockReadingProgress {
  final int dailyGoalMinutes;
  final int minutesReadToday;
  final int streakDays;
  final int booksRead;
  final int goalReachedDays;
  final int totalGoalDays;

  const MockReadingProgress({
    this.dailyGoalMinutes = 30,
    this.minutesReadToday = 13,
    this.streakDays = 15,
    this.booksRead = 12,
    this.goalReachedDays = 5,
    this.totalGoalDays = 7,
  });

  double get dailyProgressPercent =>
      (minutesReadToday / dailyGoalMinutes).clamp(0.0, 1.0);
}

class MockHomeData {
  static const readingProgress = MockReadingProgress();

  static const currentRead = MockBook(
    id: '1',
    title: 'The Midnight Library',
    author: 'Matt Haig',
    coverUrl: 'https://covers.openlibrary.org/b/isbn/9780525559474-L.jpg',
    progress: 0.65,
    currentChapter: 14,
    totalChapters: 22,
    genre: 'Fiction',
  );

  static const List<MockBook> pickedForYou = [
    MockBook(
      id: '2',
      title: 'Circe',
      author: 'Madeline Miller',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780316556347-L.jpg',
      genre: 'Mythology',
    ),
    MockBook(
      id: '3',
      title: 'Project Hail Mary',
      author: 'Andy Weir',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780593135204-L.jpg',
      genre: 'Sci-Fi',
    ),
    MockBook(
      id: '4',
      title: 'Klara and the Sun',
      author: 'Kazuo Ishiguro',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780593318171-L.jpg',
      genre: 'Literary',
    ),
    MockBook(
      id: '5',
      title: 'The Song of Achilles',
      author: 'Madeline Miller',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780062060624-L.jpg',
      genre: 'Mythology',
    ),
  ];

  static const String dailyTip =
      'Reading for just 15 minutes before bed can improve your sleep quality by 68%. Try a chapter tonight!';
}
