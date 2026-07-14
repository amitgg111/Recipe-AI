import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/segmented_control.dart';
import 'package:recipe_ai/widgets/app_search_bar.dart';
import 'package:recipe_ai/widgets/app_bottom_nav.dart';
import 'package:recipe_ai/screens/cookbooks/sort_sheet.dart';

class RecipesGridScreen extends StatefulWidget {
  const RecipesGridScreen({super.key});

  @override
  State<RecipesGridScreen> createState() => _RecipesGridScreenState();
}

class _RecipesGridScreenState extends State<RecipesGridScreen> {
  int _segmentIndex = 1; // Recipes tab active

  // Sample recipe data
  final List<_RecipeItem> _recipes = const [
    _RecipeItem(
      title: 'Classic Margherita Pizza',
      duration: '35 min',
      isFavorite: true,
    ),
    _RecipeItem(
      title: 'Thai Green Curry',
      duration: '45 min',
      isFavorite: false,
    ),
    _RecipeItem(title: 'Avocado Toast', duration: '10 min', isFavorite: true),
    _RecipeItem(
      title: 'Chicken Tikka Masala',
      duration: '50 min',
      isFavorite: false,
    ),
    _RecipeItem(
      title: 'Berry Smoothie Bowl',
      duration: '15 min',
      isFavorite: false,
    ),
    _RecipeItem(title: 'Pasta Carbonara', duration: '25 min', isFavorite: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Logo row + credits badge
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.xxl,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  const AppWordmark(fontSize: 22, fontWeight: FontWeight.w800),
                  const Spacer(),
                  // Credits badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusRound,
                      ),
                      border: Border.all(color: AppColors.surfaceBorderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '5 credits',
                          style: AppTextStyles.chipLabel.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Segmented control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: SegmentedControl(
                segments: ['cookbooks'.tr, 'recipes'.tr],
                selectedIndex: _segmentIndex,
                onChanged: (index) {
                  setState(() => _segmentIndex = index);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Sort button + Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Row(
                children: [
                  // Sort button
                  GestureDetector(
                    onTap: () => SortSheet.show(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusIcon,
                        ),
                        border: Border.all(color: AppColors.surfaceBorderLight),
                      ),
                      child: const Icon(
                        Icons.swap_vert_rounded,
                        size: 22,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Search bar
                  Expanded(
                    child: AppSearchBar(
                      hintText: 'search_recipes'.tr,
                      readOnly: true,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Recipe grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  100,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                itemCount: _recipes.length,
                itemBuilder: (context, index) {
                  return _RecipeGridCard(recipe: _recipes[index]);
                },
              ),
            ),
          ],
        ),
      ),
      // Orange FAB
      floatingActionButton: Container(
        width: AppDimensions.fabSize,
        height: AppDimensions.fabSize,

        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: AppColors.primaryShadow,
              blurRadius: 24,
              offset: Offset(0, 10),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Container(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {},
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 0, onTap: (_) {}),
    );
  }
}

/// Recipe card for the grid
class _RecipeGridCard extends StatelessWidget {
  final _RecipeItem recipe;

  const _RecipeGridCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Stack(
              children: [
                Container(
                  height: 104,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5EDE0),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppDimensions.radiusLg - 1),
                    ),
                  ),
                  child: Icon(
                    Icons.restaurant_rounded,
                    size: 36,
                    color: AppColors.textLight.withValues(alpha: 0.4),
                  ),
                ),
                // Heart icon
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      recipe.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 14,
                      color: recipe.isFavorite
                          ? AppColors.primary
                          : AppColors.textMedium,
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: AppTextStyles.chipLabel.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recipe.duration,
                        style: AppTextStyles.smallLabel.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeItem {
  final String title;
  final String duration;
  final bool isFavorite;

  const _RecipeItem({
    required this.title,
    required this.duration,
    required this.isFavorite,
  });
}
