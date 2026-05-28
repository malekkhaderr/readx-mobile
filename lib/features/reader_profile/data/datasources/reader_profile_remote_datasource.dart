import '../../../../core/network/dio_client.dart';

class CompletedBookData {
  final int bookId;
  final String title;
  final String? coverImageUrl;
  final String authorName;

  CompletedBookData({required this.bookId, required this.title, this.coverImageUrl, required this.authorName});

  factory CompletedBookData.fromJson(Map<String, dynamic> json) {
    return CompletedBookData(
      bookId: json['bookId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String?,
      authorName: json['authorName'] as String? ?? 'Unknown',
    );
  }
}

class ReaderProfileData {
  final int userId;
  final String firstName;
  final String lastName;
  final String? avatarImageUrl;
  final bool isPrivateProfile;
  final int? levelId;
  final int? totalReadingTimeMinutes;
  final int? booksReadCount;
  final int? currentStreak;
  final int? longestStreak;
  final int? tokenBalance;
  final int? totalTokensEarned;
  final DateTime? lastReadDate;
  final List<CompletedBookData> completedBooks;

  ReaderProfileData({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.avatarImageUrl,
    required this.isPrivateProfile,
    this.levelId,
    this.totalReadingTimeMinutes,
    this.booksReadCount,
    this.currentStreak,
    this.longestStreak,
    this.tokenBalance,
    this.totalTokensEarned,
    this.lastReadDate,
    this.completedBooks = const [],
  });

  String get fullName => '$firstName $lastName';
  String get initial => firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

  String get formattedReadingTime {
    final mins = totalReadingTimeMinutes ?? 0;
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  factory ReaderProfileData.fromJson(Map<String, dynamic> json) {
    return ReaderProfileData(
      userId: json['userId'] as int,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      avatarImageUrl: json['avatarImageUrl'] as String?,
      isPrivateProfile: json['isPrivateProfile'] as bool? ?? false,
      levelId: (json['levelId'] as num?)?.toInt(),
      totalReadingTimeMinutes: (json['totalReadingTimeMinutes'] as num?)?.toInt(),
      booksReadCount: (json['booksReadCount'] as num?)?.toInt(),
      currentStreak: (json['currentStreak'] as num?)?.toInt(),
      longestStreak: (json['longestStreak'] as num?)?.toInt(),
      tokenBalance: (json['tokenBalance'] as num?)?.toInt(),
      totalTokensEarned: (json['totalTokensEarned'] as num?)?.toInt() ?? (json['tokenBalance'] as num?)?.toInt(),
      lastReadDate: json['lastReadDate'] != null ? DateTime.tryParse(json['lastReadDate'] as String) : null,
      completedBooks: json['completedBooks'] is List
          ? (json['completedBooks'] as List).map((e) => CompletedBookData.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
    );
  }
}

class ReaderProfileRemoteDataSource {
  final DioClient dioClient;
  ReaderProfileRemoteDataSource({required this.dioClient});

  Future<ReaderProfileData> getReaderProfile(int id) async {
    // Try as user ID first (the API expects userId)
    final response = await dioClient.dio.get('/readers/$id');
    if (response.statusCode == 200) {
      return ReaderProfileData.fromJson(response.data);
    }
    if (response.statusCode == 404) {
      throw Exception('Reader profile not found');
    }
    throw Exception('Failed to load reader profile');
  }
}
