import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/widgets/social_guide_animation.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — kept as ImportFromSocialScreen for backward compat
// Now just shows the Social Media Picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class ImportFromSocialScreen extends StatelessWidget {
  const ImportFromSocialScreen({super.key});

  static void showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _SocialMediaPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showPicker(context);
    });
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add a recipe',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Social media banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.share_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Import from social media',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _socialIconWhiteBg(
                          Icons.camera_alt_rounded,
                          const Color(0xFFE1306C),
                        ),
                        const SizedBox(width: 8),
                        _socialIconWhiteBg(
                          Icons.music_note_rounded,
                          Colors.black,
                        ),
                        const SizedBox(width: 8),
                        _socialIconWhiteBg(
                          Icons.facebook_rounded,
                          const Color(0xFF1877F2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _socialIconWhiteBg(IconData icon, Color color) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Social Media Picker Bottom Sheet (screen 28)
// ─────────────────────────────────────────────────────────────────────────────

class _SocialMediaPickerSheet extends StatelessWidget {
  const _SocialMediaPickerSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 34),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Import from social media', style: AppTextStyles.screenTitle),
          const SizedBox(height: 4),
          Text(
            'Pick where your recipe is from.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 24),
          // Instagram
          _SocialOptionTile(
            icon: Icons.camera_alt_rounded,
            iconBgColor: const Color(0xFFE1306C),
            title: 'Instagram',
            subtitle: 'Reels, posts & saved',
            onTap: () {
              Navigator.pop(context);
              SocialGuideScreen.show(Get.context!, SocialPlatform.instagram);
            },
          ),
          const SizedBox(height: 4),
          // TikTok
          _SocialOptionTile(
            icon: Icons.music_note_rounded,
            iconBgColor: Colors.black,
            title: 'TikTok',
            subtitle: 'Recipe videos',
            onTap: () {
              Navigator.pop(context);
              SocialGuideScreen.show(Get.context!, SocialPlatform.tiktok);
            },
          ),
          const SizedBox(height: 4),
          // Facebook
          _SocialOptionTile(
            icon: Icons.facebook_rounded,
            iconBgColor: const Color(0xFF1877F2),
            title: 'Facebook',
            subtitle: 'Posts & watch videos',
            onTap: () {
              Navigator.pop(context);
              SocialGuideScreen.show(Get.context!, SocialPlatform.facebook);
            },
          ),
        ],
      ),
    );
  }
}

class _SocialOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SocialOptionTile({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.smallLabel.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Social Platform enum
// ─────────────────────────────────────────────────────────────────────────────

enum SocialPlatform { instagram, tiktok, facebook }

// ─────────────────────────────────────────────────────────────────────────────
// Social Guide Screen (screens 29/30/31)
// Shows platform-specific step-by-step sharing guide
// ─────────────────────────────────────────────────────────────────────────────

class SocialGuideScreen extends StatefulWidget {
  final SocialPlatform platform;

  const SocialGuideScreen({super.key, required this.platform});

  /// Shows the platform guide as a bottom sheet (matching the HTML design).
  static Future<void> show(BuildContext context, SocialPlatform platform) {
    return showModalBottomSheet(
      scrollControlDisabledMaxHeightRatio: Get.height * 0.8,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x801E1B18),
      builder: (_) => SocialGuideScreen(platform: platform),
    );
  }

  @override
  State<SocialGuideScreen> createState() => _SocialGuideScreenState();
}

class _SocialGuideScreenState extends State<SocialGuideScreen> {
  GuidePlatform get _guidePlatform {
    switch (widget.platform) {
      case SocialPlatform.instagram:
        return GuidePlatform.instagram;
      case SocialPlatform.tiktok:
        return GuidePlatform.tiktok;
      case SocialPlatform.facebook:
        return GuidePlatform.facebook;
    }
  }

  String get _platformName {
    switch (widget.platform) {
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.tiktok:
        return 'TikTok';
      case SocialPlatform.facebook:
        return 'Facebook';
    }
  }

  IconData get _platformIcon {
    switch (widget.platform) {
      case SocialPlatform.instagram:
        return Icons.camera_alt_rounded;
      case SocialPlatform.tiktok:
        return Icons.music_note_rounded;
      case SocialPlatform.facebook:
        return Icons.facebook_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E0D2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),
              // Header: back + title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Import from $_platformName',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.38,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Guide illustration (auto-cross-fading slides, HTML design) —
              // fixed 372px height to match the HTML sheet (not stretched).
              SizedBox(
                height: 472,
                width: double.infinity,
                child: SocialGuideAnimation(platform: _guidePlatform),
              ),
              const SizedBox(height: 24),

              // Open app button
              GestureDetector(
                onTap: _openPlatformApp,
                child: Container(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusButton,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.primaryShadow,
                        blurRadius: 30,
                        offset: Offset(0, 16),
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_platformIcon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Open $_platformName to find a recipe',
                        style: AppTextStyles.buttonLabel,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _openPlatformApp() {
    String urlScheme;
    String fallbackUrl;

    switch (widget.platform) {
      case SocialPlatform.instagram:
        urlScheme = 'instagram://app';
        fallbackUrl = 'https://www.instagram.com';
        break;
      case SocialPlatform.tiktok:
        urlScheme = 'snssdk1233://';
        fallbackUrl = 'https://www.tiktok.com';
        break;
      case SocialPlatform.facebook:
        urlScheme = 'fb://';
        fallbackUrl = 'https://www.facebook.com';
        break;
    }

    _tryLaunch(urlScheme, fallbackUrl);
  }

  Future<void> _tryLaunch(String scheme, String fallback) async {
    final uri = Uri.parse(scheme);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(
        Uri.parse(fallback),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
