import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/bottom_sheet_handle.dart';

/// "Import from social media" picker — matched 1:1 to design "28 · Social
/// media picker". Icons are the design's own SVG glyphs (camera / music / chat)
/// rendered white on the brand-coloured tiles.
class SocialPickerSheet extends StatelessWidget {
  const SocialPickerSheet({super.key});

  /// Returns the chosen platform key ('instagram' / 'tiktok' / 'facebook'),
  /// or null if dismissed.
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const SocialPickerSheet(),
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'import_from_social_media'.tr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2A211B),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'pick_recipe_source'.tr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8A7E70),
                  ),
                ),
                const SizedBox(height: 18),

                // Instagram — gradient tile + white camera glyph.
                _SocialOption(
                  icon: _tile(
                    child: Image.asset(
                      'assets/welcome/instragram.png',
                      height: 48,
                      width: 48,
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFEDA77),
                        Color(0xFFDD2A7B),
                        Color(0xFF8134AF),
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                  title: 'Instagram',
                  subtitle: 'reels_posts_saved'.tr,
                  onTap: () => Navigator.pop(context, 'instagram'),
                ),
                const SizedBox(height: 11),

                // TikTok — dark tile + white music glyph.
                _SocialOption(
                  icon: _tile(
                    child: Image.asset(
                      'assets/welcome/tiktok.png',
                      height: 48,
                      width: 48,
                    ),
                    color: const Color(0xFF1F1F24),
                  ),
                  title: 'TikTok',
                  subtitle: 'recipe_videos'.tr,
                  onTap: () => Navigator.pop(context, 'tiktok'),
                ),
                const SizedBox(height: 11),

                // Facebook — blue tile + white chat glyph.
                _SocialOption(
                  icon: _tile(
                    // child: _svg(_kChat, size: 22)
                    child: Image.asset(
                      'assets/welcome/facebook.png',
                      height: 48,
                      width: 48,
                    ),
                    color: const Color(0xFF2D6FE0),
                  ),
                  title: 'Facebook',
                  subtitle: 'posts_watch_videos'.tr,
                  onTap: () => Navigator.pop(context, 'facebook'),
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 48×48 rounded tile holding a white glyph.
  Widget _tile({required Widget child, Color? color, Gradient? gradient}) {
    return Container(
      // width: 48,
      // height: 48,
      alignment: Alignment.center,

      decoration: BoxDecoration(
        // color: color,
        // gradient: gradient,
        borderRadius: BorderRadius.circular(15),
      ),
      child: child,
    );
  }
}

// White design glyph, viewBox 0 0 24 24.
// Widget _svg(String inner, {double size = 22}) {
//   final svg =
//       '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
//       'fill="none" stroke="#FFFFFF" stroke-width="1.9" '
//       'stroke-linecap="round" stroke-linejoin="round">$inner</svg>';
//   return SvgPicture.string(svg, width: size, height: size);
// }

// Design icon paths (verbatim). The camera's viewfinder dot is a filled circle.
const _kCamera =
    '<rect x="3" y="7" width="18" height="13" rx="4"/>'
    '<circle cx="12" cy="13.5" r="3.4"/>'
    '<circle cx="17" cy="10.5" r="1" fill="#FFFFFF" stroke="none"/>';
const _kMusic =
    '<circle cx="7" cy="18" r="2.6"/>'
    '<circle cx="17" cy="16" r="2.6"/><path d="M9.6 18V5l9.4-2v13"/>';

const _kChevR = '<path d="M9 6l6 6-6 6"/>';

class _SocialOption extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SocialOption({
    required this.icon,
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
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight, // #FBF7F0
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.surfaceBorder), // #F0E7D6
        ),
        child: Row(
          children: [
            icon,
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
            SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
              'fill="none" stroke="#C7BCAC" stroke-width="1.9" '
              'stroke-linecap="round" stroke-linejoin="round">$_kChevR</svg>',
              width: 18,
              height: 18,
            ),
          ],
        ),
      ),
    );
  }
}
