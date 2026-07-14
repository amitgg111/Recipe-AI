import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/app_bottom_nav.dart';

class MealPlanDayScreen extends StatefulWidget {
  const MealPlanDayScreen({super.key});

  @override
  State<MealPlanDayScreen> createState() => _MealPlanDayScreenState();
}

class _MealPlanDayScreenState extends State<MealPlanDayScreen> {
  int _selectedDay = 2; // Wednesday
  int _viewMode = 0; // 0 = Day, 1 = Month

  final _weekDays = [
    const _DayData('M', '23'),
    const _DayData('T', '24'),
    const _DayData('W', '25'),
    const _DayData('T', '26'),
    const _DayData('F', '27'),
    const _DayData('S', '28'),
    const _DayData('S', '29'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildWeekStrip(),
                  const SizedBox(height: 18),
                  _buildGroceryButton(),
                  const SizedBox(height: 22),
                  _buildMealSection(
                    'breakfast'.tr,
                    AppColors.gold,
                    [
                      const _RecipeItem('Avocado Toast with Eggs', '15 min'),
                    ],
                  ),
                  _buildMealSection(
                    'lunch'.tr,
                    AppColors.green,
                    [
                      const _RecipeItem('Mediterranean Quinoa Salad', '20 min'),
                      const _RecipeItem('Lemon Herb Chicken Wrap', '10 min'),
                    ],
                  ),
                  _buildMealSection(
                    'dinner'.tr,
                    AppColors.blue,
                    [
                      const _RecipeItem('Spicy Tomato Rigatoni', '35 min'),
                    ],
                  ),
                  _buildMealSection(
                    'snack'.tr,
                    AppColors.red,
                    [],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) {},
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Text(
            'meal_plan'.tr,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 22),
          ),
          const Spacer(),
          // Segmented control
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                _segmentTab('day'.tr, 0),
                _segmentTab('month'.tr, 1),
              ],
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
              child: const Icon(Icons.more_horiz, size: 20, color: AppColors.textMedium),
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

  Widget _buildWeekStrip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.chevron_left, color: AppColors.textMedium, size: 24),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_weekDays.length, (index) {
                final day = _weekDays[index];
                final selected = index == _selectedDay;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = index),
                  child: Container(
                    width: 40,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      border: selected
                          ? null
                          : Border.all(color: const Color(0xFFEFE6D6)),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryShadow.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          day.letter,
                          style: AppTextStyles.smallLabel.copyWith(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.8)
                                : AppColors.textMedium,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          day.number,
                          style: AppTextStyles.chipLabel.copyWith(
                            color: selected ? Colors.white : AppColors.textDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.chevron_right, color: AppColors.textMedium, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildGroceryButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3EF),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'add_this_week_to_groceries'.tr,
                style: AppTextStyles.chipLabel.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealSection(String title, Color color, List<_RecipeItem> recipes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: AppTextStyles.tagLabel.copyWith(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Recipe cards
          ...recipes.map((r) => _buildRecipeCard(r)),
          // Add button
          _buildAddButton(title.toLowerCase()),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(_RecipeItem recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          // Image placeholder
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surfaceBorder,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.restaurant,
              size: 22,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: AppTextStyles.chipLabel.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 13, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(
                      recipe.time,
                      style: AppTextStyles.smallLabel.copyWith(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert, size: 20, color: AppColors.textLight),
        ],
      ),
    );
  }

  Widget _buildAddButton(String mealType) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: const Color(0xFFD8CFBE),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              '${'add'.tr} $mealType',
              style: AppTextStyles.chipLabel.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayData {
  final String letter;
  final String number;
  const _DayData(this.letter, this.number);
}

class _RecipeItem {
  final String title;
  final String time;
  const _RecipeItem(this.title, this.time);
}
