import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Fixed top bar for the onboarding flow.
///
/// Left: a rounded-square back button (hidden on the first step).
/// Right: a thin rounded progress track that animates smoothly between steps.
///
/// [currentStep] is 1-based. Progress fill = currentStep / totalSteps.
class OnboardingProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool showBackButton;
  final VoidCallback? onBack;

  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.showBackButton = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = (currentStep / totalSteps).clamp(0.0, 1.0);
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          if (showBackButton) ...[
            _OnboardingBackButton(onTap: onBack),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: _ProgressTrack(fraction: fraction),
          ),
        ],
      ),
    );
  }
}

class _OnboardingBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _OnboardingBackButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDE3D2)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          size: 15,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  final double fraction;

  const _ProgressTrack({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Stack(
        children: [
          // Inactive track (warm beige, matching the HTML).
          Container(
            height: 6,
            width: double.infinity,
            color: const Color(0xFFEDE3D0),
          ),
          // Active fill (animates smoothly when [fraction] changes)
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: fraction),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
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
