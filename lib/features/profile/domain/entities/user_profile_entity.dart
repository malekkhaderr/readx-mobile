import 'package:equatable/equatable.dart';

enum UserRole {
  reader(0),
  author(1),
  admin(2);

  const UserRole(this.value);
  final int value;

  static UserRole fromValue(int v) {
    return UserRole.values.firstWhere(
      (r) => r.value == v,
      orElse: () => UserRole.reader,
    );
  }
}

// ── Sub-entities ────────────────────────────────────────────

class DayActivityEntity extends Equatable {
  final String day;
  final bool completed;
  final int minutesRead;

  const DayActivityEntity({
    required this.day,
    required this.completed,
    required this.minutesRead,
  });

  @override
  List<Object> get props => [day, completed, minutesRead];
}

class CompletedBookEntity extends Equatable {
  final String id;
  final String title;
  final String? coverImageUrl;

  const CompletedBookEntity({
    required this.id,
    required this.title,
    this.coverImageUrl,
  });

  @override
  List<Object?> get props => [id, title, coverImageUrl];
}

class TrophyEntity extends Equatable {
  final String id;
  final String name;
  final String? iconUrl;
  final bool earned;

  const TrophyEntity({
    required this.id,
    required this.name,
    this.iconUrl,
    required this.earned,
  });

  @override
  List<Object?> get props => [id, name, iconUrl, earned];
}

// ── Reader Dashboard entity ──────────────────────────────────

class ReaderDashboardEntity extends Equatable {
  /// Combined label from backend, e.g. "Bookworm Lvl 1"
  final String levelLabel;
  final int? levelId;
  final int booksRead;
  final int streakDays;
  final int cubes;
  final int totalTokensEarned;
  final int dailyGoal;
  /// Pre-formatted by backend e.g. "11h 45m" or "0m"
  final String totalReadingTime;
  /// Pre-formatted by backend e.g. "34m" or "0m"
  final String avgSessionTime;
  final List<DayActivityEntity> weeklyRituals;
  final List<CompletedBookEntity> completedBooks;
  final List<TrophyEntity> trophies;

  const ReaderDashboardEntity({
    required this.levelLabel,
    this.levelId,
    required this.booksRead,
    required this.streakDays,
    required this.cubes,
    this.totalTokensEarned = 0,
    required this.dailyGoal,
    required this.totalReadingTime,
    required this.avgSessionTime,
    required this.weeklyRituals,
    required this.completedBooks,
    required this.trophies,
  });

  /// e.g. "4.5k" or "450"
  String get formattedCubes =>
      cubes >= 1000
          ? '${(cubes / 1000).toStringAsFixed(1)}k'
          : '$cubes';

  @override
  List<Object?> get props => [
        levelLabel,
        levelId,
        booksRead,
        streakDays,
        cubes,
        totalTokensEarned,
        dailyGoal,
        totalReadingTime,
        avgSessionTime,
        weeklyRituals,
        completedBooks,
        trophies,
      ];
}

// ── Top-level User Profile entity ────────────────────────────

class UserProfileEntity extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarImageUrl;
  final bool isEmailVerified;
  final bool isPrivateProfile;
  final UserRole role;
  final ReaderDashboardEntity? readerDashboard;

  const UserProfileEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarImageUrl,
    required this.isEmailVerified,
    required this.isPrivateProfile,
    required this.role,
    this.readerDashboard,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get avatarInitial =>
      firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';
  bool get hasAvatar => avatarImageUrl != null && avatarImageUrl!.isNotEmpty;
  bool get isReader => role == UserRole.reader;
  bool get isAuthor => role == UserRole.author;

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        avatarImageUrl,
        isEmailVerified,
        isPrivateProfile,
        role,
        readerDashboard,
      ];
}
