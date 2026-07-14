import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:recipe_ai/Controllers/meal_planner_controller.dart';
import 'package:recipe_ai/screens/meal_plan/meal_plan_generating_screen.dart';
import 'package:recipe_ai/screens/meal_plan/meal_planner_ui.dart';
import 'package:recipe_ai/screens/meal_plan/week_review_screen.dart';

/// Screen 1 — "Plan my week" goal bottom sheet.
///
/// Slides up from the meal-plan screen. The user picks ONE goal, optionally adds
/// a custom prompt, then taps "Generate my week".
class AutoFillGoalSheet extends StatefulWidget {
  const AutoFillGoalSheet({super.key});

  static void open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AutoFillGoalSheet(),
    );
  }

  @override
  State<AutoFillGoalSheet> createState() => _AutoFillGoalSheetState();
}

class _AutoFillGoalSheetState extends State<AutoFillGoalSheet> {
  MealGoal _goal = MealGoal.healthy;
  final _promptCtrl = TextEditingController();
  bool _hasDraft = false;

  @override
  void initState() {
    super.initState();
    // Surface a "resume" option if a generated-but-unapplied week is saved.
    MealPlannerController.to.hasDraft().then((v) {
      if (mounted && v) setState(() => _hasDraft = true);
    });
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _resume() async {
    final ok = await MealPlannerController.to.loadDraft();
    if (!mounted) return;
    Navigator.pop(context);
    if (ok) {
      Get.to(
        () => const WeekReviewScreen(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _generate() {
    final c = MealPlannerController.to;
    c.goal.value = _goal;
    c.customPrompt = _promptCtrl.text.trim();
    Navigator.pop(context);
    Get.to(
      () => const MealPlanGeneratingScreen(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Mp.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3D9C8),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Mp.purple, Mp.purpleDark],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Plan my week',
                              style: Mp.f(17, FontWeight.w800, Mp.ink)),
                          const SizedBox(height: 1),
                          Text('Pick a goal — AI does the rest',
                              style: Mp.f(12.5, FontWeight.w600, Mp.purpleDark)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0E9DA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: Mp.body),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                  child: Column(
                    children: [
                      if (_hasDraft) ...[
                        TapScale(
                          onTap: _resume,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Mp.purpleBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Mp.purpleBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.history_rounded,
                                    size: 18, color: Mp.purpleDark),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text('Resume your last generated week',
                                      style: Mp.f(13, FontWeight.w700,
                                          Mp.purpleDark)),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    size: 20, color: Mp.purpleDark),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      for (final g in MealGoal.values) ...[
                        GoalOptionCard(
                          goal: g,
                          selected: _goal == g,
                          onTap: () => setState(() => _goal = g),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 2),
                      // Custom prompt
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(
                          color: Mp.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Mp.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome,
                                size: 17, color: Mp.purple),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _promptCtrl,
                                style: Mp.f(13.5, FontWeight.w600, Mp.ink),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  hintText: 'Or describe it… "kid-friendly, no nuts"',
                                  hintStyle:
                                      Mp.f(13.5, FontWeight.w500, Mp.muted),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                child: GradientButton(
                  label: 'Generate my week',
                  icon: Icons.auto_awesome,
                  onTap: _generate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
