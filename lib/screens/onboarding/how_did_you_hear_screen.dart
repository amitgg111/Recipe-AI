import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  final List<_SourceOption> _sources = [
    _SourceOption(
      label: "Google Search",
      icon: Icons.search,
      iconColor: const Color(0xFF6B6359),
      bgColor: const Color(0xFFF0EEE9),
    ),
    _SourceOption(
      label: "YouTube",
      icon: Icons.play_arrow,
      iconColor: const Color(0xFFDD3B33),
      bgColor: const Color(0xFFFCE2E0),
    ),
    _SourceOption(
      label: "TikTok",
      icon: Icons.music_note,
      iconColor: const Color(0xFF1F1F24),
      bgColor: const Color(0xFFECECEF),
    ),
    _SourceOption(
      label: "Through a friend",
      icon: Icons.people,
      iconColor: const Color(0xFF2F7AB5),
      bgColor: const Color(0xFFDCEBF4),
    ),
    _SourceOption(
      label: "App Store",
      icon: Icons.play_arrow,
      iconColor: const Color(0xFF2E9E5B),
      bgColor: const Color(0xFFE2F0E6),
    ),
    _SourceOption(
      label: "Facebook",
      icon: Icons.chat,
      iconColor: const Color(0xFF2D6FE0),
      bgColor: const Color(0xFFE4ECFB),
    ),
    _SourceOption(
      label: "Instagram",
      icon: Icons.camera_alt,
      iconColor: const Color(0xFFC13584),
      bgColor: const Color(0xFFFCE4EE),
    ),
    _SourceOption(
      label: "Other",
      icon: Icons.more_horiz,
      iconColor: const Color(0xFF8A7E70),
      bgColor: const Color(0xFFEFEAE0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26)
                  .copyWith(top: 16),
              child: const ProgressIndicatorDots(
                totalSteps: 8,
                currentStep: 6,
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Text(
                "How did you hear about us?",
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 25,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 26),
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceBorder,
                            ),
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
                              const SizedBox(width: 12),
                              Text(
                                source.label,
                                style: AppTextStyles.bodyLarge,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26)
                  .copyWith(bottom: 16, top: 18),
              child: Column(
                children: [
                  PrimaryButton(
                    label: "Continue",
                    onPressed: () {
                      Get.to(() => const RecipeSourcesScreen());
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
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
