import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_logo.dart';

import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NOTE: this screen uses a real photo asset instead of the old pot
// animation. Make sure the file below is added to pubspec.yaml, e.g.:
//
//   flutter:
//     assets:
//       - assets/welcome/hero-photo.png
//
// (copy exports/welcome-assets/hero-photo.png from the design export into
// assets/welcome/ or update _heroImagePath to wherever you place it).
// ─────────────────────────────────────────────────────────────────────────────
const String _heroImagePath = 'assets/welcome/hero-photo.png';

class WelcomeScreen extends StatefulWidget {
  static const String routeName = '/onboarding/welcome';
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _heroFade;
  late final Animation<double> _badgeFade;
  late final Animation<Offset> _badgeSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _chipsFade;
  late final Animation<Offset> _chipsSlide;

  late final AnimationController _sheenController;

  @override
  void initState() {
    super.initState();

    // Edge-to-edge with a transparent status bar so the hero photo runs
    // up behind it, matching the design.
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _sheenController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..repeat();

    _heroFade = _fade(0.0, 0.35);
    _badgeFade = _fade(0.15, 0.4);
    _badgeSlide = _slide(const Offset(0, 0.2), 0.15, 0.4);
    _titleFade = _fade(0.25, 0.55);
    _titleSlide = _slide(const Offset(0, 0.15), 0.25, 0.55);
    _subtitleFade = _fade(0.35, 0.65);
    _subtitleSlide = _slide(const Offset(0, 0.15), 0.35, 0.65);
    _chipsFade = _fade(0.5, 0.8);
    _chipsSlide = _slide(const Offset(0, 0.15), 0.5, 0.8);

    _entranceController.forward();
  }

  Animation<double> _fade(double start, double end) {
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
  }

  Animation<Offset> _slide(Offset begin, double start, double end) {
    return Tween<Offset>(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _entranceController.dispose();
    _sheenController.dispose();
    super.dispose();
  }

  Widget _animatedFadeSlide(
    Animation<double> fade,
    Animation<Offset> slide,
    Widget child,
  ) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, _) => SlideTransition(
        position: slide,
        child: Opacity(opacity: fade.value, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.5 + 45;

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        // Light icons — the hero photo sits behind the status bar.
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFF1B1310),
          body: Stack(
            children: [
              // ── Hero photo (top ~50% of screen) ─────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: heroHeight,
                child: AnimatedBuilder(
                  animation: _heroFade,
                  builder: (context, child) =>
                      Opacity(opacity: _heroFade.value, child: child),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        _heroImagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF3A302A),
                          child: const Center(
                            child: Icon(
                              Icons.restaurant,
                              color: Colors.white38,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                      // Fade the photo into the dark body below it.
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.75, 1.0],
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.35),
                              const Color(0xFF1B1310),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Foreground content ───────────────────────────────────────
              SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo row, over the photo.
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppLogo(size: 30),
                          SizedBox(width: 9),
                          AppWordmark(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: heroHeight * 0.65),

                    // "YOUR AI SOUS-CHEF" badge, sitting over the fade.
                    _animatedFadeSlide(
                      _badgeFade,
                      _badgeSlide,
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 4.0),
                                  child: OnboardingLineIcon(
                                    'sparkF',
                                    size: 18,
                                    color: Color.fromARGB(255, 246, 175, 33),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'YOUR AI SOUS-CHEF'.tr,
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: _animatedFadeSlide(
                        _titleFade,
                        _titleSlide,
                        Align(
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            textAlign: TextAlign.left,
                            text: TextSpan(
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1,
                                letterSpacing: -1.0,
                              ),
                              children: [
                                TextSpan(text: 'Every recipe.\nOne '.tr),
                                TextSpan(
                                  text: 'beautiful'.tr,
                                  style: const TextStyle(color: AppColors.gold),
                                ),
                                TextSpan(text: '\nkitchen.'.tr),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: _animatedFadeSlide(
                        _subtitleFade,
                        _subtitleSlide,
                        Text(
                          'Save from anywhere, plan the week, and shop smarter — all in one place.'
                              .tr,
                          textAlign: TextAlign.left,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.65),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Feature chips row.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: _animatedFadeSlide(
                        _chipsFade,
                        _chipsSlide,
                        Row(
                          children: [
                            Expanded(
                              child: _FeatureButton(
                                iconWidget: const OnboardingLineIcon(
                                  'sparkF',
                                  size: 18,
                                  color: Color.fromARGB(255, 246, 175, 33),
                                ),
                                label: 'Import\nanything'.tr,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _FeatureButton(
                                iconWidget: const OnboardingLineIcon(
                                  'cal',
                                  size: 18,
                                  color: Color.fromARGB(255, 246, 175, 33),
                                ),
                                label: 'Plan the\nweek'.tr,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _FeatureButton(
                                iconWidget: const OnboardingLineIcon(
                                  'cart',
                                  size: 18,
                                  color: Color.fromARGB(255, 246, 175, 33),
                                ),
                                label: 'Auto\ngroceries'.tr,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // SizedBox(height: MediaQuery.of(context).padding.bottom + 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FeatureButton — the small dark "Import anything / Plan the week /
// Auto groceries" cards under the title.
// ─────────────────────────────────────────────────────────────────────────────
class _FeatureButton extends StatelessWidget {
  final Widget iconWidget;
  final String label;

  const _FeatureButton({required this.iconWidget, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AnimatedBuilder helper (shared)
// ─────────────────────────────────────────────────────────────────────────────
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
