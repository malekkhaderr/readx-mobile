class HomeResponse {
  final List<BookCard> trendingBooks;
  final List<BookCard> recommendedBooks;
  final List<BookCard> newlyAddedBooks;
  final List<BookCategory> categories;

  HomeResponse({
    required this.trendingBooks,
    required this.recommendedBooks,
    required this.newlyAddedBooks,
    required this.categories,
  });

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      trendingBooks:
          (json['trendingBooks'] as List<dynamic>?)
              ?.map((e) => BookCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendedBooks:
          (json['recommendedBooks'] as List<dynamic>?)
              ?.map((e) => BookCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      newlyAddedBooks:
          (json['newlyAddedBooks'] as List<dynamic>?)
              ?.map((e) => BookCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) => BookCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BookCard {
  final int id;
  final String title;
  final String authorName;
  final String categoryName;
  final int totalPages;
  final String coverImageUrl;
  final bool isPublished;
  final int viewCount;
  final double priceUSD;
  final double priceTokens;
  final double averageRating;

  BookCard({
    required this.id,
    required this.title,
    required this.authorName,
    required this.categoryName,
    required this.totalPages,
    required this.coverImageUrl,
    required this.isPublished,
    required this.viewCount,
    required this.priceUSD,
    required this.priceTokens,
    required this.averageRating,
  });

  bool get isFree => priceUSD == 0;

  // Backward compat for any existing code
  double get price => priceUSD;
  double get effectivePrice => priceUSD;

  factory BookCard.fromJson(Map<String, dynamic> json) {
    return BookCard(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      totalPages: json['totalPages'] as int? ?? 0,
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      isPublished: json['isPublished'] as bool? ?? true,
      viewCount: json['viewCount'] as int? ?? 0,
      priceUSD: (json['priceUSD'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ?? 0.0,
      priceTokens: (json['priceTokens'] as num?)?.toDouble() ??
          (json['effectivePrice'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BookCategory {
  final int categoryId;
  final String categoryName;
  final List<BookCard> books;

  BookCategory({
    required this.categoryId,
    required this.categoryName,
    required this.books,
  });

  factory BookCategory.fromJson(Map<String, dynamic> json) {
    return BookCategory(
      categoryId: json['categoryId'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
      books:
          (json['books'] as List<dynamic>?)
              ?.map((e) => BookCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
