import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:recipe_ai/Controllers/meal_planner_controller.dart';
import 'package:recipe_ai/screens/meal_plan/meal_planner_ui.dart';
import 'package:recipe_ai/screens/meal_plan/week_review_screen.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

/// Screen 2 — full-screen generating page (design 53b · AI auto-fill
/// generating). Dark-purple radial background, a crown badge inside a pulsing
/// glow + a spinning progress ring, and the live step list. Runs the fallback
/// pipeline (Cookbook → Community → AI) then hands off to the Week Review.
class MealPlanGeneratingScreen extends StatefulWidget {
  const MealPlanGeneratingScreen({super.key});

  @override
  State<MealPlanGeneratingScreen> createState() =>
      _MealPlanGeneratingScreenState();
}

class _MealPlanGeneratingScreenState extends State<MealPlanGeneratingScreen>
    with TickerProviderStateMixin {
  final _controller = MealPlannerController.to;

  // ── Animations (match the HTML) ──
  // nutGlow: 0/100% opacity .35 · scale .92 → 50% opacity .7 · scale 1.06,
  // 2.6s ease-in-out — a reversing controller over half the cycle.
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);
  // spin: rotate 360° · 1.2s linear infinite.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _controller.generateWeeklyPlan();
    if (!mounted) return;
    Get.off(
      () => const WeekReviewScreen(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _glow.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // radial-gradient(120% 80% at 50% 12%, #3A2358, #1E1226 70%)
        decoration: const BoxDecoration(
          color: Color(0xFF1E1226),
          gradient: RadialGradient(
            center: Alignment(0, -0.76),
            radius: 1.2,
            colors: [Color(0xFF3A2358), Color(0xFF1E1226)],
            stops: [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                _glowIcon(),
                const SizedBox(height: 34),
                Text(
                  'Planning your week…',
                  style: Mp.f(21, FontWeight.w800, Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'Balancing nutrition, variety & your prep time across 7 days.',
                  textAlign: TextAlign.center,
                  style: Mp.f(
                    13.5,
                    FontWeight.w500,
                    Colors.white.withValues(alpha: 0.6),
                    h: 1.45,
                  ),
                ),
                const SizedBox(height: 30),
                Obx(
                  () => Column(
                    children: [
                      for (final step in _controller.steps) ...[
                        GeneratingStepCard(step: step),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                const Spacer(flex: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // The 120×120 badge stack: pulsing glow · spinning ring · crown core.
  Widget _glowIcon() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing glow circle (nutGlow).
          AnimatedBuilder(
            animation: _glow,
            builder: (_, __) {
              final t = Curves.easeInOut.transform(_glow.value);
              return Transform.scale(
                scale: 0.92 + 0.14 * t, // .92 → 1.06
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFFA78BFA,
                    ).withValues(alpha: 0.35 + 0.35 * t), // .35 → .7
                  ),
                ),
              );
            },
          ),
          // Spinning progress ring (spin).
          AnimatedBuilder(
            animation: _spin,
            builder: (_, __) => Transform.rotate(
              angle: _spin.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(120, 120),
                painter: _RingPainter(),
              ),
            ),
          ),
          // Core crown badge (74×74 rounded square, radius 22).
          Container(
            width: 74,
            height: 74,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment(-0.342, -0.940),
                end: Alignment(0.342, 0.940),
                colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.7),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                  spreadRadius: -10,
                ),
              ],
            ),
            child: const OnboardingLineIcon(
              'crown',
              size: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// The spinning progress arc: a faint full track + a ~72% purple arc with a
/// round cap (matches the SVG dasharray 327 / dashoffset 90).
class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - stroke / 2 - 2; // r ≈ 52 on a 120 box
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.14);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFA78BFA);
    canvas.drawCircle(center, radius, track);
    // Visible arc fraction = (327 - 90) / 327 ≈ 0.725.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * 0.725,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => false;
}
