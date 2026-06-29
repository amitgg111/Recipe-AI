import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/app_bottom_nav.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class CookbooksEmptyScreen extends StatefulWidget {
  const CookbooksEmptyScreen({super.key});

  @override
  State<CookbooksEmptyScreen> createState() => _CookbooksEmptyScreenState();
}

class _CookbooksEmptyScreenState extends State<CookbooksEmptyScreen>
    with TickerProviderStateMixin {
  int _selectedNavIndex = 0;
  late AnimationController _steamController;
  late AnimationController _fabPulseController;
  late Animation<double> _steamAnimation;
  late Animation<double> _fabPulseAnimation;

  @override
  void initState() {
    super.initState();
    _steamController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _steamAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _steamController, curve: Curves.easeInOut),
    );

    _fabPulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
    _fabPulseAnimation = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _fabPulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _steamController.dispose();
    _fabPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Cookbooks', style: AppTextStyles.screenTitle),
                  ),
                ),
                Expanded(child: _buildEmptyState()),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNav(
                currentIndex: _selectedNavIndex,
                onTap: (i) => setState(() => _selectedNavIndex = i),
              ),
            ),
            _buildFAB(),
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
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 20,
            ),
          ),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.goldBg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: AppColors.gold),
                const SizedBox(width: 4),
                Text(
                  '5/5',
                  style: AppTextStyles.chipLabel.copyWith(
                    color: AppColors.gold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Steam wisps
                  _AnimatedBuilder(
                    animation: _steamAnimation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 10 + _steamAnimation.value,
                            left: 80,
                            child: _steamWisp(3, 18),
                          ),
                          Positioned(
                            top: 5 + _steamAnimation.value * 0.8,
                            child: _steamWisp(3, 24),
                          ),
                          Positioned(
                            top: 12 + _steamAnimation.value * 1.2,
                            right: 80,
                            child: _steamWisp(3, 16),
                          ),
                        ],
                      );
                    },
                  ),
                  // Whisk icon left
                  Positioned(
                    left: 30,
                    top: 50,
                    child: Transform.rotate(
                      angle: -0.3,
                      child: Icon(
                        Icons.blender_outlined,
                        size: 32,
                        color: AppColors.textHint.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  // Main circle with chef hat
                  Container(
                    width: 152,
                    height: 152,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surfaceBorder,
                            width: 1.5,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                        child: CustomPaint(
                          painter: _DashedCirclePainter(
                            color: AppColors.surfaceBorder,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.restaurant_rounded,
                              size: 40,
                              color: AppColors.iconLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Knife/spatula icon right
                  Positioned(
                    right: 30,
                    top: 55,
                    child: Transform.rotate(
                      angle: 0.3,
                      child: Icon(
                        Icons.flatware_rounded,
                        size: 32,
                        color: AppColors.textHint.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              "Let's get cooking!",
              style: AppTextStyles.screenTitle.copyWith(fontSize: 27),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your cookbook is empty for now. Save your first recipe and it\'ll have a cozy home right here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textBody,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: 'Add your first recipe',
              leadingIcon: const Icon(Icons.add, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _steamWisp(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.textHint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }

  Widget _buildFAB() {
    return Positioned(
      right: AppSpacing.xl,
      bottom: AppDimensions.bottomNavHeight + AppSpacing.lg,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing ring
          _AnimatedBuilder(
            animation: _fabPulseAnimation,
            builder: (context, child) {
              return Container(
                width: AppDimensions.fabSize + 20,
                height: AppDimensions.fabSize + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(
                      alpha: _fabPulseAnimation.value,
                    ),
                    width: 2,
                  ),
                ),
              );
            },
          ),
          // FAB
          GestureDetector(
            onTap: () {},
            child: Container(
              width: AppDimensions.fabSize,
              height: AppDimensions.fabSize,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryShadow,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashCount = 24;
    const dashArc = 3.14159 * 2 / dashCount;
    const gapFraction = 0.4;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashArc;
      final sweepAngle = dashArc * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
