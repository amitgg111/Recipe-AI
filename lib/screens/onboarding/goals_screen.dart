import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
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
  final IconData icon;

  const _GoalItem({
    required this.label,
    required this.bgColor,
    required this.fgColor,
    required this.icon,
  });
}

class _GoalsScreenState extends State<GoalsScreen> {
  // Goals 0 and 1 are pre-selected
  final Set<int> _selectedGoals = {0, 1};

  static const List<_GoalItem> _goals = [
    _GoalItem(
      label: 'Eat healthier',
      bgColor: AppColors.greenBg,
      fgColor: AppColors.green,
      icon: Icons.restaurant,
    ),
    _GoalItem(
      label: 'Save money',
      bgColor: AppColors.goldBg,
      fgColor: AppColors.gold,
      icon: Icons.account_balance_wallet,
    ),
    _GoalItem(
      label: 'Improve cooking skills',
      bgColor: Color(0xFFFCE3DB),
      fgColor: Color(0xFFE0552F),
      icon: Icons.school,
    ),
    _GoalItem(
      label: 'Organize recipes',
      bgColor: Color(0xFFE6E7FB),
      fgColor: Color(0xFF5559CE),
      icon: Icons.folder,
    ),
    _GoalItem(
      label: 'Plan out meals',
      bgColor: Color(0xFFE7F0DC),
      fgColor: Color(0xFF5E8A2C),
      icon: Icons.calendar_today,
    ),
    _GoalItem(
      label: 'Try new cuisines',
      bgColor: Color(0xFFF4E1F0),
      fgColor: Color(0xFFA23E8C),
      icon: Icons.public,
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
                  Text(
                    'Recipe AI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress dots (step 2 of 8, index 1)
              const ProgressIndicatorDots(totalSteps: 8, currentStep: 1),
              // Title area
              const SizedBox(height: 16),
              Text(
                'What are your goals?',
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
                'Select all that apply',
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
                  // physics: const NeverScrollableScrollPhysics(),
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
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: goal.bgColor,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Center(
                                child: Icon(
                                  goal.icon,
                                  size: 20,
                                  color: goal.fgColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Label
                            Expanded(
                              child: Text(
                                goal.label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
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
                                  ? const Icon(
                                      Icons.check,
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
                label: 'Continue',
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
  // Goals 0 and 1 are pre-selected
  final Set<int> _selectedGoals = {0, 1};

  static const List<_GoalItem> _goals = [
    _GoalItem(
      label: 'Eat healthier',
      bgColor: AppColors.greenBg,
      fgColor: AppColors.green,
      icon: Icons.restaurant,
    ),
    _GoalItem(
      label: 'Save money',
      bgColor: AppColors.goldBg,
      fgColor: AppColors.gold,
      icon: Icons.account_balance_wallet,
    ),
    _GoalItem(
      label: 'Improve cooking skills',
      bgColor: Color(0xFFFCE3DB),
      fgColor: Color(0xFFE0552F),
      icon: Icons.school,
    ),
    _GoalItem(
      label: 'Organize recipes',
      bgColor: Color(0xFFE6E7FB),
      fgColor: Color(0xFF5559CE),
      icon: Icons.folder,
    ),
    _GoalItem(
      label: 'Plan out meals',
      bgColor: Color(0xFFE7F0DC),
      fgColor: Color(0xFF5E8A2C),
      icon: Icons.calendar_today,
    ),
    _GoalItem(
      label: 'Try new cuisines',
      bgColor: Color(0xFFF4E1F0),
      fgColor: Color(0xFFA23E8C),
      icon: Icons.public,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Report the initial (default) validity after the first frame.
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
            'What are your goals?',
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
            'Select all that apply',
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
              physics: const NeverScrollableScrollPhysics(),
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
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: goal.bgColor,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Center(
                            child: Icon(
                              goal.icon,
                              size: 20,
                              color: goal.fgColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Label
                        Expanded(
                          child: Text(
                            goal.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
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
                              ? const Icon(
                                  Icons.check,
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
