import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/Controllers/onboarding_controller.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
import 'package:recipe_ai/screens/onboarding/awesome_import_screen.dart';

class RecipeSourcesScreen extends StatefulWidget {
  static const String routeName = '/onboarding/recipe-sources';

  const RecipeSourcesScreen({super.key});

  @override
  State<RecipeSourcesScreen> createState() => _RecipeSourcesScreenState();
}

class _RecipeSourcesScreenState extends State<RecipeSourcesScreen> {
  final Set<int> _selected = {0};

  void _toggle(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 26),
          child: Column(
            children: [
              // Logo + Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppWordmark(fontSize: 16, fontWeight: FontWeight.w700),
                ],
              ),
              const SizedBox(height: 10),
              const ProgressIndicatorDots(totalSteps: 8, currentStep: 7),
              // Title
              const SizedBox(height: 16),
              Text(
                'recipe_sources_title'.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 25,
                  height: 1.18,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'select_all_that_apply'.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 22),
              // Card 1: Social media (pre-selected)
              _SourceCard(
                title: 'social_media'.tr,
                isSelected: _selected.contains(0),
                onTap: () => _toggle(0),
                trailing: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SocialBadge(
                      iconKey: 'camera',
                      color: Color(0xFFC13584),
                      bg: Color(0xFFFCE4EE),
                    ),
                    SizedBox(width: 6),
                    _SocialBadge(
                      iconKey: 'music',
                      color: Color(0xFF1F1F24),
                      bg: Color(0xFFECECEF),
                    ),
                    SizedBox(width: 6),
                    _SocialBadge(
                      iconKey: 'chat',
                      color: Color(0xFF2D6FE0),
                      bg: Color(0xFFE4ECFB),
                    ),
                    SizedBox(width: 6),
                    _SocialBadge(
                      iconKey: 'pin',
                      color: Color(0xFFDD3B33),
                      bg: Color(0xFFFCE2E0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              // Card 2: Recipe websites
              _SourceCard(
                title: 'recipe_websites'.tr,
                isSelected: _selected.contains(1),
                onTap: () => _toggle(1),
                trailing: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SocialBadge(
                      iconKey: 'globe',
                      color: Color(0xFF2F7AB5),
                      bg: Color(0xFFDCEBF4),
                    ),
                    SizedBox(width: 6),
                    _SocialBadge(
                      iconKey: 'search',
                      color: Color(0xFF6B6359),
                      bg: Color(0xFFF0EEE9),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              // Card 3: Printed / handwritten
              _SourceCard(
                title: 'printed_handwritten'.tr,
                isSelected: _selected.contains(2),
                onTap: () => _toggle(2),
                trailing: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SocialBadge(
                      iconKey: 'book',
                      color: Color(0xFFE0552F),
                      bg: Color(0xFFFCE3DB),
                    ),
                    SizedBox(width: 6),
                    _SocialBadge(
                      iconKey: 'pencil',
                      color: Color(0xFF5E8A2C),
                      bg: Color(0xFFE7F0DC),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Continue button
              PrimaryButton(
                label: 'continue_'.tr,
                onPressed: () => Get.to(() => const AwesomeImportScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecipeSourcesBody extends StatefulWidget {
  /// Reports whether at least one source is selected (drives the Continue
  /// button).
  final ValueChanged<bool>? onValidityChanged;

  const RecipeSourcesBody({super.key, this.onValidityChanged});

  @override
  State<RecipeSourcesBody> createState() => _RecipeSourcesBodyState();
}

class _RecipeSourcesBodyState extends State<RecipeSourcesBody> {
  final OnboardingController _c = Get.find<OnboardingController>();
  // Restored from the shared controller so it survives back/forward navigation.
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<int>.from(_c.recipeSources);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onValidityChanged?.call(_selected.isNotEmpty);
    });
  }

  void _toggle(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
    // Persist immediately (local now, Firebase after the user authenticates).
    _c.setRecipeSources(_selected);
    widget.onValidityChanged?.call(_selected.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Title
          Text(
            'recipe_sources_title'.tr,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 1.18,
              letterSpacing: -0.50,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'select_all_that_apply'.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 22),
          // Card 1: Social media (pre-selected)
          _SourceCard(
            title: 'social_media'.tr,
            isSelected: _selected.contains(0),
            onTap: () => _toggle(0),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SocialBadge(
                  iconKey: 'camera',
                  color: Color(0xFFC13584),
                  bg: Color(0xFFFCE4EE),
                ),
                SizedBox(width: 6),
                _SocialBadge(
                  iconKey: 'music',
                  color: Color(0xFF1F1F24),
                  bg: Color(0xFFECECEF),
                ),
                SizedBox(width: 6),
                _SocialBadge(
                  iconKey: 'chat',
                  color: Color(0xFF2D6FE0),
                  bg: Color(0xFFE4ECFB),
                ),
                SizedBox(width: 6),
                _SocialBadge(
                  iconKey: 'pin',
                  color: Color(0xFFDD3B33),
                  bg: Color(0xFFFCE2E0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          // Card 2: Recipe websites
          _SourceCard(
            title: 'recipe_websites'.tr,
            isSelected: _selected.contains(1),
            onTap: () => _toggle(1),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SocialBadge(
                  iconKey: 'globe',
                  color: Color(0xFF2F7AB5),
                  bg: Color(0xFFDCEBF4),
                ),
                SizedBox(width: 6),
                _SocialBadge(
                  iconKey: 'search',
                  color: Color(0xFF6B6359),
                  bg: Color(0xFFF0EEE9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          // Card 3: Printed / handwritten
          _SourceCard(
            title: 'printed_handwritten'.tr,
            isSelected: _selected.contains(2),
            onTap: () => _toggle(2),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SocialBadge(
                  iconKey: 'book',
                  color: Color(0xFFE0552F),
                  bg: Color(0xFFFCE3DB),
                ),
                SizedBox(width: 6),
                _SocialBadge(
                  iconKey: 'pencil',
                  color: Color(0xFF5E8A2C),
                  bg: Color(0xFFE7F0DC),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget trailing;

  const _SourceCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF2623E).withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                    spreadRadius: -16,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.bodyLarge),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// One 28×28 rounded badge holding a stroke line-icon, rendered from the exact
/// SVG path data used by the HTML mock (outline style, 24-unit viewBox,
/// stroke-width 1.9, round caps/joins) so it matches the design pixel-for-pixel.
class _SocialBadge extends StatelessWidget {
  final String iconKey;
  final Color color;
  final Color bg;

  const _SocialBadge({
    required this.iconKey,
    required this.color,
    required this.bg,
  });

  // Icon geometry copied verbatim from the HTML `I` icon set (viewBox 0 0 24).
  // `{c}` is substituted with the icon colour for filled sub-shapes. The second
  // value is the render size in px (matching the HTML `sv(..., size)` calls).
  static const Map<String, ({String body, double size})> _icons = {
    'camera': (
      body:
          '<rect x="3" y="7" width="18" height="13" rx="4"/><circle cx="12" cy="13.5" r="3.4"/><circle cx="17" cy="10.5" r="1" fill="{c}" stroke="none"/>',
      size: 22,
    ),
    'music': (
      body:
          '<circle cx="7" cy="18" r="2.6"/><circle cx="17" cy="16" r="2.6"/><path d="M9.6 18V5l9.4-2v13"/>',
      size: 22,
    ),
    'chat': (
      body:
          '<path d="M4 6a1 1 0 0 1 1-1h14a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H9l-4 4z"/>',
      size: 22,
    ),
    'pin': (
      body: '<circle cx="12" cy="10" r="7"/><path d="M12 17v4"/>',
      size: 18,
    ),
    'globe': (
      body:
          '<circle cx="12" cy="12" r="8"/><path d="M4 12h16M12 4c2.5 2.4 2.5 13.6 0 16M12 4c-2.5 2.4-2.5 13.6 0 16"/>',
      size: 20,
    ),
    'search': (
      body: '<circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/>',
      size: 22,
    ),
    'book': (
      body:
          '<path d="M5 4h12a1 1 0 0 1 1 1v15H7a2 2 0 0 1-2-2z"/><path d="M5 17a2 2 0 0 1 2-2h11"/>',
      size: 22,
    ),
    'pencil': (
      body:
          '<path d="M4 20h4l10.5-10.5a2.1 2.1 0 0 0-3-3L5 17z"/><path d="M13.5 6.5l3 3"/>',
      size: 18,
    ),
  };

  static String _hex(Color c) {
    int ch(double v) => (v * 255).round().clamp(0, 255);
    String h(int v) => v.toRadixString(16).padLeft(2, '0');
    return '#${h(ch(c.r))}${h(ch(c.g))}${h(ch(c.b))}';
  }

  @override
  Widget build(BuildContext context) {
    final def = _icons[iconKey]!;
    final hex = _hex(color);
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
        'stroke="$hex" stroke-width="1.9" stroke-linecap="round" '
        'stroke-linejoin="round">${def.body.replaceAll('{c}', hex)}</svg>';
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: SvgPicture.string(svg, width: def.size, height: def.size),
    );
  }
}
