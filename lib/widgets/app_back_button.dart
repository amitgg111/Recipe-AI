import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;

  const AppBackButton({
    super.key,
    this.onTap,
    this.icon = Icons.arrow_back_ios_new_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      child: Container(
        width: AppDimensions.appBarButtonSize,
        height: AppDimensions.appBarButtonSize,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.surfaceBorderLight),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
