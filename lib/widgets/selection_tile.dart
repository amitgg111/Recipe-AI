import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_dimensions.dart';

class SelectionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? leadingIcon;
  final Color? leadingIconBackground;

  const SelectionTile({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.leadingIcon,
    this.leadingIconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: leadingIconBackground ?? AppColors.background,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusIcon),
                ),
                child: Center(child: leadingIcon!),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge,
              ),
            ),
            const SizedBox(width: 12),
            _CheckCircle(isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  final bool isSelected;

  const _CheckCircle({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.unselectedBorder,
          width: isSelected ? 0 : 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : null,
    );
  }
}
