class RatingReviewItem {
  final int id;
  final double rating;
  final String? reviewText;
  final String? readerName;
  final DateTime createdAt;

  RatingReviewItem({
    required this.id,
    required this.rating,
    this.reviewText,
    this.readerName,
    required this.createdAt,
  });

  factory RatingReviewItem.fromJson(Map<String, dynamic> json) {
    // Backend renamed the field to `text` after enabling textual reviews.
    // The `reviewText`/`comment` keys stay as fallbacks for older payloads
    // that may still be cached client-side or returned by older endpoints.
    final text = json['text'] as String? ??
        json['reviewText'] as String? ??
        json['comment'] as String?;
    return RatingReviewItem(
      id: json['id'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewText: text,
      readerName: json['readerName'] as String? ??
          json['userName'] as String? ??
          'Anonymous',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class RatingReviewsResponse {
  final List<RatingReviewItem> reviews;
  final int totalCount;
  final int pageNumber;
  final int pageSize;

  RatingReviewsResponse({
    required this.reviews,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
  });

  factory RatingReviewsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['reviews'] as List? ?? [];
    return RatingReviewsResponse(
      reviews: list.map((e) => RatingReviewItem.fromJson(e as Map<String, dynamic>)).toList(),
      totalCount: json['totalCount'] as int? ?? 0,
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
    );
  }
}
