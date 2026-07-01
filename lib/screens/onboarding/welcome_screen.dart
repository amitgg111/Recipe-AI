import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/screens/onboarding/social_proof_screen.dart';
import 'package:recipe_ai/screens/auth/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  static const String routeName = '/onboarding/welcome';
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _potFade;
  late final Animation<double> _potScale;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _loginFade;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _logoFade = _fade(0.0, 0.25);
    _logoSlide = _slide(const Offset(0, -0.3), 0.0, 0.25);
    _titleFade = _fade(0.10, 0.35);
    _titleSlide = _slide(const Offset(0, 0.15), 0.10, 0.35);
    _subtitleFade = _fade(0.18, 0.42);
    _subtitleSlide = _slide(const Offset(0, 0.15), 0.18, 0.42);
    _potFade = _fade(0.28, 0.58);
    _potScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.28, 0.58, curve: Curves.elasticOut),
      ),
    );
    _buttonFade = _fade(0.70, 0.90);
    _buttonSlide = _slide(const Offset(0, 0.3), 0.70, 0.90);
    _loginFade = _fade(0.82, 1.0);

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
    _entranceController.dispose();
    super.dispose();
  }

  Widget _animatedSlide(
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [const Color(0x15F2623E), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomLeft,
                  radius: 1.0,
                  colors: [const Color(0x101F7A5E), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Logo
                  _animatedSlide(
                    _logoFade,
                    _logoSlide,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.restaurant_menu,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Recipe AI',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Title
                  _animatedSlide(
                    _titleFade,
                    _titleSlide,
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 33,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          height: 1.08,
                          letterSpacing: -1.0,
                        ),
                        children: [
                          const TextSpan(text: 'Cook '),
                          TextSpan(
                            text: 'anything',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                          const TextSpan(text: ',\nwithout the chaos'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Subtitle
                  _animatedSlide(
                    _subtitleFade,
                    _subtitleSlide,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Import any recipe, build smart shopping lists, and plan your week — like a pro.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMedium,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Animation area
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) => Opacity(
                        opacity: _potFade.value,
                        child: Transform.scale(
                          scale: _potScale.value,
                          child: child,
                        ),
                      ),
                      child: const WelcomeCookingAnimation(),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Get Started button
                  _animatedSlide(
                    _buttonFade,
                    _buttonSlide,
                    PrimaryButton(
                      label: 'Get Started',
                      enableSheen: false,

                      height: 54,
                      onPressed: () => Get.to(() => const SocialProofScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Login link
                  AnimatedBuilder(
                    animation: _loginFade,
                    builder: (context, child) =>
                        Opacity(opacity: _loginFade.value, child: child),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMedium,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.to(() => const LoginScreen()),
                          child: Text(
                            'Log in',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              decoration: TextDecoration.underline,
                              decorationThickness: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WelcomeBody — content-only version for single-screen onboarding flow
// ─────────────────────────────────────────────────────────────────────────────

class WelcomeBody extends StatefulWidget {
  const WelcomeBody({super.key});

  @override
  State<WelcomeBody> createState() => _WelcomeBodyState();
}

class _WelcomeBodyState extends State<WelcomeBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedBuilder(
        animation: _fade,
        builder: (context, child) =>
            Opacity(opacity: _fade.value, child: child),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Logo
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.restaurant_menu,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Recipe AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Title
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 33,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1.08,
                  letterSpacing: -1.0,
                ),
                children: [
                  const TextSpan(text: 'Cook '),
                  TextSpan(
                    text: 'anything',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const TextSpan(text: ',\nwithout the chaos'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Import any recipe, build smart shopping lists, and plan your week — like a pro.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Animation area
            const Expanded(child: WelcomeCookingAnimation()),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WelcomeCookingAnimation — pot, steam, bubbles, floating ingredients, chips
// ─────────────────────────────────────────────────────────────────────────────

class WelcomeCookingAnimation extends StatefulWidget {
  const WelcomeCookingAnimation({super.key});

  @override
  State<WelcomeCookingAnimation> createState() =>
      _WelcomeCookingAnimationState();
}

class _WelcomeCookingAnimationState extends State<WelcomeCookingAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  double _pingPong(double t, double period, double phase) {
    final x = ((t * 5 / period) + phase) % 1.0;
    return (1 - math.cos(x * 2 * math.pi)) / 2;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, _) {
        final t = _loop.value;
        return SizedBox(
          width: double.infinity,
          height: 330,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ambient glow
              Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x26F2623E), Color(0x00F2623E)],
                    stops: [0.0, 0.66],
                  ),
                ),
              ),

              // floating ingredients
              _floater(
                top: 34,
                left: 64,
                dy: -11 * _pingPong(t, 4.0, 0.0),
                child: _tomato(),
              ),
              _floater(
                top: 26,
                right: 70,
                dy: -11 * _pingPong(t, 4.6, 0.4),
                child: _lemon(),
              ),
              _floater(
                bottom: 96,
                right: 48,
                dy: -11 * _pingPong(t, 5.0, 0.8),
                child: _herb(),
              ),

              // simmering pot (potbob)
              Transform.translate(
                offset: Offset(0, -4 * _pingPong(t, 4.0, 0.0)),
                child: _pot(t),
              ),

              // feature chips (floaty)
              _chip(
                top: 10,
                left: 6,
                dy: -7 * _pingPong(t, 4.0, 0.0),
                bg: const Color(0xFFFDEBD2),
                fg: const Color(0xFFD98A12),
                icon: Icons.auto_awesome,
                label: 'Import any recipe',
              ),
              _chip(
                topFraction: 0.48,
                right: 8,
                dy: -7 * _pingPong(t, 4.8, 0.5),
                bg: const Color(0xFFE4ECFB),
                fg: const Color(0xFF2D6FE0),
                icon: Icons.calendar_today,
                label: 'Plan your week',
              ),
              _chip(
                bottom: 8,
                left: 2,
                dy: -7 * _pingPong(t, 4.4, 0.9),
                bg: const Color(0xFFDBF0E7),
                fg: const Color(0xFF1F7A5E),
                icon: Icons.shopping_cart_outlined,
                label: 'Auto shopping list',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _floater({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double dy,
    required Widget child,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Transform.translate(offset: Offset(0, dy), child: child),
    );
  }

  Widget _tomato() => SizedBox(
    width: 30,
    height: 30,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment(-0.36, -0.4),
              colors: [Color(0xFFFF6F52), Color(0xFFE5402A)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x802A211B),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
        ),
        Positioned(
          top: -4,
          left: 11,
          child: Transform.rotate(
            angle: 0.35,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF3E8E4F),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _lemon() => Container(
    width: 32,
    height: 23,
    decoration: const BoxDecoration(
      borderRadius: BorderRadius.all(Radius.elliptical(32, 23)),
      gradient: RadialGradient(
        center: Alignment(-0.36, -0.4),
        colors: [Color(0xFFFFE05A), Color(0xFFEBAE14)],
      ),
      boxShadow: [
        BoxShadow(
          color: Color(0x802A211B),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    ),
  );

  Widget _herb() => SizedBox(
    width: 26,
    height: 26,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: 7,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF3E8E4F),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Positioned(
          top: 1,
          left: 2,
          child: Transform.rotate(angle: -0.52, child: _leafShape()),
        ),
        Positioned(
          top: 6,
          right: 2,
          child: Transform.rotate(angle: 0.52, child: _leafShape()),
        ),
      ],
    ),
  );

  Widget _leafShape() => Container(
    width: 11,
    height: 11,
    decoration: const BoxDecoration(
      color: Color(0xFF54B069),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(11),
        topRight: Radius.circular(11),
        bottomLeft: Radius.circular(11),
      ),
    ),
  );

  Widget _pot(double t) {
    return SizedBox(
      width: 220,
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // steam
          Positioned(
            top: 18,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _steam(34, _pingPong(t, 2.6, 0.0)),
                  const SizedBox(width: 16),
                  _steam(48, _pingPong(t, 2.6, 0.27)),
                  const SizedBox(width: 16),
                  _steam(34, _pingPong(t, 2.6, 0.5)),
                ],
              ),
            ),
          ),
          // left handle
          Positioned(
            left: -6,
            top: 122,
            child: Container(
              width: 30,
              height: 26,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0xFF2A211B), width: 7),
                  top: BorderSide(color: Color(0xFF2A211B), width: 7),
                  bottom: BorderSide(color: Color(0xFF2A211B), width: 7),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
          // right handle
          Positioned(
            right: -6,
            top: 122,
            child: Container(
              width: 30,
              height: 26,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFF2A211B), width: 7),
                  top: BorderSide(color: Color(0xFF2A211B), width: 7),
                  bottom: BorderSide(color: Color(0xFF2A211B), width: 7),
                ),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
          ),
          // body
          Positioned(
            left: 24,
            top: 102,
            child: Container(
              width: 172,
              height: 105,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3A302A), Color(0xFF241C17)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                  bottomLeft: Radius.circular(46),
                  bottomRight: Radius.circular(46),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x8C2A211B),
                    blurRadius: 38,
                    offset: Offset(0, 22),
                  ),
                ],
              ),
            ),
          ),
          // rim
          Positioned(
            left: 12,
            top: 86,
            child: Container(
              width: 196,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1712),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // food surface
          Positioned(
            left: 35,
            top: 105,
            child: ClipOval(
              child: SizedBox(
                width: 140,
                height: 18,
                child: Image.network(
                  'https://images.unsplash.com/photo-1547592180-85f173990554?w=400&q=80&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF4A9B4A),
                    child: const Center(
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // bubbles
          _bubble(left: 78, top: 94, size: 9, p: _pingPong(t, 2.2, 0.0)),
          _bubble(left: 118, top: 98, size: 7, p: _pingPong(t, 2.4, 0.33)),
          _bubble(left: 98, top: 96, size: 6, p: _pingPong(t, 2.0, 0.7)),
        ],
      ),
    );
  }

  Widget _steam(double h, double p) {
    return Opacity(
      opacity: (0.5 * p).clamp(0.0, 0.5),
      child: Transform.translate(
        offset: Offset(0, 10 - 40 * p),
        child: Container(
          width: 9,
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xFFE0D4C0),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _bubble({
    required double left,
    required double top,
    required double size,
    required double p,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: Opacity(
        opacity: (0.9 * p).clamp(0.0, 0.9),
        child: Transform.translate(
          offset: Offset(0, 2 - 14 * p),
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Color(0xE6FFEBD2),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip({
    double? top,
    double? topFraction,
    double? left,
    double? right,
    double? bottom,
    required double dy,
    required Color bg,
    required Color fg,
    required IconData icon,
    required String label,
  }) {
    final chip = Transform.translate(
      offset: Offset(0, dy),
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 8, 13, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0E7D6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x732A211B),
              blurRadius: 30,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: fg),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2A211B),
              ),
            ),
          ],
        ),
      ),
    );
    return Positioned(
      top: topFraction != null ? 330 * topFraction : top,
      left: left,
      right: right,
      bottom: bottom,
      child: chip,
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
