import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:recipe_ai/Controllers/meal_planner_controller.dart';
import 'package:recipe_ai/screens/meal_plan/meal_planner_ui.dart';
import 'package:recipe_ai/screens/meal_plan/week_review_screen.dart';

/// Screen 2 — full-screen generating page with a dark-purple gradient, a
/// premium pulsing AI icon and the live step list. Runs the fallback pipeline
/// (Cookbook → Community → AI) then hands off to the Week Review screen.
class MealPlanGeneratingScreen extends StatefulWidget {
  const MealPlanGeneratingScreen({super.key});

  @override
  State<MealPlanGeneratingScreen> createState() =>
      _MealPlanGeneratingScreenState();
}

class _MealPlanGeneratingScreenState extends State<MealPlanGeneratingScreen>
    with SingleTickerProviderStateMixin {
  final _controller = MealPlannerController.to;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
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
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A1A55), Color(0xFF1A1030), Color(0xFF120A22)],
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
                Text('Planning your week…',
                    style: Mp.f(21, FontWeight.w800, Colors.white)),
                const SizedBox(height: 10),
                Text(
                  'Balancing nutrition, variety & your prep time across 7 days.',
                  textAlign: TextAlign.center,
                  style: Mp.f(13.5, FontWeight.w500,
                      Colors.white.withValues(alpha: 0.6), h: 1.45),
                ),
                const SizedBox(height: 30),
                Obx(() => Column(
                      children: [
                        for (final step in _controller.steps) ...[
                          GeneratingStepCard(step: step),
                          const SizedBox(height: 10),
                        ],
                      ],
                    )),
                const Spacer(flex: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glowIcon() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final t = _pulse.value;
        return SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Two expanding, fading halo rings.
              _ring(t),
              _ring((t + 0.5) % 1.0),
              // Static soft glow.
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Mp.purple.withValues(alpha: 0.18),
                ),
              ),
              // Core badge.
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9B6BF2), Color(0xFF7C3AED)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Mp.purple.withValues(alpha: 0.6),
                      blurRadius: 34,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 34, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ring(double t) {
    final size = 84.0 + t * 62;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Mp.purple.withValues(alpha: (1 - t) * 0.5),
          width: 2,
        ),
      ),
    );
  }
}
