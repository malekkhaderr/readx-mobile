class BookPerformanceModel {
  final int id;
  final String title;
  final int views;
  final int reads;
  final double averageRating;
  final int ratingsCount;
  final int totalReviewsWithText;

  const BookPerformanceModel({
    required this.id,
    required this.title,
    required this.views,
    required this.reads,
    required this.averageRating,
    required this.ratingsCount,
    required this.totalReviewsWithText,
  });

  factory BookPerformanceModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    return BookPerformanceModel(
      id: parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      views: parseInt(json['views']),
      reads: parseInt(json['reads']),
      averageRating: parseDouble(json['averageRating']),
      ratingsCount: parseInt(json['ratingsCount']),
      totalReviewsWithText: parseInt(json['totalReviewsWithText']),
    );
  }
}

class AuthorDashboardOverview {
  final int totalPublishedBooks;
  final int totalViewsAcrossAllBooks;
  final int totalReadsAcrossAllBooks;
  final List<BookPerformanceModel> booksPerformance;

  const AuthorDashboardOverview({
    required this.totalPublishedBooks,
    required this.totalViewsAcrossAllBooks,
    required this.totalReadsAcrossAllBooks,
    required this.booksPerformance,
  });

  factory AuthorDashboardOverview.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    final performanceJson = json['booksPerformance'] as List<dynamic>? ?? [];
    
    return AuthorDashboardOverview(
      totalPublishedBooks: parseInt(json['totalPublishedBooks']),
      totalViewsAcrossAllBooks: parseInt(json['totalViewsAcrossAllBooks']),
      totalReadsAcrossAllBooks: parseInt(json['totalReadsAcrossAllBooks']),
      booksPerformance: performanceJson
          .map((item) => BookPerformanceModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
