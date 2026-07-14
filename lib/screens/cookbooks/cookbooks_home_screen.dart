import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/app_bottom_nav.dart';
import 'package:recipe_ai/widgets/app_search_bar.dart';
import 'package:recipe_ai/widgets/cookbook_grid_card.dart';
import 'package:recipe_ai/widgets/segmented_control.dart';

class CookbooksHomeScreen extends StatefulWidget {
  const CookbooksHomeScreen({super.key});

  @override
  State<CookbooksHomeScreen> createState() => _CookbooksHomeScreenState();
}

class _CookbooksHomeScreenState extends State<CookbooksHomeScreen> {
  int _selectedNavIndex = 0;
  int _selectedSegment = 0;

  static const _mockCookbooks = [
    _CookbookData(title: 'Weeknight Dinners', recipeCount: 12),
    _CookbookData(title: 'Quick Breakfast', recipeCount: 0),
    _CookbookData(title: 'Meal Prep Sunday', recipeCount: 8),
    _CookbookData(title: 'Date Night', recipeCount: 5),
    _CookbookData(title: 'Healthy Bowls', recipeCount: 3),
    _CookbookData(title: 'Holiday Specials', recipeCount: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.bottomNavHeight + AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        _buildSegmentedRow(),
                        const SizedBox(height: AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                          ),
                          child: AppSearchBar(hintText: 'search_cookbooks'.tr),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _buildGrid(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNav(
                currentIndex: _selectedNavIndex,
                onTap: (i) => setState(() => _selectedNavIndex = i),
              ),
            ),
            _buildFAB(),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 20,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.goldBg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: AppColors.gold),
                const SizedBox(width: 4),
                Text(
                  '4/5',
                  style: AppTextStyles.chipLabel.copyWith(
                    color: AppColors.gold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: SegmentedControl(
              segments: ['cookbooks'.tr, 'recipes'.tr],
              selectedIndex: _selectedSegment,
              onChanged: (i) => setState(() => _selectedSegment = i),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Sort button
          GestureDetector(
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
                Icons.tune_rounded,
                size: 20,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemCount: _mockCookbooks.length,
        itemBuilder: (context, index) {
          final cookbook = _mockCookbooks[index];
          return CookbookGridCard(
            title: cookbook.title,
            recipeCount: cookbook.recipeCount,
            onTap: () {},
          );
        },
      ),
    );
  }

  Widget _buildFAB() {
    return Positioned(
      right: AppSpacing.xl,
      bottom: AppDimensions.bottomNavHeight + AppSpacing.lg,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: AppDimensions.fabSize,
          height: AppDimensions.fabSize,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryShadow,
                blurRadius: 20,
                offset: Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _CookbookData {
  final String title;
  final int recipeCount;

  const _CookbookData({required this.title, required this.recipeCount});
}
