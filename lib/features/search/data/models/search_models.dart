import '../../../home/data/models/home_response_model.dart';

/// Paged response from `GET /api/books/search`. The item shape matches the
/// home page's BookCard (title/author/cover/price/...), so we reuse that
/// type instead of defining a parallel model. The search endpoint does NOT
/// return `averageRating` today, so cards from this stream will show "—"
/// for the star rating until the backend includes the field.
class SearchBooksResponse {
  final List<BookCard> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;

  const SearchBooksResponse({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
  });

  bool get hasMore => pageNumber * pageSize < totalCount;

  factory SearchBooksResponse.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? const [];
    return SearchBooksResponse(
      items: list
          .whereType<Map<String, dynamic>>()
          .map(BookCard.fromJson)
          .toList(),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
    );
  }
}

/// Lightweight category record used to populate the filter chips. We hit
/// `/api/categories` once on bloc init so we get *all* categories and not
/// just the ones the home page happens to surface.
class SearchCategory {
  final int id;
  final String name;
  final int bookCount;

  const SearchCategory({
    required this.id,
    required this.name,
    required this.bookCount,
  });

  factory SearchCategory.fromJson(Map<String, dynamic> json) {
    return SearchCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      bookCount: (json['bookCount'] as num?)?.toInt() ??
          (json['booksCount'] as num?)?.toInt() ??
          0,
    );
  }
}
