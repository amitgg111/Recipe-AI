import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/app_back_button.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class CookbookDetailEmptyScreen extends StatefulWidget {
  final String title;

  const CookbookDetailEmptyScreen({super.key, this.title = 'Quick Breakfast'});

  @override
  State<CookbookDetailEmptyScreen> createState() =>
      _CookbookDetailEmptyScreenState();
}

class _CookbookDetailEmptyScreenState extends State<CookbookDetailEmptyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 25),
                  ),
                  const SizedBox(height: 4),
                  Text('No recipes yet', style: AppTextStyles.smallLabel),
                ],
              ),
            ),
            Expanded(child: _buildEmptyState()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AppBackButton(),
          Text(
            widget.title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: AppDimensions.appBarButtonSize,
              height: AppDimensions.appBarButtonSize,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.surfaceBorderLight),
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 180,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Open book - left page
                  Positioned(
                    bottom: 20,
                    child: Transform.rotate(
                      angle: -7 * math.pi / 180,
                      child: Container(
                        width: 100,
                        height: 130,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(-2, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _textLine(60),
                            const SizedBox(height: 8),
                            _textLine(50),
                            const SizedBox(height: 8),
                            _textLine(40),
                            const SizedBox(height: 8),
                            _textLine(55),
                            const SizedBox(height: 8),
                            _textLine(35),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Open book - right page
                  Positioned(
                    bottom: 20,
                    child: Transform.translate(
                      offset: const Offset(30, 0),
                      child: Transform.rotate(
                        angle: 7 * math.pi / 180,
                        child: Container(
                          width: 100,
                          height: 130,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(2, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _textLine(55),
                              const SizedBox(height: 8),
                              _textLine(45),
                              const SizedBox(height: 8),
                              _textLine(60),
                              const SizedBox(height: 8),
                              _textLine(38),
                              const SizedBox(height: 8),
                              _textLine(50),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Floating sparkle badge
                  _AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: 0 + _floatAnimation.value,
                        right: 40,
                        child: child!,
                      );
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      padding: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusIconLg,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.primaryShadow,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'This cookbook is empty',
              style: AppTextStyles.cardTitle.copyWith(fontSize: 24),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "Add your first recipe and it'll show up here, ready to cook.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textBody,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: 'Add a recipe',
              leadingIcon: const Icon(Icons.add, color: Colors.white, size: 20),
              onPressed: () {},
              width: 180,
            ),
          ],
        ),
      ),
    );
  }

  Widget _textLine(double width) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.surfaceBorder,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const _AnimatedBuilder({
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
