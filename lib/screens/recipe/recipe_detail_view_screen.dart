import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/app_bottom_nav.dart';
import 'package:recipe_ai/screens/recipe/recipe_menu_popup.dart';
import 'package:recipe_ai/screens/recipe/add_note_sheet.dart';
import 'package:recipe_ai/screens/recipe/add_to_cookbook_sheet.dart';
import 'package:recipe_ai/screens/recipe/recipe_detail_edit_screen.dart';

class RecipeDetailViewScreen extends StatefulWidget {
  const RecipeDetailViewScreen({super.key});

  @override
  State<RecipeDetailViewScreen> createState() => _RecipeDetailViewScreenState();
}

class _RecipeDetailViewScreenState extends State<RecipeDetailViewScreen> {
  int _servings = 2;
  int _navIndex = 0;
  final Set<int> _checkedIngredients = {};
  final GlobalKey _menuButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeroImage()),
              SliverToBoxAdapter(child: _buildRecipeHeader()),
              SliverToBoxAdapter(child: _buildInfoRow()),
              SliverToBoxAdapter(child: _buildActionButtons()),
              SliverToBoxAdapter(child: _buildCookbooksCard()),
              SliverToBoxAdapter(child: _buildAddNoteCard()),
              SliverToBoxAdapter(child: _buildIngredientsCard()),
              SliverToBoxAdapter(child: _buildInstructionsCard()),
              SliverToBoxAdapter(child: _buildNutritionCard()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNav(
              currentIndex: _navIndex,
              onTap: (i) => setState(() => _navIndex = i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFD4C4A8),
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=800',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  AppColors.background,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Top buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHeroButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Get.back(),
                ),
                Row(
                  children: [
                    _buildHeroButton(
                      icon: Icons.edit_outlined,
                      onTap: () => Get.to(() => const RecipeDetailEditScreen()),
                    ),
                    const SizedBox(width: 8),
                    _buildHeroButton(
                      key: _menuButtonKey,
                      icon: Icons.more_horiz_rounded,
                      onTap: () => _showMenuPopup(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroButton({
    Key? key,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 20, color: AppColors.textDark),
      ),
    );
  }

  void _showMenuPopup() {
    final RenderBox renderBox =
        _menuButtonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    RecipeMenuPopup.show(
      context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + renderBox.size.height + 8,
        MediaQuery.of(context).size.width - offset.dx - renderBox.size.width,
        0,
      ),
    );
  }

  Widget _buildRecipeHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coconut Chickpea Curry',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.52,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.language, size: 14, color: AppColors.textMedium),
              const SizedBox(width: 5),
              Text(
                'From cookpad.com',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.greenBgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const OnboardingLineIcon('globe',
                      size: 13, color: AppColors.green),
                  const SizedBox(width: 5),
                  Text(
                    'Public',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '· tap to change',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.greenText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          _buildInfoItem(Icons.access_time_rounded, '35 min'),
          _buildInfoDot(),
          _buildInfoItem(Icons.person_outline_rounded, '2 servings'),
          _buildInfoDot(),
          _buildInfoItem(Icons.auto_awesome, 'Easy'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textBodyDark),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textBodyDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.textMedium.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.menu_book_rounded,
            label: 'Cookbook',
            onTap: () => AddToCookbookSheet.show(context),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.calendar_today_rounded,
            label: 'Meal Plan',
            onTap: () {},
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Icon(icon, size: 24, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCookbooksCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEFE6D6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cookbooks',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChipTag('Weeknight Dinners'),
                _buildChipTag('Fresh & Green'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildAddNoteCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: GestureDetector(
        onTap: () => AddNoteSheet.show(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEFE6D6)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add a note',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Personal tips, tweaks, or memories',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.textMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientsCard() {
    final groups = [
      _IngredientGroup('Curry Base', [
        _Ingredient('1 can', 'coconut milk (400ml)'),
        _Ingredient('1 can', 'chickpeas, drained'),
        _Ingredient('2 tbsp', 'curry paste'),
        _Ingredient('1 tbsp', 'olive oil'),
      ]),
      _IngredientGroup('Vegetables', [
        _Ingredient('1 cup', 'baby spinach'),
        _Ingredient('1', 'red bell pepper, diced'),
        _Ingredient('½', 'onion, diced'),
      ]),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEFE6D6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ingredients', style: AppTextStyles.cardTitle),
                _buildServingStepper(),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to add to your grocery list',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 16),
            ...groups.asMap().entries.map((entry) {
              final groupIndex = entry.key;
              final group = entry.value;
              return _buildIngredientGroup(group, groupIndex);
            }),
            const SizedBox(height: 16),
            _buildAddAllToGroceriesButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildServingStepper() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (_servings > 1) setState(() => _servings--);
            },
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              child: const Icon(Icons.remove, size: 18, color: AppColors.textDark),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$_servings serv',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _servings++),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              child: const Icon(Icons.add, size: 18, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientGroup(_IngredientGroup group, int groupIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (groupIndex > 0) const SizedBox(height: 14),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              group.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...group.items.asMap().entries.map((entry) {
          final itemIndex = groupIndex * 100 + entry.key;
          final item = entry.value;
          return _buildIngredientItem(item, itemIndex);
        }),
      ],
    );
  }

  Widget _buildIngredientItem(_Ingredient item, int index) {
    final checked = _checkedIngredients.contains(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (checked) {
              _checkedIngredients.remove(index);
            } else {
              _checkedIngredients.add(index);
            }
          });
        },
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checked ? AppColors.primary : const Color(0xFFE2D8C7),
                  width: 2,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFFBF1E4),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                size: 15,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              item.amount,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAllToGroceriesButton() {
    return Container(
      width: double.infinity,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EF),
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
        border: Border.all(color: AppColors.primary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          child: Center(
            child: Text(
              'Add all to groceries',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    final steps = [
      _InstructionStep(
        'Heat olive oil in a large pan over medium heat. Add diced onion and cook until translucent, about 3–4 minutes.',
      ),
      _InstructionStep(
        'Add curry paste and stir for 1 minute until fragrant.',
      ),
      _InstructionStep(
        'Pour in coconut milk and bring to a simmer. Add chickpeas and bell pepper.',
      ),
      _InstructionStep(
        'Cook for 15 minutes, stirring occasionally, until sauce thickens.',
      ),
      _InstructionStep(
        'Stir in baby spinach and cook until wilted. Season with salt and pepper.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEFE6D6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Instructions', style: AppTextStyles.cardTitle),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              return _buildInstructionStep(entry.key + 1, entry.value);
            }),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Cook step-by-step',
              leadingIcon: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(int number, _InstructionStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: const Color(0xFFFCE3DB),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                step.text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textBodyDark,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEFE6D6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NUTRITION',
              style: AppTextStyles.tinyLabel.copyWith(
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Per 1 serving',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 14),
            // Plus upsell banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF1C9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    size: 22,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unlock nutrition info',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Upgrade to Plus for detailed breakdowns',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Blurred donut chart preview
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: SizedBox(
                  height: 120,
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 12,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.green,
                            width: 10,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientGroup {
  final String name;
  final List<_Ingredient> items;
  _IngredientGroup(this.name, this.items);
}

class _Ingredient {
  final String amount;
  final String name;
  _Ingredient(this.amount, this.name);
}

class _InstructionStep {
  final String text;
  _InstructionStep(this.text);
}
