import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/app_bottom_nav.dart';

class MealPlanCalendarScreen extends StatefulWidget {
  const MealPlanCalendarScreen({super.key});

  @override
  State<MealPlanCalendarScreen> createState() => _MealPlanCalendarScreenState();
}

class _MealPlanCalendarScreenState extends State<MealPlanCalendarScreen> {
  int _viewMode = 1; // 0 = Day, 1 = Month
  int _selectedDay = 25;

  // Days with meals planned (dots)
  final _mealDots = {
    3: [AppColors.gold],
    5: [AppColors.gold, AppColors.green],
    7: [AppColors.gold, AppColors.green, AppColors.blue],
    10: [AppColors.green, AppColors.blue],
    12: [AppColors.gold, AppColors.blue],
    14: [AppColors.gold, AppColors.green, AppColors.blue, AppColors.red],
    17: [AppColors.green],
    19: [AppColors.gold, AppColors.green, AppColors.blue],
    21: [AppColors.blue, AppColors.red],
    23: [AppColors.gold, AppColors.green],
    24: [AppColors.gold, AppColors.green, AppColors.blue],
    25: [AppColors.gold, AppColors.green, AppColors.blue],
    26: [AppColors.green, AppColors.blue],
    28: [AppColors.gold],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildMonthNav(),
            const SizedBox(height: 18),
            _buildCalendarGrid(),
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 2, onTap: (i) {}),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Text(
            'Meal Plan',
            style: AppTextStyles.cardTitle.copyWith(fontSize: 22),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [_segmentTab('Day', 0), _segmentTab('Month', 1)],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: const Icon(
                Icons.more_horiz,
                size: 20,
                color: AppColors.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentTab(String label, int index) {
    final selected = _viewMode == index;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm - 2),
        ),
        child: Text(
          label,
          style: AppTextStyles.smallLabel.copyWith(
            color: selected ? Colors.white : AppColors.textMedium,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: const Icon(
                Icons.chevron_left,
                size: 20,
                color: AppColors.textMedium,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'June 2026',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // June 2026 starts on Monday
    const startOffset = 0;
    const totalDays = 30;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Day labels
          Row(
            children: dayLabels.map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: AppTextStyles.smallLabel.copyWith(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          // Calendar weeks
          ...List.generate(5, (week) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(7, (dayOfWeek) {
                  final dayNum = week * 7 + dayOfWeek + 1 - startOffset;
                  if (dayNum < 1 || dayNum > totalDays) {
                    return const Expanded(child: SizedBox(height: 56));
                  }
                  return Expanded(child: _buildDayCell(dayNum));
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayCell(int day) {
    final isSelected = day == _selectedDay;
    final dots = _mealDots[day] ?? [];

    return GestureDetector(
      onTap: () => setState(() => _selectedDay = day),
      child: Container(
        height: 56,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: isSelected
              ? null
              : Border.all(color: AppColors.surfaceBorder),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryShadow.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: AppTextStyles.chipLabel.copyWith(
                color: isSelected ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            if (dots.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: dots.take(4).map((color) {
                  return Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.85)
                          : color,
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
