import 'package:equatable/equatable.dart';

enum ReadingStatus {
  wantToRead(0),
  currentlyReading(1),
  read(2);

  final int value;
  const ReadingStatus(this.value);

  static ReadingStatus fromValue(int v) {
    switch (v) {
      case 1:
        return ReadingStatus.currentlyReading;
      case 2:
        return ReadingStatus.read;
      default:
        return ReadingStatus.wantToRead;
    }
  }

  String get label {
    switch (this) {
      case ReadingStatus.wantToRead:
        return 'Want to Read';
      case ReadingStatus.currentlyReading:
        return 'Reading';
      case ReadingStatus.read:
        return 'Read';
    }
  }
}

class LibraryBook extends Equatable {
  final int bookId;
  final String title;
  final String authorName;
  final String categoryName;
  final int totalPages;
  final String? coverImageUrl;
  final int viewCount;
  final DateTime addedAt;
  final ReadingStatus status;

  const LibraryBook({
    required this.bookId,
    required this.title,
    required this.authorName,
    required this.categoryName,
    required this.totalPages,
    required this.coverImageUrl,
    required this.viewCount,
    required this.addedAt,
    required this.status,
  });

  factory LibraryBook.fromJson(Map<String, dynamic> json) {
    return LibraryBook(
      bookId: json['bookId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      totalPages: json['totalPages'] as int? ?? 0,
      coverImageUrl: json['coverImageUrl'] as String?,
      viewCount: json['viewCount'] as int? ?? 0,
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : DateTime.now(),
      status: ReadingStatus.fromValue(json['status'] as int? ?? 0),
    );
  }

  @override
  List<Object?> get props => [bookId, status];
}

class LibraryResponse {
  final List<LibraryBook> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;

  LibraryResponse({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
  });

  factory LibraryResponse.fromJson(Map<String, dynamic> json) {
    return LibraryResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => LibraryBook.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['totalCount'] as int? ?? 0,
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}
