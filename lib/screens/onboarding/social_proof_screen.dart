import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
import 'package:recipe_ai/screens/onboarding/goals_screen.dart';

class SocialProofScreen extends StatefulWidget {
  static const String routeName = '/onboarding/social-proof';

  const SocialProofScreen({super.key});

  @override
  State<SocialProofScreen> createState() => _SocialProofScreenState();
}

class _SocialProofScreenState extends State<SocialProofScreen> {
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
              const SizedBox(height: 16),
              // Progress dots
              Center(
                child: ProgressIndicatorDots(
                  totalSteps: 8,
                  currentStep: 0,
                ),
              ),
              const SizedBox(height: 20),
              // Small logo
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restaurant, color: AppColors.primary, size: 18),
                    const SizedBox(width: 6),
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
              ),
              const SizedBox(height: 28),
              // Title
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 27),
                  children: [
                    const TextSpan(text: "We've helped\n"),
                    TextSpan(
                      text: '10+ million cooks',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                'be more organized and save time in the kitchen',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 28),
              // Testimonial card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.surfaceBorder),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2A211B).withValues(alpha: 0.4),
                      blurRadius: 50,
                      offset: const Offset(0, 26),
                      spreadRadius: -28,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Big quotation mark
                    Text(
                      '“',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 74,
                        color: AppColors.primary,
                        height: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Stars
                    Row(
                      children: List.generate(
                        5,
                        (index) => const Icon(
                          Icons.star,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Review text
                    Text(
                      'I used to screenshot recipes from Instagram and Pinterest, and they were always lost in my camera roll. Now I import them directly and keep everything organized in one place.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textBody,
                        height: 1.5,
                      ),
                    ),
                    Divider(color: AppColors.divider, height: 32),
                    // Reviewer info
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEADFCF),
                            borderRadius: BorderRadius.circular(21),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Leslie A.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Continue button
              PrimaryButton(
                label: 'Continue',
                onPressed: () {
                  Get.to(() => const GoalsScreen());
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
