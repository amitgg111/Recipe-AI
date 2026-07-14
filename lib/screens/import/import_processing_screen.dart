import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/widgets/app_wordmark.dart';

class ImportProcessingScreen extends StatefulWidget {
  const ImportProcessingScreen({super.key});

  @override
  State<ImportProcessingScreen> createState() => _ImportProcessingScreenState();
}

class _ImportProcessingScreenState extends State<ImportProcessingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
    // Ping-pong so the fill grows and recedes smoothly; a plain repeat would
    // snap the bar from full back to empty at the loop boundary.
    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 14),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, color: AppColors.primary, size: 20),
                  SizedBox(width: 6),
                  AppWordmark(fontSize: 17, fontWeight: FontWeight.w800),
                ],
              ),
              const SizedBox(height: 46),
              _buildOrbitAnimation(),
              const SizedBox(height: 34),
              Text('reading_your_recipe'.tr, style: AppTextStyles.sectionTitle.copyWith(fontSize: 23)),
              const SizedBox(height: 8),
              Text(
                'reading_recipe_subtitle'.tr,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              _buildProgressBar(),
              const SizedBox(height: 22),
              _buildChecklist(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrbitAnimation() {
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.primary.withValues(alpha: 0.14), AppColors.primary.withValues(alpha: 0)],
              ),
            ),
          ),
          CustomPaint(size: const Size(188, 188), painter: _DashedCirclePainter()),
          AnimatedBuilder(
            animation: _orbitController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _orbitController.value * 2 * math.pi,
                child: SizedBox(
                  width: 188,
                  height: 188,
                  child: Stack(
                    children: [
                      Positioned(left: 79, top: -4, child: _buildTomato()),
                      Positioned(right: -4, top: 82, child: _buildCheese()),
                      Positioned(left: 81, bottom: -4, child: _buildHerb()),
                      Positioned(left: -4, top: 75, child: _buildEgg()),
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              // Phase-staggered expanding rings: as one ring finishes its
              // expand-and-fade another is mid-cycle, so the pulse reads as a
              // continuous outward ripple with no snap at the loop boundary.
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (final p in const [0.0, 0.5])
                    Builder(
                      builder: (_) {
                        final t = (_pulseController.value + p) % 1.0;
                        final scale = 0.75 + t * 1.15;
                        final opacity = 0.55 * (1 - t);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: opacity),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment(-0.5, -1),
                end: Alignment(0.5, 1),
                colors: [AppColors.primaryLight, AppColors.primary],
              ),
              boxShadow: const [BoxShadow(color: AppColors.primaryShadow, blurRadius: 30, offset: Offset(0, 16), spreadRadius: -10)],
            ),
            child: const Icon(Icons.restaurant, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildTomato() => Container(
    width: 30, height: 30,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(center: Alignment(-0.36, -0.4), colors: [Color(0xFFFF6F52), Color(0xFFE5402A)]),
    ),
  );

  Widget _buildCheese() => Container(
    width: 32, height: 24,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: const RadialGradient(center: Alignment(-0.36, -0.4), colors: [Color(0xFFFFE05A), Color(0xFFEBAE14)]),
    ),
  );

  Widget _buildHerb() => Container(
    width: 26, height: 26,
    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF54B069)),
  );

  Widget _buildEgg() => Container(
    width: 28, height: 30,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: const RadialGradient(center: Alignment(-0.3, -0.4), colors: [Colors.white, Color(0xFFEFE6D6)]),
    ),
  );

  Widget _buildProgressBar() {
    return Container(
      height: 8,
      decoration: BoxDecoration(color: const Color(0xFFEEE3D2), borderRadius: BorderRadius.circular(5)),
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return FractionallySizedBox(
            widthFactor: 0.08 + (_progressController.value * 0.8),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(colors: [AppColors.primaryLight, AppColors.primary]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChecklist() {
    return Column(
      children: [
        _checkItem('found_recipe_title'.tr, true, 0),
        const SizedBox(height: 12),
        _checkItem('extracting_ingredients'.tr, true, 1),
        const SizedBox(height: 12),
        _checkItem('reading_the_steps'.tr, false, 2),
      ],
    );
  }

  Widget _checkItem(String label, bool done, int index) {
    return Row(
      children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.greenBg : AppColors.redBg,
          ),
          child: Icon(
            done ? Icons.check : Icons.access_time,
            size: 16,
            color: done ? AppColors.green : AppColors.primary,
          ),
        ),
        const SizedBox(width: 11),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      ],
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE7DBC8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    const dashWidth = 4.0;
    const dashSpace = 8.0;
    final radius = size.width / 2;
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();
    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * (dashWidth + dashSpace)) / radius;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, dashWidth / radius, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
