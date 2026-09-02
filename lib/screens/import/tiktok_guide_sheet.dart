import 'dart:async';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/bottom_sheet_handle.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class TikTokGuideSheet extends StatefulWidget {
  const TikTokGuideSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const TikTokGuideSheet(),
    );
  }

  @override
  State<TikTokGuideSheet> createState() => _TikTokGuideSheetState();
}

class _TikTokGuideSheetState extends State<TikTokGuideSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoAdvanceTimer;
  void _pauseAutoAdvance() {
    _autoAdvanceTimer?.cancel();
  }

  void _resumeAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _startAutoAdvance();
  }

  @override
  void initState() {
    super.initState();
    _startAutoAdvance();
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final nextPage = (_currentPage + 1) % 3;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 592,
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
        children: [
          const BottomSheetHandle(),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.xxl,
              AppSpacing.lg,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F1EA),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                    ),
                    child: const OnboardingLineIcon(
                      'back',
                      size: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'import_from_tiktok'.tr,
                  style: AppTextStyles.listTitle.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // Slideshow
          Expanded(
            child: Listener(
              onPointerDown: (_) => _pauseAutoAdvance(),
              onPointerUp: (_) => _resumeAutoAdvance(),

              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [_TikTokSlide1(), _TikTokSlide2(), _TikTokSlide3()],
              ),
            ),
          ),

          // Progress dots
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 24 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.textDark
                        : const Color(0xFFE2D8C7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),

          // Button
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              0,
              AppSpacing.xxl,
              MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            ),
            child: PrimaryButton(
              label: 'open_tiktok_find_recipe'.tr,
              leadingIcon: const OnboardingLineIcon(
                'music',
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide 1 - TikTok video mockup with send button highlighted
class _TikTokSlide1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mock TikTok video
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.surfaceBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Left side - video content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video placeholder
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: OnboardingLineIcon(
                                'play',
                                size: 48,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            // Username overlay
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Text(
                                '@recipe.app',
                                style: AppTextStyles.smallLabel.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right side - action icons
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Heart icon
                    const OnboardingLineIcon(
                      'heart',
                      size: 28,
                      color: AppColors.textDark,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '12.3K',
                      style: AppTextStyles.smallLabel.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 14),
                    // Chat icon
                    const OnboardingLineIcon(
                      'chat',
                      size: 26,
                      color: AppColors.textDark,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '245',
                      style: AppTextStyles.smallLabel.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 14),
                    // Bookmark icon
                    const OnboardingLineIcon(
                      'bookmark',
                      size: 26,
                      color: AppColors.textDark,
                    ),
                    const SizedBox(height: 14),
                    // Send icon - highlighted
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const OnboardingLineIcon(
                            'send',
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        // Blue arrow + text
                        Positioned(
                          left: -70,
                          top: 6,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'tap_send'.tr,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.blueArrow,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const OnboardingLineIcon(
                                'chevR',
                                size: 16,
                                color: AppColors.blueArrow,
                              ),
                            ],
                          ),
                        ),
                      ],
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
}

/// Slide 2 - Share sheet with "Share to..." highlighted
class _TikTokSlide2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'tap_share_to'.tr,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: AppColors.blueArrow,
            ),
          ),
          const SizedBox(height: 8),
          const Icon(
            Icons.arrow_downward_rounded,
            size: 24,
            color: AppColors.blueArrow,
          ),
          const SizedBox(height: 12),
          // Mock share sheet
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.surfaceBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 16),
                // Search bar
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F1EA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const OnboardingLineIcon(
                        'search',
                        size: 18,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'search'.tr,
                        style: AppTextStyles.smallLabel.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Contact circles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    4,
                    (i) => Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0EAE0),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 36,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBorder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Share to button - highlighted
                Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    border: Border.all(color: AppColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.upload_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'share_to'.tr,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
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
}

/// Slide 3 - App picker with Recipe AI highlighted
class _TikTokSlide3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'tap_recipe_ai'.tr,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: AppColors.blueArrow,
            ),
          ),
          const SizedBox(height: 8),
          const Icon(
            Icons.arrow_downward_rounded,
            size: 24,
            color: AppColors.blueArrow,
          ),
          const SizedBox(height: 12),
          // Mock app picker
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.surfaceBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gmail - red M
                _appIcon(const Color(0xFFEA4335), 'M', 'Gmail', false),
                // Recipe AI - highlighted
                Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8763), AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const OnboardingLineIcon(
                        'bowl',
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AppWordmark(fontSize: 11, fontWeight: FontWeight.w700),
                  ],
                ),
                // Chat - blue
                _appIcon(
                  const Color(0xFF2D6FE0),
                  '',
                  'chat'.tr,
                  false,
                  iconWidget: const OnboardingLineIcon(
                    'chat',
                    size: 22,
                    color: Color(0xFF2D6FE0),
                  ),
                ),
                // Triangle - green
                _appIcon(
                  const Color(0xFF34A853),
                  '',
                  'share'.tr,
                  false,
                  icon: Icons.change_history_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _appIcon(
    Color color,
    String letter,
    String label,
    bool highlighted, {
    IconData? icon,
    Widget? iconWidget,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: iconWidget != null
                ? iconWidget
                : icon != null
                ? Icon(icon, size: 22, color: color)
                : Text(
                    letter,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTextStyles.smallLabel.copyWith(
            fontSize: 11,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}
