import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/View/Home/cookbooks_screen.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class ImportCompleteScreen extends StatelessWidget {
  const ImportCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 6, 22, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWarningBanner(),
                        const SizedBox(height: 16),
                        Text(
                          'Coconut Chickpea Curry',
                          style: AppTextStyles.sectionTitle.copyWith(
                            height: 1.14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildSourceBadge(),
                        const SizedBox(height: 14),
                        _buildInfoRow(),
                        const SizedBox(height: 20),
                        _buildIngredientsCard(),
                        const SizedBox(height: 16),
                        _buildInstructionsCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomButton(context),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8B87A), Color(0xFFD49A5C)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.restaurant, size: 64, color: Colors.white54),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66140F0A),
                    Colors.transparent,
                    Colors.transparent,
                    AppColors.background,
                  ],
                  stops: [0, 0.32, 0.64, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 18,
            right: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Get.offAll(() => const CookbooksScreen()),

                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xF21F7A5E),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Imported',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.gold, size: 18),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'AI pulled this from Instagram. Check the details, then save.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.warningText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.instagramBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.camera_alt, color: AppColors.instagram, size: 16),
          SizedBox(width: 6),
          Text(
            'From Instagram · @recipe.app',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.instagram,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        _infoChip(Icons.access_time, '35 min'),
        _dot(),
        _infoChip(Icons.person_outline, '2 servings'),
        _dot(),
        _infoChip(Icons.auto_awesome, 'Easy'),
      ],
    );
  }

  Widget _dot() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 9),
    child: Text(
      '·',
      style: TextStyle(
        color: Color(0xFFD8CFC0),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textBodyDark,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsCard() {
    final groups = [
      const _IngGroup('Curry base', [
        _Ingredient('1 can', 'Coconut milk'),
        _Ingredient('2 cups', 'Chickpeas'),
        _Ingredient('1 tbsp', 'Curry paste'),
      ]),
      const _IngGroup('Seasonings', [
        _Ingredient('1 tsp', 'Turmeric'),
        _Ingredient('1 tsp', 'Cumin'),
        _Ingredient('½ tsp', 'Chili flakes'),
      ]),
      const _IngGroup('Toppings', [
        _Ingredient('¼ cup', 'Fresh cilantro'),
        _Ingredient('1 tbsp', 'Lime juice'),
        _Ingredient('2 tbsp', 'Coconut cream'),
      ]),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE6D6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F2A211B),
            blurRadius: 26,
            offset: Offset(0, 12),
            spreadRadius: -22,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ingredients', style: AppTextStyles.listTitle),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenBgLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '9 found',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...groups.expand(
            (group) => [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              ...group.items.map(
                (ing) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.divider),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF1E4),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.shopping_basket_outlined,
                          color: AppColors.goldDark,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 54,
                        child: Text(
                          ing.amount,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          ing.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textBodyDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    final steps = [
      'Heat oil in a large pan over medium heat.',
      'Add onion and garlic, sauté until soft.',
      'Stir in curry paste and cook for 1 minute.',
      'Add chickpeas and coconut milk. Simmer 15 min.',
      'Season with salt, serve over rice.',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE6D6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F2A211B),
            blurRadius: 26,
            offset: Offset(0, 12),
            spreadRadius: -22,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Instructions', style: AppTextStyles.listTitle),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenBgLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '5 steps',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map(
            (e) => Container(
              padding: const EdgeInsets.fromLTRB(15, 9, 0, 9),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: AppColors.redBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.textBodyMedium,
                        ),
                      ),
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

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: PrimaryButton(
        label: 'Save to cookbook',
        onPressed: () => Get.back(),
      ),
    );
  }
}

class _IngGroup {
  final String name;
  final List<_Ingredient> items;
  const _IngGroup(this.name, this.items);
}

class _Ingredient {
  final String amount;
  final String name;
  const _Ingredient(this.amount, this.name);
}
