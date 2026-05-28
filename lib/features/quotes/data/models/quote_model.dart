import 'package:equatable/equatable.dart';

/// Vote types — matches backend enum: 0=Upvote, 1=Downvote, null=No vote.
enum QuoteVote {
  upvote(0),
  downvote(1);

  final int value;
  const QuoteVote(this.value);
}

/// Full quote details (public feed entries + author analytics use this shape).
class QuoteDetails extends Equatable {
  final int id;
  final int bookId;
  final String bookTitle;
  final int? categoryId;
  final String? categoryName;
  final int readerProfileId;
  final int userId;
  final String readerName;
  final String content;
  final int pageNumber;
  final bool isPublic;
  final DateTime createdAt;
  final int upvotes;
  final int downvotes;
  final int? currentUserVote; // 0 = upvoted, 1 = downvoted, null = no vote

  const QuoteDetails({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    this.categoryId,
    this.categoryName,
    required this.readerProfileId,
    this.userId = 0,
    required this.readerName,
    required this.content,
    required this.pageNumber,
    required this.isPublic,
    required this.createdAt,
    required this.upvotes,
    required this.downvotes,
    this.currentUserVote,
  });

  bool get hasUpvoted => currentUserVote == 0;
  bool get hasDownvoted => currentUserVote == 1;
  int get netScore => upvotes - downvotes;

  QuoteDetails copyWith({
    int? upvotes,
    int? downvotes,
    int? currentUserVote,
    bool clearVote = false,
  }) {
    return QuoteDetails(
      id: id,
      bookId: bookId,
      bookTitle: bookTitle,
      categoryId: categoryId,
      categoryName: categoryName,
      readerProfileId: readerProfileId,
      userId: userId,
      readerName: readerName,
      content: content,
      pageNumber: pageNumber,
      isPublic: isPublic,
      createdAt: createdAt,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      currentUserVote: clearVote ? null : (currentUserVote ?? this.currentUserVote),
    );
  }

  factory QuoteDetails.fromJson(Map<String, dynamic> json) {
    return QuoteDetails(
      id: json['id'] as int? ?? 0,
      bookId: json['bookId'] as int? ?? 0,
      bookTitle: json['bookTitle'] as String? ?? '',
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      readerProfileId: json['readerProfileId'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      readerName: json['readerName'] as String? ?? 'Anonymous',
      content: json['content'] as String? ?? '',
      pageNumber: json['pageNumber'] as int? ?? 0,
      isPublic: json['isPublic'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toLocal()
          : DateTime.now(),
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      currentUserVote: json['currentUserVote'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        upvotes,
        downvotes,
        currentUserVote,
        isPublic,
      ];
}

/// Simpler shape for "My Quotes" — backend returns less detail.
class MyQuote extends Equatable {
  final int id;
  final int bookId;
  final String bookTitle;
  final String content;
  final int pageNumber;
  final bool isPublic;
  final DateTime createdAt;

  const MyQuote({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.content,
    required this.pageNumber,
    required this.isPublic,
    required this.createdAt,
  });

  factory MyQuote.fromJson(Map<String, dynamic> json) {
    return MyQuote(
      id: json['id'] as int? ?? 0,
      bookId: json['bookId'] as int? ?? 0,
      bookTitle: json['bookTitle'] as String? ?? '',
      content: json['content'] as String? ?? '',
      pageNumber: json['pageNumber'] as int? ?? 0,
      isPublic: json['isPublic'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toLocal()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, isPublic];
}

/// Public feed paged response.
class QuotesPagedResponse {
  final List<QuoteDetails> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;

  QuotesPagedResponse({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
  });

  factory QuotesPagedResponse.fromJson(Map<String, dynamic> json) {
    return QuotesPagedResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => QuoteDetails.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['totalCount'] as int? ?? 0,
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}
