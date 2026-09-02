import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/analytics_service.dart';
import 'package:recipe_ai/widgets/social_guide_animation.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/screens/import/social_picker_sheet.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — kept as ImportFromSocialScreen for backward compat
// Now just shows the Social Media Picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class ImportFromSocialScreen extends StatelessWidget {
  const ImportFromSocialScreen({super.key});

  static Future<void> showPicker(BuildContext context) async {
    // The design-accurate picker (screen 28). It returns the chosen platform;
    // we then open that platform's share guide.
    final choice = await SocialPickerSheet.show(context);
    final platform = switch (choice) {
      'instagram' => SocialPlatform.instagram,
      'tiktok' => SocialPlatform.tiktok,
      'facebook' => SocialPlatform.facebook,
      _ => null,
    };
    if (platform != null && Get.context != null) {
      SocialGuideScreen.show(Get.context!, platform);
    }
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
                    onTap: () => Get.back(),
                    child: const OnboardingLineIcon(
                      'back',
                      size: 20,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'add_a_recipe'.tr,
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
                          child: const OnboardingLineIcon(
                            'share',
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'import_from_social_media'.tr,
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
                          'assets/welcome/instagram.svg',
                          const Color(0xFFE1306C),
                        ),
                        const SizedBox(width: 8),
                        _socialIconWhiteBg(
                          'assets/welcome/tiktok.svg',
                          Colors.black,
                        ),
                        const SizedBox(width: 8),
                        _socialIconWhiteBg(
                          'assets/welcome/facebook.svg',
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

  static Widget _socialIconWhiteBg(String icon, Color color) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SvgPicture.asset(icon, height: 18, color: color),
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

  String get _platformIcon {
    switch (widget.platform) {
      case SocialPlatform.instagram:
        return 'assets/welcome/instagram.svg';
      case SocialPlatform.tiktok:
        return 'assets/welcome/tiktok.svg';
      case SocialPlatform.facebook:
        return 'assets/welcome/facebook.svg';
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = MediaQuery.of(context).size.height;

            // Smaller height → smaller illustration
            final guideHeight = screenHeight < 700
                ? 360.0
                : screenHeight < 800
                ? 410.0
                : 472.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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

                    // Header
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          behavior: HitTestBehavior.opaque,
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: OnboardingLineIcon(
                              'back',
                              size: 20,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'import_from_platform'.trParams({
                              'platform': _platformName,
                            }),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              letterSpacing: -0.38,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Responsive guide
                    SizedBox(
                      height: guideHeight,
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
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(_platformIcon, height: 30),

                            Expanded(
                              child: Text(
                                'open_platform_to_find_recipe'.trParams({
                                  'platform': _platformName,
                                }),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.buttonLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
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
    AnalyticsService.instance.trackButtonTap(
      "Generate Recipe From $urlScheme",
      screenName: "SocialGuideScreen",
    );
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
