import 'dart:math' as math;
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
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
  // Ring pulse: a single continuously-repeating controller drives several
  // phase-staggered expanding rings so the pulse reads as a seamless loop
  // (a ring that has fully expanded/faded is replaced by a fresh one).
  late final AnimationController _ringPulseController;

  // Phase offsets so the expanding rings overlap and never all reset at once.
  static const List<double> _ringPhases = [0.0, 0.5];

  // Individual float controllers for each orbiting icon
  late final List<AnimationController> _floatControllers;
  late final List<Animation<double>> _floatAnimations;

  // Durations and delays from spec
  static const List<int> _floatDurations = [4000, 4500, 5000, 4700, 4300];
  static const List<int> _floatDelays = [0, 300, 600, 900, 1100];

  // Seamless expanding-ring parameters derived from the linear controller.
  // scale grows 1 -> 1.5, opacity fades 0.6 -> 0 across one cycle; staggered
  // phases keep the overall pulse continuous with no visible restart.
  double _ringScaleAt(double p) =>
      1.0 + 0.5 * ((_ringPulseController.value + p) % 1.0);
  double _ringOpacityAt(double p) =>
      0.6 * (1.0 - ((_ringPulseController.value + p) % 1.0));

  @override
  void initState() {
    super.initState();

    // Ring pulse: linear, constant motion, started once and never reset.
    _ringPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Individual float animations per icon
    _floatControllers = [];
    _floatAnimations = [];
    for (int i = 0; i < 5; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _floatDurations[i]),
      );
      final animation = Tween<double>(
        begin: -8.0,
        end: 8.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
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
              // Logo only (no progress dots for this screen). Uses the shared
              // brand mark so the header matches the animation centre exactly.
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppLogo(size: 28),
                  SizedBox(width: 8),
                  AppWordmark(fontSize: 16, fontWeight: FontWeight.w700),
                ],
              ),
              // Badge
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 6,
                ),
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
                      'any_link_recipe'.tr,
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
                    TextSpan(text: 'import_from'.tr),
                    TextSpan(
                      text: '95%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 27,
                        color: AppColors.primary,
                        letterSpacing: -0.54,
                      ),
                    ),
                    TextSpan(
                      text: 'of_sites'.tr,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Subtitle
              const SizedBox(height: 9),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'import_subtitle'.tr,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(height: 1.5),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 6,
                ),
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
                    const OnboardingLineIcon(
                      'checkCircle',
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'and_1000s_more_sites'.tr,
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
                label: 'show_me_how'.tr,
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
      animation: Listenable.merge([_ringPulseController, ..._floatControllers]),
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
            // Pulsing rings behind center icon (phase-staggered = seamless loop)
            for (final p in _ringPhases)
              Transform.scale(
                scale: _ringScaleAt(p),
                child: Opacity(
                  opacity: _ringOpacityAt(p),
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
            // Centre tile — the app logo (static), matched to the HTML logoMark.
            const _OrbitCenterLogo(),
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
        name: 'camera',
        isGradient: true,
        bgColor: Colors.white,
        iconColor: Colors.white,
      ),
      // Right: TikTok
      const _OrbitIcon(
        left: 191,
        top: 65,
        name: 'music',
        bgColor: Color(0xFF1F1F24),
        iconColor: Colors.white,
      ),
      // Bottom-right: YouTube
      const _OrbitIcon(
        left: 155,
        top: 177,
        name: 'play',
        bgColor: Color(0xFFFCE2E0),
        iconColor: Color(0xFFDD3B33),
      ),
      // Bottom-left: Facebook
      const _OrbitIcon(
        left: 37,
        top: 177,
        name: 'chat',
        bgColor: Color(0xFFE4ECFB),
        iconColor: Color(0xFF2D6FE0),
      ),
      // Left: Pinterest
      const _OrbitIcon(
        left: 1,
        top: 65,
        name: 'pin',
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
          child: Center(
            child: OnboardingLineIcon(
              data.name,
              color: data.iconColor,
              size: 20,
            ),
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
  // Ring pulse: a single continuously-repeating controller drives several
  // phase-staggered expanding rings so the pulse reads as a seamless loop.
  late final AnimationController _ringPulseController;

  static const List<double> _ringPhases = [0.0];

  // Individual float controllers for each orbiting icon
  late final List<AnimationController> _floatControllers;
  late final List<Animation<double>> _floatAnimations;

  static const List<int> _floatDurations = [4000, 4500, 5000, 4700, 4300];
  static const List<int> _floatDelays = [0, 300, 600, 900, 1100];

  // Seamless expanding-ring parameters derived from the linear controller.
  double _ringScaleAt(double p) =>
      1.0 + 0.5 * ((_ringPulseController.value + p) % 1.0);
  double _ringOpacityAt(double p) =>
      0.6 * (1.0 - ((_ringPulseController.value + p) % 1.0));

  @override
  void initState() {
    super.initState();

    _ringPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _floatControllers = [];
    _floatAnimations = [];
    for (int i = 0; i < 5; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _floatDurations[i]),
      );
      final animation = Tween<double>(
        begin: -8.0,
        end: 8.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
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
                  'any_link_recipe'.tr,
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
                fontSize: 24,
                letterSpacing: -0.54,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(
                  text: 'import_from'.tr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: '95%',

                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: -0.54,
                  ),
                ),
                TextSpan(
                  text: 'of_sites'.tr,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Subtitle
          const SizedBox(height: 9),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'import_subtitle'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(height: 1.5),
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
                const OnboardingLineIcon(
                  'checkCircle',
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'and_1000s_more_sites'.tr,
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
      animation: Listenable.merge([_ringPulseController, ..._floatControllers]),
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Dashed guide circle + connecting lines (static).
            CustomPaint(
              size: const Size(236, 236),
              painter: _DashedCirclePainter(),
            ),
            CustomPaint(
              size: const Size(236, 236),
              painter: _DashedLinesPainter(),
            ),
            // Pulsing rings behind the centre (phase-staggered = seamless loop).
            for (final p in _ringPhases)
              Transform.scale(
                scale: _ringScaleAt(p),
                child: Opacity(
                  opacity: _ringOpacityAt(p),
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
            // Centre tile — the app logo (static), matched to the HTML logoMark.
            const _OrbitCenterLogo(),
            // Platform icons float gently in place (matches the HTML).
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
        name: 'camera',
        isGradient: true,
        bgColor: Colors.white,
        iconColor: Colors.white,
      ),
      const _OrbitIcon(
        left: 191,
        top: 65,
        name: 'music',
        bgColor: Color(0xFF1F1F24),
        iconColor: Colors.white,
      ),
      const _OrbitIcon(
        left: 155,
        top: 177,
        name: 'play',
        bgColor: Color(0xFFFCE2E0),
        iconColor: Color(0xFFDD3B33),
      ),
      const _OrbitIcon(
        left: 37,
        top: 177,
        name: 'chat',
        bgColor: Color(0xFFE4ECFB),
        iconColor: Color(0xFF2D6FE0),
      ),
      const _OrbitIcon(
        left: 1,
        top: 65,
        name: 'pin',
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
          child: Center(
            child: OnboardingLineIcon(
              data.name,
              color: data.iconColor,
              size: 20,
            ),
          ),
        ),
      );
    });
  }
}

/// The centre badge of the import orbital diagram — the orange gradient tile
/// with the white outline chef-hat, matched exactly to the HTML `hatBig` mark
/// (160deg gradient, radius 24, deep glow). Sits above the pulsing ring.
class _OrbitCenterLogo extends StatelessWidget {
  const _OrbitCenterLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment(-0.342, -0.940),
          end: Alignment(0.342, 0.940),
          colors: [Color(0xFFFF8763), Color(0xFFF2623E)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF2623E).withValues(alpha: 0.7),
            blurRadius: 30,
            offset: const Offset(0, 16),
            spreadRadius: -10,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const OnboardingLineIcon('hatBig', color: Colors.white, size: 44),
    );
  }
}

class _OrbitIcon {
  final double left;
  final double top;
  final String name;
  final Color bgColor;
  final Color iconColor;
  final bool isGradient;

  const _OrbitIcon({
    required this.left,
    required this.top,
    required this.name,
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
      const Offset(96 + 22, -4 + 22), // Instagram: top center
      const Offset(191 + 22, 65 + 22), // TikTok: right
      const Offset(155 + 22, 177 + 22), // YouTube: bottom-right
      const Offset(37 + 22, 177 + 22), // Facebook: bottom-left
      const Offset(1 + 22, 65 + 22), // Pinterest: left
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
