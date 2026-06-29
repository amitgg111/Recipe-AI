import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
import 'package:recipe_ai/screens/onboarding/age_screen.dart';

class AwesomeImportScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  final int currentStep;
  final int totalSteps;

  const AwesomeImportScreen({
    super.key,
    this.onContinue,
    this.currentStep = 1,
    this.totalSteps = 7,
  });

  @override
  State<AwesomeImportScreen> createState() => _AwesomeImportScreenState();
}

class _AwesomeImportScreenState extends State<AwesomeImportScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _floatController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
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
              ProgressIndicatorDots(
                totalSteps: widget.totalSteps,
                currentStep: widget.currentStep,
              ),
              const SizedBox(height: 32),
              // Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE3DB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ANY LINK → RECIPE',
                      style: AppTextStyles.tinyLabel.copyWith(
                        fontSize: 11.5,
                        letterSpacing: 0.46,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Title
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.screenTitle.copyWith(
                    fontSize: 27,
                  ),
                  children: [
                    const TextSpan(text: 'Import from '),
                    TextSpan(
                      text: '95%',
                      style: AppTextStyles.screenTitle.copyWith(
                        fontSize: 27,
                        color: AppColors.primary,
                      ),
                    ),
                    const TextSpan(text: ' of sites'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'Paste or share a link from anywhere — we turn it into a clean, cookable recipe.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall,
                ),
              ),
              const SizedBox(height: 36),
              // Center circle area
              SizedBox(
                width: 236,
                height: 236,
                child: AnimatedBuilder(
                  animation: _floatAnimation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Dashed circle border
                        CustomPaint(
                          size: const Size(236, 236),
                          painter: _DashedCirclePainter(),
                        ),
                        // Center logo with pulse
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment(-0.7, -0.7),
                                    end: Alignment(0.7, 0.7),
                                    colors: [
                                      Color(0xFFFF8763),
                                      Color(0xFFF2623E),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                        // Floating social icons
                        ..._buildFloatingIcons(),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              // More sites badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '…and 1,000s more sites',
                      style: AppTextStyles.chipLabel.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Show me how',
                onPressed: widget.onContinue ?? () => Get.to(() => const AgeScreen()),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFloatingIcons() {
    // Fixed positions from HTML: left/top values relative to 236x236 container
    // HTML container is ~236px, icon size is 44x44
    final iconData = [
      // Instagram: left:96, top:-4 (gradient bg)
      (Icons.camera_alt, const Color(0xFFFCE4EE), const Color(0xFFC13584), 96.0, -4.0, true),
      // TikTok: left:191, top:65
      (Icons.music_note, const Color(0xFF1F1F24), Colors.white, 191.0, 65.0, false),
      // YouTube: left:155, top:177
      (Icons.play_arrow, const Color(0xFFFCE2E0), const Color(0xFFDD3B33), 155.0, 177.0, false),
      // Facebook: left:37, top:177
      (Icons.chat, const Color(0xFFE4ECFB), const Color(0xFF2D6FE0), 37.0, 177.0, false),
      // Pinterest: left:1, top:65
      (Icons.push_pin, const Color(0xFFFCE4EE), const Color(0xFFC13584), 1.0, 65.0, false),
    ];

    return List.generate(iconData.length, (i) {
      final data = iconData[i];
      final floatOffset = _floatAnimation.value * (i.isEven ? 1 : -1);

      return Positioned(
        left: data.$4,
        top: data.$5 + floatOffset,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: data.$6 ? null : data.$2,
            gradient: data.$6
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF58529),
                      Color(0xFFDD2A7B),
                      Color(0xFF8134AF),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(data.$1, size: 20, color: data.$6 ? Colors.white : data.$3),
        ),
      );
    });
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const dashCount = 40;
    const dashArc = (2 * math.pi) / dashCount;
    const gapFraction = 0.4;

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
