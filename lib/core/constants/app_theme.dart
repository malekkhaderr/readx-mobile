import 'package:flutter/material.dart';

// ─── Dynamic Color Palette ──────────────────────────────────────
// AppColors holds mutable static fields that get swapped when the
// theme changes. All files using AppColors.xxx auto-adapt.
// Fields are NOT const/final so they can be reassigned.

class AppColors {
  AppColors._();

  static Color primary = const Color(0xFF5B4EC4);
  static Color primaryLight = const Color(0xFFEEEBFF);
  static Color primaryDark = const Color(0xFF3D2E9E);

  static Color background = const Color(0xFFF4F3F7);
  static Color surface = const Color(0xFFFFFFFF);
  static Color cardBackground = const Color(0xFFF8F7FB);
  static Color ivory = const Color(0xFFEFEEF3);

  static Color textDark = const Color(0xFF1C1B2A);
  static Color textGrey = const Color(0xFF5A596E);
  static Color textLight = const Color(0xFF8E8DA3);

  static Color accent = const Color(0xFFE8505B);
  static Color gold = const Color(0xFFD4930D);
  static Color successGreen = const Color(0xFF1AA367);
  static Color warningOrange = const Color(0xFFE8820A);

  static Color gradientStart = const Color(0xFF4A3FB0);
  static Color gradientEnd = const Color(0xFF7B6BDF);

  static Color divider = const Color(0xFFE4E2EC);
  static Color error = const Color(0xFFCC3030);
  static Color shimmer = const Color(0xFFEEEBFF);

  static void setLight() {
    primary = const Color(0xFF5B4EC4);
    primaryLight = const Color(0xFFEEEBFF);
    primaryDark = const Color(0xFF3D2E9E);
    background = const Color(0xFFF4F3F7);
    surface = const Color(0xFFFFFFFF);
    cardBackground = const Color(0xFFF8F7FB);
    ivory = const Color(0xFFEFEEF3);
    textDark = const Color(0xFF1C1B2A);
    textGrey = const Color(0xFF5A596E);
    textLight = const Color(0xFF8E8DA3);
    accent = const Color(0xFFE8505B);
    gold = const Color(0xFFD4930D);
    successGreen = const Color(0xFF1AA367);
    warningOrange = const Color(0xFFE8820A);
    gradientStart = const Color(0xFF4A3FB0);
    gradientEnd = const Color(0xFF7B6BDF);
    divider = const Color(0xFFE4E2EC);
    error = const Color(0xFFCC3030);
    shimmer = const Color(0xFFEEEBFF);
  }

  static void setDark() {
    primary = const Color(0xFFB8A9FF);
    primaryLight = const Color(0xFF2A2545);
    primaryDark = const Color(0xFF9D8AFF);
    background = const Color(0xFF0F0F1A);
    surface = const Color(0xFF1A1B2E);
    cardBackground = const Color(0xFF1E2035);
    ivory = const Color(0xFF161828);
    textDark = const Color(0xFFF0EEF6);
    textGrey = const Color(0xFF9B9AB0);
    textLight = const Color(0xFF5E5D73);
    accent = const Color(0xFFFF8A80);
    gold = const Color(0xFFFFD54F);
    successGreen = const Color(0xFF50E3A0);
    warningOrange = const Color(0xFFFFB74D);
    gradientStart = const Color(0xFF2D1F5E);
    gradientEnd = const Color(0xFF4A3A8A);
    divider = const Color(0xFF2A2D45);
    error = const Color(0xFFE85D5D);
    shimmer = const Color(0xFF2A2545);
  }

  static void updateBrightness(Brightness brightness) {
    if (brightness == Brightness.dark) {
      setDark();
    } else {
      setLight();
    }
  }
}

// ─── Text Styles ────────────────────────────────────────────────

class AppTextStyles {
  static TextStyle get heading1 => TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark, height: 1.3);
  static TextStyle get heading2 => TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark, height: 1.3);
  static TextStyle get heading3 => TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark);
  static TextStyle get body => TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textDark, height: 1.5);
  static TextStyle get caption => TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textGrey);
  static TextStyle get label => TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey, letterSpacing: 0.5);
  static const TextStyle button = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white);
}

// ─── Theme Data ─────────────────────────────────────────────────

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F3F7),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B4EC4), primary: const Color(0xFF5B4EC4), surface: const Color(0xFFFFFFFF), error: const Color(0xFFCC3030), brightness: Brightness.light),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFFFFFFF), elevation: 0, surfaceTintColor: Colors.transparent, iconTheme: IconThemeData(color: Color(0xFF1C1B2A)), titleTextStyle: TextStyle(color: Color(0xFF1C1B2A), fontSize: 18, fontWeight: FontWeight.w700)),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFFF8F7FB), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE4E2EC))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF5B4EC4), width: 1.5)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCC3030)))),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4EC4), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0, textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      cardColor: const Color(0xFFFFFFFF),
      dividerColor: const Color(0xFFE4E2EC),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1C1B2A), letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1C1B2A)),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1C1B2A)),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFF1C1B2A), height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF1C1B2A), height: 1.5),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF5A596E)),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5A596E), letterSpacing: 0.5),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB8A9FF), primary: const Color(0xFFB8A9FF), surface: const Color(0xFF1A1B2E), error: const Color(0xFFE85D5D), brightness: Brightness.dark),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A1B2E), elevation: 0, surfaceTintColor: Colors.transparent, iconTheme: IconThemeData(color: Color(0xFFF0EEF6)), titleTextStyle: TextStyle(color: Color(0xFFF0EEF6), fontSize: 18, fontWeight: FontWeight.w700)),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF1E2035), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2A2D45))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFB8A9FF), width: 1.5)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE85D5D)))),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB8A9FF), foregroundColor: const Color(0xFF0F0F1A), minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0, textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      cardColor: const Color(0xFF1A1B2E),
      dividerColor: const Color(0xFF2A2D45),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFFF0EEF6), letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFF0EEF6)),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFF0EEF6)),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFFF0EEF6), height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFFF0EEF6), height: 1.5),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF9B9AB0)),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9B9AB0), letterSpacing: 0.5),
      ),
    );
  }
}

// ─── Owl Animation ──────────────────────────────────────────────

class AppOwl extends StatefulWidget {
  final double size;
  const AppOwl({super.key, this.size = 140});
  @override State<AppOwl> createState() => _AppOwlState();
}

class _AppOwlState extends State<AppOwl> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: -12).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) => Transform.translate(offset: Offset(0, _bounceAnimation.value), child: child),
      child: Image.asset('assets/images/owl.png', width: widget.size, height: widget.size, fit: BoxFit.contain),
    );
  }
}
