import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/import_with_image_api_calling_service.dart';
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
          Text(
            'Import from social media',
            style: AppTextStyles.screenTitle,
          ),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SocialGuideScreen(
                    platform: SocialPlatform.instagram,
                  ),
                ),
              );
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SocialGuideScreen(
                    platform: SocialPlatform.tiktok,
                  ),
                ),
              );
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SocialGuideScreen(
                    platform: SocialPlatform.facebook,
                  ),
                ),
              );
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

  @override
  State<SocialGuideScreen> createState() => _SocialGuideScreenState();
}

class _SocialGuideScreenState extends State<SocialGuideScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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

  Color get _platformColor {
    switch (widget.platform) {
      case SocialPlatform.instagram:
        return const Color(0xFFE1306C);
      case SocialPlatform.tiktok:
        return Colors.black;
      case SocialPlatform.facebook:
        return const Color(0xFF1877F2);
    }
  }

  List<_GuideStep> get _steps {
    switch (widget.platform) {
      case SocialPlatform.instagram:
        return [
          _GuideStep(
            title: 'Find a recipe post or reel',
            description: 'Open Instagram and find a recipe you want to save.',
            icon: Icons.search_rounded,
          ),
          _GuideStep(
            title: 'Tap the share button',
            description: 'Tap the paper plane icon below the post.',
            icon: Icons.send_rounded,
          ),
          _GuideStep(
            title: 'Share to Recipe AI',
            description:
                'Find Recipe AI in the share sheet and tap it to import.',
            icon: Icons.restaurant_menu_rounded,
          ),
        ];
      case SocialPlatform.tiktok:
        return [
          _GuideStep(
            title: 'Find a recipe video',
            description: 'Open TikTok and find a recipe video you like.',
            icon: Icons.search_rounded,
          ),
          _GuideStep(
            title: 'Tap the share button',
            description: 'Tap the share arrow on the right side of the video.',
            icon: Icons.send_rounded,
          ),
          _GuideStep(
            title: 'Share to Recipe AI',
            description:
                'Find Recipe AI in the share sheet and tap it to import.',
            icon: Icons.restaurant_menu_rounded,
          ),
        ];
      case SocialPlatform.facebook:
        return [
          _GuideStep(
            title: 'Find a recipe post',
            description:
                'Open Facebook and find a recipe post or watch video.',
            icon: Icons.search_rounded,
          ),
          _GuideStep(
            title: 'Tap the share button',
            description: 'Tap Share below the post.',
            icon: Icons.send_rounded,
          ),
          _GuideStep(
            title: 'Share to Recipe AI',
            description:
                'Find Recipe AI in the share sheet and tap it to import.',
            icon: Icons.restaurant_menu_rounded,
          ),
        ];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Top bar
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
                    'Import from $_platformName',
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

            // Guide carousel
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceBorderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Phone mockup area with steps
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (i) =>
                              setState(() => _currentPage = i),
                          itemCount: _steps.length,
                          itemBuilder: (context, index) {
                            return _buildGuidePage(_steps[index], index);
                          },
                        ),
                      ),

                      // Page dots
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_steps.length, (i) {
                            return Container(
                              width: _currentPage == i ? 24 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: _currentPage == i
                                    ? AppColors.textDark
                                    : AppColors.surfaceBorder,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hint text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'tap ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    'share to',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMedium,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Open app button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _openPlatformApp,
                child: Container(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusButton,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryShadow,
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: Row(
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
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidePage(_GuideStep step, int index) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Phone mockup illustration
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Fake food image placeholder
                  Container(
                    width: 180,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E6D6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Icon(
                            Icons.restaurant_rounded,
                            size: 48,
                            color: AppColors.textHint.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search bar mockup
                  Container(
                    width: 180,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surfaceBorderLight),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 16,
                          color: AppColors.textHint.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Grid of circles mockup
                  SizedBox(
                    width: 180,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(8, (i) {
                        return Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBorder.withValues(
                              alpha: 0.5,
                            ),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Action buttons row (share icon highlighted)
                  SizedBox(
                    width: 180,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBorder.withValues(
                              alpha: 0.4,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Share/upload button (highlighted)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _platformColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            index == 1
                                ? Icons.file_upload_outlined
                                : Icons.file_upload_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Green circle (send)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF25D366),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // "Share to..." label
                  Text(
                    'Share to...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textHint,
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

class _GuideStep {
  final String title;
  final String description;
  final IconData icon;

  _GuideStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}
