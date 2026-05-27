class AuthorQuotesStatsModel {
  final int totalQuotesCount;
  final List<BookQuoteCountModel> bookQuoteCounts;

  AuthorQuotesStatsModel({
    required this.totalQuotesCount,
    required this.bookQuoteCounts,
  });

  factory AuthorQuotesStatsModel.fromJson(Map<String, dynamic> json) {
    return AuthorQuotesStatsModel(
      totalQuotesCount: json['totalQuotesCount'] ?? 0,
      bookQuoteCounts: (json['bookQuoteCounts'] as List?)
              ?.map((item) => BookQuoteCountModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BookQuoteCountModel {
  final int bookId;
  final String bookTitle;
  final int quotesCount;

  BookQuoteCountModel({
    required this.bookId,
    required this.bookTitle,
    required this.quotesCount,
  });

  factory BookQuoteCountModel.fromJson(Map<String, dynamic> json) {
    return BookQuoteCountModel(
      bookId: json['bookId'] ?? 0,
      bookTitle: json['bookTitle'] ?? '',
      quotesCount: json['quotesCount'] ?? 0,
    );
  }
}
