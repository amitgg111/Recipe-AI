import 'package:flutter/material.dart';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/Controllers/onboarding_controller.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:recipe_ai/screens/onboarding/notifications_screen.dart';

class WhenToCookScreen extends StatefulWidget {
  static const String routeName = '/onboarding/when-to-cook';

  const WhenToCookScreen({super.key});

  @override
  State<WhenToCookScreen> createState() => _WhenToCookScreenState();
}

class _WhenToCookScreenState extends State<WhenToCookScreen> {
  int selectedIndex = 0; // First option selected by default

  final List<String> _options = [
    'In the morning, I like to plan ahead',
    'Around lunch time, when I start thinking about it',
    'In the evening, when I\'m ready to cook',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Logo + Progress row
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
              const SizedBox(height: 12),
              // Progress dots (step 5 of 8, index 4)
              const ProgressIndicatorDots(totalSteps: 8, currentStep: 4),
              // Title
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    Text(
                      'When do you usually think about what to cook?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        height: 1.2,
                        letterSpacing: -0.48,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "We'll check in at the right moment, not a random one.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMedium,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Options
              Expanded(
                child: Column(
                  children: List.generate(_options.length, (index) {
                    final isSelected = selectedIndex == index;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < _options.length - 1 ? 13 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Radio circle (left side per spec)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.unselectedBorder,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Center(
                                        child: OnboardingLineIcon(
                                          'check',
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 13),
                              // Label
                              Expanded(
                                child: Text(
                                  _options[index],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                    height: 1.3,
                                  ),
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
              // Bottom: Continue button
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Continue',
                onPressed: () {
                  Get.to(() => const NotificationsScreen());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WhenToCookBody — content-only widget for single-screen onboarding
// ─────────────────────────────────────────────────────────────────────────────

class WhenToCookBody extends StatefulWidget {
  const WhenToCookBody({super.key});

  @override
  State<WhenToCookBody> createState() => _WhenToCookBodyState();
}

class _WhenToCookBodyState extends State<WhenToCookBody> {
  final OnboardingController _c = Get.find<OnboardingController>();
  late int selectedIndex; // restored from the shared controller

  @override
  void initState() {
    super.initState();
    selectedIndex = _c.whenToCook.value;
  }

  final List<String> _options = [
    'In the morning, I like to plan ahead',
    'Around lunch time, when I start thinking about it',
    'In the evening, when I\'m ready to cook',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                Text(
                  'When do you usually think about what to cook?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    height: 1.2,
                    letterSpacing: -0.48,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "We'll check in at the right moment, not a random one.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Options
          Expanded(
            child: Column(
              children: List.generate(_options.length, (index) {
                final isSelected = selectedIndex == index;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < _options.length - 1 ? 13 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                      _c.setWhenToCook(index);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          // Radio circle (left side per spec)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.unselectedBorder,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Center(
                                    child: OnboardingLineIcon(
                                      'check',
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 13),
                          // Label
                          Expanded(
                            child: Text(
                              _options[index],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                                height: 1.3,
                              ),
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
        ],
      ),
    );
  }
}
