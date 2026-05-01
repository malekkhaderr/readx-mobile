class MockUserProfile {
  final String name;
  final String level;
  final int booksRead;
  final int streakDays;
  final int cubes;
  final String avatarEmoji;

  const MockUserProfile({
    required this.name,
    required this.level,
    required this.booksRead,
    required this.streakDays,
    required this.cubes,
    this.avatarEmoji = '👩‍💼',
  });
}

class Trophy {
  final String id;
  final String name;
  final String emoji;
  final bool unlocked;

  const Trophy({
    required this.id,
    required this.name,
    required this.emoji,
    this.unlocked = false,
  });
}

class ReadingRitual {
  final String day;
  final bool completed;
  final int minutesRead;

  const ReadingRitual({
    required this.day,
    required this.completed,
    this.minutesRead = 0,
  });
}

class MockProfileData {
  static MockUserProfile _profile = const MockUserProfile(
    name: 'Elena Vane',
    level: 'Bookworm Lvl 12',
    booksRead: 128,
    streakDays: 14,
    cubes: 4500,
  );

  static MockUserProfile get profile => _profile;

  /// Swap this with: `await dio.put('/user/profile', data: {...});`
  static void updateProfile({String? name, String? email, int? dailyGoal}) {
    _profile = MockUserProfile(
      name: name ?? _profile.name,
      level: _profile.level,
      booksRead: _profile.booksRead,
      streakDays: _profile.streakDays,
      cubes: _profile.cubes,
    );
  }

  static const List<ReadingRitual> weeklyRituals = [
    ReadingRitual(day: 'Mon', completed: true, minutesRead: 35),
    ReadingRitual(day: 'Tue', completed: true, minutesRead: 42),
    ReadingRitual(day: 'Wed', completed: true, minutesRead: 28),
    ReadingRitual(day: 'Thu', completed: true, minutesRead: 30),
    ReadingRitual(day: 'Fri', completed: false, minutesRead: 10),
    ReadingRitual(day: 'Sat', completed: false, minutesRead: 0),
    ReadingRitual(day: 'Sun', completed: false, minutesRead: 0),
  ];

  static const String totalReadingTime = '11h 45m';
  static const String avgSessionTime = '34m';

  static const List<Trophy> trophies = [
    Trophy(id: 't1', name: 'First Read', emoji: '📖', unlocked: true),
    Trophy(id: 't2', name: 'Streak Master', emoji: '🔥', unlocked: true),
    Trophy(id: 't3', name: 'Book Worm', emoji: '🐛', unlocked: true),
    Trophy(id: 't4', name: 'Night Owl', emoji: '🦉', unlocked: true),
    Trophy(id: 't5', name: 'Speed Reader', emoji: '⚡', unlocked: false),
    Trophy(id: 't6', name: 'Sage', emoji: '🧙', unlocked: false),
  ];
}
