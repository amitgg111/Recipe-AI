import 'package:flutter/material.dart';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:recipe_ai/Controllers/onboarding_controller.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
import 'package:recipe_ai/screens/onboarding/thats_great_screen.dart';

class GoalsScreen extends StatefulWidget {
  static const String routeName = '/onboarding/goals';

  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalItem {
  final String label;
  final Color bgColor;
  final Color fgColor;
  final String iconKey;

  const _GoalItem({
    required this.label,
    required this.bgColor,
    required this.fgColor,
    required this.iconKey,
  });
}

class _GoalsScreenState extends State<GoalsScreen> {
  // Goals 0 and 1 are pre-selected
  final Set<int> _selectedGoals = {0, 1};

  static final List<_GoalItem> _goals = [
    _GoalItem(
      label: 'goal_eat_healthier'.tr,
      bgColor: const Color(0xFFDBF0E7),
      fgColor: const Color(0xFF1F7A5E),
      iconKey: 'bowl',
    ),
    _GoalItem(
      label: 'goal_save_money'.tr,
      bgColor: const Color(0xFFFCEFD0),
      fgColor: const Color(0xFFC0860F),
      iconKey: 'wallet',
    ),
    _GoalItem(
      label: 'goal_improve_cooking_skills'.tr,
      bgColor: const Color(0xFFFCE3DB),
      fgColor: const Color(0xFFE0552F),
      iconKey: 'hat',
    ),
    _GoalItem(
      label: 'goal_organize_recipes'.tr,
      bgColor: const Color(0xFFE6E7FB),
      fgColor: const Color(0xFF5559CE),
      iconKey: 'folder',
    ),
    _GoalItem(
      label: 'goal_plan_out_meals'.tr,
      bgColor: const Color(0xFFE7F0DC),
      fgColor: const Color(0xFF5E8A2C),
      iconKey: 'cal',
    ),
    _GoalItem(
      label: 'goal_try_new_cuisines'.tr,
      bgColor: const Color(0xFFF4E1F0),
      fgColor: const Color(0xFFA23E8C),
      iconKey: 'globe',
    ),
  ];

  void _toggleGoal(int index) {
    setState(() {
      if (_selectedGoals.contains(index)) {
        _selectedGoals.remove(index);
      } else {
        _selectedGoals.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const AppWordmark(fontSize: 16, fontWeight: FontWeight.w700),
                ],
              ),
              const SizedBox(height: 12),
              // Progress dots (step 2 of 8, index 1)
              const ProgressIndicatorDots(totalSteps: 8, currentStep: 1),
              // Title area
              const SizedBox(height: 16),
              Text(
                'goals_title'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.50,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'select_all_that_apply'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 18),
              // Goal tiles - flex:1, column, gap 11
              Expanded(
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  shrinkWrap: true,
                  // scrollDirection: Axis.vertical,
                  itemCount: _goals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 11),
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    final isSelected = _selectedGoals.contains(index);
                    return GestureDetector(
                      onTap: () => _toggleGoal(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Row(
                          children: [
                            // Icon container
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: goal.bgColor,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Center(
                                child: OnboardingLineIcon(
                                  goal.iconKey,
                                  color: goal.fgColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Label
                            Expanded(
                              child: Text(
                                goal.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            // Check circle
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.unselectedBorder,
                                  width: isSelected ? 0 : 2,
                                ),
                              ),
                              child: isSelected
                                  ? const OnboardingLineIcon(
                                      'check',
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Continue button with margin-top 14
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'continue_'.tr,
                onPressed: () {
                  Get.to(() => const ThatsGreatScreen());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GoalsBody — content-only version for single-screen onboarding flow
// ─────────────────────────────────────────────────────────────────────────────

class GoalsBody extends StatefulWidget {
  /// Reports whether at least one goal is selected (drives the Continue button).
  final ValueChanged<bool>? onValidityChanged;

  const GoalsBody({super.key, this.onValidityChanged});

  @override
  State<GoalsBody> createState() => _GoalsBodyState();
}

class _GoalsBodyState extends State<GoalsBody> {
  final OnboardingController _c = Get.find<OnboardingController>();
  // Restored from the shared controller so the choice survives navigating
  // back and forth (and app restarts).
  late Set<int> _selectedGoals;

  static final List<_GoalItem> _goals = [
    _GoalItem(
      label: 'goal_eat_healthier'.tr,
      bgColor: const Color(0xFFDBF0E7),
      fgColor: const Color(0xFF1F7A5E),
      iconKey: 'bowl',
    ),
    _GoalItem(
      label: 'goal_save_money'.tr,
      bgColor: const Color(0xFFFCEFD0),
      fgColor: const Color(0xFFC0860F),
      iconKey: 'wallet',
    ),
    _GoalItem(
      label: 'goal_improve_cooking_skills'.tr,
      bgColor: const Color(0xFFFCE3DB),
      fgColor: const Color(0xFFE0552F),
      iconKey: 'hat',
    ),
    _GoalItem(
      label: 'goal_organize_recipes'.tr,
      bgColor: const Color(0xFFE6E7FB),
      fgColor: const Color(0xFF5559CE),
      iconKey: 'folder',
    ),
    _GoalItem(
      label: 'goal_plan_out_meals'.tr,
      bgColor: const Color(0xFFE7F0DC),
      fgColor: const Color(0xFF5E8A2C),
      iconKey: 'cal',
    ),
    _GoalItem(
      label: 'goal_try_new_cuisines'.tr,
      bgColor: const Color(0xFFF4E1F0),
      fgColor: const Color(0xFFA23E8C),
      iconKey: 'globe',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedGoals = Set<int>.from(_c.goals);
    // Report the restored validity after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onValidityChanged?.call(_selectedGoals.isNotEmpty);
    });
  }

  void _toggleGoal(int index) {
    setState(() {
      if (_selectedGoals.contains(index)) {
        _selectedGoals.remove(index);
      } else {
        _selectedGoals.add(index);
      }
    });
    // Persist immediately (local now, Firebase after the user authenticates).
    _c.setGoals(_selectedGoals);
    widget.onValidityChanged?.call(_selectedGoals.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Title area
          Text(
            'goals_title'.tr,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.50,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'select_all_that_apply'.tr,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
          ),

          // Goal tiles - flex:1, column, gap 11
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 11),
              itemBuilder: (context, index) {
                final goal = _goals[index];
                final isSelected = _selectedGoals.contains(index);
                return GestureDetector(
                  onTap: () => _toggleGoal(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        // Icon container
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: goal.bgColor,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Center(
                            child: OnboardingLineIcon(
                              goal.iconKey,
                              color: goal.fgColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Label
                        Expanded(
                          child: Text(
                            goal.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        // Check circle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.unselectedBorder,
                              width: isSelected ? 0 : 2,
                            ),
                          ),
                          child: isSelected
                              ? const OnboardingLineIcon(
                                  'check',
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
