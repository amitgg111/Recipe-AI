import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/screens/onboarding/age_screen.dart';

class AwesomeImportScreen extends StatefulWidget {
  static const String routeName = '/onboarding/awesome-import';

  const AwesomeImportScreen({super.key});

  @override
  State<AwesomeImportScreen> createState() => _AwesomeImportScreenState();
}

class _AwesomeImportScreenState extends State<AwesomeImportScreen>
    with TickerProviderStateMixin {
  // Ring pulse animation: scale 1 -> 1.5, opacity 0.6 -> 0
  late final AnimationController _ringPulseController;
  late final Animation<double> _ringScaleAnimation;
  late final Animation<double> _ringOpacityAnimation;

  // Individual float controllers for each orbiting icon
  late final List<AnimationController> _floatControllers;
  late final List<Animation<double>> _floatAnimations;

  // Durations and delays from spec
  static const List<int> _floatDurations = [4000, 4500, 5000, 4700, 4300];
  static const List<int> _floatDelays = [0, 300, 600, 900, 1100];

  @override
  void initState() {
    super.initState();

    // Ring pulse: scale 1->1.5, opacity 0.6->0, 2.4s repeating
    _ringPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _ringScaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _ringPulseController, curve: Curves.easeOut),
    );
    _ringOpacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ringPulseController, curve: Curves.easeOut),
    );

    // Individual float animations per icon
    _floatControllers = [];
    _floatAnimations = [];
    for (int i = 0; i < 5; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _floatDurations[i]),
      );
      final animation = Tween<double>(begin: -8.0, end: 8.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
      _floatControllers.add(controller);
      _floatAnimations.add(animation);

      // Start with delay
      Future.delayed(Duration(milliseconds: _floatDelays[i]), () {
        if (mounted) {
          controller.repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _ringPulseController.dispose();
    for (final controller in _floatControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 26),
          child: Column(
            children: [
              // Logo only (no progress dots for this screen)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.restaurant, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recipe AI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              // Badge
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE3DB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '✦',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'ANY LINK → RECIPE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.46,
                      ),
                    ),
                  ],
                ),
              ),
              // Title
              const SizedBox(height: 13),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.screenTitle.copyWith(
                    fontSize: 27,
                    letterSpacing: -0.54,
                  ),
                  children: [
                    const TextSpan(text: 'Import from '),
                    TextSpan(
                      text: '95%',
                      style: AppTextStyles.screenTitle.copyWith(
                        fontSize: 27,
                        color: AppColors.primary,
                        letterSpacing: -0.54,
                      ),
                    ),
                    const TextSpan(text: ' of sites'),
                  ],
                ),
              ),
              // Subtitle
              const SizedBox(height: 9),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'Paste or share a link from anywhere — we turn it into a clean, cookable recipe.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    height: 1.5,
                  ),
                ),
              ),
              // Orbital diagram
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 236,
                    height: 236,
                    child: _buildOrbitalDiagram(),
                  ),
                ),
              ),
              // Bottom "...and 1,000s more sites" badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '…and 1,000s more sites',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Show me how button
              PrimaryButton(
                label: 'Show me how',
                onPressed: () => Get.to(() => const AgeScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrbitalDiagram() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _ringPulseController,
        ..._floatControllers,
      ]),
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Dashed circle
            CustomPaint(
              size: const Size(236, 236),
              painter: _DashedCirclePainter(),
            ),
            // Dashed lines from center to each planet
            CustomPaint(
              size: const Size(236, 236),
              painter: _DashedLinesPainter(),
            ),
            // Pulsing ring behind center icon
            Transform.scale(
              scale: _ringScaleAnimation.value,
              child: Opacity(
                opacity: _ringOpacityAnimation.value,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            // Center Recipe AI icon
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment(-0.5, -0.8),
                  end: Alignment(0.5, 0.8),
                  colors: [
                    Color(0xFFFF8763),
                    Color(0xFFF2623E),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant,
                color: Colors.white,
                size: 32,
              ),
            ),
            // Floating platform icons
            ..._buildFloatingIcons(),
          ],
        );
      },
    );
  }

  List<Widget> _buildFloatingIcons() {
    // Positions from HTML spec: left, top relative to 236x236 container
    // Each icon is 44x44
    final icons = <_OrbitIcon>[
      // Top center: Instagram (gradient)
      const _OrbitIcon(
        left: 96,
        top: -4,
        icon: Icons.camera_alt,
        isGradient: true,
        bgColor: Colors.white,
        iconColor: Colors.white,
      ),
      // Right: TikTok
      const _OrbitIcon(
        left: 191,
        top: 65,
        icon: Icons.music_note,
        bgColor: Color(0xFF1F1F24),
        iconColor: Colors.white,
      ),
      // Bottom-right: YouTube
      const _OrbitIcon(
        left: 155,
        top: 177,
        icon: Icons.play_arrow,
        bgColor: Color(0xFFFCE2E0),
        iconColor: Color(0xFFDD3B33),
      ),
      // Bottom-left: Facebook
      const _OrbitIcon(
        left: 37,
        top: 177,
        icon: Icons.chat_bubble,
        bgColor: Color(0xFFE4ECFB),
        iconColor: Color(0xFF2D6FE0),
      ),
      // Left: Pinterest
      const _OrbitIcon(
        left: 1,
        top: 65,
        icon: Icons.push_pin,
        bgColor: Color(0xFFFCE4EE),
        iconColor: Color(0xFFC13584),
      ),
    ];

    return List.generate(icons.length, (i) {
      final data = icons[i];
      final floatY = _floatAnimations[i].value;

      return Positioned(
        left: data.left,
        top: data.top + floatY,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: data.isGradient ? null : data.bgColor,
            gradient: data.isGradient
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFEDA77),
                      Color(0xFFDD2A7B),
                      Color(0xFF8134AF),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  )
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            data.icon,
            size: 20,
            color: data.iconColor,
          ),
        ),
      );
    });
  }
}

/// Content-only body widget for the single-screen onboarding architecture.
/// Renders the logo, badge, title, subtitle, orbital diagram and bottom badge
/// (no progress dots, no CTA button).
class AwesomeImportBody extends StatefulWidget {
  const AwesomeImportBody({super.key});

  @override
  State<AwesomeImportBody> createState() => _AwesomeImportBodyState();
}

class _AwesomeImportBodyState extends State<AwesomeImportBody>
    with TickerProviderStateMixin {
  // Ring pulse animation: scale 1 -> 1.5, opacity 0.6 -> 0
  late final AnimationController _ringPulseController;
  late final Animation<double> _ringScaleAnimation;
  late final Animation<double> _ringOpacityAnimation;

  // Individual float controllers for each orbiting icon
  late final List<AnimationController> _floatControllers;
  late final List<Animation<double>> _floatAnimations;

  static const List<int> _floatDurations = [4000, 4500, 5000, 4700, 4300];
  static const List<int> _floatDelays = [0, 300, 600, 900, 1100];

  @override
  void initState() {
    super.initState();

    _ringPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _ringScaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _ringPulseController, curve: Curves.easeOut),
    );
    _ringOpacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ringPulseController, curve: Curves.easeOut),
    );

    _floatControllers = [];
    _floatAnimations = [];
    for (int i = 0; i < 5; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _floatDurations[i]),
      );
      final animation = Tween<double>(begin: -8.0, end: 8.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
      _floatControllers.add(controller);
      _floatAnimations.add(animation);

      Future.delayed(Duration(milliseconds: _floatDelays[i]), () {
        if (mounted) {
          controller.repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _ringPulseController.dispose();
    for (final controller in _floatControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE3DB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '✦',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'ANY LINK → RECIPE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.46,
                  ),
                ),
              ],
            ),
          ),
          // Title
          const SizedBox(height: 13),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.screenTitle.copyWith(
                fontSize: 27,
                letterSpacing: -0.54,
              ),
              children: [
                const TextSpan(text: 'Import from '),
                TextSpan(
                  text: '95%',
                  style: AppTextStyles.screenTitle.copyWith(
                    fontSize: 27,
                    color: AppColors.primary,
                    letterSpacing: -0.54,
                  ),
                ),
                const TextSpan(text: ' of sites'),
              ],
            ),
          ),
          // Subtitle
          const SizedBox(height: 9),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'Paste or share a link from anywhere — we turn it into a clean, cookable recipe.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                height: 1.5,
              ),
            ),
          ),
          // Orbital diagram
          Expanded(
            child: Center(
              child: SizedBox(
                width: 236,
                height: 236,
                child: _buildOrbitalDiagram(),
              ),
            ),
          ),
          // Bottom "...and 1,000s more sites" badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '…and 1,000s more sites',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbitalDiagram() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _ringPulseController,
        ..._floatControllers,
      ]),
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(236, 236),
              painter: _DashedCirclePainter(),
            ),
            CustomPaint(
              size: const Size(236, 236),
              painter: _DashedLinesPainter(),
            ),
            Transform.scale(
              scale: _ringScaleAnimation.value,
              child: Opacity(
                opacity: _ringOpacityAnimation.value,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment(-0.5, -0.8),
                  end: Alignment(0.5, 0.8),
                  colors: [
                    Color(0xFFFF8763),
                    Color(0xFFF2623E),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant,
                color: Colors.white,
                size: 32,
              ),
            ),
            ..._buildFloatingIcons(),
          ],
        );
      },
    );
  }

  List<Widget> _buildFloatingIcons() {
    final icons = <_OrbitIcon>[
      const _OrbitIcon(
        left: 96,
        top: -4,
        icon: Icons.camera_alt,
        isGradient: true,
        bgColor: Colors.white,
        iconColor: Colors.white,
      ),
      const _OrbitIcon(
        left: 191,
        top: 65,
        icon: Icons.music_note,
        bgColor: Color(0xFF1F1F24),
        iconColor: Colors.white,
      ),
      const _OrbitIcon(
        left: 155,
        top: 177,
        icon: Icons.play_arrow,
        bgColor: Color(0xFFFCE2E0),
        iconColor: Color(0xFFDD3B33),
      ),
      const _OrbitIcon(
        left: 37,
        top: 177,
        icon: Icons.chat_bubble,
        bgColor: Color(0xFFE4ECFB),
        iconColor: Color(0xFF2D6FE0),
      ),
      const _OrbitIcon(
        left: 1,
        top: 65,
        icon: Icons.push_pin,
        bgColor: Color(0xFFFCE4EE),
        iconColor: Color(0xFFC13584),
      ),
    ];

    return List.generate(icons.length, (i) {
      final data = icons[i];
      final floatY = _floatAnimations[i].value;

      return Positioned(
        left: data.left,
        top: data.top + floatY,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: data.isGradient ? null : data.bgColor,
            gradient: data.isGradient
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFEDA77),
                      Color(0xFFDD2A7B),
                      Color(0xFF8134AF),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  )
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            data.icon,
            size: 20,
            color: data.iconColor,
          ),
        ),
      );
    });
  }
}

class _OrbitIcon {
  final double left;
  final double top;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final bool isGradient;

  const _OrbitIcon({
    required this.left,
    required this.top,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.isGradient = false,
  });
}

// Dashed circle painter
class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE7DBC8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    const radius = 100.0; // 200/2 = 100 for the dashed circle

    const dashCount = 40;
    const dashArc = (2 * math.pi) / dashCount;
    const gapFraction = 0.5;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashArc;
      const sweepAngle = dashArc * (1 - gapFraction);
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

// Dashed lines from center to each planet position
class _DashedLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE3D6C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);

    // Planet center positions (left + 22, top + 22 for 44x44 icons)
    final planetCenters = [
      const Offset(96 + 22, -4 + 22),   // Instagram: top center
      const Offset(191 + 22, 65 + 22),  // TikTok: right
      const Offset(155 + 22, 177 + 22), // YouTube: bottom-right
      const Offset(37 + 22, 177 + 22),  // Facebook: bottom-left
      const Offset(1 + 22, 65 + 22),    // Pinterest: left
    ];

    for (final target in planetCenters) {
      _drawDashedLine(canvas, center, target, paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final unitX = dx / distance;
    final unitY = dy / distance;

    const dashLength = 2.0;
    const gapLength = 6.0;
    double current = 0;

    while (current < distance) {
      final startX = from.dx + unitX * current;
      final startY = from.dy + unitY * current;
      final endDist = math.min(current + dashLength, distance);
      final endX = from.dx + unitX * endDist;
      final endY = from.dy + unitY * endDist;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      current += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// AnimatedBuilder helper
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Listenable animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
