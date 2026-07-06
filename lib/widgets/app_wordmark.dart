import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';

/// The "Recipe AI" wordmark — "Recipe" in the dark brand color and "AI" in the
/// app's primary orange. Use this everywhere the app name is shown as a title
/// so the two-tone treatment stays consistent.
class AppWordmark extends StatelessWidget {
  final double fontSize;
  final FontWeight fontWeight;
  final double? letterSpacing;

  /// Colour of the "Recipe" part (defaults to the dark brand text). Pass white
  /// for placement over coloured/dark backgrounds; "AI" always stays primary.
  final Color? recipeColor;

  const AppWordmark({
    super.key,
    this.fontSize = 22,
    this.fontWeight = FontWeight.w800,
    this.letterSpacing,
    this.recipeColor,
  });

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
    return Text.rich(
      TextSpan(
        style: base.copyWith(color: recipeColor ?? AppColors.textDark),
        children: [
          const TextSpan(text: 'Recipe'),
          TextSpan( 
            text: ' AI',
            style: TextStyle(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
