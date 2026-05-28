class AuthorBook {
  final int id;
  final String title;
  final String? coverImageUrl;
  final bool isPublished;
  final int viewCount;
  final int readCount;
  final double averageRating;
  final double price;
  final String? categoryName;
  final String? description;
  final DateTime? createdAt;
  final int totalPages;
  final String? languageName;
  final int? publishedYear;
  final String? isbn;
  final double? priceTokens;

  const AuthorBook({
    required this.id,
    required this.title,
    this.coverImageUrl,
    required this.isPublished,
    required this.viewCount,
    required this.readCount,
    required this.averageRating,
    required this.price,
    this.categoryName,
    this.description,
    this.createdAt,
    required this.totalPages,
    this.languageName,
    this.publishedYear,
    this.isbn,
    this.priceTokens,
  });

  factory AuthorBook.fromJson(Map<String, dynamic> json) {
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

    return AuthorBook(
      id: parseInt(json['id'] ?? json['bookId']),
      title: json['title']?.toString() ?? '',
      coverImageUrl: json['coverImageUrl'] ?? json['coverImage'] ?? json['imageUrl'],
      isPublished: json['isPublished'] ?? json['published'] ?? (json['status'] == 'published') ?? false,
      viewCount: parseInt(json['viewCount'] ?? json['views']),
      readCount: parseInt(json['readCount'] ?? json['reads']),
      averageRating: parseDouble(json['averageRating'] ?? json['rating']),
      price: parseDouble(json['priceUSD'] ?? json['price']),
      categoryName: json['categoryName'] ?? json['category'],
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      totalPages: parseInt(json['totalPages'] ?? json['pages']),
      languageName: json['languageName']?.toString(),
      publishedYear: json['publishedYear'] != null ? parseInt(json['publishedYear']) : null,
      isbn: json['isbn']?.toString(),
      priceTokens: json['priceTokens'] != null ? parseDouble(json['priceTokens']) : null,
    );
  }
}
