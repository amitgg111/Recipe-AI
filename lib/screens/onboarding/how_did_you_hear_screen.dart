import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
import 'package:recipe_ai/screens/onboarding/recipe_sources_screen.dart';

class HowDidYouHearScreen extends StatefulWidget {
  static const String routeName = '/onboarding/how-did-you-hear';

  const HowDidYouHearScreen({super.key});

  @override
  State<HowDidYouHearScreen> createState() => _HowDidYouHearScreenState();
}

class _HowDidYouHearScreenState extends State<HowDidYouHearScreen> {
  int? selectedSource;

  final List<_SourceOption> _sources = const [
    _SourceOption(
      label: 'Google Search',
      icon: Icons.search,
      iconColor: Color(0xFF6B6359),
      bgColor: Color(0xFFF0EEE9),
    ),
    _SourceOption(
      label: 'YouTube',
      icon: Icons.play_arrow,
      iconColor: Color(0xFFDD3B33),
      bgColor: Color(0xFFFCE2E0),
    ),
    _SourceOption(
      label: 'TikTok',
      icon: Icons.music_note,
      iconColor: Color(0xFF1F1F24),
      bgColor: Color(0xFFECECEF),
    ),
    _SourceOption(
      label: 'Through a friend',
      icon: Icons.people,
      iconColor: Color(0xFF2F7AB5),
      bgColor: Color(0xFFDCEBF4),
    ),
    _SourceOption(
      label: 'App store',
      icon: Icons.play_arrow,
      iconColor: Color(0xFF2E9E5B),
      bgColor: Color(0xFFE2F0E6),
    ),
    _SourceOption(
      label: 'Facebook',
      icon: Icons.chat_bubble,
      iconColor: Color(0xFF2D6FE0),
      bgColor: Color(0xFFE4ECFB),
    ),
    _SourceOption(
      label: 'Instagram',
      icon: Icons.camera_alt,
      iconColor: Color(0xFFC13584),
      bgColor: Color(0xFFFCE4EE),
    ),
    _SourceOption(
      label: 'Other',
      icon: Icons.more_horiz,
      iconColor: Color(0xFF8A7E70),
      bgColor: Color(0xFFEFEAE0),
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
                    child: const Icon(Icons.restaurant, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recipe AI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const ProgressIndicatorDots(
                totalSteps: 8,
                currentStep: 6,
              ),
              // Title
              const SizedBox(height: 16),
              Text(
                'How did you hear about us?',
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
                      final isSelected = selectedSource == index;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < _sources.length - 1 ? 11 : 0,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedSource = index;
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
                                        color: const Color(0xFFF2623E).withValues(alpha: 0.5),
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
                                    color: source.bgColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      source.icon,
                                      color: source.iconColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    source.label,
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
                label: 'Continue',
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
  const HowDidYouHearBody({super.key});

  @override
  State<HowDidYouHearBody> createState() => _HowDidYouHearBodyState();
}

class _HowDidYouHearBodyState extends State<HowDidYouHearBody> {
  // First option selected by default (single-select, always one active).
  int? selectedSource = 0;

  final List<_SourceOption> _sources = const [
    _SourceOption(
      label: 'Google Search',
      icon: Icons.search,
      iconColor: Color(0xFF6B6359),
      bgColor: Color(0xFFF0EEE9),
    ),
    _SourceOption(
      label: 'YouTube',
      icon: Icons.play_arrow,
      iconColor: Color(0xFFDD3B33),
      bgColor: Color(0xFFFCE2E0),
    ),
    _SourceOption(
      label: 'TikTok',
      icon: Icons.music_note,
      iconColor: Color(0xFF1F1F24),
      bgColor: Color(0xFFECECEF),
    ),
    _SourceOption(
      label: 'Through a friend',
      icon: Icons.people,
      iconColor: Color(0xFF2F7AB5),
      bgColor: Color(0xFFDCEBF4),
    ),
    _SourceOption(
      label: 'App store',
      icon: Icons.play_arrow,
      iconColor: Color(0xFF2E9E5B),
      bgColor: Color(0xFFE2F0E6),
    ),
    _SourceOption(
      label: 'Facebook',
      icon: Icons.chat_bubble,
      iconColor: Color(0xFF2D6FE0),
      bgColor: Color(0xFFE4ECFB),
    ),
    _SourceOption(
      label: 'Instagram',
      icon: Icons.camera_alt,
      iconColor: Color(0xFFC13584),
      bgColor: Color(0xFFFCE4EE),
    ),
    _SourceOption(
      label: 'Other',
      icon: Icons.more_horiz,
      iconColor: Color(0xFF8A7E70),
      bgColor: Color(0xFFEFEAE0),
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
            'How did you hear about us?',
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
                  final isSelected = selectedSource == index;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < _sources.length - 1 ? 11 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedSource = index;
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
                                    color: const Color(0xFFF2623E).withValues(alpha: 0.5),
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
                                color: source.bgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  source.icon,
                                  color: source.iconColor,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                source.label,
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
        ],
      ),
    );
  }
}

class _SourceOption {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _SourceOption({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}
