import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class CookModeTimerScreen extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final String stepText;
  final Duration totalDuration;
  final VoidCallback? onClose;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const CookModeTimerScreen({
    super.key,
    this.currentStep = 3,
    this.totalSteps = 8,
    this.stepText = 'Add the chickpeas and coconut milk to the pan and stir gently to combine.',
    this.totalDuration = const Duration(minutes: 10),
    this.onClose,
    this.onNext,
    this.onBack,
  });

  @override
  State<CookModeTimerScreen> createState() => _CookModeTimerScreenState();
}

class _CookModeTimerScreenState extends State<CookModeTimerScreen>
    with TickerProviderStateMixin {
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: widget.totalDuration,
    )..forward();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatTotal() {
    return _formatDuration(widget.totalDuration);
  }

  void _pause() {
    _timerController.stop();
  }

  void _reset() {
    _timerController.reset();
    _timerController.forward();
  }

  void _addMinute() {
    // Extend timer by 1 minute
  }

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
              const Spacer(flex: 2),
              _buildTimerCircle(),
              const SizedBox(height: 32),
              _buildTimerControls(),
              const SizedBox(height: 28),
              _buildStepCard(),
              const Spacer(flex: 3),
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
          onTap: widget.onClose ?? () => Get.back(),
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
    final progress = widget.currentStep / widget.totalSteps;
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

  Widget _buildTimerCircle() {
    return AnimatedBuilder(
      animation: _timerController,
      builder: (context, child) {
        final elapsed = widget.totalDuration * _timerController.value;
        final remaining = widget.totalDuration - elapsed;
        final progress = _timerController.value;

        return SizedBox(
          width: 248,
          height: 248,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Radial glow
              Container(
                width: 248,
                height: 248,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.18),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              // Circle track and progress
              CustomPaint(
                size: const Size(248, 248),
                painter: _TimerCirclePainter(
                  progress: progress,
                  trackColor: const Color(0xFFEEE3D2),
                  progressColor: AppColors.primary,
                  strokeWidth: 13,
                ),
              ),
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🔥', style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        'SIMMERING',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.44,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(remaining),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 54,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    'of ${_formatTotal()}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset button
        GestureDetector(
          onTap: _reset,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7DECE), width: 1),
            ),
            child: const Icon(Icons.timer_outlined, size: 20, color: AppColors.textDark),
          ),
        ),
        const SizedBox(width: 12),
        // Pause button
        SizedBox(
          width: 140,
          child: PrimaryButton(
            label: 'Pause',
            leadingIcon: const Icon(Icons.pause, size: 18, color: Colors.white),
            onPressed: _pause,
          ),
        ),
        const SizedBox(width: 12),
        // +1 button
        GestureDetector(
          onTap: _addMinute,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7DECE), width: 1),
            ),
            child: Center(
              child: Text(
                '+1',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFE6D6), width: 1),
      ),
      child: Text(
        widget.stepText,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textMedium,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBottomNav() {
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onBack ?? () => Get.back(),
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
            onPressed: widget.onNext,
          ),
        ),
      ],
    );
  }
}

class _TimerCirclePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _TimerCirclePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    // Track
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
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
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
