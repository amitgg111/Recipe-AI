// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:recipe_ai/Service/ai_translation_service.dart';
// import 'package:recipe_ai/Service/language_service.dart';
// import 'package:recipe_ai/View/Auth/auth_wrapper.dart';
// import 'package:recipe_ai/screens/onboarding/onboarding_flow_screen.dart';
// import 'package:recipe_ai/widgets/app_logo.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with TickerProviderStateMixin {
//   Timer? _redirectTimer;

//   // One-shot entrance for the icon, wordmark and tagline.
//   late final AnimationController _entrance;
//   late final Animation<double> _iconScale;
//   late final Animation<double> _iconFade;
//   late final Animation<double> _wordFade;
//   late final Animation<Offset> _wordSlide;
//   late final Animation<double> _tagFade;
//   late final Animation<Offset> _tagSlide;

//   // Continuous ripple rings + loading dots.
//   late final AnimationController _loop;

//   final country = LanguageService.deviceCountryCode;
//   @override
//   void initState() {
//     super.initState();
//     _startBackgroundLanguagePreparation();
//     _entrance = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1400),
//     );
//     // Icon pop: scale .4 -> 1 with an overshoot (cubic-bezier(.34,1.56,.64,1)).
//     _iconScale = Tween<double>(begin: 0.4, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _entrance,
//         curve: const Interval(0.0, 0.57, curve: Curves.easeOutBack),
//       ),
//     );
//     _iconFade = CurvedAnimation(
//       parent: _entrance,
//       curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
//     );
//     // Wordmark: rise + fade in at ~0.5s.
//     _wordFade = CurvedAnimation(
//       parent: _entrance,
//       curve: const Interval(0.36, 0.72, curve: Curves.easeOut),
//     );
//     _wordSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
//         .animate(
//           CurvedAnimation(
//             parent: _entrance,
//             curve: const Interval(0.36, 0.72, curve: Curves.easeOut),
//           ),
//         );
//     // Tagline: same, slightly later (~0.68s).
//     _tagFade = CurvedAnimation(
//       parent: _entrance,
//       curve: const Interval(0.49, 0.85, curve: Curves.easeOut),
//     );
//     _tagSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
//         .animate(
//           CurvedAnimation(
//             parent: _entrance,
//             curve: const Interval(0.49, 0.85, curve: Curves.easeOut),
//           ),
//         );
//     _entrance.forward();

//     _loop = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 2400),
//     )..repeat();

//     _redirectTimer = Timer(const Duration(seconds: 3), () {
//       if (!mounted) return;
//       final box = GetStorage();
//       final hasSeenOnboarding = box.read<bool>('hasSeenOnboarding') ?? false;
//       if (!hasSeenOnboarding) {
//         box.write('hasSeenOnboarding', true);
//         Get.off(
//           () => const OnboardingFlowScreen(),
//           transition: Transition.noTransition,
//         );
//       } else {
//         Get.off(() => const AuthWrapper());
//       }
//     });
//   }

//   void _startBackgroundLanguagePreparation() {
//     unawaited(AiTranslationService.preloadDeviceLanguages());
//   }

//   @override
//   void dispose() {
//     _redirectTimer?.cancel();
//     _entrance.dispose();
//     _loop.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment(0.6, -1),
//             end: Alignment(-0.6, 1),
//             colors: [Color(0xFFFF8763), Color(0xFFF2623E), Color(0xFFE0481F)],
//             stops: [0.0, 0.6, 1.0],
//           ),
//         ),
//         child: Stack(
//           children: [
//             // Soft radial glows in opposite corners.
//             Positioned(top: -80, right: -60, child: _glow(260, 0.16)),
//             Positioned(bottom: -70, left: -50, child: _glow(230, 0.10)),
//             // Centered logo + wordmark + tagline.
//             Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   SizedBox(
//                     width: 150,
//                     height: 150,
//                     child: Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         // Two staggered ripple rings.
//                         _Ripple(controller: _loop, delayFraction: 0.0),
//                         _Ripple(controller: _loop, delayFraction: 0.5),
//                         // White tile with the brand mark.
//                         FadeTransition(
//                           opacity: _iconFade,
//                           child: ScaleTransition(
//                             scale: _iconScale,
//                             child: Container(
//                               width: 118,
//                               height: 118,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(34),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: const Color(
//                                       0xFF2A211B,
//                                     ).withValues(alpha: 0.4),
//                                     blurRadius: 44,
//                                     offset: const Offset(0, 22),
//                                     spreadRadius: -16,
//                                   ),
//                                 ],
//                               ),
//                               alignment: Alignment.center,
//                               child: const AppLogoMark(
//                                 size: 72,
//                                 hatColor: Color(0xFFF2623E),
//                                 bandColor: Color(0xFFE0481F),
//                                 pleatColor: Color(0x99FFFFFF),
//                                 sparkleColor: Color(0xFFFFE3B0),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 26),
//                   FadeTransition(
//                     opacity: _wordFade,
//                     child: SlideTransition(
//                       position: _wordSlide,
//                       child: Text(
//                         'app_name'.tr,
//                         style: GoogleFonts.plusJakartaSans(
//                           fontSize: 34,
//                           fontWeight: FontWeight.w800,
//                           color: Colors.white,
//                           letterSpacing: -1.0,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   FadeTransition(
//                     opacity: _tagFade,
//                     child: SlideTransition(
//                       position: _tagSlide,
//                       child: Text(
//                         'Cook Smarter'.toUpperCase(),
//                         style: GoogleFonts.plusJakartaSans(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white.withValues(alpha: 0.85),
//                           letterSpacing: 3.0,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // Loading dots near the bottom.
//             Positioned(
//               left: 0,
//               right: 0,
//               bottom: 64,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: List.generate(
//                   3,
//                   (i) => Padding(
//                     padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
//                     child: _Dot(controller: _loop, index: i),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _glow(double size, double opacity) {
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         gradient: RadialGradient(
//           colors: [
//             Colors.white.withValues(alpha: opacity),
//             Colors.white.withValues(alpha: 0),
//           ],
//           stops: const [0.0, 0.7],
//         ),
//       ),
//     );
//   }
// }

// /// A single expanding + fading ring, matching the `splashRipple` keyframe
// /// (scale .5 -> 2.1, opacity .5 -> 0) with a staggered start.
// class _Ripple extends StatelessWidget {
//   final AnimationController controller;
//   final double delayFraction;

//   const _Ripple({required this.controller, required this.delayFraction});

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: controller,
//       builder: (context, child) {
//         var t = controller.value + delayFraction;
//         if (t > 1) t -= 1;
//         final scale = 0.5 + t * (2.1 - 0.5);
//         final opacity = (0.5 * (1 - t)).clamp(0.0, 1.0);
//         return Opacity(
//           opacity: opacity,
//           child: Transform.scale(scale: scale, child: child),
//         );
//       },
//       child: Container(
//         width: 118,
//         height: 118,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           border: Border.all(
//             color: Colors.white.withValues(alpha: 0.5),
//             width: 2,
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// A pulsing loading dot, matching the `splashDots` keyframe with per-dot delay.
// class _Dot extends StatelessWidget {
//   final AnimationController controller;
//   final int index;

//   const _Dot({required this.controller, required this.index});

//   @override
//   Widget build(BuildContext context) {
//     // The loop runs 2.4s; the dot cycle is 1.2s, so run it twice per loop.
//     return AnimatedBuilder(
//       animation: controller,
//       builder: (context, child) {
//         var t = (controller.value * 2 - (0.2 / 1.2) * index) % 1.0;
//         if (t < 0) t += 1;
//         // scale .6 -> 1 -> .6, opacity .4 -> 1 -> .4 with the peak at 40%.
//         final double p = t < 0.4 ? t / 0.4 : (1 - t) / 0.6;
//         final e = Curves.easeInOut.transform(p.clamp(0.0, 1.0));
//         final scale = 0.6 + 0.4 * e;
//         final opacity = 0.4 + 0.6 * e;
//         return Opacity(
//           opacity: opacity,
//           child: Transform.scale(scale: scale, child: child),
//         );
//       },
//       child: Container(
//         width: 9,
//         height: 9,
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           shape: BoxShape.circle,
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:recipe_ai/View/Auth/auth_wrapper.dart';
import 'package:recipe_ai/screens/onboarding/onboarding_flow_screen.dart';
import 'package:recipe_ai/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  Timer? _redirectTimer;

  // One-shot entrance for the icon, wordmark and tagline.
  late final AnimationController _entrance;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<double> _wordFade;
  late final Animation<Offset> _wordSlide;
  late final Animation<double> _tagFade;
  late final Animation<Offset> _tagSlide;

  // Continuous ripple rings + loading dots.
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _startBackgroundLanguagePreparation();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    // Icon pop: scale .4 -> 1 with an overshoot (cubic-bezier(.34,1.56,.64,1)).
    _iconScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.0, 0.57, curve: Curves.easeOutBack),
      ),
    );
    _iconFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    // Wordmark: rise + fade in at ~0.5s.
    _wordFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.36, 0.72, curve: Curves.easeOut),
    );
    _wordSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entrance,
            curve: const Interval(0.36, 0.72, curve: Curves.easeOut),
          ),
        );
    // Tagline: same, slightly later (~0.68s).
    _tagFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.49, 0.85, curve: Curves.easeOut),
    );
    _tagSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entrance,
            curve: const Interval(0.49, 0.85, curve: Curves.easeOut),
          ),
        );
    _entrance.forward();

    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _redirectTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      final box = GetStorage();
      final hasSeenOnboarding = box.read<bool>('hasSeenOnboarding') ?? false;
      if (!hasSeenOnboarding) {
        box.write('hasSeenOnboarding', true);
        Get.off(
          () => const OnboardingFlowScreen(),
          transition: Transition.noTransition,
        );
      } else {
        Get.off(() => const AuthWrapper());
      }
    });
  }

  /// Fires the whole splash-time background prep chain WITHOUT awaiting it,
  /// and without depending on this State/mounted — so even though the splash
  /// itself disposes after ~3 seconds, this keeps running in the background
  /// all the way until it completes (Home and beyond), exactly as required:
  /// "background process splash thi chalu kari ne home sudhi ma complete
  /// kari nakhvani chhe".
  void _startBackgroundLanguagePreparation() {
    unawaited(_prepareLanguageAndContent());
  }

  /// 1) Downloads the ML Kit model for the device's non-English language
  ///    (e.g. India -> Hindi) so a later manual language switch never needs
  ///    to download anything.
  /// 2) Once the model is ready, pre-warms the translation CACHE for every
  ///    existing recipe the (already logged-in) user has, so opening any
  ///    recipe later hits `cachedOrSelf()` instead of firing a live
  ///    `translateText()` call on the UI thread.
  Future<void> _prepareLanguageAndContent() async {
    // The alternate language for this user's country (India -> Hindi):
    // download the ML Kit model AND pre-translate their recipes into it, so a
    // later switch is instant rather than a screen full of live translate
    // calls. Does nothing for users outside the rollout — they stay English.
    await AiTranslationService.prepareAlternateLanguages();
    // Then top up the cache for whatever language is active right now.
    await AiTranslationService.prewarmExistingRecipesTranslation();
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _entrance.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.6, -1),
            end: Alignment(-0.6, 1),
            colors: [Color(0xFFFF8763), Color(0xFFF2623E), Color(0xFFE0481F)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Soft radial glows in opposite corners.
            Positioned(top: -80, right: -60, child: _glow(260, 0.16)),
            Positioned(bottom: -70, left: -50, child: _glow(230, 0.10)),
            // Centered logo + wordmark + tagline.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Two staggered ripple rings.
                        _Ripple(controller: _loop, delayFraction: 0.0),
                        _Ripple(controller: _loop, delayFraction: 0.5),
                        // White tile with the brand mark.
                        FadeTransition(
                          opacity: _iconFade,
                          child: ScaleTransition(
                            scale: _iconScale,
                            child: Container(
                              width: 118,
                              height: 118,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(34),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2A211B,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 44,
                                    offset: const Offset(0, 22),
                                    spreadRadius: -16,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const AppLogoMark(
                                size: 72,
                                hatColor: Color(0xFFF2623E),
                                bandColor: Color(0xFFE0481F),
                                pleatColor: Color(0x99FFFFFF),
                                sparkleColor: Color(0xFFFFE3B0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  FadeTransition(
                    opacity: _wordFade,
                    child: SlideTransition(
                      position: _wordSlide,
                      child: Text(
                        'app_name'.tr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _tagFade,
                    child: SlideTransition(
                      position: _tagSlide,
                      child: Text(
                        'Cook Smarter'.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 3.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Loading dots near the bottom.
            Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                    child: _Dot(controller: _loop, index: i),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glow(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: opacity),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.7],
        ),
      ),
    );
  }
}

/// A single expanding + fading ring, matching the `splashRipple` keyframe
/// (scale .5 -> 2.1, opacity .5 -> 0) with a staggered start.
class _Ripple extends StatelessWidget {
  final AnimationController controller;
  final double delayFraction;

  const _Ripple({required this.controller, required this.delayFraction});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        var t = controller.value + delayFraction;
        if (t > 1) t -= 1;
        final scale = 0.5 + t * (2.1 - 0.5);
        final opacity = (0.5 * (1 - t)).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: 118,
        height: 118,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
      ),
    );
  }
}

/// A pulsing loading dot, matching the `splashDots` keyframe with per-dot delay.
class _Dot extends StatelessWidget {
  final AnimationController controller;
  final int index;

  const _Dot({required this.controller, required this.index});

  @override
  Widget build(BuildContext context) {
    // The loop runs 2.4s; the dot cycle is 1.2s, so run it twice per loop.
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        var t = (controller.value * 2 - (0.2 / 1.2) * index) % 1.0;
        if (t < 0) t += 1;
        // scale .6 -> 1 -> .6, opacity .4 -> 1 -> .4 with the peak at 40%.
        final double p = t < 0.4 ? t / 0.4 : (1 - t) / 0.6;
        final e = Curves.easeInOut.transform(p.clamp(0.0, 1.0));
        final scale = 0.6 + 0.4 * e;
        final opacity = 0.4 + 0.6 * e;
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: 9,
        height: 9,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
