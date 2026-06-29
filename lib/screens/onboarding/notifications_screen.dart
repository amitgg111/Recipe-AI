import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
import 'package:recipe_ai/screens/onboarding/how_did_you_hear_screen.dart';

class NotificationsScreen extends StatefulWidget {
  static const String routeName = '/onboarding/notifications';

  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
                currentStep: 5,
              ),
              const SizedBox(height: 28),
              Text(
                "Get the right recipe at the right time",
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 25,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                "We'll send you a recipe idea at the time that works for you.",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 40),
              // Notification card
              Center(
                child: Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.surfaceBorder),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2A211B).withValues(alpha: 0.45),
                        blurRadius: 50,
                        offset: const Offset(0, 26),
                        spreadRadius: -26,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCE3DB),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.notifications,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  const TextSpan(text: "Allow "),
                                  TextSpan(
                                    text: "Recipe AI",
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: " to send you notifications?",
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: const Color(0xFFF4ECDF),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          child: Center(
                            child: Text(
                              "Allow",
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontSize: 16,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: const Color(0xFFF4ECDF),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          child: Center(
                            child: Text(
                              "Don't allow",
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8A7E70),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  "Turn off notifications anytime",
                  style: AppTextStyles.disclaimer.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFA8A092),
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: "Help me stay on track",
                onPressed: () {
                  Get.to(() => const HowDidYouHearScreen());
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
