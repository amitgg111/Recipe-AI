import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:recipe_ai/screens/onboarding/plus_comparison_screen.dart';

class PlusIntroScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  final VoidCallback? onClose;

  const PlusIntroScreen({super.key, this.onContinue, this.onClose});

  @override
  State<PlusIntroScreen> createState() => _PlusIntroScreenState();
}

class _PlusIntroScreenState extends State<PlusIntroScreen>
    with TickerProviderStateMixin {
  // One-shot staggered entrance (crown pop → badge → tags → sparkles).
  late final AnimationController _entrance;
  late final Animation<double> _crownScale;
  late final Animation<double> _crownFade;
  late final Animation<double> _badgeScale;
  late final Animation<double> _glowFade;
  late final List<Animation<double>> _tagReveal;
  late final Animation<double> _sparkleFade;

  // Continuous loops.
  late final AnimationController _pulse; // crown ring pulse + glow breathing
  late final AnimationController _bob; // crown gentle vertical bob
  late final AnimationController _float; // tags + sparkles floating
  late final Animation<double> _bobAnim;

  // Fixed per-tag data: rotation (deg) and float phase (0..1).
  static const List<double> _tagRot = [0, 0, 0, 0];
  static const List<double> _tagPhase = [0.0, 0.25, 0.5, 0.75];

  // The close button is hidden at first and fades in ~2s later, after the
  // entrance animation has played out.
  bool _showClose = false;

  static double _cl(double v) => v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v);

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _crownScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _crownFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.32, curve: Curves.easeOut),
    );
    _glowFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _badgeScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.42, 0.72, curve: Curves.easeOutBack),
      ),
    );
    const tagStart = [0.44, 0.54, 0.64, 0.74];
    _tagReveal = List.generate(4, (i) {
      final s = tagStart[i];
      return CurvedAnimation(
        parent: _entrance,
        curve: Interval(s, _cl(s + 0.34), curve: Curves.easeOutCubic),
      );
    });
    _sparkleFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.82, 1.0, curve: Curves.easeOut),
    );

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
    _bobAnim = Tween<double>(
      begin: 0.0,
      end: -6.0,
    ).animate(CurvedAnimation(parent: _bob, curve: Curves.easeInOut));

    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();

    _entrance.forward();

    // Reveal the close button ~2s in, once the entrance animation has settled.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showClose = true);
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    _bob.dispose();
    _float.dispose();
    super.dispose();
  }

  // Seamless vertical bob (one full smooth cycle per loop).
  double _bobDy(double phase, double amp) =>
      amp * math.sin(2 * math.pi * ((_float.value + phase) % 1.0));

  // Subtle, slower horizontal drift for an organic "floating" feel.
  double _driftDx(double phase, double amp) =>
      amp * math.sin(2 * math.pi * ((0.6 * _float.value + phase) % 1.0));

  // A ring's expanding-fade parameters at a given phase offset.
  double _ringScaleAt(double p) => 1.0 + 0.62 * ((_pulse.value + p) % 1.0);
  double _ringOpacityAt(double p) => 0.55 * (1.0 - ((_pulse.value + p) % 1.0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 26),
          child: Column(
            children: [
              // Top: close button at top-right, height 36
              SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Hidden and untappable until it fades in ~2s later.
                    IgnorePointer(
                      ignoring: !_showClose,
                      child: AnimatedOpacity(
                        opacity: _showClose ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        child: GestureDetector(
                          onTap:
                              widget.onClose ??
                              () => Get.to(
                                () => const PlusComparisonScreen(),
                                transition: Transition.noTransition,
                              ),
                          child: Container(
                            width: 36,
                            height: 36,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2A211B,
                              ).withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const OnboardingLineIcon(
                              'x',
                              size: 18,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Logo: margin 6px 0 24px
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 6, 0, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.7),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: const AppLogoMark(size: 13),
                    ),
                    const SizedBox(width: 9),
                    Text.rich(
                      TextSpan(
                        text: 'Recipe AI ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          letterSpacing: -0.42,
                        ),
                        children: [
                          TextSpan(
                            text: 'Plus',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: AppColors.purple,
                              letterSpacing: -0.42,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Subtitle
              Text(
                'Recipe AI is free to use, but…',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              // Title
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    height: 1.2,
                    letterSpacing: -0.58,
                  ),
                  children: [
                    const TextSpan(text: 'We\'d love you to try '),
                    TextSpan(
                      text: 'the full experience for 7 days, free!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purple,
                        height: 1.2,
                        letterSpacing: -0.58,
                      ),
                    ),
                  ],
                ),
              ),
              // Center animation area: flex:1
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 330,
                    height: 300,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // Radial glow (fades in + gentle breathing)
                        AnimatedBuilder(
                          animation: Listenable.merge([_entrance, _pulse]),
                          builder: (context, child) {
                            return Opacity(
                              opacity: _glowFade.value,
                              child: Transform.scale(
                                scale:
                                    1.0 +
                                    0.06 * math.sin(2 * math.pi * _pulse.value),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(
                                    0xFF8B5CF6,
                                  ).withValues(alpha: 0.18),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.66],
                              ),
                            ),
                          ),
                        ),
                        // Crown with entrance + bob + double-ring pulse
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _entrance,
                            _bob,
                            _pulse,
                          ]),
                          builder: (context, _) {
                            return Opacity(
                              opacity: _crownFade.value,
                              child: Transform.scale(
                                scale: _crownScale.value,
                                child: Transform.translate(
                                  offset: Offset(0, _bobAnim.value),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Two staggered expanding pulse rings
                                      _pulseRing(0.0),
                                      _pulseRing(0.5),
                                      // Main icon: 80x80, gradient 160deg
                                      Container(
                                        width: 40,
                                        height: 40,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF8B5CF6),
                                              Color(0xFF6D3BD4),
                                            ],
                                          ),
                                        ),
                                        child: const OnboardingLineIcon(
                                          'crown',
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                      // "7 DAYS FREE" badge (pops in)
                                      Positioned(
                                        top: -8,
                                        right: -12,
                                        child: Transform.scale(
                                          scale: _badgeScale.value,
                                          child: _daysFreeBadge(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Feature tags (staggered reveal + floating)
                        _tag(
                          0,

                          left: 0,
                          top: 8,
                          label: 'Unlimited Recipe imports',
                          iconName: 'spark',
                          color: AppColors.purple,
                        ),
                        _tag(
                          1,
                          right: 0,
                          top: 48,
                          label: 'Nutrition calculator',
                          iconName: 'checkCircle',
                          color: AppColors.green,
                        ),
                        _tag(
                          2,
                          left: 0,
                          bottom: 56,
                          label: 'AI cooking assistant',
                          iconName: 'spark',
                          color: AppColors.primary,
                        ),
                        _tag(
                          3,
                          right: 0,
                          bottom: 22,
                          label: 'Convert measurements',
                          iconName: 'globe',
                          color: AppColors.blue,
                        ),
                        // Sparkles (fade in + float)
                        _sparkle(
                          left: 40,
                          top: 96,
                          phase: 0.1,
                          color: AppColors.starOrange,
                        ),
                        _sparkle(
                          right: 50,
                          bottom: 96,
                          phase: 0.6,
                          color: AppColors.purple,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom button
              PrimaryButton.purple(
                label: 'Try for ₹0.00',
                onPressed:
                    widget.onContinue ??
                    () => Get.to(
                      () => const PlusComparisonScreen(),
                      transition: Transition.noTransition,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Building blocks -----------------------------------------------------

  Widget _pulseRing(double phase) {
    return Transform.scale(
      scale: _ringScaleAt(phase),
      child: Opacity(
        opacity: _ringOpacityAt(phase),
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.purple,
            borderRadius: BorderRadius.circular(26),
          ),
        ),
      ),
    );
  }

  Widget _daysFreeBadge() {
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '7',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8,

              fontWeight: FontWeight.w800,
              color: AppColors.purple,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(width: 3),
          Text(
            'DAYS FREE',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 5,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
              letterSpacing: 0.42,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(
    int i, {
    double? left,
    double? right,
    double? top,
    double? bottom,
    required String label,
    required String iconName,
    required Color color,
  }) {
    final tagWidget = Transform.rotate(
      angle: _tagRot[i] * math.pi / 180,
      child: _buildFeatureTag(label, iconName, color),
    );
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: Listenable.merge([_entrance, _float]),
        builder: (context, child) {
          final rev = _tagReveal[i].value;
          return Opacity(
            opacity: rev,
            child: Transform.translate(
              offset: Offset(
                _driftDx(_tagPhase[i], 4),
                _bobDy(_tagPhase[i], 6) + (1 - rev) * 10,
              ),
              child: Transform.scale(scale: 0.7 + 0.2 * rev, child: child),
            ),
          );
        },
        child: tagWidget,
      ),
    );
  }

  Widget _sparkle({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double phase,
    required Color color,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: Listenable.merge([_entrance, _float]),
        builder: (context, child) {
          return Opacity(
            opacity: _sparkleFade.value,
            child: Transform.translate(
              offset: Offset(_driftDx(phase, 2), _bobDy(phase, 1)),
              child: child,
            ),
          );
        },
        child: OnboardingLineIcon('spark', color: color, size: 14),
      ),
    );
  }

  Widget _buildFeatureTag(String text, String iconName, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.purpleBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -18,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OnboardingLineIcon(iconName, size: 12, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
