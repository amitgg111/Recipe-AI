import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class PublicRecipeScreen extends StatelessWidget {
  const PublicRecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildHeroImage(context),
              SliverToBoxAdapter(child: _buildContent()),
            ],
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: Padding(
        padding: const EdgeInsets.all(6),
        child: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 22),
          ),
        ),
      ),
      actions: [
        _heroActionButton(Icons.share_outlined),
        const SizedBox(width: 8),
        _heroActionButton(Icons.bookmark_border),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: const Color(0xFFD44A2E),
              child: Center(
                child: Icon(
                  Icons.restaurant,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroActionButton(IconData icon) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textDark, size: 20),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAuthorRow(),
          const SizedBox(height: 18),
          Text('Spicy Tomato Rigatoni', style: AppTextStyles.cardTitle),
          const SizedBox(height: 14),
          _buildStats(),
          const SizedBox(height: 24),
          _buildIngredientsCard(),
          const SizedBox(height: 18),
          _buildInstructionsCard(),
          const SizedBox(height: 24),
          _buildCommentsSection(),
        ],
      ),
    );
  }

  Widget _buildAuthorRow() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFF2623E), Color(0xFFFF8763)],
            ),
          ),
          child: Center(
            child: Text(
              'SM',
              style: AppTextStyles.smallLabel.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Sarah Mitchell',
                  style: AppTextStyles.chipLabel.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ],
            ),
            Text(
              '124 recipes shared',
              style: AppTextStyles.smallLabel.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          ),
          child: Text(
            'Follow',
            style: AppTextStyles.chipLabel.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _statChip(Icons.schedule, '35 min'),
        const SizedBox(width: 12),
        _statChip(Icons.people_outline, '4 servings'),
        const SizedBox(width: 12),
        _statChip(Icons.trending_up, 'Medium'),
      ],
    );
  }

  Widget _statChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textMedium),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.smallLabel.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsCard() {
    final ingredients = [
      '400g rigatoni pasta',
      '2 cans crushed tomatoes',
      '4 cloves garlic, minced',
      '1 tsp red pepper flakes',
      '1/4 cup fresh basil',
      '2 tbsp olive oil',
      'Salt and pepper to taste',
      '1/2 cup parmesan, grated',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingredients',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...ingredients.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(item, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDark)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    final steps = [
      'Cook rigatoni in salted boiling water until al dente. Reserve 1 cup pasta water.',
      'Heat olive oil in a large skillet. Add garlic and red pepper flakes, cook 1 minute.',
      'Add crushed tomatoes, season with salt and pepper. Simmer for 15 minutes.',
      'Toss pasta with sauce, adding pasta water as needed for consistency.',
      'Serve topped with fresh basil and grated parmesan.',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructions',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: AppTextStyles.smallLabel.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textDark,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Comments',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
              ),
              child: Text(
                '28',
                style: AppTextStyles.smallLabel.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildCommentItem(
          'Alex K.',
          'AK',
          '1h ago',
          'Made this last night and it was incredible! The red pepper flakes really make it.',
        ),
        _buildCommentItem(
          'Maria L.',
          'ML',
          '3h ago',
          'Can I substitute penne for rigatoni?',
        ),
        _buildCommentItem(
          'Tom W.',
          'TW',
          '6h ago',
          'Added some Italian sausage and it was next level!',
        ),
      ],
    );
  }

  Widget _buildCommentItem(
    String name,
    String initials,
    String time,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceBorder,
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.smallLabel.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.chipLabel.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: AppTextStyles.smallLabel.copyWith(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textBody,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 34,
      child: PrimaryButton(
        label: 'Save to Cookbook',
        leadingIcon: const Icon(Icons.bookmark_add_outlined, color: Colors.white, size: 20),
        onPressed: () {},
      ),
    );
  }
}
