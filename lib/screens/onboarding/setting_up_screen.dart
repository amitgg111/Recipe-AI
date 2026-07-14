import 'dart:math' as math;
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
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
  // Pan tilt animation
  late final AnimationController _panController;
  late final Animation<double> _panRotation;

  // Food flip animations
  late final AnimationController _foodController1;
  late final AnimationController _foodController2;
  late final Animation<double> _foodArc1;
  late final Animation<double> _foodArc2;

  // Sizzle puffs
  late final AnimationController _sizzleController1;
  late final AnimationController _sizzleController2;
  late final AnimationController _sizzleController3;

  // Spinner
  late final AnimationController _spinnerController;

  // Sparkle floaty
  late final AnimationController _sparkleController;
  late final Animation<double> _sparkleY;

  // Message cycling
  late final AnimationController _messageController;
  int _messageIndex = 0;

  List<String> get _messages => [
    'setup_msg_gathering'.tr,
    'setup_msg_cookbooks'.tr,
    'setup_msg_planner'.tr,
    'setup_msg_almost'.tr,
  ];

  @override
  void initState() {
    super.initState();

    // Pan tilt: subtle rotation -3deg to 3deg, 2.2s, ease-in-out, infinite
    _panController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _panRotation = Tween<double>(
      begin: -3.0 * math.pi / 180.0,
      end: 3.0 * math.pi / 180.0,
    ).animate(
      CurvedAnimation(parent: _panController, curve: Curves.easeInOut),
    );

    // Food flip 1 (orange ball): arc Y 0 -> -60 -> 0, 2.2s, ease-in-out
    _foodController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _foodArc1 = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -60.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -60.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_foodController1);

    // Food flip 2 (green ball): same but delayed by 0.35s (350ms)
    _foodController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _foodArc2 = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -60.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -60.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_foodController2);
    // Start with delay
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _foodController2.repeat();
    });

    // Sizzle puffs: opacity 0->1->0 with upward drift, 1.6s, staggered
    _sizzleController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _sizzleController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _sizzleController3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _sizzleController2.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _sizzleController3.repeat();
    });

    // Spinner: continuous 360deg, 1s, linear
    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    // Sparkle floaty: Y oscillation +/-8px, 3.4s, ease-in-out
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);
    _sparkleY = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    // Message cycling: 2s per message, fade transition
    _messageController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
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
    _foodController1.dispose();
    _foodController2.dispose();
    _sizzleController1.dispose();
    _sizzleController2.dispose();
    _sizzleController3.dispose();
    _spinnerController.dispose();
    _sparkleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Logo
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
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppWordmark(fontSize: 16, fontWeight: FontWeight.w700),
                ],
              ),
              // Title
              const SizedBox(height: 24),
              Text(
                'setting_up_title'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.52,
                  height: 1.18,
                ),
              ),
              // Center content area
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Frying pan animation area
                    Container(
                      width: 220,
                      height: 220,
                      margin: const EdgeInsets.only(bottom: 34),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Ambient glow
                          Center(
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFF2623E)
                                        .withValues(alpha: 0.14),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.66],
                                ),
                              ),
                            ),
                          ),
                          // Pan with tilt animation
                          AnimatedBuilder(
                            animation: _panRotation,
                            builder: (context, child) {
                              return Positioned(
                                bottom: 46,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Transform.rotate(
                                    angle: _panRotation.value,
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Pan body
                                        Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(0xFF3A302A),
                                                Color(0xFF241C17),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.18),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            // Inner circle
                                            child: Container(
                                              width: 96,
                                              height: 96,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF2A211B),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Handle
                                        Container(
                                          width: 78,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF5A4632),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Orange food ball - food flip arc
                          AnimatedBuilder(
                            animation: _foodArc1,
                            builder: (context, _) {
                              return Positioned(
                                top: 42 + _foodArc1.value,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Transform.rotate(
                                    angle: _foodController1.value *
                                        2 *
                                        math.pi,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFFFC074),
                                            Color(0xFFE58A3C),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Green food ball - food flip arc, delayed
                          AnimatedBuilder(
                            animation: _foodController2,
                            builder: (context, _) {
                              return Positioned(
                                top: 48 + _foodArc2.value,
                                left: 0,
                                right: 14,
                                child: Center(
                                  child: Transform.translate(
                                    offset: const Offset(14, 0),
                                    child: Transform.rotate(
                                      angle: _foodController2.value *
                                          2 *
                                          math.pi,
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF9BD45E),
                                              Color(0xFF5E9C36),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Sizzle puff 1: bottom 78px, left 78px
                          _buildSizzlePuff(
                            controller: _sizzleController1,
                            bottom: 78,
                            left: 78,
                            size: 8,
                          ),
                          // Sizzle puff 2: bottom 80px, left 120px
                          _buildSizzlePuff(
                            controller: _sizzleController2,
                            bottom: 80,
                            left: 120,
                            size: 7,
                          ),
                          // Sizzle puff 3: bottom 76px, left 100px
                          _buildSizzlePuff(
                            controller: _sizzleController3,
                            bottom: 76,
                            left: 100,
                            size: 6,
                          ),
                          // Sparkle: top 20px, right 36px, primary, floaty
                          AnimatedBuilder(
                            animation: _sparkleY,
                            builder: (context, _) {
                              return Positioned(
                                top: 20 + _sparkleY.value,
                                right: 36,
                                child: const OnboardingLineIcon(
                                  'sparkF2',
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Loading indicator
                    Column(
                      children: [
                        // Spinner
                        AnimatedBuilder(
                          animation: _spinnerController,
                          builder: (context, _) {
                            return Transform.rotate(
                              angle:
                                  _spinnerController.value * 2 * math.pi,
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CustomPaint(
                                  painter: _SpinnerPainter(),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        // Rotating messages
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            _messages[_messageIndex],
                            key: ValueKey<int>(_messageIndex),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Continue button
              PrimaryButton(
                label: 'continue_'.tr,
                onPressed: widget.onContinue ??
                    () => Get.to(() => const PlusIntroScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizzlePuff({
    required AnimationController controller,
    required double bottom,
    required double left,
    required double size,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // opacity 0 -> 1 -> 0 with slight upward drift
        final progress = controller.value;
        double opacity;
        if (progress < 0.5) {
          opacity = progress * 2.0; // 0 -> 1
        } else {
          opacity = (1.0 - progress) * 2.0; // 1 -> 0
        }
        final drift = progress * -12.0; // upward drift
        return Positioned(
          bottom: bottom - drift,
          left: left,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: Color(0xFFE7DCC8),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Content-only body widget for the single-screen onboarding architecture.
/// Renders the logo, title, frying-pan animation, spinner and cycling
/// loading messages (no progress dots, no CTA button).
class SettingUpBody extends StatefulWidget {
  /// True once setup is finished. Swaps the spinner + cycling loading message
  /// for a "done" checkmark + confirmation text (the parent reveals the
  /// Continue button at the same moment).
  final bool ready;

  const SettingUpBody({super.key, this.ready = false});

  @override
  State<SettingUpBody> createState() => _SettingUpBodyState();
}

class _SettingUpBodyState extends State<SettingUpBody>
    with TickerProviderStateMixin {
  // Pan tilt animation
  late final AnimationController _panController;
  late final Animation<double> _panRotation;

  // Food flip animations
  late final AnimationController _foodController1;
  late final AnimationController _foodController2;
  late final Animation<double> _foodArc1;
  late final Animation<double> _foodArc2;

  // Sizzle puffs
  late final AnimationController _sizzleController1;
  late final AnimationController _sizzleController2;
  late final AnimationController _sizzleController3;

  // Spinner
  late final AnimationController _spinnerController;

  // Sparkle floaty
  late final AnimationController _sparkleController;
  late final Animation<double> _sparkleY;

  // Message cycling
  late final AnimationController _messageController;
  int _messageIndex = 0;

  List<String> get _messages => [
    'setup_msg_gathering'.tr,
    'setup_msg_cookbooks'.tr,
    'setup_msg_planner'.tr,
    'setup_msg_almost'.tr,
  ];

  @override
  void initState() {
    super.initState();

    _panController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _panRotation = Tween<double>(
      begin: -3.0 * math.pi / 180.0,
      end: 3.0 * math.pi / 180.0,
    ).animate(
      CurvedAnimation(parent: _panController, curve: Curves.easeInOut),
    );

    _foodController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _foodArc1 = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -60.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -60.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_foodController1);

    _foodController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _foodArc2 = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -60.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -60.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_foodController2);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _foodController2.repeat();
    });

    _sizzleController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _sizzleController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _sizzleController3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _sizzleController2.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _sizzleController3.repeat();
    });

    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);
    _sparkleY = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    _messageController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
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
    _foodController1.dispose();
    _foodController2.dispose();
    _sizzleController1.dispose();
    _sizzleController2.dispose();
    _sizzleController3.dispose();
    _spinnerController.dispose();
    _sparkleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Title
          Text(
            'setting_up_title'.tr,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.52,
              height: 1.18,
            ),
          ),
          // Center content area
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Frying pan animation area
                Container(
                  width: 220,
                  height: 220,
                  margin: const EdgeInsets.only(bottom: 34),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Ambient glow
                      Center(
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFF2623E)
                                    .withValues(alpha: 0.14),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.66],
                            ),
                          ),
                        ),
                      ),
                      // Pan with tilt animation
                      AnimatedBuilder(
                        animation: _panRotation,
                        builder: (context, child) {
                          return Positioned(
                            bottom: 46,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Transform.rotate(
                                angle: _panRotation.value,
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Pan body
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xFF3A302A),
                                            Color(0xFF241C17),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.18),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        // Inner circle
                                        child: Container(
                                          width: 96,
                                          height: 96,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF2A211B),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Handle
                                    Container(
                                      width: 78,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5A4632),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Orange food ball - food flip arc
                      AnimatedBuilder(
                        animation: _foodArc1,
                        builder: (context, _) {
                          return Positioned(
                            top: 42 + _foodArc1.value,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Transform.rotate(
                                angle: _foodController1.value * 2 * math.pi,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFFC074),
                                        Color(0xFFE58A3C),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Green food ball - food flip arc, delayed
                      AnimatedBuilder(
                        animation: _foodController2,
                        builder: (context, _) {
                          return Positioned(
                            top: 48 + _foodArc2.value,
                            left: 0,
                            right: 14,
                            child: Center(
                              child: Transform.translate(
                                offset: const Offset(14, 0),
                                child: Transform.rotate(
                                  angle:
                                      _foodController2.value * 2 * math.pi,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF9BD45E),
                                          Color(0xFF5E9C36),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Sizzle puff 1: bottom 78px, left 78px
                      _buildSizzlePuff(
                        controller: _sizzleController1,
                        bottom: 78,
                        left: 78,
                        size: 8,
                      ),
                      // Sizzle puff 2: bottom 80px, left 120px
                      _buildSizzlePuff(
                        controller: _sizzleController2,
                        bottom: 80,
                        left: 120,
                        size: 7,
                      ),
                      // Sizzle puff 3: bottom 76px, left 100px
                      _buildSizzlePuff(
                        controller: _sizzleController3,
                        bottom: 76,
                        left: 100,
                        size: 6,
                      ),
                      // Sparkle: top 20px, right 36px, primary, floaty
                      AnimatedBuilder(
                        animation: _sparkleController,
                        builder: (context, _) {
                          final tw = _sparkleController.value;
                          return Positioned(
                            top: 20 + _sparkleY.value,
                            right: 36,
                            // Twinkle: gentle scale pulse + slight wobble on top
                            // of the existing float.
                            child: Transform.rotate(
                              angle: tw * 0.6,
                              child: Transform.scale(
                                scale: 0.82 + 0.36 * tw,
                                child: const OnboardingLineIcon(
                                  'sparkF2',
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Loading indicator → swaps to a "done" state once ready.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: widget.ready
                      ? Column(
                          key: const ValueKey('done'),
                          children: [
                            // Done checkmark
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const OnboardingLineIcon(
                                'check',
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'youre_all_set'.tr,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey('loading'),
                          children: [
                            // Spinner
                            AnimatedBuilder(
                              animation: _spinnerController,
                              builder: (context, _) {
                                return Transform.rotate(
                                  angle:
                                      _spinnerController.value * 2 * math.pi,
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CustomPaint(
                                      painter: _SpinnerPainter(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            // Rotating messages
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: Text(
                                _messages[_messageIndex],
                                key: ValueKey<int>(_messageIndex),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizzlePuff({
    required AnimationController controller,
    required double bottom,
    required double left,
    required double size,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final progress = controller.value;
        double opacity;
        if (progress < 0.5) {
          opacity = progress * 2.0;
        } else {
          opacity = (1.0 - progress) * 2.0;
        }
        final drift = progress * -12.0;
        return Positioned(
          bottom: bottom - drift,
          left: left,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: Color(0xFFE7DCC8),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background circle border
    final bgPaint = Paint()
      ..color = const Color(0xFFF0EDE5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 1.5,
      bgPaint,
    );

    // Active arc (top portion)
    final arcPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3),
      -math.pi / 2,
      math.pi * 0.7,
      false,
      arcPaint,
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
