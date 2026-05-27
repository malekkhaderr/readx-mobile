class BookDetail {
  final int id;
  final String title;
  final String? description;
  final int authorId;
  final String authorName;
  final int categoryId;
  final String categoryName;
  final int totalPages;
  final String coverImageUrl;
  final String epubFileUrl;
  final int languageId;
  final String languageName;
  final bool isPublished;
  final DateTime publishedAt;
  final int publishedYear;
  final int viewCount;
  final int readCount;
  final DateTime createdAt;
  final double priceUSD;
  final double priceTokens;
  final double averageRating;

  BookDetail({
    required this.id,
    required this.title,
    this.description,
    required this.authorId,
    required this.authorName,
    required this.categoryId,
    required this.categoryName,
    required this.totalPages,
    required this.coverImageUrl,
    required this.epubFileUrl,
    required this.languageId,
    required this.languageName,
    required this.isPublished,
    required this.publishedAt,
    required this.publishedYear,
    required this.viewCount,
    required this.readCount,
    required this.createdAt,
    required this.priceUSD,
    required this.priceTokens,
    required this.averageRating,
  });

  bool get isFree => priceUSD == 0;

  // Keep backward compat for UI that uses these
  double get price => priceUSD;
  double get effectivePrice => priceUSD;

  factory BookDetail.fromJson(Map<String, dynamic> json) {
    return BookDetail(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      authorId: json['authorId'] as int? ?? 0,
      authorName: json['authorName'] as String? ?? '',
      categoryId: json['categoryId'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
      totalPages: json['totalPages'] as int? ?? 0,
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      epubFileUrl: json['epubFileUrl'] as String? ?? '',
      languageId: json['languageId'] as int? ?? 0,
      languageName: json['languageName'] as String? ?? '',
      isPublished: json['isPublished'] as bool? ?? false,
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'])
          : DateTime.now(),
      publishedYear: json['publishedYear'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
      readCount: json['readCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      priceUSD: (json['priceUSD'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ?? 0.0,
      priceTokens: (json['priceTokens'] as num?)?.toDouble() ??
          (json['effectivePrice'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
