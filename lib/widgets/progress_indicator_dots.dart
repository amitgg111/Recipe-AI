import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProgressIndicatorDots extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final Color activeColor;
  final Color inactiveColor;

  const ProgressIndicatorDots({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.activeColor = AppColors.textDark,
    this.inactiveColor = AppColors.surfaceBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
