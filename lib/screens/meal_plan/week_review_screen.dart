// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
// import 'package:recipe_ai/Controllers/meal_planner_controller.dart';
// import 'package:recipe_ai/screens/meal_plan/meal_planner_ui.dart';
// import 'package:recipe_ai/widgets/custom_snackbar.dart';
// import 'package:recipe_ai/widgets/nutrition_animations.dart';

// /// Screen 3 — The AI plan review.
// /// Shows generated week grouped by day.
// /// Allows shuffling meals/week and applying the plan.
// class WeekReviewScreen extends StatefulWidget {
//   const WeekReviewScreen({super.key});

//   @override
//   State<WeekReviewScreen> createState() => _WeekReviewScreenState();
// }

// class _WeekReviewScreenState extends State<WeekReviewScreen> {
//   final _controller = MealPlannerController.to;

//   // ------------------------------------------------------------
//   // SEPARATE LOADING STATES
//   // ------------------------------------------------------------

//   bool _applying = false;
//   bool _shufflingWeek = false;
//   bool _goingBack = false;

//   static const _dow = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

//   // ------------------------------------------------------------
//   // COMMON CHECK
//   // ------------------------------------------------------------

//   bool get _isAnyActionRunning =>
//       _applying || _shufflingWeek || _controller.isRegenerating.value;

//   // ------------------------------------------------------------
//   // APPLY
//   // ------------------------------------------------------------

//   Future<void> _apply() async {
//     if (_applying || _shufflingWeek) return;

//     setState(() {
//       _applying = true;
//     });

//     var ok = true;

//     try {
//       await _controller.applyToPlan().timeout(const Duration(seconds: 25));
//     } catch (e) {
//       ok = false;
//     }

//     if (!mounted) return;

//     setState(() {
//       _applying = false;
//     });

//     Get.back<void>();

//     CustomSnackbar.show(
//       title: ok ? 'Meal plan applied' : 'Applied',
//       message: ok
//           ? 'Your AI week is ready in Meal Plan.'
//           : 'Saved — check Meal Plan for your week.',
//       type: SnackbarType.success,
//     );
//   }

//   // ------------------------------------------------------------
//   // SHUFFLE WEEK
//   // ------------------------------------------------------------

//   Future<void> _shuffleWeek() async {
//     if (_shufflingWeek || _applying) return;

//     setState(() {
//       _shufflingWeek = true;
//     });

//     try {
//       await _controller.shuffleWeek();
//     } catch (e) {
//       if (mounted) {
//         CustomSnackbar.show(
//           title: 'Unable to shuffle',
//           message: 'Please try again.',
//           type: SnackbarType.error,
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _shufflingWeek = false;
//         });
//       }
//     }
//   }

//   // ------------------------------------------------------------
//   // BACK
//   // ------------------------------------------------------------

//   void _goBack() {
//     if (_goingBack || _isAnyActionRunning) return;

//     setState(() {
//       _goingBack = true;
//     });

//     Get.back<void>();
//   }

//   // ------------------------------------------------------------
//   // BUILD
//   // ------------------------------------------------------------

//   @override
//   Widget build(BuildContext context) {
//     final plan = Get.find<MealPlanController>();
//     final weekStart = plan.selectedWeekStart.value;

//     return Scaffold(
//       backgroundColor: Mp.bg,
//       body: SafeArea(
//         bottom: false,
//         child: Column(
//           children: [
//             _appBar(),

//             Expanded(
//               child: RevealIn(
//                 duration: const Duration(milliseconds: 380),
//                 beginOffset: const Offset(0, 16),
//                 child: Obx(() {
//                   final meals = _controller.meals;

//                   return ListView(
//                     padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
//                     children: [
//                       _infoCard(),

//                       const SizedBox(height: 14),

//                       for (final day in _controller.allowedDays) ...[
//                         RevealIn(
//                           delay: Duration(milliseconds: 80 + day * 55),
//                           beginOffset: const Offset(0, 14),
//                           child: MealDayCard(
//                             title: _dayTitle(weekStart, day),
//                             meals: meals.where((m) => m.day == day).toList()
//                               ..sort(
//                                 (a, b) => MealPlannerController.slots
//                                     .indexOf(a.slot)
//                                     .compareTo(
//                                       MealPlannerController.slots.indexOf(
//                                         b.slot,
//                                       ),
//                                     ),
//                               ),

//                             onDropMeal: (from, to) {
//                               if (_isAnyActionRunning) return;

//                               _controller.reorderMeal(
//                                 fromDay: from.day,
//                                 fromSlot: from.slot,
//                                 toDay: to.day,
//                                 toSlot: to.slot,
//                               );
//                             },
//                           ),
//                         ),

//                         const SizedBox(height: 12),
//                       ],
//                     ],
//                   );
//                 }),
//               ),
//             ),

//             _bottomBar(),
//           ],
//         ),
//       ),
//     );
//   }

//   // ------------------------------------------------------------
//   // DAY TITLE
//   // ------------------------------------------------------------

//   String _dayTitle(DateTime weekStart, int day) {
//     final d = weekStart.add(Duration(days: day));

//     return '${_dow[day]} ${d.day}';
//   }

//   // ------------------------------------------------------------
//   // APP BAR
//   // ------------------------------------------------------------

//   Widget _appBar() {
//     final c = _controller;

//     final subtitle = '${c.goal.value.shortLabel} · Serves ${c.servings}';

//     return Padding(
//       padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
//       child: Row(
//         children: [
//           // BACK BUTTON
//           TapScale(
//             onTap: _isAnyActionRunning ? null : _goBack,
//             child: AnimatedOpacity(
//               duration: const Duration(milliseconds: 150),
//               opacity: _isAnyActionRunning ? 0.45 : 1,
//               child: Container(
//                 width: 40,
//                 height: 40,
//                 alignment: Alignment.center,
//                 decoration: BoxDecoration(
//                   color: Mp.card,
//                   borderRadius: BorderRadius.circular(13),
//                   border: Border.all(color: Mp.border),
//                 ),
//                 child: _goingBack
//                     ? const SizedBox(
//                         width: 18,
//                         height: 18,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : const Icon(
//                         Icons.chevron_left_rounded,
//                         size: 24,
//                         color: Mp.ink,
//                       ),
//               ),
//             ),
//           ),

//           const SizedBox(width: 12),

//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Your AI meal plan',
//                   style: Mp.f(17, FontWeight.w800, Mp.ink),
//                 ),
//                 const SizedBox(height: 1),
//                 Text(subtitle, style: Mp.f(12, FontWeight.w600, Mp.muted)),
//               ],
//             ),
//           ),

//           // HEADER SHUFFLE
//           _headerShuffleButton(),
//         ],
//       ),
//     );
//   }

//   // ------------------------------------------------------------
//   // HEADER SHUFFLE BUTTON
//   // ------------------------------------------------------------

//   Widget _headerShuffleButton() {
//     final disabled = _applying || _shufflingWeek;

//     return TapScale(
//       onTap: disabled ? null : _shuffleWeek,
//       child: AnimatedOpacity(
//         duration: const Duration(milliseconds: 150),
//         opacity: disabled ? 0.55 : 1,
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           decoration: BoxDecoration(
//             color: Mp.purpleBg,
//             borderRadius: BorderRadius.circular(11),
//             border: Border.all(color: Mp.purpleBorder),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _shufflingWeek
//                   ? const SizedBox(
//                       width: 15,
//                       height: 15,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation(Mp.purpleDark),
//                       ),
//                     )
//                   : const Icon(
//                       Icons.autorenew_rounded,
//                       size: 15,
//                       color: Mp.purpleDark,
//                     ),

//               const SizedBox(width: 6),

//               Text(
//                 _shufflingWeek ? 'Shuffling...' : 'Shuffle all',
//                 style: Mp.f(12.5, FontWeight.w800, Mp.purpleDark),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ------------------------------------------------------------
//   // INFO CARD
//   // ------------------------------------------------------------

//   Widget _infoCard() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//       decoration: BoxDecoration(
//         color: Mp.purpleBg,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Mp.purpleBorder),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.auto_awesome, size: 17, color: Mp.purpleDark),

//           const SizedBox(width: 10),

//           Expanded(
//             child: Text(
//               'Balanced for the week. Tap any meal to swap it, then apply.',
//               style: Mp.f(
//                 12.5,
//                 FontWeight.w600,
//                 const Color(0xFF5A4A78),
//                 h: 1.35,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ------------------------------------------------------------
//   // BOTTOM BAR
//   // ------------------------------------------------------------

//   Widget _bottomBar() {
//     return Container(
//       padding: EdgeInsets.fromLTRB(
//         16,
//         12,
//         16,
//         12 + MediaQuery.of(context).padding.bottom,
//       ),
//       decoration: const BoxDecoration(
//         color: Mp.bg,
//         border: Border(top: BorderSide(color: Mp.divider)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // ----------------------------------------------------
//           // APPLY BUTTON
//           // ----------------------------------------------------
//           _applyButton(),

//           const SizedBox(height: 10),

//           // ----------------------------------------------------
//           // BOTTOM SHUFFLE BUTTON
//           // ----------------------------------------------------
//           _bottomShuffleButton(),
//         ],
//       ),
//     );
//   }

//   // ------------------------------------------------------------
//   // APPLY BUTTON
//   // ------------------------------------------------------------

//   Widget _applyButton() {
//     final disabled = _applying || _shufflingWeek;

//     if (_applying) {
//       return Container(
//         height: 56,
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           gradient: const LinearGradient(colors: [Mp.orangeLight, Mp.orange]),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const SizedBox(
//               width: 22,
//               height: 22,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2.4,
//                 valueColor: AlwaysStoppedAnimation(Colors.white),
//               ),
//             ),

//             const SizedBox(width: 10),

//             Text('Applying...', style: Mp.f(14, FontWeight.w800, Colors.white)),
//           ],
//         ),
//       );
//     }

//     return Opacity(
//       opacity: disabled ? 0.5 : 1,
//       child: PrimaryButton(
//         label: 'Apply to my plan',
//         icon: Icons.check_rounded,
//         onTap: disabled ? () {} : _apply,
//       ),
//     );
//   }

//   // ------------------------------------------------------------
//   // BOTTOM SHUFFLE BUTTON
//   // ------------------------------------------------------------

//   Widget _bottomShuffleButton() {
//     final disabled = _applying || _shufflingWeek;

//     return Opacity(
//       opacity: disabled ? 0.55 : 1,
//       child: SecondaryButton(
//         label: _shufflingWeek ? 'Shuffling week...' : 'Shuffle all meals',
//         icon: Icons.autorenew_rounded,
//         onTap: disabled ? () {} : _shuffleWeek,
//       ),
//     );
//   }
// }

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
import 'package:recipe_ai/Controllers/meal_planner_controller.dart';
import 'package:recipe_ai/screens/meal_plan/meal_planner_ui.dart';
import 'package:recipe_ai/widgets/custom_snackbar.dart';
import 'package:recipe_ai/widgets/nutrition_animations.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';

/// Screen 3 — The AI plan review.
/// Shows generated week grouped by day.
/// Allows shuffling meals/week and applying the plan.
class WeekReviewScreen extends StatefulWidget {
  const WeekReviewScreen({super.key});

  @override
  State<WeekReviewScreen> createState() => _WeekReviewScreenState();
}

class _WeekReviewScreenState extends State<WeekReviewScreen> {
  final _controller = MealPlannerController.to;

  // ------------------------------------------------------------
  // SEPARATE LOADING STATES
  // ------------------------------------------------------------

  bool _applying = false;
  bool _shufflingWeek = false;

  // Translation state
  bool translationLoading = true;
  final Map<String, String> _translated = {};
  // ------------------------------------------------------------
  // TRANSLATION
  // ------------------------------------------------------------

  static const _dow = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // ------------------------------------------------------------
  // COMMON CHECK
  // ------------------------------------------------------------

  bool get _isAnyActionRunning =>
      _applying || _shufflingWeek || _controller.isRegenerating.value;

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    // Start translation immediately.
    unawaited(_loadTranslations());
  }

  // ------------------------------------------------------------
  // TRANSLATE ALL STATIC/DYNAMIC SCREEN TEXT
  // ------------------------------------------------------------

  Future<void> _loadTranslations() async {
    if (!mounted) return;

    setState(() {
      translationLoading = true;
    });

    try {
      final goalLabel = _controller.goal.value.shortLabel;

      final texts = <String>[
        'Your AI meal plan',
        'Serves',
        'Shuffle all',
        'Shuffling...',
        'Balanced for the week. Tap any meal to swap it, then apply.',
        'Applying...',
        'Apply to my plan',
        'Shuffling week...',
        'Shuffle all meals',
        'Meal plan applied',
        'Your AI week is ready in Meal Plan.',
        'Applied',
        'Saved — check Meal Plan for your week.',
        'Unable to shuffle',
        'Please try again.',
        goalLabel,
        ..._dow,
      ];

      final uniqueTexts = texts
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      final results = await Future.wait(
        uniqueTexts.map((text) => AiTranslationService.translate(text)),
      );

      if (!mounted) return;

      final map = <String, String>{};

      for (int i = 0; i < uniqueTexts.length; i++) {
        map[uniqueTexts[i]] = results[i];
      }

      setState(() {
        _translated
          ..clear()
          ..addAll(map);

        translationLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        translationLoading = false;
      });
    }
  }
  // ------------------------------------------------------------
  // TRANSLATION HELPER
  // ------------------------------------------------------------

  String _tr(String text) {
    final value = text.trim();

    if (value.isEmpty) return value;

    // If translation has already been loaded, use it.
    return _translated[value] ?? value;
  }

  // ------------------------------------------------------------
  // APPLY
  // ------------------------------------------------------------

  // Future<void> _apply() async {
  //   if (_applying || _shufflingWeek) return;

  //   setState(() {
  //     _applying = true;
  //   });

  //   var ok = true;

  //   try {
  //     await _controller.applyToPlan().timeout(const Duration(seconds: 25));
  //   } catch (e) {
  //     ok = false;
  //   }

  //   if (!mounted) return;

  //   setState(() {
  //     _applying = false;
  //   });

  //   Get.back<void>();

  //   CustomSnackbar.show(
  //     title: ok ? _tr('Meal plan applied') : _tr('Applied'),
  //     message: ok
  //         ? _tr('Your AI week is ready in Meal Plan.')
  //         : _tr('Saved — check Meal Plan for your week.'),
  //     type: SnackbarType.success,
  //   );
  // }
  Future<void> _apply() async {
    if (_applying || _shufflingWeek) return;

    setState(() {
      _applying = true;
    });

    bool success = false;

    try {
      await _controller.applyToPlan();
      success = true;
    } catch (e, stackTrace) {
      print('Apply failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (!mounted) return;

    setState(() {
      _applying = false;
    });

    if (!success) {
      CustomSnackbar.show(
        title: _tr('Unable to apply'),
        message: _tr('Please try again.'),
        type: SnackbarType.error,
      );
      return;
    }

    Get.back<void>();

    CustomSnackbar.show(
      title: _tr('Meal plan applied'),
      message: _tr('Your AI week is ready in Meal Plan.'),
      type: SnackbarType.success,
    );
  }

  // ------------------------------------------------------------
  // SHUFFLE WEEK
  // ------------------------------------------------------------

  Future<void> _shuffleWeek() async {
    if (_shufflingWeek || _applying) return;

    setState(() {
      _shufflingWeek = true;
    });

    try {
      await _controller.shuffleWeek();
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          title: _tr('Unable to shuffle'),
          message: _tr('Please try again.'),
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _shufflingWeek = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

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
                  final isTranslating = _controller.isTranslatingPlan.value;

                  final meals = _controller.translatedMeals.isNotEmpty
                      ? _controller.translatedMeals
                      : _controller.meals;

                  return Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        children: [
                          _infoCard(),

                          const SizedBox(height: 14),

                          for (final day in _controller.allowedDays) ...[
                            RevealIn(
                              delay: Duration(milliseconds: 80 + day * 55),
                              beginOffset: const Offset(0, 14),
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

                                onDropMeal: (from, to) {
                                  if (_isAnyActionRunning) return;

                                  _controller.reorderMeal(
                                    fromDay: from.day,
                                    fromSlot: from.slot,
                                    toDay: to.day,
                                    toSlot: to.slot,
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 12),
                          ],
                        ],
                      ),

                      if (isTranslating)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              color: Colors.black.withOpacity(0.04),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                        ),
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

  // ------------------------------------------------------------
  // DAY TITLE
  // ------------------------------------------------------------

  String _dayTitle(DateTime weekStart, int day) {
    final d = weekStart.add(Duration(days: day));

    return '${_tr(_dow[day])} ${d.day}';
  }

  // ------------------------------------------------------------
  // APP BAR
  // ------------------------------------------------------------

  Widget _appBar() {
    final c = _controller;

    final goal = _tr(c.goal.value.shortLabel);

    final subtitle = '${goal} · ${_tr('Serves')} ${c.servings}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        children: [
          // BACK BUTTON
          GestureDetector(
            onTap: () {
              _isAnyActionRunning ? null : Get.back();
            },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _isAnyActionRunning ? 0.45 : 1,
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
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr('Your AI meal plan'),
                  style: Mp.f(17, FontWeight.w800, Mp.ink),
                ),

                const SizedBox(height: 1),

                Text(subtitle, style: Mp.f(12, FontWeight.w600, Mp.muted)),
              ],
            ),
          ),

          _headerShuffleButton(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER SHUFFLE BUTTON
  // ------------------------------------------------------------

  Widget _headerShuffleButton() {
    final disabled = _applying || _shufflingWeek;

    return TapScale(
      onTap: disabled ? null : _shuffleWeek,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: disabled ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Mp.purpleBg,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Mp.purpleBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _shufflingWeek
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
                _shufflingWeek ? _tr('Shuffling...') : _tr('Shuffle all'),
                style: Mp.f(12.5, FontWeight.w800, Mp.purpleDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // INFO CARD
  // ------------------------------------------------------------

  // Widget _infoCard() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  //     decoration: BoxDecoration(
  //       color: Mp.purpleBg,
  //       borderRadius: BorderRadius.circular(14),
  //       border: Border.all(color: Mp.purpleBorder),
  //     ),
  //     child: Row(
  //       children: [
  //         const Icon(Icons.auto_awesome, size: 17, color: Mp.purpleDark),

  //         const SizedBox(width: 10),

  //         Expanded(
  //           child: Text(
  //             _tr(
  //               'Balanced for the week. Tap any meal to swap it, then apply.',
  //             ),
  //             style: Mp.f(
  //               12.5,
  //               FontWeight.w600,
  //               const Color(0xFF5A4A78),
  //               h: 1.35,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _infoCard() {
    return Obx(() {
      final translating = _controller.isTranslatingPlan.value;

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
                translating
                    ? 'Preparing your meal plan...'
                    : _tr(
                        'Balanced for the week. Tap any meal to swap it, then apply.',
                      ),
                style: Mp.f(
                  12.5,
                  FontWeight.w600,
                  const Color(0xFF5A4A78),
                  h: 1.35,
                ),
              ),
            ),

            if (translating) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      );
    });
  }
  // ------------------------------------------------------------
  // BOTTOM BAR
  // ------------------------------------------------------------

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
          _applyButton(),

          const SizedBox(height: 10),

          _bottomShuffleButton(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // APPLY BUTTON
  // ------------------------------------------------------------

  Widget _applyButton() {
    final disabled = _applying || _shufflingWeek;

    if (_applying) {
      return Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [Mp.orangeLight, Mp.orange]),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _shufflingWeek
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

            const SizedBox(width: 10),

            Text(
              _tr('Applying...'),
              style: Mp.f(14, FontWeight.w800, Colors.white),
            ),
          ],
        ),
      );
    }

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: PrimaryButton(
        label: _tr('Apply to my plan'),
        icon: Icons.check_rounded,
        onTap: disabled ? () {} : _apply,
      ),
    );
  }

  // ------------------------------------------------------------
  // BOTTOM SHUFFLE BUTTON
  // ------------------------------------------------------------

  Widget _bottomShuffleButton() {
    final disabled = _applying || _shufflingWeek;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: SecondaryButton(
        label: _shufflingWeek
            ? _tr('Shuffling week...')
            : _tr('Shuffle all meals'),
        icon: Icons.autorenew_rounded,
        onTap: disabled ? () {} : _shuffleWeek,
      ),
    );
  }
}
