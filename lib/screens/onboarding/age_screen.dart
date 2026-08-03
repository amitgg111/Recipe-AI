import 'package:flutter/material.dart';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/Controllers/onboarding_controller.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:recipe_ai/screens/onboarding/setting_up_screen.dart';

class AgeScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  final int currentStep;
  final int totalSteps;

  const AgeScreen({
    super.key,
    this.onContinue,
    this.currentStep = 2,
    this.totalSteps = 7,
  });

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  int _selectedIndex = 1; // "25-34" selected by default

  List<String> get _ageRanges => [
    'age_24_and_under'.tr,
    '25–34',
    '35–44',
    '45–54',
    '55+',
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
              // Logo
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
              // Title
              const SizedBox(height: 16),
              Text(
                'how_old_are_you'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.50,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'age_personalize_note'.tr,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Age options
              ...List.generate(_ageRanges.length, (index) {
                final isSelected = _selectedIndex == index;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < _ageRanges.length - 1 ? 12 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 17,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.surfaceBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _ageRanges[index],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
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
                                width: isSelected ? 0 : 2,
                              ),
                            ),
                            child: isSelected
                                ? const OnboardingLineIcon(
                                    'check',
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              PrimaryButton(
                label: 'continue_'.tr,
                onPressed: widget.onContinue ??
                    () => Get.to(() => const SettingUpScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Content-only body widget for the single-screen onboarding architecture.
/// Renders the logo, title, subtitle and the tappable age options
/// (no progress dots, no CTA button).
class AgeBody extends StatefulWidget {
  const AgeBody({super.key});

  @override
  State<AgeBody> createState() => _AgeBodyState();
}

class _AgeBodyState extends State<AgeBody> {
  final OnboardingController _c = Get.find<OnboardingController>();
  late int _selectedIndex; // restored from the shared controller

  @override
  void initState() {
    super.initState();
    _selectedIndex = _c.age.value;
  }

  List<String> get _ageRanges => [
    'age_24_and_under'.tr,
    '25–34',
    '35–44',
    '45–54',
    '55+',
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
            'how_old_are_you'.tr,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.50,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'age_personalize_note'.tr,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Age options
          ...List.generate(_ageRanges.length, (index) {
            final isSelected = _selectedIndex == index;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _ageRanges.length - 1 ? 12 : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = index);
                  _c.setAge(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 17,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.surfaceBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _ageRanges[index],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
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
                            width: isSelected ? 0 : 2,
                          ),
                        ),
                        child: isSelected
                            ? const OnboardingLineIcon(
                                'check',
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
