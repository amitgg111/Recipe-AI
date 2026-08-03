import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
import 'package:recipe_ai/Controllers/meal_planner_controller.dart';
import 'package:recipe_ai/screens/meal_plan/meal_planner_ui.dart';
import 'package:recipe_ai/widgets/custom_snackbar.dart';
import 'package:recipe_ai/widgets/nutrition_animations.dart';

/// Screen 3 — the AI plan review. Shows the generated week grouped by day, lets
/// the user shuffle a meal / the whole week, then apply it to their plan.
class WeekReviewScreen extends StatefulWidget {
  const WeekReviewScreen({super.key});

  @override
  State<WeekReviewScreen> createState() => _WeekReviewScreenState();
}

class _WeekReviewScreenState extends State<WeekReviewScreen> {
  final _controller = MealPlannerController.to;
  bool _applying = false;

  static const _dow = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Future<void> _apply() async {
    if (_applying) return;
    setState(() => _applying = true);

    // Never let a slow/stuck Firestore write freeze the button — the applied
    // week is written incrementally, so a timeout still leaves a usable plan.
    var ok = true;
    try {
      await _controller.applyToPlan().timeout(const Duration(seconds: 25));
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;
    setState(() => _applying = false);
    Get.back<void>(); // back to the meal plan (always)
    CustomSnackbar.show(
      title: ok ? 'Meal plan applied' : 'Applied',
      message: ok
          ? 'Your AI week is ready in Meal Plan.'
          : 'Saved — check Meal Plan for your week.',
      type: SnackbarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = Get.find<MealPlanController>();
    final weekStart = plan.selectedWeekStart.value;

    return Scaffold(
      backgroundColor: Mp.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _appBar(),
            Expanded(
              child: RevealIn(
                duration: const Duration(milliseconds: 380),
                beginOffset: const Offset(0, 16),
                child: Obx(() {
                  final meals = _controller.meals;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    children: [
                      _infoCard(),
                      const SizedBox(height: 14),
                      for (final day in _controller.allowedDays) ...[
                        RevealIn(
                          delay: Duration(milliseconds: 80 + day * 55),
                          beginOffset: const Offset(0, 14),
                          // child: MealDayCard(
                          //   title: _dayTitle(weekStart, day),
                          //   meals: meals.where((m) => m.day == day).toList()
                          //     ..sort(
                          //       (a, b) => MealPlannerController.slots
                          //           .indexOf(a.slot)
                          //           .compareTo(
                          //             MealPlannerController.slots.indexOf(
                          //               b.slot,
                          //             ),
                          //           ),
                          //     ),
                          //   onSwapMeal: (m) => _showReorderSheet(m),
                          //   // _controller.shuffleMeal(m.day, m.slot),
                          // ),
                          child: MealDayCard(
                            title: _dayTitle(weekStart, day),
                            meals: meals.where((m) => m.day == day).toList()
                              ..sort(
                                (a, b) => MealPlannerController.slots
                                    .indexOf(a.slot)
                                    .compareTo(
                                      MealPlannerController.slots.indexOf(
                                        b.slot,
                                      ),
                                    ),
                              ),

                            onDropMeal: (from, to) => _controller.reorderMeal(
                              fromDay: from.day,
                              fromSlot: from.slot,
                              toDay: to.day,
                              toSlot: to.slot,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                }),
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  String _dayTitle(DateTime weekStart, int day) {
    final d = weekStart.add(Duration(days: day));
    return '${_dow[day]} ${d.day}';
  }

  Widget _appBar() {
    final c = _controller;
    final subtitle = '${c.goal.value.shortLabel} · Serves ${c.servings}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        children: [
          TapScale(
            onTap: () => Get.back<void>(),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Mp.card,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Mp.border),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 24,
                color: Mp.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your AI meal plan',
                  style: Mp.f(17, FontWeight.w800, Mp.ink),
                ),
                const SizedBox(height: 1),
                Text(subtitle, style: Mp.f(12, FontWeight.w600, Mp.muted)),
              ],
            ),
          ),
          Obx(() {
            final regenerating = _controller.isRegenerating.value;

            return TapScale(
              onTap: regenerating ? null : _controller.shuffleWeek,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Mp.purpleBg,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: Mp.purpleBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    regenerating
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Mp.purpleDark),
                            ),
                          )
                        : const Icon(
                            Icons.autorenew_rounded,
                            size: 15,
                            color: Mp.purpleDark,
                          ),
                    const SizedBox(width: 6),
                    Text(
                      regenerating ? 'Regenerating...' : 'Shuffle all',
                      style: Mp.f(12.5, FontWeight.w800, Mp.purpleDark),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Mp.purpleBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Mp.purpleBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 17, color: Mp.purpleDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Balanced for the week. Tap any meal to swap it, then apply.',
              style: Mp.f(
                12.5,
                FontWeight.w600,
                const Color(0xFF5A4A78),
                h: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Mp.bg,
        border: Border(top: BorderSide(color: Mp.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // APPLY BUTTON
          Obx(() {
            final regenerating = _controller.isRegenerating.value;

            if (_applying || regenerating) {
              return Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Mp.orangeLight, Mp.orange],
                  ),
                ),
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              );
            }

            return PrimaryButton(
              label: 'Apply to my plan',
              icon: Icons.check_rounded,
              onTap: _apply,
            );
          }),

          const SizedBox(height: 10),

          // SHUFFLE ALL MEALS
          Obx(() {
            final regenerating = _controller.isRegenerating.value;

            return SecondaryButton(
              label: regenerating
                  ? 'Regenerating week...'
                  : 'Shuffle all meals',
              icon: Icons.autorenew_rounded,
              onTap: regenerating
                  ? () {}
                  : () {
                      _controller.shuffleWeek();
                    },
            );
          }),
        ],
      ),
    );
  }
}
