import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
import 'package:recipe_ai/screens/onboarding/goals_happen_screen.dart';

class ThatsGreatScreen extends StatefulWidget {
  static const String routeName = '/onboarding/thats-great';

  const ThatsGreatScreen({super.key});

  @override
  State<ThatsGreatScreen> createState() => _ThatsGreatScreenState();
}

class _ThatsGreatScreenState extends State<ThatsGreatScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _walletFloatController;
  late final Animation<double> _walletFloatAnimation;

  @override
  void initState() {
    super.initState();
    _walletFloatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _walletFloatAnimation = Tween<double>(begin: -6, end: 0).animate(
      CurvedAnimation(
        parent: _walletFloatController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _walletFloatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Progress dots
              Center(
                child: ProgressIndicatorDots(
                  totalSteps: 8,
                  currentStep: 2,
                ),
              ),
              const SizedBox(height: 28),
              // Title
              Text(
                "That's great!",
                style: AppTextStyles.screenTitle,
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                "Here's what members just like you are achieving with Recipe AI.",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 32),
              // Progress ring
              Center(
                child: SizedBox(
                  width: 210,
                  height: 210,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Ring
                      CustomPaint(
                        size: const Size(210, 210),
                        painter: _ProgressRingPainter(
                          progress: 0.92,
                          trackColor: const Color(0xFFF1E4CF),
                          progressColor: AppColors.primary,
                          strokeWidth: 18,
                        ),
                      ),
                      // Center text
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '92',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                    height: 1,
                                    letterSpacing: -1.44,
                                  ),
                                ),
                                TextSpan(
                                  text: '%',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'report saving money',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                      // Floating wallet icon
                      Positioned(
                        top: -6,
                        right: -6,
                        child: AnimatedBuilder(
                          animation: _walletFloatController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                  0, _walletFloatAnimation.value),
                              child: child,
                            );
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2A211B).withValues(alpha: 0.45),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                  spreadRadius: -12,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.account_balance_wallet,
                                color: AppColors.gold,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Testimonial mini card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (index) => const Icon(
                                Icons.star,
                                color: AppColors.starOrange,
                                size: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Saved over \$1,200 this year cooking at home.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Leslie A. · member since 2024',
                            style: AppTextStyles.smallLabel.copyWith(
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Continue button
              PrimaryButton(
                label: 'Continue',
                onPressed: () {
                  Get.to(() => const GoalsHappenScreen());
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

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = progress * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
