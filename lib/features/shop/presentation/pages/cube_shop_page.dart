import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../data/models/mock_shop_data.dart';

class CubeShopPage extends StatefulWidget {
  const CubeShopPage({super.key});

  @override
  State<CubeShopPage> createState() => _CubeShopPageState();
}

class _CubeShopPageState extends State<CubeShopPage> {
  ShopCategory _selectedCategory = ShopCategory.allDeals;
  int _cubeBalance = MockShopData.userCubeBalance;
  final Set<String> _purchasedItems = {};

  List<ShopItem> get _filteredDeals {
    if (_selectedCategory == ShopCategory.allDeals) return MockShopData.dailyDeals;
    return MockShopData.dailyDeals.where((i) => i.category == _selectedCategory).toList();
  }

  List<ShopItem> get _filteredFeatured {
    if (_selectedCategory == ShopCategory.allDeals) return MockShopData.featuredRewards;
    return MockShopData.featuredRewards.where((i) => i.category == _selectedCategory).toList();
  }

  void _buyItem(ShopItem item) {
    if (_purchasedItems.contains(item.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already own this item!'), duration: Duration(seconds: 1)),
      );
      return;
    }

    if (_cubeBalance < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough cubes! You need ${item.price - _cubeBalance} more.'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Text(item.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(child: Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description, style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.4)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Price', style: TextStyle(fontWeight: FontWeight.w600)),
                  Row(children: [
                    const Text('🧊', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text('${item.price}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ]),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _cubeBalance -= item.price;
                _purchasedItems.add(item.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    const Text('✅ '),
                    Text('Purchased ${item.name}!'),
                  ]),
                  backgroundColor: AppColors.successGreen,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Buy Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Cube Shop', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ),
              const SizedBox(height: 8),

              // Balance Card
              _CubeBalanceCard(balance: _cubeBalance),
              const SizedBox(height: 16),

              // Category Tabs
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ShopCategory.values.length,
                  itemBuilder: (context, index) {
                    final cat = ShopCategory.values[index];
                    final isSelected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected ? null : Border.all(color: AppColors.divider),
                          ),
                          child: Text(
                            cat.label,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textGrey),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Daily Deals
              if (_filteredDeals.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Daily Deals', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: _filteredDeals.map((item) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: item != _filteredDeals.last ? 12 : 0),
                          child: _DealCard(
                            item: item,
                            isPurchased: _purchasedItems.contains(item.id),
                            onBuy: () => _buyItem(item),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Featured Rewards
              if (_filteredFeatured.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Featured Rewards', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                ),
                const SizedBox(height: 8),
                ..._filteredFeatured.map(
                  (item) => _FeaturedRewardCard(
                    item: item,
                    isPurchased: _purchasedItems.contains(item.id),
                    onBuy: () => _buyItem(item),
                  ),
                ),
              ],

              if (_filteredDeals.isEmpty && _filteredFeatured.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Text('🏪', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 8),
                        Text('No items in this category', style: TextStyle(color: AppColors.textGrey, fontSize: 14)),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Balance Card ────────────────────────────────────────────
class _CubeBalanceCard extends StatelessWidget {
  final int balance;
  const _CubeBalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('YOUR BALANCE', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Get Cubes', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('🧊', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Text(
                balance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'),
                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, height: 1),
              ),
              const SizedBox(width: 6),
              const Padding(padding: EdgeInsets.only(bottom: 3), child: Text('Cubes', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Deal Card ───────────────────────────────────────────────
class _DealCard extends StatelessWidget {
  final ShopItem item;
  final bool isPurchased;
  final VoidCallback onBuy;
  const _DealCard({required this.item, required this.isPurchased, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBuy,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(height: 8),
            Text(item.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text(item.description, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isPurchased ? AppColors.successGreen : AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: isPurchased
                  ? const Text('Owned', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🧊', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text('${item.price}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Featured Reward ─────────────────────────────────────────
class _FeaturedRewardCard extends StatelessWidget {
  final ShopItem item;
  final bool isPurchased;
  final VoidCallback onBuy;
  const _FeaturedRewardCard({required this.item, required this.isPurchased, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBuy,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark))),
                      if (item.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.badge == 'New' ? AppColors.successGreen : item.badge == 'Rare' ? AppColors.warningOrange : AppColors.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(item.badge!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textGrey, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            isPurchased
                ? const Icon(Icons.check_circle, color: AppColors.successGreen, size: 24)
                : Column(
                    children: [
                      const Text('🧊', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('${item.price}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
