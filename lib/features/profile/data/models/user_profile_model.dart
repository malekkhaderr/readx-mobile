import '../../domain/entities/user_profile_entity.dart';

// ── Sub-models ───────────────────────────────────────────────

class DayActivityModel extends DayActivityEntity {
  const DayActivityModel({
    required super.day,
    required super.completed,
    required super.minutesRead,
  });

  factory DayActivityModel.fromJson(Map<String, dynamic> json) {
    return DayActivityModel(
      day: json['day']?.toString() ?? '',
      completed: json['completed'] == true,
      minutesRead: (json['minutesRead'] as num?)?.toInt() ?? 0,
    );
  }
}

class CompletedBookModel extends CompletedBookEntity {
  const CompletedBookModel({
    required super.id,
    required super.title,
    super.coverImageUrl,
  });

  factory CompletedBookModel.fromJson(Map<String, dynamic> json) {
    return CompletedBookModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      coverImageUrl: json['coverImageUrl']?.toString(),
    );
  }
}

class TrophyModel extends TrophyEntity {
  const TrophyModel({
    required super.id,
    required super.name,
    super.iconUrl,
    required super.earned,
  });

  factory TrophyModel.fromJson(Map<String, dynamic> json) {
    return TrophyModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString(),
      earned: json['earned'] == true,
    );
  }
}

// ── Reader Dashboard model ───────────────────────────────────
// API shape:
//   readerDashboard.user   → { name, email, level, booksRead, streakDays, cubes, avatarImageUrl, dailyGoal }
//   readerDashboard.stats  → { totalReadingTime, avgSessionTime }
//   readerDashboard.weeklyRituals → [{ day, completed, minutesRead }]
//   readerDashboard.completedBooks → [{ id, title, coverImageUrl }]

class ReaderDashboardModel extends ReaderDashboardEntity {
  const ReaderDashboardModel({
    required super.levelLabel,
    required super.booksRead,
    required super.streakDays,
    required super.cubes,
    required super.dailyGoal,
    required super.totalReadingTime,
    required super.avgSessionTime,
    required super.weeklyRituals,
    required super.completedBooks,
    required super.trophies,
  });

  factory ReaderDashboardModel.fromJson(Map<String, dynamic> json) {
    // ── user sub-object ──
    final user = json['user'] as Map<String, dynamic>? ?? {};

    // ── stats sub-object ──
    final stats = json['stats'] as Map<String, dynamic>? ?? {};

    // ── weeklyRituals ──
    List<DayActivityEntity> weeklyRituals = [];
    if (json['weeklyRituals'] is List) {
      weeklyRituals = (json['weeklyRituals'] as List)
          .map((e) => DayActivityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // ── completedBooks ──
    List<CompletedBookEntity> completedBooks = [];
    if (json['completedBooks'] is List) {
      completedBooks = (json['completedBooks'] as List)
          .map((e) => CompletedBookModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // ── trophies (may not exist yet) ──
    List<TrophyEntity> trophies = [];
    if (json['trophies'] is List) {
      trophies = (json['trophies'] as List)
          .map((e) => TrophyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ReaderDashboardModel(
      levelLabel: user['level']?.toString() ?? 'Reader',
      booksRead: (user['booksRead'] as num?)?.toInt() ?? 0,
      streakDays: (user['streakDays'] as num?)?.toInt() ?? 0,
      cubes: (user['cubes'] as num?)?.toInt() ?? 0,
      dailyGoal: (user['dailyGoal'] as num?)?.toInt() ?? 30,
      totalReadingTime: stats['totalReadingTime']?.toString() ?? '0m',
      avgSessionTime: stats['avgSessionTime']?.toString() ?? '0m',
      weeklyRituals: weeklyRituals,
      completedBooks: completedBooks,
      trophies: trophies,
    );
  }
}

// ── Top-level User Profile model ─────────────────────────────

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    super.avatarImageUrl,
    required super.isEmailVerified,
    required super.isPrivateProfile,
    required super.role,
    super.readerDashboard,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    ReaderDashboardEntity? dashboard;
    if (json['readerDashboard'] is Map<String, dynamic>) {
      dashboard = ReaderDashboardModel.fromJson(
          json['readerDashboard'] as Map<String, dynamic>);
    }

    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatarImageUrl: json['avatarImageUrl']?.toString(),
      isEmailVerified: json['isEmailVerified'] == true,
      isPrivateProfile: json['isPrivateProfile'] == true,
      role: UserRole.fromValue((json['role'] as num?)?.toInt() ?? 0),
      readerDashboard: dashboard,
    );
  }
}
