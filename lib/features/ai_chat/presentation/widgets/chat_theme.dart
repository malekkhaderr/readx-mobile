import 'package:flutter/material.dart';

class ChatColors {
  // The chat always uses its own dark theme for immersive feel,
  // but adapts slightly if the app is in light mode.

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Core backgrounds
  static const Color backgroundDark = Color(0xFF0F0F1A);
  static const Color backgroundLight = Color(0xFFF5F4FA);

  static Color background(BuildContext context) =>
      _isDark(context) ? backgroundDark : backgroundLight;

  static const Color surfaceDark = Color(0xFF1A1B2E);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  static Color surface(BuildContext context) =>
      _isDark(context) ? surfaceDark : surfaceLight;

  static const Color cardBorderDark = Color(0xFF2A2D45);
  static const Color cardBorderLight = Color(0xFFE8E6F0);

  static Color cardBorder(BuildContext context) =>
      _isDark(context) ? cardBorderDark : cardBorderLight;

  // Accent — soft violet
  static const Color accent = Color(0xFFB8A9FF);
  static const Color accentLight = Color(0xFFD4CCFF);
  static const Color accentDim = Color(0xFF7B6FC4);
  static const Color accentOnLight = Color(0xFF7B61FF);

  static Color accentColor(BuildContext context) =>
      _isDark(context) ? accent : accentOnLight;

  // User message gradient
  static const Color userGradientStart = Color(0xFF4A3ABA);
  static const Color userGradientEnd = Color(0xFF6C5CE7);

  // Owl's message
  static const Color owlBubbleDark = Color(0xFF1E2035);
  static const Color owlBubbleLight = Color(0xFFF0EDFF);
  static const Color owlBubbleBorderDark = Color(0xFF2E3150);
  static const Color owlBubbleBorderLight = Color(0xFFE0DBFF);

  static Color owlBubble(BuildContext context) =>
      _isDark(context) ? owlBubbleDark : owlBubbleLight;
  static Color owlBubbleBorder(BuildContext context) =>
      _isDark(context) ? owlBubbleBorderDark : owlBubbleBorderLight;

  // Text
  static const Color textPrimaryDark = Color(0xFFF0EEF6);
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryDark = Color(0xFF9B9AB0);
  static const Color textSecondaryLight = Color(0xFF6E6E82);
  static const Color textMutedDark = Color(0xFF5E5D73);
  static const Color textMutedLight = Color(0xFFB0B0C0);
  static const Color textOnUser = Color(0xFFF8F7FF);

  static Color textPrimary(BuildContext context) =>
      _isDark(context) ? textPrimaryDark : textPrimaryLight;
  static Color textSecondary(BuildContext context) =>
      _isDark(context) ? textSecondaryDark : textSecondaryLight;
  static Color textMuted(BuildContext context) =>
      _isDark(context) ? textMutedDark : textMutedLight;

  // Status
  static const Color online = Color(0xFF50E3A0);
  static const Color error = Color(0xFFE85D5D);
  static const Color errorBgDark = Color(0xFF2A1B1B);
  static const Color errorBgLight = Color(0xFFFFF0F0);

  static Color errorBg(BuildContext context) =>
      _isDark(context) ? errorBgDark : errorBgLight;

  // Particles & glow
  static const Color particleViolet = Color(0xFFB8A9FF);
  static const Color particlePurple = Color(0xFF6C5CE7);
  static const Color glowPurple = Color(0xFF4A3ABA);

  // Input bar
  static const Color inputBgDark = Color(0xFF161828);
  static const Color inputBgLight = Color(0xFFF5F4FA);
  static const Color inputBorderDark = Color(0xFF2A2D45);
  static const Color inputBorderLight = Color(0xFFE8E6F0);
  static const Color inputSurfaceDark = Color(0xFF111322);
  static const Color inputSurfaceLight = Color(0xFFFFFFFF);

  static Color inputBg(BuildContext context) =>
      _isDark(context) ? inputBgDark : inputBgLight;
  static Color inputBorder(BuildContext context) =>
      _isDark(context) ? inputBorderDark : inputBorderLight;
  static Color inputSurface(BuildContext context) =>
      _isDark(context) ? inputSurfaceDark : inputSurfaceLight;
}
