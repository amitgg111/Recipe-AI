import 'package:flutter/material.dart';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:recipe_ai/screens/onboarding/when_to_cook_screen.dart';

class GoalsHappenScreen extends StatefulWidget {
  static const String routeName = '/onboarding/goals-happen';

  const GoalsHappenScreen({super.key});

  @override
  State<GoalsHappenScreen> createState() => _GoalsHappenScreenState();
}

class _GoalsHappenScreenState extends State<GoalsHappenScreen> {
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
              // Progress dots (step 4 of 8, index 3)
              const ProgressIndicatorDots(totalSteps: 8, currentStep: 3),
              // Title
              const SizedBox(height: 18),
              Text(
                "Let's make your\ngoals happen!",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1.15,
                  letterSpacing: -0.52,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "You want to save money and eat healthier — we'll help you get there.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                ),
              ),
              // Content area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Progress chart card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.surfaceBorder),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2A211B,
                              ).withValues(alpha: 0.4),
                              blurRadius: 38,
                              offset: const Offset(0, 18),
                              spreadRadius: -24,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Your progress',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.greenBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const OnboardingLineIcon(
                                        'spark',
                                        size: 12,
                                        color: AppColors.green,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'ON TRACK',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Chart
                            SizedBox(
                              height: 92,
                              child: CustomPaint(
                                size: const Size(double.infinity, 92),
                                painter: _ProgressChartPainter(),
                              ),
                            ),
                            // Week labels
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Wk 1',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSubtle,
                                  ),
                                ),
                                Text(
                                  'Wk 2',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSubtle,
                                  ),
                                ),
                                Text(
                                  'Wk 3',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSubtle,
                                  ),
                                ),
                                Text(
                                  'Wk 4',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSubtle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      // 2-column grid
                      Row(
                        children: [
                          // Card 1: Eat healthier
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: AppColors.greenBgLight,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.greenBorder,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: OnboardingLineIcon(
                                        'bowl',
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 11),
                                  Text(
                                    'Eat healthier',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Balanced, fresh meals',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.greenText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Card 2: Save money
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: AppColors.goldBg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.goldBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.gold,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: OnboardingLineIcon(
                                        'wallet',
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 11),
                                  Text(
                                    'Save money',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cook more, waste less',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.goldText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom: Continue button
              PrimaryButton(
                label: 'Continue',
                onPressed: () {
                  Get.to(
                    () => const WhenToCookScreen(),
                    transition: Transition.rightToLeftWithFade,
                    duration: const Duration(milliseconds: 350),
                  );
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
// GoalsHappenBody — content-only widget for single-screen onboarding
// ─────────────────────────────────────────────────────────────────────────────

class GoalsHappenBody extends StatefulWidget {
  const GoalsHappenBody({super.key});

  @override
  State<GoalsHappenBody> createState() => _GoalsHappenBodyState();
}

class _GoalsHappenBodyState extends State<GoalsHappenBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _chartController;
  late final Animation<double> _chartAnim;

  @override
  void initState() {
    super.initState();
    // The progress curve draws in left → right on entry.
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _chartAnim = CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeInOutCubic,
    );
    _chartController.forward();
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Title
          Text(
            "Let's make your\ngoals happen!",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 1.15,
              letterSpacing: -0.52,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "You want to save money and eat healthier —we'll help you get there.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ),
          // Content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Progress chart card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.surfaceBorder),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2A211B).withValues(alpha: 0.4),
                          blurRadius: 38,
                          offset: const Offset(0, 18),
                          spreadRadius: -24,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your progress',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.greenBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const OnboardingLineIcon(
                                    'spark',
                                    size: 12,
                                    color: AppColors.green,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'ON TRACK',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Chart
                        SizedBox(
                          height: 92,
                          child: AnimatedBuilder(
                            animation: _chartAnim,
                            builder: (context, _) => CustomPaint(
                              size: const Size(double.infinity, 92),
                              painter: _ProgressChartPainter(
                                progress: _chartAnim.value,
                              ),
                            ),
                          ),
                        ),
                        // Week labels
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Wk 1',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSubtle,
                              ),
                            ),
                            Text(
                              'Wk 2',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSubtle,
                              ),
                            ),
                            Text(
                              'Wk 3',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSubtle,
                              ),
                            ),
                            Text(
                              'Wk 4',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  // 2-column grid
                  Row(
                    children: [
                      // Card 1: Eat healthier
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: AppColors.greenBgLight,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.greenBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: OnboardingLineIcon(
                                    'bowl',
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 11),
                              Text(
                                'Eat healthier',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Balanced, fresh meals',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.greenText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Card 2: Save money
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCF3DE),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.goldBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: OnboardingLineIcon(
                                    'wallet',
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 11),
                              Text(
                                'Save money',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Cook more, waste less',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.goldText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

/// Custom painter that draws the ascending progress curve.
/// Based on SVG viewBox 0 0 280 92:
///   Path: "M6 82 C 60 78, 78 52, 120 50 C 166 48, 192 22, 274 10"
///   Fill area: same path + L274 90 L6 90 Z
///   Mid-circle at (120,50): r4, white fill, #F2623E stroke 2.5
///   End-circle at (274,10): r5, #F2623E fill
class _ProgressChartPainter extends CustomPainter {
  /// 0 → 1: how much of the curve is drawn (used for the entrance animation).
  final double progress;

  _ProgressChartPainter({this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    // Map SVG viewBox (280x92) to actual canvas size
    final sx = size.width / 280;
    final sy = size.height / 92;

    Offset p(double x, double y) => Offset(x * sx, y * sy);

    // Build the cubic bezier path matching the SVG
    final path = Path();
    path.moveTo(p(6, 82).dx, p(6, 82).dy);
    path.cubicTo(
      p(60, 78).dx,
      p(60, 78).dy,
      p(78, 52).dx,
      p(78, 52).dy,
      p(120, 50).dx,
      p(120, 50).dy,
    );
    path.cubicTo(
      p(166, 48).dx,
      p(166, 48).dy,
      p(192, 22).dx,
      p(192, 22).dy,
      p(274, 10).dx,
      p(274, 10).dy,
    );

    // Extract only the drawn fraction of the curve (left → right reveal).
    final t = progress.clamp(0.0, 1.0);
    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * t);
    final endX =
        metric.getTangentForOffset(metric.length * t)?.position.dx ??
        p(6, 82).dx;
    final baseY = p(6, 90).dy;

    // Fill area below the drawn portion of the curve.
    final fillPath = Path.from(drawn)
      ..lineTo(endX, baseY)
      ..lineTo(p(6, 90).dx, baseY)
      ..close();
    final fillPaint = Paint()
      ..color = const Color(0xFFF2623E).withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Stroke the drawn curve.
    final linePaint = Paint()
      ..color = const Color(0xFFF2623E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(drawn, linePaint);

    // Mid-point circle at (120, 50) — appears once the reveal reaches it.
    final midCenter = p(120, 50);
    if (endX >= midCenter.dx - 0.5) {
      canvas.drawCircle(midCenter, 4 * sx, Paint()..color = Colors.white);
      canvas.drawCircle(
        midCenter,
        4 * sx,
        Paint()
          ..color = const Color(0xFFF2623E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // End-point circle at (274, 10) — appears at the end.
    if (t >= 0.999) {
      canvas.drawCircle(
        p(274, 10),
        5 * sx,
        Paint()..color = const Color(0xFFF2623E),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressChartPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
