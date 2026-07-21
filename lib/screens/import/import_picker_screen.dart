import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:recipe_ai/Service/import_with_image_api_calling_service.dart';
import 'package:recipe_ai/View/Home/import_from_text_screen.dart';
import 'package:recipe_ai/View/Home/import_from_web.dart';
import 'package:recipe_ai/View/Home/recipe_editor_screen.dart';
import 'package:recipe_ai/View/Home/import_from_social_screen.dart';

// Design glyph (viewBox 0 0 24 24) in the given hex colour. `camera`'s
// viewfinder dot is a filled circle, so its fill tracks the icon colour.
Widget _glyph(String key, {required double size, required String color}) {
  final inner = {
    'share':
        '<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/>'
        '<circle cx="18" cy="19" r="3"/>'
        '<path d="M8.6 13.5l6.8 4M15.4 6.5l-6.8 4"/>',
    'camera':
        '<rect x="3" y="7" width="18" height="13" rx="4"/>'
        '<circle cx="12" cy="13.5" r="3.4"/>'
        '<circle cx="17" cy="10.5" r="1" fill="$color" stroke="none"/>',
    'music':
        '<circle cx="7" cy="18" r="2.6"/><circle cx="17" cy="16" r="2.6"/>'
        '<path d="M9.6 18V5l9.4-2v13"/>',
    'chat':
        '<path d="M4 6a1 1 0 0 1 1-1h14a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H9l-4 4z"/>',
  }[key]!;
  final svg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
      'fill="none" stroke="$color" stroke-width="1.9" '
      'stroke-linecap="round" stroke-linejoin="round">$inner</svg>';
  return SvgPicture.string(svg, width: size, height: size);
}

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
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 42,
                      height: 42,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEDE3D2)),
                      ),
                      child: const OnboardingLineIcon(
                        'back',
                        size: 18,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text('add_a_recipe'.tr, style: AppTextStyles.listTitle),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    // Featured card — opens the social-share picker.
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => ImportFromSocialScreen.showPicker(context),
                      child: _buildFeaturedCard(),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 2x2 grid
                    Row(
                      children: [
                        Expanded(
                          child: _ImportOptionCard(
                            icon: Icons.camera_alt_rounded,
                            iconBgColor: AppColors.blueBg,
                            iconColor: AppColors.blue,
                            title: 'import_from_photo'.tr,
                            subtitle: 'snap_or_upload_pic'.tr,
                            onTap: () {
                              // Get.back();
                              // RecipeImportService.importRecipeFromGallery(
                              //   context,
                              // );
                              Get.to(() => const RecipeCameraScreen());
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _ImportOptionCard(
                            icon: Icons.description_rounded,
                            iconBgColor: AppColors.goldBgLight,
                            iconColor: AppColors.gold,
                            title: 'import_from_text'.tr,
                            subtitle: 'paste_or_type'.tr,
                            onTap: () {
                              // Get.back();
                              Get.to(() => const GenerateRecipeScreen());
                            },
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
                            title: 'import_from_web'.tr,
                            subtitle: 'paste_recipe_url'.tr,
                            onTap: () {
                              // Get.back();
                              Get.to(() => const ImportFromWebScreen());
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _ImportOptionCard(
                            icon: Icons.edit_rounded,
                            iconBgColor: AppColors.greenBg,
                            iconColor: AppColors.green,
                            title: 'write_from_scratch'.tr,
                            subtitle: 'create_your_own'.tr,
                            onTap: () {
                              // Get.back();
                              Get.to(() => const RecipeEditorScreen());
                            },
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
          // Header: share icon + title (row).
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: _glyph('share', size: 18, color: '#FFFFFF'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'import_from_social_media'.tr,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'share_to_recipe_ai'.tr,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          // Social icon tiles (white .92 background, brand-coloured glyph).
          const Row(
            children: [
              _SocialIconButton(glyph: 'camera', colorHex: '#C13584'),
              SizedBox(width: 8),
              _SocialIconButton(glyph: 'music', colorHex: '#1F1F24'),
              SizedBox(width: 8),
              _SocialIconButton(glyph: 'chat', colorHex: '#2D6FE0'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final String glyph;
  final String colorHex;

  const _SocialIconButton({required this.glyph, required this.colorHex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _glyph(glyph, size: 18, color: colorHex),
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
        height: 150,
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.smallLabel.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
