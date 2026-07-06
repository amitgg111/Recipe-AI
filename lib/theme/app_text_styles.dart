import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base => GoogleFonts.plusJakartaSans();

  // Headlines
  static TextStyle heroTitle = _base.copyWith(
    fontSize: 33,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    letterSpacing: -0.99,
    height: 1.08,
  );

  static TextStyle screenTitle = _base.copyWith(
    fontSize: 27,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    letterSpacing: -0.54,
    height: 1.15,
  );

  static TextStyle sectionTitle = _base.copyWith(
    fontSize: 25,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    letterSpacing: -0.5,
    height: 1.18,
  );

  static TextStyle cardTitle = _base.copyWith(
    fontSize: 21,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    letterSpacing: -0.42,
  );

  static TextStyle listTitle = _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    letterSpacing: -0.18,
  );

  // Body
  static TextStyle bodyLarge = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static TextStyle bodyMedium = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textMedium,
    height: 1.5,
  );

  static TextStyle bodySmall = _base.copyWith(
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textMedium,
    height: 1.5,
  );

  static TextStyle bodyXSmall = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textMedium,
    height: 1.55,
  );

  // Labels
  static TextStyle buttonLabel = _base.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle navLabel = _base.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static TextStyle chipLabel = _base.copyWith(
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static TextStyle tagLabel = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static TextStyle smallLabel = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
  );

  static TextStyle tinyLabel = _base.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.46,
  );

  static TextStyle inputLabel = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
  );

  static TextStyle inputText = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static TextStyle inputHint = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textHintLight,
  );

  // Link
  static TextStyle link = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static TextStyle linkDark = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  // Section header
  static TextStyle sectionHeader = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF8C887E),
    letterSpacing: 0.65,
  );

  // Stats
  static TextStyle statLarge = _base.copyWith(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    height: 1,
    letterSpacing: -1.44,
  );

  static TextStyle statMedium = _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
  );

  // Bottom nav
  static TextStyle bottomNavActive = _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );

  static TextStyle bottomNavInactive = _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );

  // Misc
  static TextStyle disclaimer = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textLighter,
    height: 1.5,
  );

  static TextStyle trialPrice = _base.copyWith(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textLighter,
  );
}
