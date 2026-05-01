/// Reading history data source — tracks daily sessions and activities.
/// Swap with API calls when backend is ready.

class ReadingSession {
  final String id;
  final String bookTitle;
  final String coverUrl;
  final int minutesRead;
  final int pagesRead;
  final int chaptersRead;
  final DateTime date;

  const ReadingSession({
    required this.id,
    required this.bookTitle,
    required this.coverUrl,
    required this.minutesRead,
    required this.pagesRead,
    required this.chaptersRead,
    required this.date,
  });
}

class DailyReadingSummary {
  final DateTime date;
  final int totalMinutes;
  final int sessions;
  final bool goalReached;
  final List<ReadingSession> sessionDetails;

  const DailyReadingSummary({
    required this.date,
    required this.totalMinutes,
    required this.sessions,
    required this.goalReached,
    this.sessionDetails = const [],
  });
}

class ReadingHistoryRepository {
  /// Swap this with: `final response = await dio.get('/reading/history');`
  static List<DailyReadingSummary> getHistory() {
    final now = DateTime.now();
    return [
      DailyReadingSummary(
        date: now,
        totalMinutes: 13,
        sessions: 1,
        goalReached: false,
        sessionDetails: [
          ReadingSession(id: 's1', bookTitle: 'The Midnight Library', coverUrl: 'https://covers.openlibrary.org/b/isbn/9780525559474-L.jpg', minutesRead: 13, pagesRead: 8, chaptersRead: 0, date: now),
        ],
      ),
      DailyReadingSummary(
        date: now.subtract(const Duration(days: 1)),
        totalMinutes: 42,
        sessions: 2,
        goalReached: true,
        sessionDetails: [
          ReadingSession(id: 's2', bookTitle: 'The Midnight Library', coverUrl: 'https://covers.openlibrary.org/b/isbn/9780525559474-L.jpg', minutesRead: 25, pagesRead: 14, chaptersRead: 1, date: now.subtract(const Duration(days: 1))),
          ReadingSession(id: 's3', bookTitle: 'Dune', coverUrl: 'https://covers.openlibrary.org/b/isbn/9780441172719-L.jpg', minutesRead: 17, pagesRead: 10, chaptersRead: 0, date: now.subtract(const Duration(days: 1))),
        ],
      ),
      DailyReadingSummary(
        date: now.subtract(const Duration(days: 2)),
        totalMinutes: 35,
        sessions: 1,
        goalReached: true,
        sessionDetails: [
          ReadingSession(id: 's4', bookTitle: 'Atomic Habits', coverUrl: 'https://covers.openlibrary.org/b/isbn/9780735211292-L.jpg', minutesRead: 35, pagesRead: 20, chaptersRead: 1, date: now.subtract(const Duration(days: 2))),
        ],
      ),
      DailyReadingSummary(
        date: now.subtract(const Duration(days: 3)),
        totalMinutes: 28,
        sessions: 1,
        goalReached: false,
        sessionDetails: [
          ReadingSession(id: 's5', bookTitle: 'Circe', coverUrl: 'https://covers.openlibrary.org/b/isbn/9780316556347-L.jpg', minutesRead: 28, pagesRead: 16, chaptersRead: 1, date: now.subtract(const Duration(days: 3))),
        ],
      ),
      DailyReadingSummary(
        date: now.subtract(const Duration(days: 4)),
        totalMinutes: 45,
        sessions: 2,
        goalReached: true,
        sessionDetails: [
          ReadingSession(id: 's6', bookTitle: 'Sapiens', coverUrl: 'https://covers.openlibrary.org/b/isbn/9780062316097-L.jpg', minutesRead: 30, pagesRead: 18, chaptersRead: 1, date: now.subtract(const Duration(days: 4))),
          ReadingSession(id: 's7', bookTitle: 'The Midnight Library', coverUrl: 'https://covers.openlibrary.org/b/isbn/9780525559474-L.jpg', minutesRead: 15, pagesRead: 9, chaptersRead: 0, date: now.subtract(const Duration(days: 4))),
        ],
      ),
      DailyReadingSummary(
        date: now.subtract(const Duration(days: 5)),
        totalMinutes: 55,
        sessions: 3,
        goalReached: true,
        sessionDetails: [
          ReadingSession(id: 's8', bookTitle: 'Dune', coverUrl: 'https://covers.openlibrary.org/b/isbn/9780441172719-L.jpg', minutesRead: 20, pagesRead: 12, chaptersRead: 1, date: now.subtract(const Duration(days: 5))),
          ReadingSession(id: 's9', bookTitle: 'Atomic Habits', coverUrl: 'https://covers.openlibrary.org/b/isbn/9780735211292-L.jpg', minutesRead: 20, pagesRead: 12, chaptersRead: 0, date: now.subtract(const Duration(days: 5))),
          ReadingSession(id: 's10', bookTitle: 'The Great Gatsby', coverUrl: 'https://covers.openlibrary.org/b/isbn/9780743273565-L.jpg', minutesRead: 15, pagesRead: 10, chaptersRead: 1, date: now.subtract(const Duration(days: 5))),
        ],
      ),
      DailyReadingSummary(
        date: now.subtract(const Duration(days: 6)),
        totalMinutes: 30,
        sessions: 1,
        goalReached: true,
        sessionDetails: [
          ReadingSession(id: 's11', bookTitle: 'The Midnight Library', coverUrl: 'https://covers.openlibrary.org/b/isbn/9780525559474-L.jpg', minutesRead: 30, pagesRead: 17, chaptersRead: 1, date: now.subtract(const Duration(days: 6))),
        ],
      ),
      DailyReadingSummary(
        date: now.subtract(const Duration(days: 7)),
        totalMinutes: 38,
        sessions: 1,
        goalReached: true,
        sessionDetails: [
          ReadingSession(id: 's12', bookTitle: '1984', coverUrl: 'https://covers.openlibrary.org/b/isbn/9780451524935-L.jpg', minutesRead: 38, pagesRead: 22, chaptersRead: 2, date: now.subtract(const Duration(days: 7))),
        ],
      ),
      DailyReadingSummary(date: now.subtract(const Duration(days: 8)), totalMinutes: 0, sessions: 0, goalReached: false),
      DailyReadingSummary(
        date: now.subtract(const Duration(days: 9)),
        totalMinutes: 52,
        sessions: 2,
        goalReached: true,
        sessionDetails: [
          ReadingSession(id: 's13', bookTitle: '1984', coverUrl: 'https://covers.openlibrary.org/b/isbn/9780451524935-L.jpg', minutesRead: 32, pagesRead: 18, chaptersRead: 1, date: now.subtract(const Duration(days: 9))),
          ReadingSession(id: 's14', bookTitle: 'Sapiens', coverUrl: 'https://covers.openlibrary.org/b/isbn/9780062316097-L.jpg', minutesRead: 20, pagesRead: 12, chaptersRead: 0, date: now.subtract(const Duration(days: 9))),
        ],
      ),
      DailyReadingSummary(
        date: now.subtract(const Duration(days: 10)),
        totalMinutes: 33,
        sessions: 1,
        goalReached: true,
        sessionDetails: [
          ReadingSession(id: 's15', bookTitle: 'The Great Gatsby', coverUrl: 'https://covers.openlibrary.org/b/isbn/9780743273565-L.jpg', minutesRead: 33, pagesRead: 20, chaptersRead: 2, date: now.subtract(const Duration(days: 10))),
        ],
      ),
    ];
  }

  /// Swap this with: `final response = await dio.get('/reading/stats');`
  static Map<String, dynamic> getStats() {
    final history = getHistory();
    final totalMinutes = history.fold<int>(0, (sum, d) => sum + d.totalMinutes);
    final totalSessions = history.fold<int>(0, (sum, d) => sum + d.sessions);
    final goalsReached = history.where((d) => d.goalReached).length;
    final activeDays = history.where((d) => d.totalMinutes > 0).length;
    return {
      'totalMinutes': totalMinutes,
      'totalSessions': totalSessions,
      'goalsReached': goalsReached,
      'activeDays': activeDays,
      'avgMinutesPerDay': activeDays > 0 ? (totalMinutes / activeDays).round() : 0,
    };
  }
}
