class PaginatedAuthorQuotesResponse {
  final List<AuthorQuoteModel> items;
  final int totalPages;

  PaginatedAuthorQuotesResponse({
    required this.items,
    this.totalPages = 1,
  });

  factory PaginatedAuthorQuotesResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedAuthorQuotesResponse(
      items: (json['items'] as List?)
              ?.map((item) => AuthorQuoteModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}

class AuthorQuoteModel {
  final int id;
  final int bookId;
  final String bookTitle;
  final int categoryId;
  final String categoryName;
  final int readerProfileId;
  final String readerName;
  final String content;
  final int pageNumber;
  final bool isPublic;
  final DateTime? createdAt;
  final int upvotes;
  final int downvotes;
  final bool? currentUserVote;

  AuthorQuoteModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.categoryId,
    required this.categoryName,
    required this.readerProfileId,
    required this.readerName,
    required this.content,
    required this.pageNumber,
    required this.isPublic,
    this.createdAt,
    required this.upvotes,
    required this.downvotes,
    this.currentUserVote,
  });

  factory AuthorQuoteModel.fromJson(Map<String, dynamic> json) {
    return AuthorQuoteModel(
      id: json['id'] ?? 0,
      bookId: json['bookId'] ?? 0,
      bookTitle: json['bookTitle'] ?? '',
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'] ?? '',
      readerProfileId: json['readerProfileId'] ?? 0,
      readerName: json['readerName'] ?? '',
      content: json['content'] ?? '',
      pageNumber: json['pageNumber'] ?? 0,
      isPublic: json['isPublic'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      currentUserVote: json['currentUserVote'],
    );
  }
}
