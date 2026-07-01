import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
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
              // Progress dots (step 6 of 8, index 5)
              const ProgressIndicatorDots(
                totalSteps: 8,
                currentStep: 5,
              ),
              // Title
              const SizedBox(height: 18),
              Text(
                'Get the right recipe at the right time',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1.18,
                  letterSpacing: -0.50,
                ),
              ),
              const SizedBox(height: 11),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "We'll send you a recipe idea at the time that works for you.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                ),
              ),
              // Center content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Notification dialog card
                    SizedBox(
                      width: 300,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: AppColors.surfaceBorder),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2A211B)
                                  .withValues(alpha: 0.45),
                              blurRadius: 50,
                              offset: const Offset(0, 26),
                              spreadRadius: -26,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Top section
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(22, 24, 22, 18),
                              child: Column(
                                children: [
                                  // Bell icon
                                  Container(
                                    width: 58,
                                    height: 58,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: AppColors.redBg,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.notifications,
                                        color: AppColors.primary,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                  // Permission text
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                        height: 1.35,
                                      ),
                                      children: [
                                        const TextSpan(text: 'Allow '),
                                        TextSpan(
                                          text: 'Recipe AI',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                            height: 1.35,
                                          ),
                                        ),
                                        const TextSpan(
                                          text:
                                              ' to send you notifications?',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Allow button
                            Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: AppColors.divider,
                                  ),
                                ),
                              ),
                              child: GestureDetector(
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Center(
                                    child: Text(
                                      'Allow',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Don't allow button
                            Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: AppColors.divider,
                                  ),
                                ),
                              ),
                              child: GestureDetector(
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Center(
                                    child: Text(
                                      "Don't allow",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMedium,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Below card text
                    const SizedBox(height: 18),
                    Text(
                      'Turn off notifications anytime',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textLighter,
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom: Help me stay on track button
              PrimaryButton(
                label: 'Help me stay on track',
                onPressed: () {
                  Get.to(() => const HowDidYouHearScreen());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationsBody extends StatelessWidget {
  const NotificationsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Title
          Text(
            'Get the right recipe at the right time',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 1.18,
              letterSpacing: -0.50,
            ),
          ),
          const SizedBox(height: 11),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "We'll send you a recipe idea at the time that works for you.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ),
          // Center content
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Notification dialog card
                SizedBox(
                  width: 300,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.surfaceBorder),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2A211B)
                              .withValues(alpha: 0.45),
                          blurRadius: 50,
                          offset: const Offset(0, 26),
                          spreadRadius: -26,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top section
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(22, 24, 22, 18),
                          child: Column(
                            children: [
                              // Bell icon
                              Container(
                                width: 58,
                                height: 58,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.redBg,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.notifications,
                                    color: AppColors.primary,
                                    size: 30,
                                  ),
                                ),
                              ),
                              // Permission text
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                    height: 1.35,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Allow '),
                                    TextSpan(
                                      text: 'Recipe AI',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                        height: 1.35,
                                      ),
                                    ),
                                    const TextSpan(
                                      text:
                                          ' to send you notifications?',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Allow button
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppColors.divider,
                              ),
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Center(
                                child: Text(
                                  'Allow',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Don't allow button
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppColors.divider,
                              ),
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Center(
                                child: Text(
                                  "Don't allow",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMedium,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Below card text
                const SizedBox(height: 18),
                Text(
                  'Turn off notifications anytime',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textLighter,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
