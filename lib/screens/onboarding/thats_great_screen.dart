import 'dart:math';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:recipe_ai/screens/onboarding/goals_happen_screen.dart';

class ThatsGreatScreen extends StatefulWidget {
  static const String routeName = '/onboarding/thats-great';

  const ThatsGreatScreen({super.key});

  @override
  State<ThatsGreatScreen> createState() => _ThatsGreatScreenState();
}

class _ThatsGreatScreenState extends State<ThatsGreatScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    // 4.2s duration, ease-in-out, infinite reverse
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 4200),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

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
                  AppWordmark(fontSize: 16, fontWeight: FontWeight.w700),
                ],
              ),
              const SizedBox(height: 12),
              // Progress dots (step 3 of 8, index 2)
              const ProgressIndicatorDots(totalSteps: 8, currentStep: 2),
              // Title area
              const SizedBox(height: 18),
              Text(
                'thats_great_title'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.54,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'thats_great_subtitle'.tr,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                ),
              ),
              // Center content - flex:1, column centered, gap 22
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Circular progress ring 210x210
                    SizedBox(
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
                              const SizedBox(height: 3),
                              Text(
                                'report_saving_money'.tr,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ],
                          ),
                          // Floating wallet icon - top-right
                          Positioned(
                            top: -6,
                            right: -6,
                            child: AnimatedBuilder(
                              animation: _floatController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatAnimation.value),
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
                                      color: const Color(
                                        0xFF2A211B,
                                      ).withValues(alpha: 0.45),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                      spreadRadius: -12,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: OnboardingLineIcon(
                                    'wallet',
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
                    const SizedBox(height: 22),
                    // Testimonial mini card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.surfaceBorder),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2A211B,
                            ).withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEADFCF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 13),
                          // Content column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Stars - color #F2A24C, gap 2px
                                Row(
                                  children: List.generate(
                                    5,
                                    (index) => Padding(
                                      padding: EdgeInsets.only(
                                        right: index < 4 ? 2 : 0,
                                      ),
                                      child: const OnboardingLineIcon(
                                        'starF',
                                        color: AppColors.starOrange,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Quote
                                Text(
                                  'saved_over_this_year'.tr,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Continue button
              PrimaryButton(
                label: 'continue_'.tr,
                onPressed: () {
                  Get.to(() => const GoalsHappenScreen());
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
// ThatsGreatBody — content-only widget for single-screen onboarding
// ─────────────────────────────────────────────────────────────────────────────

class ThatsGreatBody extends StatefulWidget {
  const ThatsGreatBody({super.key});

  @override
  State<ThatsGreatBody> createState() => _ThatsGreatBodyState();
}

class _ThatsGreatBodyState extends State<ThatsGreatBody>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;
  late final AnimationController _ringController;
  late final Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    // 4.2s duration, ease-in-out, infinite reverse
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 4200),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    // Ring sweeps 0 → 92% on entry, with the number counting up alongside it.
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _ringAnimation = Tween<double>(begin: 0, end: 0.92).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic),
    );
    _ringController.forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Title area
          Text(
            'thats_great_title'.tr,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.54,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'thats_great_subtitle'.tr,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ),
          // Center content - flex:1, column centered, gap 22
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular progress ring 210x210
                SizedBox(
                  width: 210,
                  height: 210,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Animated ring + counting number
                      AnimatedBuilder(
                        animation: _ringAnimation,
                        builder: (context, _) {
                          final p = _ringAnimation.value;
                          final pct = (p * 100).round();
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(220, 220),
                                painter: _ProgressRingPainter(
                                  progress: p,
                                  trackColor: const Color(0xFFF1E4CF),
                                  progressColor: AppColors.primary,
                                  strokeWidth: 18,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$pct',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 35,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textDark,
                                            height: 1,
                                            letterSpacing: -1.44,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '%',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 35,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textDark,
                                            height: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'report_saving_money'.tr,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      // Floating wallet icon - top-right
                      Positioned(
                        top: -6,
                        right: -6,
                        child: AnimatedBuilder(
                          animation: _floatController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatAnimation.value),
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
                                  color: const Color(
                                    0xFF2A211B,
                                  ).withValues(alpha: 0.45),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                  spreadRadius: -12,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: OnboardingLineIcon(
                                'wallet',
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
                const SizedBox(height: 22),
                // Testimonial mini card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.surfaceBorder),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2A211B).withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      _demoAvatar(),
                      const SizedBox(width: 13),
                      // Content column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stars - color #F2A24C, gap 2px
                            Row(
                              children: List.generate(
                                5,
                                (index) => Padding(
                                  padding: EdgeInsets.only(
                                    right: index < 4 ? 2 : 0,
                                  ),
                                  child: const OnboardingLineIcon(
                                    'starF',
                                    color: AppColors.starOrange,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Quote
                            Text(
                              'saved_over_this_year'.tr,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Progress ring painter
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// AnimatedBuilder helper
// ─────────────────────────────────────────────────────────────────────────────

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

/// Demo reviewer avatar (42px) with a graceful fallback while loading / offline.
Widget _demoAvatar() => ClipOval(
  child: Image.network(
    'https://i.pravatar.cc/120?img=45',
    width: 42,
    height: 42,
    fit: BoxFit.cover,
    loadingBuilder: (_, child, progress) =>
        progress == null ? child : _avatarFallback,
    errorBuilder: (_, __, ___) => _avatarFallback,
  ),
);

final Widget _avatarFallback = Container(
  width: 42,
  height: 42,
  alignment: Alignment.center,
  decoration: const BoxDecoration(
    color: Color(0xFFEADFCF),
    shape: BoxShape.circle,
  ),
  child: const Text(
    'L',
    style: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: AppColors.textDark,
    ),
  ),
);
