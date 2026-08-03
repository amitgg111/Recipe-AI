
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

  /// Convenience alias for [recipeColor] — kept so call sites that pass
  /// `color:` (e.g. `AppWordmark(color: Colors.white)`) keep working.
  /// If both are provided, [recipeColor] wins.
  final Color? color;

  const AppWordmark({
    super.key,
    this.fontSize = 22,
    this.fontWeight = FontWeight.w800,
    this.letterSpacing,
    this.recipeColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );

    // `recipeColor` takes priority; fall back to `color`, then the default
    // dark brand text color. "AI" always stays the primary orange.
    final resolvedRecipeColor = recipeColor ?? color ?? AppColors.textDark;

    return Text.rich(
      TextSpan(
        style: base.copyWith(color: resolvedRecipeColor),
        children: const [
          TextSpan(text: 'Recipe'),
          TextSpan(
            text: ' AI',
            style: TextStyle(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
