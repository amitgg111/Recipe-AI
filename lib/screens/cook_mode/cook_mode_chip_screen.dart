import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class CookModeChipScreen extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String stepText;
  final String timerStepLabel;
  final String timerTimeLeft;
  final double timerProgress;
  final VoidCallback? onClose;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onTimerChipTap;

  const CookModeChipScreen({
    super.key,
    this.currentStep = 4,
    this.totalSteps = 8,
    this.stepText = 'Meanwhile, finely chop the cilantro and squeeze half a lime for garnish.',
    this.timerStepLabel = 'Simmer · Step 3',
    this.timerTimeLeft = '2:14 left',
    this.timerProgress = 0.78,
    this.onClose,
    this.onNext,
    this.onBack,
    this.onTimerChipTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildTopBar(),
              const SizedBox(height: 8),
              _buildProgressBar(),
              const SizedBox(height: 12),
              _buildTimerChip(),
              const SizedBox(height: 32),
              _buildStepLabel(),
              const Spacer(),
              _buildStepText(),
              const Spacer(),
              _buildBottomNav(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: onClose ?? () => Get.back(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFEFE6D6), width: 1),
            ),
            child: const Icon(Icons.close, size: 20, color: AppColors.textDark),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = currentStep / totalSteps;
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFEEE3D2),
        borderRadius: BorderRadius.circular(5),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerChip() {
    return GestureDetector(
      onTap: onTimerChipTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFF0E7D6), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Mini circular progress
            SizedBox(
              width: 34,
              height: 34,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(34, 34),
                    painter: _MiniTimerPainter(
                      progress: timerProgress,
                      trackColor: const Color(0xFFF6D8CC),
                      progressColor: AppColors.primary,
                      strokeWidth: 4,
                    ),
                  ),
                  const Text('🔥', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Timer info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timerStepLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMedium,
                    ),
                  ),
                  Text(
                    timerTimeLeft,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.textMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildStepLabel() {
    return Text(
      'STEP $currentStep OF $totalSteps',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.textMedium,
        letterSpacing: 0.04 * 13,
      ),
    );
  }

  Widget _buildStepText() {
    return Text(
      stepText,
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        height: 1.35,
      ),
    );
  }

  Widget _buildBottomNav() {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack ?? () => Get.back(),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7DECE), width: 1),
            ),
            child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textDark),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryButton(
            label: 'Next step',
            leadingIcon: const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}

class _MiniTimerPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _MiniTimerPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniTimerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
