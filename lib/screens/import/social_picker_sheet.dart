import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/bottom_sheet_handle.dart';

class SocialPickerSheet extends StatelessWidget {
  const SocialPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const SocialPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.md,
              AppSpacing.xxl,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import from social media',
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick where your recipe is from.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Instagram
                _SocialOption(
                  icon: _buildInstagramIcon(),
                  title: 'Instagram',
                  subtitle: 'Reels, posts & saved',
                  onTap: () => Navigator.pop(context, 'instagram'),
                ),
                const SizedBox(height: 11),

                // TikTok
                _SocialOption(
                  icon: _buildTikTokIcon(),
                  title: 'TikTok',
                  subtitle: 'Recipe videos',
                  onTap: () => Navigator.pop(context, 'tiktok'),
                ),
                const SizedBox(height: 11),

                // Facebook
                _SocialOption(
                  icon: _buildFacebookIcon(),
                  title: 'Facebook',
                  subtitle: 'Posts & watch videos',
                  onTap: () => Navigator.pop(context, 'facebook'),
                ),

                SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstagramIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF405DE6),
            Color(0xFF833AB4),
            Color(0xFFC13584),
            Color(0xFFE1306C),
            Color(0xFFFD1D1D),
            Color(0xFFF56040),
            Color(0xFFF77737),
            Color(0xFFFCAF45),
            Color(0xFFFFDC80),
          ],
        ),
      ),
      child: const Icon(
        Icons.camera_alt_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildTikTokIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.tiktok,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildFacebookIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.facebook,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.facebook_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _SocialOption extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SocialOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.smallLabel,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
