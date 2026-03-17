import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF7B61FF);
  static const Color primaryLight = Color(0xFFEDE9FF);

  // Background
  static const Color background = Color(0xFFF5F3EF);
  static const Color surface = Color(0xFFFFFFFF);

  // Text
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF9E9E9E);

  // Other
  static const Color divider = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFE53935);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      fontFamily: 'Inter',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class AppOwl extends StatefulWidget {
  final double size;
  const AppOwl({super.key, this.size = 140});

  @override
  State<AppOwl> createState() => _AppOwlState();
}

class _AppOwlState extends State<AppOwl> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: -12,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: child,
        );
      },
      child: Image.asset(
        'assets/images/owl.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );
  }
}
