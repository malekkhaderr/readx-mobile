class PublisherRequestModel {
  final int id;
  final String type;
  final int? targetBookId;
  final String? requestMessage;
  final String status;
  final String? adminNotes;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? bookTitle;
  final String? bookEpubFileUrl;
  final String? bookCoverImageUrl;
  final String? bookIsbn;
  final String? bookSummary;
  final int? bookCategoryId;
  final int? bookLanguageId;
  final double? bookPrice;
  final int? bookTotalPages;

  PublisherRequestModel({
    required this.id,
    required this.type,
    this.targetBookId,
    this.requestMessage,
    required this.status,
    this.adminNotes,
    this.createdAt,
    this.reviewedAt,
    this.bookTitle,
    this.bookEpubFileUrl,
    this.bookCoverImageUrl,
    this.bookIsbn,
    this.bookSummary,
    this.bookCategoryId,
    this.bookLanguageId,
    this.bookPrice,
    this.bookTotalPages,
  });

  factory PublisherRequestModel.fromJson(Map<String, dynamic> json) {
    return PublisherRequestModel(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'Unknown',
      targetBookId: json['targetBookId'] as int?,
      requestMessage: json['requestMessage'] as String?,
      status: json['status'] as String? ?? 'Pending',
      adminNotes: json['adminNotes'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      reviewedAt: json['reviewedAt'] != null ? DateTime.tryParse(json['reviewedAt']) : null,
      bookTitle: json['bookTitle'] as String?,
      bookEpubFileUrl: json['bookEpubFileUrl'] as String?,
      bookCoverImageUrl: json['bookCoverImageUrl'] as String?,
      bookIsbn: json['bookIsbn'] as String?,
      bookSummary: json['bookSummary'] as String?,
      bookCategoryId: json['bookCategoryId'] as int?,
      bookLanguageId: json['bookLanguageId'] as int?,
      bookPrice: (json['bookPrice'] as num?)?.toDouble(),
      bookTotalPages: json['bookTotalPages'] as int?,
    );
  }
}

class AddBookRequestModel {
  final String title;
  final String epubFileUrl;
  final String coverImageUrl;
  final String isbn;
  final String summary;
  final int categoryId;
  final int languageId;
  final double price;
  final int totalPages;
  final String requestMessage;

  AddBookRequestModel({
    required this.title,
    required this.epubFileUrl,
    required this.coverImageUrl,
    required this.isbn,
    required this.summary,
    required this.categoryId,
    required this.languageId,
    required this.price,
    required this.totalPages,
    required this.requestMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'epubFileUrl': epubFileUrl,
      'coverImageUrl': coverImageUrl,
      'isbn': isbn,
      'summary': summary,
      'categoryId': categoryId,
      'languageId': languageId,
      'price': price,
      'totalPages': totalPages,
      'requestMessage': requestMessage,
    };
  }
}

class ModifyBookRequestModel {
  final int bookId;
  final String modificationDetails;

  ModifyBookRequestModel({
    required this.bookId,
    required this.modificationDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'modificationDetails': modificationDetails,
    };
  }
}

class RemoveBookRequestModel {
  final int bookId;
  final String reason;

  RemoveBookRequestModel({
    required this.bookId,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'reason': reason,
    };
  }
}
