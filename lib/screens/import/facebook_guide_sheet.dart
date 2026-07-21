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

class FacebookGuideSheet extends StatefulWidget {
  const FacebookGuideSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const FacebookGuideSheet(),
    );
  }

  @override
  State<FacebookGuideSheet> createState() => _FacebookGuideSheetState();
}

class _FacebookGuideSheetState extends State<FacebookGuideSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoAdvanceTimer;

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
                  'import_from_facebook'.tr,
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
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: [
                _FacebookSlide1(),
                _FacebookSlide2(),
                _FacebookSlide3(),
              ],
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
              label: 'open_facebook_find_recipe'.tr,
              leadingIcon: const OnboardingLineIcon(
                'chat',
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

/// Slide 1 - Facebook post mockup with Share button highlighted
class _FacebookSlide1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mock Facebook post
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
                // User row
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D6FE0),
                        shape: BoxShape.circle,
                      ),
                      child: const OnboardingLineIcon(
                        'user',
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 90,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBorder,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBorder.withValues(
                              alpha: 0.6,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Image placeholder
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EDE0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.restaurant_rounded,
                    size: 40,
                    color: AppColors.textLight.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 12),
                // Like / Comment / Share action row
                Row(
                  children: [
                    // Like
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.thumb_up_outlined,
                            size: 20,
                            color: AppColors.textMedium,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'like'.tr,
                            style: AppTextStyles.smallLabel.copyWith(
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Comment
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const OnboardingLineIcon(
                            'chat',
                            size: 20,
                            color: AppColors.textMedium,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'comment'.tr,
                            style: AppTextStyles.smallLabel.copyWith(
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Share - highlighted
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const OnboardingLineIcon(
                              'share',
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'share'.tr,
                              style: AppTextStyles.smallLabel.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
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
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'tap_share'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: AppColors.blueArrow,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_upward_rounded,
                size: 18,
                color: AppColors.blueArrow,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Slide 2 - Share sheet with "Share to..." highlighted
class _FacebookSlide2 extends StatelessWidget {
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
class _FacebookSlide3 extends StatelessWidget {
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
                _appIcon(const Color(0xFFEA4335), 'M', 'Gmail', icon: null),
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
    String label, {
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
            child:
                iconWidget ??
                (icon != null
                    ? Icon(icon, size: 22, color: color)
                    : Text(
                        letter,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      )),
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
