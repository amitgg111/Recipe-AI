import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/app_back_button.dart';
import 'package:recipe_ai/widgets/app_search_bar.dart';
import 'package:recipe_ai/widgets/recipe_card.dart';

class CookbookDetailMenuScreen extends StatefulWidget {
  final String title;
  final int recipeCount;

  const CookbookDetailMenuScreen({
    super.key,
    this.title = 'Weeknight Dinners',
    this.recipeCount = 12,
  });

  @override
  State<CookbookDetailMenuScreen> createState() =>
      _CookbookDetailMenuScreenState();
}

class _CookbookDetailMenuScreenState extends State<CookbookDetailMenuScreen> {
  bool _showMenu = true;

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
        child: Stack(
          children: [
            // Background content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
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
                                widget.title,
                                style: AppTextStyles.sectionTitle.copyWith(
                                  fontSize: 25,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${'n_recipes_lc'.trParams({'count': '${widget.recipeCount}'})} · ${'updated_today'.tr}',
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
                          child: AppSearchBar(hintText: 'search_recipes'.tr),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildRecipeList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Dark overlay
            if (_showMenu)
              GestureDetector(
                onTap: () => setState(() => _showMenu = false),
                child: Container(color: const Color(0x521E1B18)),
              ),
            // Popup menu
            if (_showMenu) _buildPopupMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
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
            widget.title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          // Dots button in active state
          GestureDetector(
            onTap: () => setState(() => _showMenu = !_showMenu),
            child: Container(
              width: AppDimensions.appBarButtonSize,
              height: AppDimensions.appBarButtonSize,
              decoration: BoxDecoration(
                color: _showMenu ? AppColors.redBg : AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: _showMenu
                      ? AppColors.primary
                      : AppColors.surfaceBorderLight,
                ),
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu() {
    return Positioned(
      top: 90,
      right: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Triangle pointer
          // Padding(
          //   padding: const EdgeInsets.only(right: 14),
          //   child: CustomPaint(
          //     size: const Size(16, 8),
          //     painter: _TrianglePainter(),
          //   ),
          // ),
          // Menu card
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Edit row
                GestureDetector(
                  onTap: () {
                    setState(() => _showMenu = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: AppColors.textBodyDark,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'edit'.tr,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textBodyDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.divider,
                  indent: 18,
                  endIndent: 18,
                ),
                // Delete row
                GestureDetector(
                  onTap: () {
                    setState(() => _showMenu = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.red,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'delete'.tr,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(recipe.time, style: AppTextStyles.smallLabel),
                  const SizedBox(width: 8),
                  const Icon(
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
