import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'sliding_segmented.dart';

/// Full-width segmented toggle used for the wide tab selectors (Cookbooks /
/// Recipes, Login / Sign up). Thin wrapper over [SlidingSegmented] in its
/// [SlidingSegmented.expand] mode so every toggle in the app shares one widget.
class SegmentedControl extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const SegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SlidingSegmented(
      expand: true,
      labels: segments,
      selectedIndex: selectedIndex,
      onChanged: onChanged,
      trackColor: AppColors.tabBg,
      pillColor: AppColors.surface,
      trackRadius: 12,
      pillRadius: 9,
      trackPadding: 3,
      vPad: 10,
      pillShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      style: (active) => active
          ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)
          : AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
    );
  }
}
