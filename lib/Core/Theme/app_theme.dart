import 'package:flutter/material.dart';

class AppTheme {
  // =========================
  // Light Colors
  // =========================

  static const Color primary = Color(0xFFFF6B35);
  static const Color secondary = Color(0xFFF7931E);

  static const Color lightBackground = Color(0xFFFFF8F2);
  static const Color lightSurface = Color(0xFFFFFFFF);

  static const Color lightTextPrimary = Color(0xFF1E1E1E);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const Color lightBorder = Color(0xFFE5E7EB);

  // =========================
  // Dark Colors
  // =========================

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  static const Color darkBorder = Color(0xFF2D2D2D);

  // =========================
  // Theme Getters
  // =========================

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? darkBackground : lightBackground;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  // =========================
  // Light Theme
  // =========================

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: lightSurface,
      error: error,
    ),
    scaffoldBackgroundColor: lightBackground,
  );

  // =========================
  // Dark Theme
  // =========================

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: darkSurface,
      error: error,
    ),
    scaffoldBackgroundColor: darkBackground,
  );
}