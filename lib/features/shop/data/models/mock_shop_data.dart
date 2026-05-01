class ShopItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String emoji;
  final String? badge;
  final ShopCategory category;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
    this.badge,
    this.category = ShopCategory.allDeals,
  });
}

enum ShopCategory {
  allDeals('All Deals'),
  powerUps('Power-ups'),
  avatars('Avatars'),
  themes('Themes');

  final String label;
  const ShopCategory(this.label);
}

class MockShopData {
  static const int userCubeBalance = 1250;

  static const List<ShopItem> dailyDeals = [
    ShopItem(
      id: 'd1',
      name: 'Double XP Scroll',
      description: '2 hours duration',
      price: 150,
      emoji: '📜',
      badge: 'Hot',
      category: ShopCategory.powerUps,
    ),
    ShopItem(
      id: 'd2',
      name: 'Scholar Hat',
      description: '+5% reading speed',
      price: 200,
      emoji: '🎓',
      category: ShopCategory.avatars,
    ),
  ];

  static const List<ShopItem> featuredRewards = [
    ShopItem(
      id: 'f1',
      name: 'Premium Library Key',
      description: 'Unlock 3 exclusive premium short stories for your reading catalog.',
      price: 1200,
      emoji: '🔑',
      badge: 'New',
      category: ShopCategory.allDeals,
    ),
    ShopItem(
      id: 'f2',
      name: 'Midnight Theme',
      description: 'Transform your reading experience with a premium dark aesthetic.',
      price: 750,
      emoji: '🌙',
      category: ShopCategory.themes,
    ),
    ShopItem(
      id: 'f3',
      name: 'Golden Owl Avatar',
      description: 'Exclusive golden variant of the Hootie mascot.',
      price: 2000,
      emoji: '🦉',
      badge: 'Rare',
      category: ShopCategory.avatars,
    ),
  ];

  static const List<ShopItem> allItems = [
    ...dailyDeals,
    ...featuredRewards,
  ];
}
