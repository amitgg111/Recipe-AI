import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/Controllers/onboarding_controller.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
import 'package:recipe_ai/screens/onboarding/recipe_sources_screen.dart';
import 'package:recipe_ai/Service/analytics_service.dart';

class HowDidYouHearScreen extends StatefulWidget {
  static const String routeName = '/onboarding/how-did-you-hear';

  const HowDidYouHearScreen({super.key});

  @override
  State<HowDidYouHearScreen> createState() => _HowDidYouHearScreenState();
}

class _HowDidYouHearScreenState extends State<HowDidYouHearScreen> {
  // Multi-select; the user can pick any number of sources. Nothing is
  // highlighted until they tap (selection is shown by the card's border).
  final Set<int> _selectedSources = <int>{};

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen('HowDidYouHearScreen');
  }

  // Exactly the eight sources shown in the design, in order.
  final List<_SourceOption> _sources = const [
    _SourceOption(
      label: 'Google Search',
      icon: 'assets/welcome/google.svg',
      // iconColor: Color(0xFF6B6359),
      // bgColor: Color(0xFFF0EEE9),
    ),
    _SourceOption(
      label: 'YouTube',
      icon: 'assets/welcome/youtube.svg',
      // iconColor: Color(0xFFDD3B33),
      // bgColor: Color(0xFFFCE2E0),
    ),
    _SourceOption(
      label: 'TikTok',
      icon: 'assets/welcome/tiktok.svg',
      // iconColor: Colors.white,
      // bgColor: Color(0xFF1F1F24),
    ),
    _SourceOption(
      label: 'source_through_a_friend',
      icon: '',
      // iconColor: Color(0xFF5B63D3),
      // bgColor: Color(0xFFE8E9FB),
    ),
    _SourceOption(
      label: 'App store',
      icon: 'assets/welcome/apple.svg',
      // iconColor: Color(0xFF2E9E5B),
      // bgColor: Color(0xFFE2F0E6),
    ),
    _SourceOption(
      label: 'Facebook',
      icon: 'assets/welcome/facebook.svg',
      // iconColor: Color(0xFF2D6FE0),
      // bgColor: Color(0xFFE4ECFB),
    ),
    _SourceOption(
      label: 'Instagram',
      icon: 'assets/welcome/instagram.svg',

      // iconColor: Color(0xFFC13584),
      // bgColor: Color(0xFFFCE4EE),
    ),
    _SourceOption(
      label: 'source_other',
      icon: '',
      // iconColor: Color(0xFF8A7E70),
      // bgColor: Color(0xFFEFEAE0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 30),
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
                  const AppWordmark(fontSize: 16, fontWeight: FontWeight.w700),
                ],
              ),
              const SizedBox(height: 10),
              const ProgressIndicatorDots(totalSteps: 8, currentStep: 6),
              // Title
              const SizedBox(height: 16),
              Text(
                'how_did_you_hear_title'.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 25,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              // Source tiles list (scrollable)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(_sources.length, (index) {
                      final source = _sources[index];
                      final isSelected = _selectedSources.contains(index);
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < _sources.length - 1 ? 11 : 0,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_selectedSources.contains(index)) {
                                _selectedSources.remove(index);
                              } else {
                                _selectedSources.add(index);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.surfaceBorder,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFF2623E,
                                        ).withValues(alpha: 0.5),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                        spreadRadius: -16,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    // color: source.bgColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: _SourceLeadingIcon(source),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    source.label.tr,
                                    style: AppTextStyles.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              // Continue button
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'continue_'.tr,
                onPressed: () {
                  Get.to(() => const RecipeSourcesScreen());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HowDidYouHearBody extends StatefulWidget {
  /// Reports whether at least one source is selected (drives the Continue
  /// button — it stays disabled until the user picks one).
  final ValueChanged<bool>? onValidityChanged;

  const HowDidYouHearBody({super.key, this.onValidityChanged});

  @override
  State<HowDidYouHearBody> createState() => _HowDidYouHearBodyState();
}

class _HowDidYouHearBodyState extends State<HowDidYouHearBody> {
  final OnboardingController _c = Get.find<OnboardingController>();
  // Multi-select attribution sources, restored from the shared controller so
  // the selections survive navigating back/forward and app restarts.
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(_c.attributionSources);
    // Continue stays DISABLED until at least one source is picked (nothing is
    // selected by default). Report the restored validity after the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onValidityChanged?.call(_selected.isNotEmpty);
    });
  }

  void _toggle(String key) {
    setState(() {
      if (_selected.contains(key)) {
        _selected.remove(key);
      } else {
        _selected.add(key);
      }
    });
    // Persist immediately (local now, Firebase after the user authenticates).
    _c.setAttributionSources(_selected);
    widget.onValidityChanged?.call(_selected.isNotEmpty);
  }

  // Exactly the eight sources shown in the design, in order. Stable keys are
  // stored in Firebase (robust to label/icon changes).
  static const List<_SourceOption> _sources = [
    _SourceOption(
      key: 'google_search',
      label: 'Google Search',
      icon: 'assets/welcome/google.svg',
      // iconColor: Color(0xFF6B6359),
      // bgColor: Color(0xFFF0EEE9),
    ),
    _SourceOption(
      key: 'youtube',
      label: 'YouTube',
      icon: 'assets/welcome/youtube.svg',
      // iconColor: Color(0xFFDD3B33),
      // bgColor: Color(0xFFFCE2E0),
    ),

    _SourceOption(
      key: 'app_store',
      label: 'App store',
      icon: 'assets/welcome/apple.svg',
      // iconColor: Color(0xFF2E9E5B),
      // bgColor: Color(0xFFE2F0E6),
    ),
    _SourceOption(
      key: 'facebook',
      label: 'Facebook',
      icon: 'assets/welcome/facebook.svg',

      // iconColor: Color(0xFF2D6FE0),
      // bgColor: Color(0xFFE4ECFB),
    ),
    _SourceOption(
      key: 'instagram',
      label: 'Instagram',
      icon: 'assets/welcome/instagram.svg',

      // iconColor: Color(0xFFC13584),
      // bgColor: Color(0xFFFCE4EE),
    ),
    _SourceOption(
      key: 'other',
      label: 'source_other',
      icon: '',
      // iconColor: Color(0xFF8A7E70),
      // bgColor: Color(0xFFEFEAE0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Title
          Text(
            'how_did_you_hear_title'.tr,
            textAlign: TextAlign.center,

            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 1.18,
              letterSpacing: -0.50,
            ),
          ),

          const SizedBox(height: 14),
          // Source tiles list (scrollable, multi-select)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(_sources.length, (index) {
                  final source = _sources[index];
                  final isSelected = _selected.contains(source.key);
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < _sources.length - 1 ? 11 : 0,
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _toggle(source.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),

                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF2623E,
                                    ).withValues(alpha: 0.5),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                    spreadRadius: -16,
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(child: _SourceLeadingIcon(source)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                source.label.tr,
                                style: AppTextStyles.bodyLarge,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Multi-select checkbox indicator.
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.surfaceBorder,
                                  width: 1.6,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceOption {
  final String key;
  final String label;
  final String icon;
  // final Color iconColor;
  // final Color bgColor;

  /// Render the custom Instagram glyph instead of [icon] (Material has no
  /// Instagram logo, so it's drawn by [_InstagramGlyphPainter]).

  const _SourceOption({
    this.key = '',
    required this.label,
    required this.icon,

    // required this.iconColor,
    // required this.bgColor,
  });
}

class _SourceLeadingIcon extends StatelessWidget {
  final _SourceOption option;

  const _SourceLeadingIcon(this.option);

  @override
  Widget build(BuildContext context) {
    // SVG icon available હોય તો actual SVG image બતાવશે.
    if (option.icon.isNotEmpty) {
      return SvgPicture.asset(
        option.icon,
        width: 30,
        height: 30,
        fit: BoxFit.contain,
      );
    }

    // Friend / Other માટે fallback icon
    return Icon(
      option.key == 'friend'
          ? Icons.people_outline_rounded
          : Icons.more_horiz_rounded,
      size: 20,
      // color: option.iconColor,
    );
  }
}
