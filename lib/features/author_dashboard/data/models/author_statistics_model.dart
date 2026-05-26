class AuthorStatistics {
  final int totalPurchases;
  final int totalReadingTimeMinutes;
  final List<BookStatistic> books;

  // Legacy fields kept for backward compat with existing StatisticsPage
  final int totalViews;
  final int totalReads;
  final double averageRating;
  final int totalComments;
  final int totalRatings;
  final List<BookStatistic> bookStatistics;

  const AuthorStatistics({
    required this.totalPurchases,
    required this.totalReadingTimeMinutes,
    required this.books,
    this.totalViews = 0,
    this.totalReads = 0,
    this.averageRating = 0,
    this.totalComments = 0,
    this.totalRatings = 0,
    List<BookStatistic>? bookStatistics,
  }) : bookStatistics = bookStatistics ?? books;

  factory AuthorStatistics.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    // The API returns: { totalPurchases, totalReadingTimeMinutes, books: [...] }
    final booksJson = (json['books'] as List<dynamic>?) ??
        (json['bookStatistics'] as List<dynamic>?) ??
        [];

    final booksList = booksJson
        .map((e) => BookStatistic.fromJson(e as Map<String, dynamic>))
        .toList();

    return AuthorStatistics(
      totalPurchases:
          parseInt(json['totalPurchases'] ?? json['purchases'] ?? 0),
      totalReadingTimeMinutes: parseInt(
          json['totalReadingTimeMinutes'] ?? json['readingTimeMinutes'] ?? 0),
      books: booksList,
      // Legacy
      totalViews: parseInt(json['totalViews'] ?? json['views'] ?? 0),
      totalReads: parseInt(json['totalReads'] ?? json['reads'] ?? 0),
      averageRating: parseDouble(json['averageRating'] ?? json['rating'] ?? 0),
      totalComments:
          parseInt(json['totalComments'] ?? json['comments'] ?? 0),
      totalRatings: parseInt(json['totalRatings'] ?? json['ratings'] ?? 0),
      bookStatistics: booksList,
    );
  }
}

class BookStatistic {
  final int bookId;
  final String title;
  final String? categoryName;
  final int purchaseCount;
  final int totalReadingTimeMinutes;
  // Legacy / extra fields
  final int viewCount;
  final int readCount;
  final double averageRating;
  final int ratingsCount;

  const BookStatistic({
    required this.bookId,
    required this.title,
    this.categoryName,
    this.purchaseCount = 0,
    this.totalReadingTimeMinutes = 0,
    this.viewCount = 0,
    this.readCount = 0,
    this.averageRating = 0,
    this.ratingsCount = 0,
  });

  factory BookStatistic.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return BookStatistic(
      bookId: parseInt(json['bookId'] ?? json['id']),
      title: json['title']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? json['category']?.toString(),
      purchaseCount: parseInt(json['purchaseCount'] ?? json['purchases'] ?? 0),
      totalReadingTimeMinutes: parseInt(
          json['totalReadingTimeMinutes'] ?? json['readingTimeMinutes'] ?? 0),
      viewCount: parseInt(json['viewCount'] ?? json['views'] ?? 0),
      readCount: parseInt(json['readCount'] ?? json['reads'] ?? 0),
      averageRating: parseDouble(json['averageRating'] ?? json['rating'] ?? 0),
      ratingsCount: parseInt(json['ratingsCount'] ?? json['ratings'] ?? 0),
    );
  }
}
