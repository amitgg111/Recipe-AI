import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/bottom_sheet_handle.dart';
import 'package:recipe_ai/widgets/app_search_bar.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class AddMealSheet extends StatefulWidget {
  final ScrollController? scrollController;

  const AddMealSheet({super.key, this.scrollController});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusSheet),
              ),
            ),
            child: AddMealSheet(scrollController: scrollController),
          );
        },
      ),
    );
  }

  @override
  State<AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<AddMealSheet> {
  int _selectedMealType = 2; // Dinner selected

  final _mealTypes = [
    const _MealType('Breakfast', Color(0xFFFCF3DE), Color(0xFF7A5B12)),
    const _MealType('Lunch', Color(0xFFEAF6F0), Color(0xFF1F5E42)),
    const _MealType('Dinner', AppColors.blue, Colors.white),
    const _MealType('Snack', Color(0xFFFCEAE3), Color(0xFF9B3417)),
  ];

  final _recipes = [
    const _RecipeData('Spicy Tomato Rigatoni', '35 min'),
    const _RecipeData('Crispy Honey Garlic Salmon', '25 min'),
    const _RecipeData('Rainbow Buddha Bowl', '20 min'),
    const _RecipeData('Lemon Herb Chicken', '40 min'),
    const _RecipeData('Mushroom Risotto', '45 min'),
    const _RecipeData('Thai Green Curry', '30 min'),
  ];

  int? _selectedRecipe;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BottomSheetHandle(),
        const SizedBox(height: 6),
        // Title row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Add to Wed, Dinner',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceBorder,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18, color: AppColors.textMedium),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Meal type chips
        _buildMealTypeChips(),
        const SizedBox(height: 16),
        // Search bar
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: AppSearchBar(hintText: 'Search your recipes'),
        ),
        const SizedBox(height: 14),
        const Divider(color: AppColors.divider, height: 1),
        // Recipe list
        Expanded(
          child: ListView.separated(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            itemCount: _recipes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              return _buildRecipeItem(index);
            },
          ),
        ),
        // Bottom button
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.divider),
            ),
          ),
          child: SafeArea(
            top: false,
            child: PrimaryButton(
              label: 'Add to Plan',
              leadingIcon: const Icon(Icons.check, color: Colors.white, size: 20),
              onPressed: _selectedRecipe != null ? () => Navigator.pop(context) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealTypeChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _mealTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final type = _mealTypes[index];
          final selected = index == _selectedMealType;

          Color bgColor;
          Color textColor;
          if (selected && index == 2) {
            // Dinner selected
            bgColor = AppColors.blue;
            textColor = Colors.white;
          } else {
            bgColor = type.bgColor;
            textColor = type.textColor;
          }

          return GestureDetector(
            onTap: () => setState(() => _selectedMealType = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                border: selected
                    ? null
                    : Border.all(color: bgColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                type.label,
                style: AppTextStyles.chipLabel.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipeItem(int index) {
    final recipe = _recipes[index];
    final selected = _selectedRecipe == index;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedRecipe = selected ? null : index;
      }),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceBorder,
            width: selected ? 1.5 : 1,
          ),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    recipe.time,
                    style: AppTextStyles.smallLabel.copyWith(
                      color: AppColors.textMedium,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Add button
            GestureDetector(
              onTap: () => setState(() {
                _selectedRecipe = selected ? null : index;
              }),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  shape: BoxShape.circle,
                  border: selected
                      ? null
                      : Border.all(color: AppColors.surfaceBorder),
                ),
                child: Icon(
                  selected ? Icons.check : Icons.add,
                  size: 16,
                  color: selected ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealType {
  final String label;
  final Color bgColor;
  final Color textColor;
  const _MealType(this.label, this.bgColor, this.textColor);
}

class _RecipeData {
  final String title;
  final String time;
  const _RecipeData(this.title, this.time);
}
