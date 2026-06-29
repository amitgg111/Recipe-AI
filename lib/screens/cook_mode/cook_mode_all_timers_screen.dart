import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class CookModeAllTimersScreen extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<ActiveTimer>? timers;
  final VoidCallback? onClose;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const CookModeAllTimersScreen({
    super.key,
    this.currentStep = 4,
    this.totalSteps = 8,
    this.timers,
    this.onClose,
    this.onNext,
    this.onBack,
  });

  List<ActiveTimer> get _timers =>
      timers ??
      [
        ActiveTimer(
          label: 'Simmering',
          stepLabel: 'Step 3',
          timeRemaining: '2:14',
          totalTime: '10:00',
          progress: 0.78,
        ),
        ActiveTimer(
          label: 'Roasting',
          stepLabel: 'Step 1',
          timeRemaining: '8:32',
          totalTime: '15:00',
          progress: 0.43,
        ),
        ActiveTimer(
          label: 'Resting',
          stepLabel: 'Step 2',
          timeRemaining: '1:05',
          totalTime: '5:00',
          progress: 0.79,
        ),
      ];

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
              const SizedBox(height: 28),
              Text(
                'Active timers',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _timers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildTimerCard(_timers[index]);
                  },
                ),
              ),
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

  Widget _buildTimerCard(ActiveTimer timer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFE6D6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(52, 52),
                  painter: _TimerArcPainter(
                    progress: timer.progress,
                    trackColor: const Color(0xFFEEE3D2),
                    progressColor: AppColors.primary,
                    strokeWidth: 5,
                  ),
                ),
                const Text('🔥', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Timer info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      timer.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EFE3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        timer.stepLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${timer.timeRemaining} remaining of ${timer.totalTime}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.textMedium),
        ],
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

class ActiveTimer {
  final String label;
  final String stepLabel;
  final String timeRemaining;
  final String totalTime;
  final double progress;

  const ActiveTimer({
    required this.label,
    required this.stepLabel,
    required this.timeRemaining,
    required this.totalTime,
    required this.progress,
  });
}

class _TimerArcPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _TimerArcPainter({
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
  bool shouldRepaint(covariant _TimerArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
