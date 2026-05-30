class ReaderLevel {
  static const _backendBaseUrl =
      'https://graduation-project-backend-j3bw.onrender.com';

  final int id;
  final int levelNumber;
  final String name;
  final String? description;
  final String? _rawIconUrl;
  final int minTokens;
  final int? maxTokens;
  final bool isDefault;

  const ReaderLevel({
    required this.id,
    required this.levelNumber,
    required this.name,
    this.description,
    String? iconUrl,
    required this.minTokens,
    this.maxTokens,
    required this.isDefault,
  }) : _rawIconUrl = iconUrl;

  /// Resolves the icon URL to a full network URL. The backend returns
  /// relative paths like `/owls/level1-glaucus.png` — CachedNetworkImage
  /// needs a complete `https://...` URL to fetch them.
  String? get iconUrl {
    final raw = _rawIconUrl;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return '$_backendBaseUrl$raw';
  }

  factory ReaderLevel.fromJson(Map<String, dynamic> json) {
    return ReaderLevel(
      id: json['id'] as int,
      levelNumber: json['levelNumber'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String?,
      minTokens: (json['minTokens'] as num).toInt(),
      maxTokens: json['maxTokens'] != null ? (json['maxTokens'] as num).toInt() : null,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
