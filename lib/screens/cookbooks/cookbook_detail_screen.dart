import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/app_back_button.dart';
import 'package:recipe_ai/widgets/app_search_bar.dart';
import 'package:recipe_ai/widgets/recipe_card.dart';

class CookbookDetailScreen extends StatelessWidget {
  final String title;
  final int recipeCount;

  const CookbookDetailScreen({
    super.key,
    this.title = 'Weeknight Dinners',
    this.recipeCount = 12,
  });

  static const _mockRecipes = [
    _RecipeData(title: 'Coconut Chickpea Curry', time: '35 min'),
    _RecipeData(title: 'Lemon Herb Salmon', time: '25 min'),
    _RecipeData(title: 'One-Pot Pasta Primavera', time: '30 min'),
    _RecipeData(title: 'Thai Basil Chicken', time: '20 min'),
    _RecipeData(title: 'Mushroom Risotto', time: '45 min'),
    _RecipeData(title: 'Crispy Tofu Bowl', time: '35 min'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: AppSpacing.huge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.sectionTitle.copyWith(
                              fontSize: 25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$recipeCount recipes · updated today',
                            style: AppTextStyles.smallLabel,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: AppSearchBar(hintText: 'Search recipes'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildRecipeList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AppBackButton(),
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          _buildMenuButton(context),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: AppDimensions.appBarButtonSize,
        height: AppDimensions.appBarButtonSize,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.surfaceBorderLight),
        ),
        child: const Icon(
          Icons.more_horiz_rounded,
          size: 20,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildRecipeList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: _mockRecipes.map((recipe) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: RecipeCard(
              title: recipe.title,
              subtitle: recipe.time,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(recipe.time, style: AppTextStyles.smallLabel),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textHint,
                    size: AppDimensions.iconMd,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecipeData {
  final String title;
  final String time;

  const _RecipeData({required this.title, required this.time});
}
