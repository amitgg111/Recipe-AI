import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
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
  int? _selectedIndex;

  static const _ageRanges = ['24 and under', '25–34', '35–44', '45–54', '55+'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(
                child: ProgressIndicatorDots(
                  totalSteps: widget.totalSteps,
                  currentStep: widget.currentStep,
                ),
              ),
              const SizedBox(height: 36),
              Center(
                child: Text(
                  'How old are you?',
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 25),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    'We only use this to personalize your experience.',
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 14.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ...List.generate(_ageRanges.length, (index) {
                final isSelected = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 17,
                        vertical: 18,
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
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _ageRanges[index],
                              style: AppTextStyles.bodyLarge,
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
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 14)
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
                label: 'Continue',
                onPressed: widget.onContinue ?? () => Get.to(() => const SettingUpScreen()),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
