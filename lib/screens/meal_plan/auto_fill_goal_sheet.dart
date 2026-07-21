import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/cuisine_controller.dart';

import 'package:recipe_ai/Controllers/meal_planner_controller.dart';
import 'package:recipe_ai/screens/meal_plan/meal_plan_generating_screen.dart';
import 'package:recipe_ai/screens/meal_plan/meal_planner_ui.dart';
import 'package:recipe_ai/screens/meal_plan/week_review_screen.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/cuisine_picker_sheet.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:recipe_ai/widgets/tr_text.dart';

/// Screen 1 — "Plan my week" goal bottom sheet.
///
/// Slides up from the meal-plan screen. The user picks ONE OR MORE goals,
/// optionally adds a custom prompt, then taps "Generate my week".
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
  // Multi-select: at least one goal must remain selected at all times.
  final Set<MealGoal> _selectedGoals = {MealGoal.healthy};
  final Set<String> selectedGoals = {};
  final _promptCtrl = TextEditingController();
  bool _hasDraft = false;
  String? selectedGoalId;
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
    Get.back();
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
    if (_selectedGoals.isEmpty) return;

    final c = MealPlannerController.to;

    final goalsList = MealGoal.values
        .where((g) => _selectedGoals.contains(g))
        .toList();

    c.goal.value = goalsList.first;
    c.goals.value = goalsList;

    c.customPrompt = _promptCtrl.text.trim();

    // Selected cuisine pass to MealPlannerController
    c.selectedCuisine = CuisineController.to.selectedCuisine.value.trim();

    Get.back();

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
                      child: const OnboardingLineIcon(
                        'crown', //: 'sparkF',
                        size: 18,

                        color: AppColors.background,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'plan_my_week'.tr,
                            style: Mp.f(17, FontWeight.w800, Mp.ink),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'plan_week_subtitle'.tr,
                            style: Mp.f(12.5, FontWeight.w600, Mp.purpleDark),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0E9DA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Mp.body,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'cuisine_section_label'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final cuisine = await CuisinePickerSheet.open<String>(
                          context,
                        );
                        if (cuisine != null) {
                          setState(() {});
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE7D5C7),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Mp.purple, Mp.purpleDark],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Text(
                                  "🍽️",
                                  style: TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CuisineController
                                          .to
                                          .selectedCuisine
                                          .value
                                          .isEmpty
                                      ? Text(
                                          'select_cuisine'.tr,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        )
                                      : TrText(
                                          CuisineController
                                              .to
                                              .selectedCuisine
                                              .value,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'tap_to_change_cuisine'.tr,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey.shade500,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'goal_section_label'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_hasDraft) ...[
                        TapScale(
                          onTap: _resume,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Mp.purpleBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Mp.purpleBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.history_rounded,
                                  size: 18,
                                  color: Mp.purpleDark,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'resume_last_generated_week'.tr,
                                    style: Mp.f(
                                      13,
                                      FontWeight.w700,
                                      Mp.purpleDark,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: Mp.purpleDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // for (final g in MealGoal.values) ...[
                      //   GoalOptionCard(
                      //     goal: g,
                      //     selected: _selectedGoals.contains(g),
                      //     onTap: () => _toggleGoal(g),
                      //   ),
                      //   const SizedBox(height: 10),
                      // ],
                      Obx(() {
                        if (GoalController.to.isLoading.value) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: GoalController.to.goals.map((goal) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GoalOptionCard(
                                title: goal['title'] ?? '',
                                subtitle: goal['subtitle'] ?? '',
                                image: goal['image'],
                                emoji: goal['emoji'],
                                selected: selectedGoals.contains(goal['id']),
                                onTap: () {
                                  setState(() {
                                    if (selectedGoals.contains(goal['id'])) {
                                      selectedGoals.remove(goal['id']);
                                    } else {
                                      selectedGoals.add(goal['id']);
                                    }
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        );
                      }),
                      // Obx(() {
                      //   if (GoalController.to.isLoading.value) {
                      //     return const Center(
                      //       child: CircularProgressIndicator(),
                      //     );
                      //   }

                      //   return Column(
                      //     children: GoalController.to.goals.map((goal) {
                      //       final selected = selectedGoalId == goal['id'];

                      //       return Padding(
                      //         padding: const EdgeInsets.only(bottom: 10),
                      //         child: GestureDetector(
                      //           onTap: () {
                      //             setState(() {
                      //               selectedGoalId = goal['id'];
                      //             });
                      //           },
                      //           child: Container(
                      //             padding: const EdgeInsets.all(16),
                      //             decoration: BoxDecoration(
                      //               color: selected
                      //                   ? const Color(0xFFF2EBFF)
                      //                   : Colors.white,
                      //               borderRadius: BorderRadius.circular(16),
                      //               border: Border.all(
                      //                 color: selected
                      //                     ? const Color(0xFF7C4DFF)
                      //                     : Colors.grey.shade300,
                      //               ),
                      //             ),
                      //             child: Column(
                      //               crossAxisAlignment:
                      //                   CrossAxisAlignment.start,
                      //               children: [
                      //                 Text(
                      //                   goal['title'] ?? "",
                      //                   style: const TextStyle(
                      //                     fontSize: 16,
                      //                     fontWeight: FontWeight.bold,
                      //                   ),
                      //                 ),
                      //                 const SizedBox(height: 4),
                      //                 Text(
                      //                   goal['subtitle'] ?? "",
                      //                   style: TextStyle(
                      //                     color: Colors.grey.shade600,
                      //                   ),
                      //                 ),
                      //               ],
                      //             ),
                      //           ),
                      //         ),
                      //       );
                      //     }).toList(),
                      //   );
                      // }),
                      const SizedBox(height: 2),
                      // Custom prompt
                      Container(
                        height: 70,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Mp.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Mp.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 17,
                              color: Mp.purple,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _promptCtrl,
                                style: Mp.f(13.5, FontWeight.w600, Mp.ink),
                                cursorColor: Mp.purple,
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: false,
                                  // Kill the theme's focus/enabled borders — the
                                  // rounded outline is the wrapping Container's.
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  hintText:
                                      'goal_prompt_hint'.tr,
                                  hintStyle: Mp.f(
                                    13.5,
                                    FontWeight.w500,
                                    Mp.muted,
                                  ),
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
                  label: _selectedGoals.length > 1
                      ? 'generate_my_week_count'.trParams(
                          {'count': '${_selectedGoals.length}'},
                        )
                      : 'generate_my_week'.tr,
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

class GoalOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? image;
  final String? emoji;
  final bool selected;
  final VoidCallback onTap;

  const GoalOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.image,
    this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = image != null && image!.trim().isNotEmpty;

    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Mp.purpleBg : Mp.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Mp.purple : Mp.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            // Image / Emoji
            SizedBox(
              width: 46,
              height: 46,
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFF4EEFF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          image!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;

                            return const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                emoji ?? "🍽️",
                                style: const TextStyle(fontSize: 24),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          emoji ?? "🍽️",
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 13),

            // Text
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TrText(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Mp.f(15, FontWeight.w800, Mp.ink),
                  ),

                  const SizedBox(height: 2),

                  TrText(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Mp.f(12.5, FontWeight.w500, Mp.muted),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Selection Circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFF7C4DFF) : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF7C4DFF)
                      : const Color(0xFFD8D0C5),
                  width: 1.6,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
