import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// A small feather icon — the project's currency symbol (replaces the diamond/token icon).
/// Always renders the [purple_feather.png] asset at the requested size.
class FeatherIcon extends StatelessWidget {
  final double size;

  const FeatherIcon({super.key, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/purple_feather.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// Displays a feather amount: "[icon] 250" with consistent styling.
/// Use the [compact] flag for tight spaces (smaller icon + tighter spacing).
class FeatherAmount extends StatelessWidget {
  final num amount;
  final double fontSize;
  final double iconSize;
  final Color color;
  final FontWeight fontWeight;
  final bool showLabel;

  const FeatherAmount({
    super.key,
    required this.amount,
    this.fontSize = 13,
    this.iconSize = 14,
    this.color = AppColors.primary,
    this.fontWeight = FontWeight.w800,
    this.showLabel = false,
  });

  String get _formattedAmount {
    final n = amount.toInt();
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FeatherIcon(size: iconSize),
        const SizedBox(width: 4),
        Text(
          _formattedAmount,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 3),
          Text(
            amount.toInt() == 1 ? 'feather' : 'feathers',
            style: TextStyle(
              fontSize: fontSize - 2,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ],
    );
  }
}

/// A modern price display card showing both USD and Feathers prices.
/// Used on book cards in the home, library, and search pages.
class PriceTag extends StatelessWidget {
  final double priceUSD;
  final double priceFeathers;
  final bool isFree;
  final bool isOwned;
  final bool compact;

  const PriceTag({
    super.key,
    required this.priceUSD,
    required this.priceFeathers,
    this.isFree = false,
    this.isOwned = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwned) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.successGreen.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded,
                size: compact ? 11 : 13, color: AppColors.successGreen),
            const SizedBox(width: 4),
            Text(
              'Owned',
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w800,
                color: AppColors.successGreen,
              ),
            ),
          ],
        ),
      );
    }

    if (isFree) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.successGreen.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'FREE',
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w800,
            color: AppColors.successGreen,
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    final iconSize = compact ? 10.0 : 13.0;
    final fontSize = compact ? 10.0 : 11.5;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.10),
            AppColors.primary.withOpacity(0.04),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // USD
          Icon(Icons.attach_money_rounded,
              size: iconSize, color: AppColors.textDark),
          Text(
            priceUSD.toStringAsFixed(2),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(width: compact ? 4 : 6),
          // Divider
          Container(
            width: 1,
            height: compact ? 8 : 12,
            color: AppColors.primary.withOpacity(0.25),
          ),
          SizedBox(width: compact ? 4 : 6),
          // Feathers
          FeatherIcon(size: iconSize + 1),
          const SizedBox(width: 2),
          Text(
            priceFeathers.toInt().toString(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
