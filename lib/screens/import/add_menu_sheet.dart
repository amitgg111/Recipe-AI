import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/bottom_sheet_handle.dart';

/// "Add to Recipe AI" menu — matched 1:1 to design "24 · Add menu".
///
/// Icons are the design's own SVG glyphs: a filled sparkle for "Add a Recipe"
/// (orange tile) and an outline book for "Add a Cookbook" (purple tile).
class AddMenuSheet extends StatelessWidget {
  /// Invoked (after the sheet closes) when the user taps "Add a Recipe".
  final VoidCallback? onAddRecipe;

  /// Invoked (after the sheet closes) when the user taps "Add a Cookbook".
  final VoidCallback? onAddCookbook;

  const AddMenuSheet({super.key, this.onAddRecipe, this.onAddCookbook});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onAddRecipe,
    VoidCallback? onAddCookbook,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMenuSheet(
        onAddRecipe: onAddRecipe,
        onAddCookbook: onAddCookbook,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add to Recipe AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2A211B),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 16),
                _OptionRow(
                  iconBgColor: const Color(0xFFFCE3DB),
                  iconGlyph: _glyph(
                    _kSpark,
                    size: 22,
                    color: '#F2623E',
                    filled: true,
                  ),
                  title: 'Add a Recipe',
                  subtitle: 'Import from anywhere',
                  onTap: () {
                    Navigator.pop(context);
                    onAddRecipe?.call();
                  },
                ),
                const SizedBox(height: 12),
                _OptionRow(
                  iconBgColor: const Color(0xFFEDE7FE),
                  iconGlyph: _glyph(_kBook, size: 22, color: '#7C3AED'),
                  title: 'Add a Cookbook',
                  subtitle: 'Start a new collection',
                  onTap: () {
                    Navigator.pop(context);
                    onAddCookbook?.call();
                  },
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Design glyph, viewBox 0 0 24 24.
Widget _glyph(
  String inner, {
  required double size,
  required String color,
  double stroke = 1.9,
  bool filled = false,
}) {
  final attrs = filled
      ? 'fill="$color" stroke="none"'
      : 'fill="none" stroke="$color" stroke-width="$stroke" '
          'stroke-linecap="round" stroke-linejoin="round"';
  final svg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" $attrs>'
      '$inner</svg>';
  return SvgPicture.string(svg, width: size, height: size);
}

const _kSpark =
    '<path d="M12 2l1.9 5.6L19.5 9.5 14 11.4 12 17l-1.9-5.6L4.5 9.5l5.6-1.9z"/>';
const _kBook = '<path d="M5 4h12a1 1 0 0 1 1 1v15H7a2 2 0 0 1-2-2z"/>'
    '<path d="M5 17a2 2 0 0 1 2-2h11"/>';
const _kChevR = '<path d="M9 6l6 6-6 6"/>';

class _OptionRow extends StatelessWidget {
  final Color iconBgColor;
  final Widget iconGlyph;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _OptionRow({
    required this.iconBgColor,
    required this.iconGlyph,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight, // #FBF7F0
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.surfaceBorder), // #F0E7D6
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: iconGlyph,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2A211B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8A7E70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _glyph(_kChevR, size: 18, color: '#C7BCAC'),
          ],
        ),
      ),
    );
  }
}
