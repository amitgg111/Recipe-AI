import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
import 'package:recipe_ai/widgets/selection_tile.dart';
import 'package:recipe_ai/screens/onboarding/thats_great_screen.dart';

class GoalsScreen extends StatefulWidget {
  static const String routeName = '/onboarding/goals';

  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final Set<int> _selectedGoals = {};

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
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Progress dots
              Center(
                child: ProgressIndicatorDots(
                  totalSteps: 8,
                  currentStep: 1,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                'What are your goals?',
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitle,
              ),
              const SizedBox(height: 18),
              // Subtitle
              Text(
                'Select all that apply',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 24),
              // Goal tiles
              SelectionTile(
                label: 'Eat healthier',
                isSelected: _selectedGoals.contains(0),
                onTap: () => _toggleGoal(0),
                leadingIcon: Icon(Icons.favorite, size: 20, color: AppColors.green),
                leadingIconBackground: AppColors.greenBg,
              ),
              const SizedBox(height: 11),
              SelectionTile(
                label: 'Save money',
                isSelected: _selectedGoals.contains(1),
                onTap: () => _toggleGoal(1),
                leadingIcon: Icon(Icons.savings, size: 20, color: AppColors.gold),
                leadingIconBackground: AppColors.goldBg,
              ),
              const SizedBox(height: 11),
              SelectionTile(
                label: 'Improve cooking skills',
                isSelected: _selectedGoals.contains(2),
                onTap: () => _toggleGoal(2),
                leadingIcon: const Icon(Icons.restaurant, size: 20, color: Color(0xFFE0552F)),
                leadingIconBackground: const Color(0xFFFCE3DB),
              ),
              const SizedBox(height: 11),
              SelectionTile(
                label: 'Organize recipes',
                isSelected: _selectedGoals.contains(3),
                onTap: () => _toggleGoal(3),
                leadingIcon: const Icon(Icons.folder_outlined, size: 20, color: Color(0xFF5559CE)),
                leadingIconBackground: const Color(0xFFE6E7FB),
              ),
              const SizedBox(height: 11),
              SelectionTile(
                label: 'Plan out meals',
                isSelected: _selectedGoals.contains(4),
                onTap: () => _toggleGoal(4),
                leadingIcon: const Icon(Icons.calendar_today, size: 20, color: Color(0xFF5E8A2C)),
                leadingIconBackground: const Color(0xFFE7F0DC),
              ),
              const SizedBox(height: 11),
              SelectionTile(
                label: 'Try new cuisines',
                isSelected: _selectedGoals.contains(5),
                onTap: () => _toggleGoal(5),
                leadingIcon: const Icon(Icons.explore, size: 20, color: Color(0xFFA23E8C)),
                leadingIconBackground: const Color(0xFFF4E1F0),
              ),
              const Spacer(),
              // Continue button
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Continue',
                onPressed: () {
                  Get.to(() => const ThatsGreatScreen());
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
