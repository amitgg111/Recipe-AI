import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ProgressIndicatorDots(
                totalSteps: 8,
                currentStep: 3,
              ),
              const SizedBox(height: 28),
              Text(
                "Let's make your\ngoals happen!",
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitle.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 6),
              Text(
                "You want to save money and eat healthier — we'll help you get there.",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 28),
              // Progress chart card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          "Your progress",
                          style: AppTextStyles.bodyLarge,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBF0E7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: Color(0xFF1F7A5E),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "ON TRACK",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1F7A5E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 140,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _ChartPainter(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Wk 1", style: AppTextStyles.smallLabel),
                        Text("Wk 2", style: AppTextStyles.smallLabel),
                        Text("Wk 3", style: AppTextStyles.smallLabel),
                        Text("Wk 4", style: AppTextStyles.smallLabel),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Two goal cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF6F0),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD5EDE2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F7A5E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.restaurant,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Eat healthier",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Balanced, fresh meals",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF5E8676),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCF3DE),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF1E4C3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC0860F),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Save money",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Cook more, waste less",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF9A7B3A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              PrimaryButton(
                label: "Continue",
                onPressed: () {
                  Get.to(() => const WhenToCookScreen());
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

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dashPaint = Paint()
      ..color = AppColors.surfaceBorder
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw 4 vertical dashed grid lines
    for (int i = 0; i < 4; i++) {
      final x = size.width * (i + 1) / 5;
      _drawDashedLine(
        canvas,
        Offset(x, 0),
        Offset(x, size.height),
        dashPaint,
      );
    }

    // Curved line from bottom-left to top-right
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final startPoint = Offset(0, size.height * 0.9);
    final endPoint = Offset(size.width, size.height * 0.1);
    final controlPoint = Offset(size.width * 0.4, size.height * 0.7);

    path.moveTo(startPoint.dx, startPoint.dy);
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    canvas.drawPath(path, linePaint);

    // Area fill below curve
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Dot at end of line
    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(endPoint, 5, dotPaint);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dashLength = 5.0;
    const gapLength = 4.0;
    final totalLength = (end - start).distance;
    final direction = (end - start) / totalLength;
    var current = 0.0;

    while (current < totalLength) {
      final dashEnd = (current + dashLength).clamp(0, totalLength).toDouble();
      canvas.drawLine(
        start + direction * current,
        start + direction * dashEnd,
        paint,
      );
      current += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
