import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/bottom_sheet_handle.dart';

class SortSheet extends StatefulWidget {
  const SortSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SortSheet(),
    );
  }

  @override
  State<SortSheet> createState() => _SortSheetState();
}

class _SortSheetState extends State<SortSheet> {
  int _selectedIndex = 0; // "Newest first" selected by default

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.sm,
              AppSpacing.xxl,
              AppSpacing.xl,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'sort_by'.tr,
                style: AppTextStyles.listTitle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // Sort options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              children: [
                _SortOption(
                  icon: _buildClockIcon(isSelected: true),
                  title: 'newest_first'.tr,
                  isSelected: _selectedIndex == 0,
                  onTap: () => _select(0),
                ),
                const SizedBox(height: 10),
                _SortOption(
                  icon: _buildClockIcon(isSelected: false),
                  title: 'oldest_first'.tr,
                  isSelected: _selectedIndex == 1,
                  onTap: () => _select(1),
                ),
                const SizedBox(height: 10),
                _SortOption(
                  icon: _buildLetterIcon('A', isSelected: _selectedIndex == 2),
                  title: 'name_a_z'.tr,
                  isSelected: _selectedIndex == 2,
                  onTap: () => _select(2),
                ),
                const SizedBox(height: 10),
                _SortOption(
                  icon: _buildLetterIcon('Z', isSelected: _selectedIndex == 3),
                  title: 'name_z_a'.tr,
                  isSelected: _selectedIndex == 3,
                  onTap: () => _select(3),
                ),
              ],
            ),
          ),

          SizedBox(
            height: MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
          ),
        ],
      ),
    );
  }

  void _select(int index) {
    setState(() => _selectedIndex = index);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) Navigator.pop(context, index);
    });
  }

  /// Clock icon for Newest/Oldest
  Widget _buildClockIcon({required bool isSelected}) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFCE3DB) : const Color(0xFFF4F1EA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.access_time_rounded,
        size: 20,
        color: isSelected ? AppColors.primary : AppColors.textMedium,
      ),
    );
  }

  /// Letter icon for A-Z / Z-A
  Widget _buildLetterIcon(String letter, {required bool isSelected}) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFCE3DB) : const Color(0xFFF4F1EA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isSelected ? AppColors.primary : AppColors.textMedium,
          ),
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final Widget icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF3EF) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: isSelected
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.textDark : AppColors.textDark,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
