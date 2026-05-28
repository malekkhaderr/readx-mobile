class CommentItem {
  final int id;
  final int bookId;
  final int readerProfileId;
  final int userId;
  final String readerName;
  final String body;
  final bool isSpoiler;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int upvoteCount;
  final int downvoteCount;
  final int? currentUserVote;

  CommentItem({
    required this.id,
    required this.bookId,
    required this.readerProfileId,
    this.userId = 0,
    required this.readerName,
    required this.body,
    this.isSpoiler = false,
    required this.createdAt,
    this.updatedAt,
    required this.upvoteCount,
    required this.downvoteCount,
    this.currentUserVote,
  });

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    return CommentItem(
      id: json['id'] as int? ?? 0,
      bookId: json['bookId'] as int? ?? 0,
      readerProfileId: json['readerProfileId'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      readerName: json['readerName'] as String? ?? 'Anonymous',
      body: json['body'] as String? ?? '',
      isSpoiler: json['isSpoiler'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      upvoteCount: json['upvoteCount'] as int? ?? 0,
      downvoteCount: json['downvoteCount'] as int? ?? 0,
      currentUserVote: json['currentUserVote'] as int?,
    );
  }

  CommentItem copyWith({
    int? id,
    int? bookId,
    int? readerProfileId,
    int? userId,
    String? readerName,
    String? body,
    bool? isSpoiler,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? upvoteCount,
    int? downvoteCount,
    int? currentUserVote,
  }) {
    return CommentItem(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      readerProfileId: readerProfileId ?? this.readerProfileId,
      userId: userId ?? this.userId,
      readerName: readerName ?? this.readerName,
      isSpoiler: isSpoiler ?? this.isSpoiler,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      downvoteCount: downvoteCount ?? this.downvoteCount,
      currentUserVote: currentUserVote ?? this.currentUserVote,
    );
  }
}

class CommentListResponse {
  final List<CommentItem> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;

  CommentListResponse({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
  });

  factory CommentListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    return CommentListResponse(
      items: list.map((e) => CommentItem.fromJson(e as Map<String, dynamic>)).toList(),
      totalCount: json['totalCount'] as int? ?? 0,
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}
