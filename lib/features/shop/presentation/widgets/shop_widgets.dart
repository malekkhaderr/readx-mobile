import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../data/models/mock_shop_data.dart';

// ── Cube Balance Card ───────────────────────────────────────
class CubeBalanceCard extends StatelessWidget {
  final int balance;
  const CubeBalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR BALANCE',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.add, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Get Feathers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Image.asset('assets/images/purple_feather.png', width: 32, height: 32, fit: BoxFit.contain),
              const SizedBox(width: 8),
              Text(
                '${balance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text(
                  'Feathers',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Earn 120 feathers today',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Tabs ───────────────────────────────────────────
class ShopCategoryTabs extends StatelessWidget {
  final ShopCategory selectedCategory;
  final ValueChanged<ShopCategory> onCategoryChanged;

  const ShopCategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ShopCategory.values.length,
        itemBuilder: (context, index) {
          final cat = ShopCategory.values[index];
          final isSelected = cat == selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onCategoryChanged(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.divider),
                ),
                child: Text(
                  cat.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textGrey,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Deal Card ───────────────────────────────────────────────
class DealCard extends StatelessWidget {
  final ShopItem item;
  const DealCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Emoji icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.description,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          // Price button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/purple_feather.png', width: 12, height: 12, fit: BoxFit.contain),
                const SizedBox(width: 4),
                Text(
                  '${item.price}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Featured Reward Card ────────────────────────────────────
class FeaturedRewardCard extends StatelessWidget {
  final ShopItem item;
  const FeaturedRewardCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    if (item.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: item.badge == 'New'
                              ? AppColors.successGreen
                              : item.badge == 'Rare'
                                  ? AppColors.warningOrange
                                  : AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Price
          Column(
            children: [
              Image.asset('assets/images/purple_feather.png', width: 18, height: 18, fit: BoxFit.contain),
              const SizedBox(height: 2),
              Text(
                '${item.price}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
