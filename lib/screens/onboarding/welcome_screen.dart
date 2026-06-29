import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
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
  // ── Entrance animation controllers ──
  late final AnimationController _entranceController;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _potFade;
  late final Animation<double> _potScale;
  late final Animation<double> _tag1Fade;
  late final Animation<Offset> _tag1Slide;
  late final Animation<double> _tag2Fade;
  late final Animation<Offset> _tag2Slide;
  late final Animation<double> _tag3Fade;
  late final Animation<Offset> _tag3Slide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _loginFade;

  // ── Continuous floating animations ──
  late final AnimationController _float1Controller;
  late final AnimationController _float2Controller;
  late final AnimationController _float3Controller;
  late final Animation<double> _float1Y;
  late final Animation<double> _float2Y;
  late final Animation<double> _float3Y;

  // ── Steam wisps ──
  late final AnimationController _steamController;

  // ── Floating leaf/herb animations ──
  late final AnimationController _leaf1Controller;
  late final AnimationController _leaf2Controller;
  late final AnimationController _leaf3Controller;
  late final AnimationController _leaf4Controller;

  @override
  void initState() {
    super.initState();
    _setupEntranceAnimations();
    _setupFloatingAnimations();
    _setupSteamAnimation();
    _setupLeafAnimations();
    _entranceController.forward();
  }

  void _setupEntranceAnimations() {
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic),
    ));

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.10, 0.35, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.10, 0.35, curve: Curves.easeOutCubic),
    ));

    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.18, 0.42, curve: Curves.easeOut),
      ),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.18, 0.42, curve: Curves.easeOutCubic),
    ));

    _potFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
      ),
    );
    _potScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.55, curve: Curves.elasticOut),
      ),
    );

    _tag1Fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.40, 0.62, curve: Curves.easeOut),
      ),
    );
    _tag1Slide = Tween<Offset>(
      begin: const Offset(-0.5, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.40, 0.62, curve: Curves.easeOutBack),
    ));

    _tag2Fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.48, 0.70, curve: Curves.easeOut),
      ),
    );
    _tag2Slide = Tween<Offset>(
      begin: const Offset(0.5, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.48, 0.70, curve: Curves.easeOutBack),
    ));

    _tag3Fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.78, curve: Curves.easeOut),
      ),
    );
    _tag3Slide = Tween<Offset>(
      begin: const Offset(-0.3, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 0.78, curve: Curves.easeOutBack),
    ));

    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.70, 0.90, curve: Curves.easeOut),
      ),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.70, 0.90, curve: Curves.easeOutCubic),
    ));

    _loginFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.82, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  void _setupFloatingAnimations() {
    _float1Controller = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..repeat(reverse: true);
    _float2Controller = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    )..repeat(reverse: true);
    _float3Controller = AnimationController(
      duration: const Duration(milliseconds: 2900),
      vsync: this,
    )..repeat(reverse: true);

    _float1Y = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _float1Controller, curve: Curves.easeInOut),
    );
    _float2Y = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _float2Controller, curve: Curves.easeInOut),
    );
    _float3Y = Tween<double>(begin: 0, end: -7).animate(
      CurvedAnimation(parent: _float3Controller, curve: Curves.easeInOut),
    );
  }

  void _setupSteamAnimation() {
    _steamController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  void _setupLeafAnimations() {
    _leaf1Controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    _leaf2Controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _leaf3Controller = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    )..repeat(reverse: true);
    _leaf4Controller = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _float1Controller.dispose();
    _float2Controller.dispose();
    _float3Controller.dispose();
    _steamController.dispose();
    _leaf1Controller.dispose();
    _leaf2Controller.dispose();
    _leaf3Controller.dispose();
    _leaf4Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Radial gradient overlays
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    const Color(0x15F2623E),
                    Colors.transparent,
                  ],
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
                  colors: [
                    const Color(0x101F7A5E),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // ── Logo ──
                  _buildAnimatedSlideAndFade(
                    fade: _logoFade,
                    slide: _logoSlide,
                    child: Row(
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
                            child: Icon(Icons.restaurant_menu,
                                color: Colors.white, size: 18),
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
                  // ── Title ──
                  _buildAnimatedSlideAndFade(
                    fade: _titleFade,
                    slide: _titleSlide,
                    child: RichText(
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
                  ),
                  const SizedBox(height: 14),
                  // ── Subtitle ──
                  _buildAnimatedSlideAndFade(
                    fade: _subtitleFade,
                    slide: _subtitleSlide,
                    child: Padding(
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
                  const SizedBox(height: 24),
                  // ── Pot + floating tags area ──
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, _) {
                        return Center(
                          child: SizedBox(
                            width: 310,
                            height: 300,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                // Pot illustration
                                Positioned(
                                  bottom: 20,
                                  child: Opacity(
                                    opacity: _potFade.value,
                                    child: Transform.scale(
                                      scale: _potScale.value,
                                      child: _buildCookingPot(),
                                    ),
                                  ),
                                ),
                                // Steam wisps
                                ..._buildSteamWisps(),
                                // Floating leaves
                                ..._buildFloatingLeaves(),
                                // Feature tag 1: Import any recipe (top-left)
                                Positioned(
                                  top: 10,
                                  left: -10,
                                  child: _buildFloatingTag(
                                    fade: _tag1Fade,
                                    slide: _tag1Slide,
                                    floatAnimation: _float1Y,
                                    floatController: _float1Controller,
                                    label: 'Import any recipe',
                                    icon: Icons.auto_awesome,
                                    iconColor: const Color(0xFFD98A12),
                                    iconBg: const Color(0xFFFDEBD2),
                                  ),
                                ),
                                // Feature tag 2: Plan your week (right)
                                Positioned(
                                  top: 65,
                                  right: -18,
                                  child: _buildFloatingTag(
                                    fade: _tag2Fade,
                                    slide: _tag2Slide,
                                    floatAnimation: _float2Y,
                                    floatController: _float2Controller,
                                    label: 'Plan your week',
                                    icon: Icons.calendar_today,
                                    iconColor: const Color(0xFF2D6FE0),
                                    iconBg: const Color(0xFFE4ECFB),
                                  ),
                                ),
                                // Feature tag 3: Auto shopping list (bottom-left)
                                Positioned(
                                  bottom: 8,
                                  left: 5,
                                  child: _buildFloatingTag(
                                    fade: _tag3Fade,
                                    slide: _tag3Slide,
                                    floatAnimation: _float3Y,
                                    floatController: _float3Controller,
                                    label: 'Auto shopping list',
                                    icon: Icons.shopping_cart_outlined,
                                    iconColor: const Color(0xFF1F7A5E),
                                    iconBg: const Color(0xFFDBF0E7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // ── Get Started button ──
                  _buildAnimatedSlideAndFade(
                    fade: _buttonFade,
                    slide: _buttonSlide,
                    child: PrimaryButton(
                      label: 'Get Started',
                      enableSheen: true,
                      height: 54,
                      onPressed: () {
                        Get.to(() => const SocialProofScreen());
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Login link ──
                  AnimatedBuilder(
                    animation: _loginFade,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _loginFade.value,
                        child: child,
                      );
                    },
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

  // ── Animated entrance helpers ──

  Widget _buildAnimatedSlideAndFade({
    required Animation<double> fade,
    required Animation<Offset> slide,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, _) {
        return SlideTransition(
          position: slide,
          child: Opacity(
            opacity: fade.value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // ── Floating tag with entrance + continuous bounce ──

  Widget _buildFloatingTag({
    required Animation<double> fade,
    required Animation<Offset> slide,
    required Animation<double> floatAnimation,
    required AnimationController floatController,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, floatController]),
      builder: (context, _) {
        return SlideTransition(
          position: slide,
          child: Opacity(
            opacity: fade.value,
            child: Transform.translate(
              offset: Offset(0, floatAnimation.value),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
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
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(icon, size: 16, color: iconColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Cooking pot illustration (built with Flutter) ──

  Widget _buildCookingPot() {
    return SizedBox(
      width: 200,
      height: 180,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Pot shadow
          Positioned(
            bottom: 0,
            child: Container(
              width: 140,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(70),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          // Main pot body
          Positioned(
            bottom: 6,
            child: Container(
              width: 150,
              height: 95,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF3A3028),
                    Color(0xFF2A211B),
                    Color(0xFF1E1814),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ),
          ),
          // Pot rim
          Positioned(
            bottom: 95,
            child: Container(
              width: 164,
              height: 12,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4A3F35),
                    Color(0xFF3A302A),
                    Color(0xFF4A3F35),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          // Left handle
          Positioned(
            bottom: 70,
            left: 5,
            child: Container(
              width: 20,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF4A3F35),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          // Right handle
          Positioned(
            bottom: 70,
            right: 5,
            child: Container(
              width: 20,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF4A3F35),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          // Food inside pot (colored circles representing ingredients)
          Positioned(
            bottom: 98,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Container(
                width: 120,
                height: 60,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6DB56D),
                      Color(0xFF4A9B4A),
                      Color(0xFF3D8B3D),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Lettuce/salad leaves
                    Positioned(
                      top: 5,
                      left: 8,
                      child: _foodCircle(22, const Color(0xFF8BC34A)),
                    ),
                    Positioned(
                      top: 2,
                      left: 35,
                      child: _foodCircle(18, const Color(0xFFE74C3C)),
                    ),
                    Positioned(
                      top: 8,
                      right: 15,
                      child: _foodCircle(20, const Color(0xFFF39C12)),
                    ),
                    Positioned(
                      top: 15,
                      left: 55,
                      child: _foodCircle(16, const Color(0xFFE8D44D)),
                    ),
                    Positioned(
                      top: 0,
                      right: 5,
                      child: _foodCircle(14, const Color(0xFF27AE60)),
                    ),
                    Positioned(
                      bottom: 5,
                      left: 20,
                      child: _foodCircle(14, const Color(0xFFD35400)),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 30,
                      child: _foodCircle(16, const Color(0xFF2ECC71)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _foodCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  // ── Steam wisps ──

  List<Widget> _buildSteamWisps() {
    return [
      _buildSingleSteam(left: 90, delay: 0.0, width: 3, height: 16),
      _buildSingleSteam(left: 105, delay: 0.3, width: 2.5, height: 20),
      _buildSingleSteam(left: 118, delay: 0.6, width: 3, height: 14),
    ];
  }

  Widget _buildSingleSteam({
    required double left,
    required double delay,
    required double width,
    required double height,
  }) {
    return Positioned(
      bottom: 175,
      left: left,
      child: AnimatedBuilder(
        animation: _steamController,
        builder: (context, _) {
          final t = ((_steamController.value + delay) % 1.0);
          final opacity = t < 0.5 ? (t * 2) * 0.4 : (1 - t) * 2 * 0.4;
          final yOffset = -t * 25;
          return Transform.translate(
            offset: Offset(math.sin(t * math.pi * 2) * 3, yOffset),
            child: Opacity(
              opacity: _potFade.value * opacity.clamp(0.0, 1.0),
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(width),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Floating leaves/herbs around the pot ──

  List<Widget> _buildFloatingLeaves() {
    return [
      _buildLeaf(
        bottom: 45,
        right: 20,
        controller: _leaf1Controller,
        rotation: 0.3,
        size: 14,
        color: const Color(0xFF2ECC71),
      ),
      _buildLeaf(
        bottom: 80,
        right: 10,
        controller: _leaf2Controller,
        rotation: -0.5,
        size: 10,
        color: const Color(0xFF27AE60),
      ),
      _buildLeaf(
        bottom: 55,
        right: 30,
        controller: _leaf3Controller,
        rotation: 0.8,
        size: 8,
        color: const Color(0xFF3D9B3D),
      ),
      _buildLeaf(
        bottom: 35,
        right: 45,
        controller: _leaf4Controller,
        rotation: -0.2,
        size: 11,
        color: const Color(0xFF1F7A5E),
      ),
    ];
  }

  Widget _buildLeaf({
    required double bottom,
    required double right,
    required AnimationController controller,
    required double rotation,
    required double size,
    required Color color,
  }) {
    return Positioned(
      bottom: bottom,
      right: right,
      child: AnimatedBuilder(
        animation: Listenable.merge([controller, _entranceController]),
        builder: (context, _) {
          final floatVal = Tween<double>(begin: 0, end: -6)
              .animate(CurvedAnimation(
                  parent: controller, curve: Curves.easeInOut))
              .value;
          final rotVal = Tween<double>(begin: rotation, end: rotation + 0.15)
              .animate(CurvedAnimation(
                  parent: controller, curve: Curves.easeInOut))
              .value;
          return Opacity(
            opacity: _potFade.value,
            child: Transform.translate(
              offset: Offset(0, floatVal),
              child: Transform.rotate(
                angle: rotVal,
                child: CustomPaint(
                  size: Size(size, size * 1.5),
                  painter: _LeafPainter(color: color),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Leaf shape painter ──

class _LeafPainter extends CustomPainter {
  final Color color;
  _LeafPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..quadraticBezierTo(size.width, size.height * 0.3, size.width * 0.5, size.height)
      ..quadraticBezierTo(0, size.height * 0.3, size.width * 0.5, 0)
      ..close();

    canvas.drawPath(path, paint);

    // Leaf vein
    final veinPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.1),
      Offset(size.width * 0.5, size.height * 0.85),
      veinPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── AnimatedBuilder helper ──

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
