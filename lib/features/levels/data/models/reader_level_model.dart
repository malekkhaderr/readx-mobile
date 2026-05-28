class ReaderLevel {
  final int id;
  final int levelNumber;
  final String name;
  final String? description;
  final String? iconUrl;
  final int minTokens;
  final int? maxTokens;
  final bool isDefault;

  const ReaderLevel({
    required this.id,
    required this.levelNumber,
    required this.name,
    this.description,
    this.iconUrl,
    required this.minTokens,
    this.maxTokens,
    required this.isDefault,
  });

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
