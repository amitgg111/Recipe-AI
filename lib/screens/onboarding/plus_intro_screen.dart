import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/screens/onboarding/plus_comparison_screen.dart';

class PlusIntroScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  final VoidCallback? onClose;

  const PlusIntroScreen({
    super.key,
    this.onContinue,
    this.onClose,
  });

  @override
  State<PlusIntroScreen> createState() => _PlusIntroScreenState();
}

class _PlusIntroScreenState extends State<PlusIntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _bobController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _bobAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _bobAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Top row with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: widget.onClose ?? () => Get.to(() => const PlusComparisonScreen()),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A211B).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.close, size: 18,
                          color: AppColors.textMedium),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.purple,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text.rich(
                    TextSpan(
                      text: 'Recipe AI ',
                      style: AppTextStyles.listTitle,
                      children: [
                        TextSpan(
                          text: 'Plus',
                          style: AppTextStyles.listTitle.copyWith(color: AppColors.purple),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Recipe AI is free to use, but…',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 14),
              // Title with purple highlight
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 29, height: 1.2),
                  children: [
                    const TextSpan(text: 'We\'d love you to try '),
                    TextSpan(
                      text: 'the full experience for 7 days, free!',
                      style: AppTextStyles.screenTitle.copyWith(
                        fontSize: 29,
                        height: 1.2,
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Crown + feature tags area
              SizedBox(
                width: 330,
                height: 300,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Radial glow
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.purple.withValues(alpha: 0.18),
                      ),
                    ),
                    // Crown with animations
                    _AnimatedBuilder(
                      animation: Listenable.merge([_pulseAnimation, _bobAnimation]),
                      builder: (context, _) {
                        return Transform.translate(
                          offset: Offset(0, _bobAnimation.value),
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // Pulse ring
                              Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.purple.withValues(alpha: 0.15),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              // Crown container
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF9466F2), Color(0xFF7A45E0)],
                                  ),
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.purple.withValues(alpha: 0.35),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.workspace_premium, color: Colors.white, size: 36),
                              ),
                              // 7 DAYS FREE badge
                              Positioned(
                                top: -8,
                                right: -18,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('7', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.purple)),
                                      const SizedBox(width: 3),
                                      Text('DAYS FREE', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: Color(0xFF9A938A), letterSpacing: 0.42)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Feature tags positioned around crown
                    Positioned(
                      left: 8,
                      top: 18,
                      child: Transform.rotate(
                        angle: -5 * 3.14159 / 180,
                        child: _buildFeatureTag('Unlimited Recipe imports', Icons.auto_awesome, AppColors.purple),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 48,
                      child: Transform.rotate(
                        angle: 6 * 3.14159 / 180,
                        child: _buildFeatureTag('Nutrition calculator', Icons.check_circle, AppColors.green),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      bottom: 46,
                      child: Transform.rotate(
                        angle: 4 * 3.14159 / 180,
                        child: _buildFeatureTag('AI cooking assistant', Icons.auto_awesome, AppColors.primary),
                      ),
                    ),
                    Positioned(
                      right: 24,
                      bottom: 22,
                      child: Transform.rotate(
                        angle: -6 * 3.14159 / 180,
                        child: _buildFeatureTag('Convert measurements', Icons.language, AppColors.blue),
                      ),
                    ),
                    // Floating sparkles
                    Positioned(
                      left: 40,
                      top: 96,
                      child: Icon(Icons.auto_awesome, color: AppColors.goldStar, size: 14),
                    ),
                    Positioned(
                      right: 50,
                      bottom: 96,
                      child: Icon(Icons.auto_awesome, color: AppColors.purple, size: 14),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton.purple(
                label: 'Try for ₹0.00',
                onPressed: widget.onContinue ?? () => Get.to(() => const PlusComparisonScreen()),
                enableSheen: true,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTag(String text, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFEEE6FB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ],
      ),
    );
  }
}

class _AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const _AnimatedBuilder({
    required Listenable animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
