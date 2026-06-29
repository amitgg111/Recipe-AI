import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
import 'package:recipe_ai/screens/onboarding/notifications_screen.dart';

class WhenToCookScreen extends StatefulWidget {
  static const String routeName = '/onboarding/when-to-cook';

  const WhenToCookScreen({super.key});

  @override
  State<WhenToCookScreen> createState() => _WhenToCookScreenState();
}

class _WhenToCookScreenState extends State<WhenToCookScreen> {
  int? selectedIndex;

  final List<String> _options = [
    "In the morning, I like to plan ahead",
    "Around lunch time, when I start thinking about it",
    "In the evening, when I'm ready to cook",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ProgressIndicatorDots(
                totalSteps: 8,
                currentStep: 4,
              ),
              const SizedBox(height: 28),
              Text(
                "When do you usually think about what to cook?",
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitle.copyWith(
                  fontSize: 24,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "We'll check in at the right moment, not a random one.",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 28),
              ...List.generate(_options.length, (index) {
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
                          Expanded(
                            child: Text(
                              _options[index],
                              style: AppTextStyles.bodyLarge,
                            ),
                          ),
                          const SizedBox(width: 12),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFFF2623E)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFF2623E)
                                    : const Color(0xFFE7DECE),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    ),
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
                label: "Continue",
                onPressed: () {
                  Get.to(() => const NotificationsScreen());
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
