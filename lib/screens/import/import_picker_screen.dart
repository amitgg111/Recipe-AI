import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/app_back_button.dart';

class ImportPickerScreen extends StatelessWidget {
  const ImportPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Add a recipe',
                    style: AppTextStyles.listTitle,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    // Featured card
                    _buildFeaturedCard(),
                    const SizedBox(height: AppSpacing.lg),

                    // 2x2 grid
                    Row(
                      children: [
                        Expanded(
                          child: _ImportOptionCard(
                            icon: Icons.camera_alt_rounded,
                            iconBgColor: AppColors.blueBg,
                            iconColor: AppColors.blue,
                            title: 'Import from photo',
                            subtitle: 'Snap or upload a pic',
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _ImportOptionCard(
                            icon: Icons.description_rounded,
                            iconBgColor: AppColors.goldBgLight,
                            iconColor: AppColors.gold,
                            title: 'Import from text',
                            subtitle: 'Paste or type it in',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _ImportOptionCard(
                            icon: Icons.language_rounded,
                            iconBgColor: const Color(0xFFEDE7FE),
                            iconColor: AppColors.primary,
                            title: 'Import from web',
                            subtitle: 'Paste a recipe URL',
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _ImportOptionCard(
                            icon: Icons.edit_rounded,
                            iconBgColor: AppColors.greenBg,
                            iconColor: AppColors.green,
                            title: 'Write from scratch',
                            subtitle: 'Create your own',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.7, -0.7),
          end: Alignment(0.7, 0.7),
          colors: [Color(0xFFFF8763), AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Share icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.share_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Import from social media',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.38,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Grab recipes from Instagram, TikTok, or Facebook in one tap.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Social icon buttons
          Row(
            children: [
              _SocialIconButton(
                icon: Icons.camera_alt_rounded,
                color: AppColors.instagram,
                onTap: () {},
              ),
              const SizedBox(width: AppSpacing.md),
              _SocialIconButton(
                icon: Icons.music_note_rounded,
                color: AppColors.tiktok,
                onTap: () {},
              ),
              const SizedBox(width: AppSpacing.md),
              _SocialIconButton(
                icon: Icons.facebook_rounded,
                color: AppColors.facebook,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SocialIconButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _ImportOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ImportOptionCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl - 2),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.smallLabel.copyWith(
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
