import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/screens/onboarding/plus_intro_screen.dart';

class SettingUpScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  final int currentStep;
  final int totalSteps;

  const SettingUpScreen({
    super.key,
    this.onContinue,
    this.currentStep = 3,
    this.totalSteps = 7,
  });

  @override
  State<SettingUpScreen> createState() => _SettingUpScreenState();
}

class _SettingUpScreenState extends State<SettingUpScreen>
    with TickerProviderStateMixin {
  late final AnimationController _panController;
  late final AnimationController _spinnerController;
  late final AnimationController _foodController;
  late final AnimationController _sizzleController;
  late final Animation<double> _panRotation;

  int _messageIndex = 0;

  static const _messages = [
    'Gathering your favorite recipes…',
    'Setting up your cookbooks…',
    'Building your meal planner…',
    'Almost ready to cook…',
  ];

  @override
  void initState() {
    super.initState();

    _panController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _panRotation = Tween<double>(
      begin: -8 * math.pi / 180,
      end: 4 * math.pi / 180,
    ).animate(
      CurvedAnimation(parent: _panController, curve: Curves.easeInOut),
    );

    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _foodController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _sizzleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Cycle messages
    Future.delayed(const Duration(seconds: 2), _cycleMessage);
  }

  void _cycleMessage() {
    if (!mounted) return;
    setState(() {
      _messageIndex = (_messageIndex + 1) % _messages.length;
    });
    Future.delayed(const Duration(seconds: 2), _cycleMessage);
  }

  @override
  void dispose() {
    _panController.dispose();
    _spinnerController.dispose();
    _foodController.dispose();
    _sizzleController.dispose();
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
              const SizedBox(height: 16),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 16),
              ),
              const SizedBox(height: 48),
              Text(
                'We\'re setting everything up for you',
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitle.copyWith(fontSize: 26, height: 1.18),
              ),
              const Spacer(flex: 2),
              // Frying pan animation
              SizedBox(
                height: 200,
                width: 200,
                child: AnimatedBuilder(
                  animation: _panRotation,
                  builder: (context, _) {
                    return Transform.rotate(
                      angle: _panRotation.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ambient radial glow
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.12),
                                  AppColors.primary.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                          // Pan body
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF3A302A),
                                  Color(0xFF241C17),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                          ),
                          // Inner circle
                          Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2A211B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          // Pan handle
                          Positioned(
                            right: 10,
                            child: Container(
                              width: 78,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5A4632),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          // Food circles
                          ..._buildFoodItems(),
                          // Sizzle dots
                          ..._buildSizzleDots(),
                          // Spark icon
                          Positioned(
                            top: 10,
                            right: 20,
                            child: Icon(Icons.auto_awesome, color: AppColors.purple, size: 20),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Spacer(flex: 1),
              // Spinner + message
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _spinnerController,
                    builder: (context, _) {
                      return Transform.rotate(
                        angle: _spinnerController.value * 2 * math.pi,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF0EDE5),
                              width: 3,
                            ),
                          ),
                          child: CustomPaint(
                            painter: _SpinnerArcPainter(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _messages[_messageIndex],
                      key: ValueKey(_messageIndex),
                      style: const TextStyle(fontSize: 15, color: Color(0xFF8A7E70), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              PrimaryButton(
                label: 'Continue',
                onPressed: widget.onContinue ?? () => Get.to(() => const PlusIntroScreen()),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFoodItems() {
    final foodColors = [
      const Color(0xFFE8B84A),
      const Color(0xFFE06B4A),
      const Color(0xFF7BC77B),
    ];
    return List.generate(3, (i) {
      final offset = _foodController.value * 2 * math.pi;
      final y = -20 + math.sin(offset + i * 1.2) * 15;
      final x = -20.0 + i * 20;
      return Positioned(
        left: 80 + x,
        top: 50 + y,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateX(math.sin(offset + i) * 0.5),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: foodColors[i],
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildSizzleDots() {
    return List.generate(5, (i) {
      final progress =
          (_sizzleController.value + i * 0.2) % 1.0;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final x = 80.0 + i * 10 - 10;
      final y = 70.0 - progress * 40;
      return Positioned(
        left: x,
        top: y,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    });
  }
}

class _SpinnerArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -math.pi / 2,
      math.pi * 0.7,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
