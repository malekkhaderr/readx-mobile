class ReaderLevel {
  /// Maps level number to a local asset path so icons load instantly
  /// without depending on the backend serving static files.
  static const _localIcons = {
    1: 'assets/images/owls-levels/TheNovice.png',
    2: 'assets/images/owls-levels/TheVoyager.png',
    3: 'assets/images/owls-levels/TheScholar.png',
    4: 'assets/images/owls-levels/TheOverseer.png',
    5: 'assets/images/owls-levels/TheOracle.png',
  };

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

  /// Returns the local asset path for this level's icon.
  String? get localIconAsset => _localIcons[levelNumber];

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
