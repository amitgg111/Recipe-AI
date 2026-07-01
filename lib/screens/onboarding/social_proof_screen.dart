import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
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
              const SizedBox(height: 12),
              // Progress dots (step 1 of 8, index 0)
              const ProgressIndicatorDots(
                totalSteps: 8,
                currentStep: 0,
              ),
              // Title area
              const SizedBox(height: 18),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    height: 1.15,
                    letterSpacing: -0.54,
                  ),
                  children: [
                    const TextSpan(text: "We've helped\n"),
                    TextSpan(
                      text: '10+ million cooks',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'be more organized and save time in the kitchen',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                ),
              ),
              // Testimonial card - flex:1, centered vertically
              Expanded(
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: AppColors.surfaceBorder),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2A211B)
                                  .withValues(alpha: 0.4),
                              blurRadius: 50,
                              offset: const Offset(0, 26),
                              spreadRadius: -28,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stars row
                            const SizedBox(height: 24),
                            Row(
                              children: List.generate(
                                5,
                                (index) => Padding(
                                  padding: EdgeInsets.only(
                                      right: index < 4 ? 4 : 0),
                                  child: const Icon(
                                    Icons.star,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Review title
                            Text(
                              'Life-changing for my recipe collection!',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Review text
                            Text(
                              'I used to screenshot recipes from Instagram and Pinterest, and they were always lost in my camera roll. Now I import them directly and keep everything organized in one place.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textBody,
                                height: 1.55,
                              ),
                            ),
                            // Divider
                            const SizedBox(height: 20),
                            Container(
                              height: 1,
                              color: AppColors.divider,
                            ),
                            const SizedBox(height: 18),
                            // Reviewer row
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEADFCF),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 11),
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
                      // Quote mark - positioned absolute, top -22, left 22
                      Positioned(
                        top: -22,
                        left: 22,
                        child: Text(
                          '“',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 74,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Continue button
              PrimaryButton(
                label: 'Continue',
                onPressed: () {
                  Get.to(() => const GoalsScreen());
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
// SocialProofBody — content-only version for single-screen onboarding flow
// ─────────────────────────────────────────────────────────────────────────────

class SocialProofBody extends StatelessWidget {
  const SocialProofBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Title area
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                height: 1.15,
                letterSpacing: -0.54,
              ),
              children: [
                const TextSpan(text: "We've helped\n"),
                TextSpan(
                  text: '10+ million cooks',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'be more organized and save time in the kitchen',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ),
          // Testimonial card - flex:1, centered vertically
          Expanded(
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.surfaceBorder),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2A211B)
                              .withValues(alpha: 0.4),
                          blurRadius: 50,
                          offset: const Offset(0, 26),
                          spreadRadius: -28,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stars row
                        const SizedBox(height: 24),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Padding(
                              padding: EdgeInsets.only(
                                  right: index < 4 ? 4 : 0),
                              child: const Icon(
                                Icons.star,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Review title
                        Text(
                          'Life-changing for my recipe collection!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Review text
                        Text(
                          'I used to screenshot recipes from Instagram and Pinterest, and they were always lost in my camera roll. Now I import them directly and keep everything organized in one place.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textBody,
                            height: 1.55,
                          ),
                        ),
                        // Divider
                        const SizedBox(height: 20),
                        Container(
                          height: 1,
                          color: AppColors.divider,
                        ),
                        const SizedBox(height: 18),
                        // Reviewer row
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEADFCF),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 11),
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
                  // Quote mark - positioned absolute, top -22, left 22
                  Positioned(
                    top: -22,
                    left: 22,
                    child: Text(
                      '“',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 74,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
