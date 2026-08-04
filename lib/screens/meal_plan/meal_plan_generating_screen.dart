import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:recipe_ai/Controllers/meal_planner_controller.dart';
import 'package:recipe_ai/screens/meal_plan/meal_planner_ui.dart';
import 'package:recipe_ai/screens/meal_plan/week_review_screen.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

/// Screen 2 — full-screen generating page (design 53b · AI auto-fill
/// generating). Dark-purple radial background, a crown badge inside a pulsing
/// glow + a spinning progress ring, and the live step list. Runs the fallback
/// pipeline (Cookbook → Community → AI) then hands off to the Week Review.
class MealPlanGeneratingScreen extends StatefulWidget {
  const MealPlanGeneratingScreen({super.key});

  @override
  State<MealPlanGeneratingScreen> createState() =>
      _MealPlanGeneratingScreenState();
}

class _MealPlanGeneratingScreenState extends State<MealPlanGeneratingScreen>
    with TickerProviderStateMixin {
  final _controller = MealPlannerController.to;

  // ── Animations (match the HTML) ──
  // nutGlow: 0/100% opacity .35 · scale .92 → 50% opacity .7 · scale 1.06,
  // 2.6s ease-in-out — a reversing controller over half the cycle.
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);
  // spin: rotate 360° · 1.2s linear infinite.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _controller.generateWeeklyPlan();
    if (!mounted) return;
    Get.off(
      () => const WeekReviewScreen(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _glow.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // radial-gradient(120% 80% at 50% 12%, #3A2358, #1E1226 70%)
        decoration: const BoxDecoration(
          color: Color(0xFF1E1226),
          gradient: RadialGradient(
            center: Alignment(0, -0.76),
            radius: 1.2,
            colors: [Color(0xFF3A2358), Color(0xFF1E1226)],
            stops: [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                _glowIcon(),
                const SizedBox(height: 34),
                Text(
                  'Planning your week…',
                  style: Mp.f(21, FontWeight.w800, Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'Balancing nutrition, variety & your prep time across 7 days.',
                  textAlign: TextAlign.center,
                  style: Mp.f(
                    13.5,
                    FontWeight.w500,
                    Colors.white.withValues(alpha: 0.6),
                    h: 1.45,
                  ),
                ),
                const SizedBox(height: 30),
                Obx(
                  () => Column(
                    children: [
                      for (final step in _controller.steps) ...[
                        GeneratingStepCard(step: step),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                const Spacer(flex: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // The 120×120 badge stack: pulsing glow · spinning ring · crown core.
  Widget _glowIcon() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing glow circle (nutGlow).
          AnimatedBuilder(
            animation: _glow,
            builder: (_, __) {
              final t = Curves.easeInOut.transform(_glow.value);
              return Transform.scale(
                scale: 0.92 + 0.14 * t, // .92 → 1.06
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFFA78BFA,
                    ).withValues(alpha: 0.35 + 0.35 * t), // .35 → .7
                  ),
                ),
              );
            },
          ),
          // Spinning progress ring (spin).
          AnimatedBuilder(
            animation: _spin,
            builder: (_, __) => Transform.rotate(
              angle: _spin.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(120, 120),
                painter: _RingPainter(),
              ),
            ),
          ),
          // Core crown badge (74×74 rounded square, radius 22).
          Container(
            width: 74,
            height: 74,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment(-0.342, -0.940),
                end: Alignment(0.342, 0.940),
                colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.7),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                  spreadRadius: -10,
                ),
              ],
            ),
            child: const OnboardingLineIcon(
              'crown',
              size: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// The spinning progress arc: a faint full track + a ~72% purple arc with a
/// round cap (matches the SVG dasharray 327 / dashoffset 90).
class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - stroke / 2 - 2; // r ≈ 52 on a 120 box
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.14);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFA78BFA);
    canvas.drawCircle(center, radius, track);
    // Visible arc fraction = (327 - 90) / 327 ≈ 0.725.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * 0.725,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => false;
}

// import 'dart:async';
// import 'dart:math' as math;

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// import 'package:recipe_ai/Controllers/meal_planner_controller.dart';
// import 'package:recipe_ai/screens/meal_plan/meal_planner_ui.dart';
// import 'package:recipe_ai/screens/meal_plan/week_review_screen.dart';
// import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

// class MealPlanGeneratingScreen extends StatefulWidget {
//   const MealPlanGeneratingScreen({super.key});

//   @override
//   State<MealPlanGeneratingScreen> createState() =>
//       _MealPlanGeneratingScreenState();
// }

// class _MealPlanGeneratingScreenState extends State<MealPlanGeneratingScreen>
//     with TickerProviderStateMixin {
//   final _controller = MealPlannerController.to;

//   late final AnimationController _glow;
//   late final AnimationController _spin;
//   late final AnimationController _pulse;

//   Timer? _uiTimer;
//   Timer? _tipTimer;

//   double _progress = 0.08;

//   int _messageIndex = 0;
//   int _tipIndex = 0;

//   final List<_GenerationMessage> _messages = [
//     const _GenerationMessage(
//       title: 'Creating your week',
//       subtitle: 'Finding the best meals for your preferences…',
//       icon: 'sparkles',
//     ),
//     const _GenerationMessage(
//       title: 'Checking variety',
//       subtitle: 'Making sure your week doesn’t feel repetitive…',
//       icon: 'refresh',
//     ),
//     const _GenerationMessage(
//       title: 'Balancing nutrition',
//       subtitle: 'Spreading meals across the week intelligently…',
//       icon: 'nutrition',
//     ),
//     const _GenerationMessage(
//       title: 'Optimizing your plan',
//       subtitle: 'Balancing prep time, variety & nutrition…',
//       icon: 'clock',
//     ),
//     const _GenerationMessage(
//       title: 'Almost ready',
//       subtitle: 'Putting the finishing touches on your week…',
//       icon: 'check',
//     ),
//   ];

//   final List<String> _tips = [
//     'Your plan is being personalized around your preferences.',
//     'We’re avoiding repetitive meals across the week.',
//     'Prep time is being considered while building your plan.',
//     'Your meals are being balanced for better variety.',
//     'Just a moment — your week is almost ready.',
//   ];

//   @override
//   void initState() {
//     super.initState();

//     _glow = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1400),
//     )..repeat(reverse: true);

//     _spin = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1100),
//     )..repeat();

//     _pulse = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     )..repeat(reverse: true);

//     _startProgressAnimation();
//     _startTipRotation();
//     _start();
//   }

//   void _startProgressAnimation() {
//     // Smoothly moves UI progress without pretending
//     // that the backend has actually completed that percentage.
//     _uiTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
//       if (!mounted) return;

//       setState(() {
//         if (_progress < 0.30) {
//           _progress += 0.008;
//         } else if (_progress < 0.52) {
//           _progress += 0.0045;
//         } else if (_progress < 0.72) {
//           _progress += 0.0028;
//         } else if (_progress < 0.88) {
//           _progress += 0.0013;
//         }

//         if (_progress >= 0.20 && _messageIndex == 0) {
//           _messageIndex = 1;
//         }

//         if (_progress >= 0.43 && _messageIndex == 1) {
//           _messageIndex = 2;
//         }

//         if (_progress >= 0.63 && _messageIndex == 2) {
//           _messageIndex = 3;
//         }

//         if (_progress >= 0.82 && _messageIndex == 3) {
//           _messageIndex = 4;
//         }
//       });
//     });
//   }

//   void _startTipRotation() {
//     _tipTimer = Timer.periodic(const Duration(seconds: 3), (_) {
//       if (!mounted) return;

//       setState(() {
//         _tipIndex = (_tipIndex + 1) % _tips.length;
//       });
//     });
//   }

//   Future<void> _start() async {
//     try {
//       await _controller.generateWeeklyPlan();

//       if (!mounted) return;

//       // Finish the visual progress before navigating.
//       setState(() {
//         _progress = 1.0;
//         _messageIndex = _messages.length - 1;
//       });

//       await Future.delayed(const Duration(milliseconds: 450));

//       if (!mounted) return;

//       Get.off(
//         () => const WeekReviewScreen(),
//         transition: Transition.fadeIn,
//         duration: const Duration(milliseconds: 320),
//         curve: Curves.easeOutCubic,
//       );
//     } catch (e) {
//       if (!mounted) return;

//       Get.snackbar(
//         'Couldn’t create your week',
//         'Please try again.',
//         snackPosition: SnackPosition.BOTTOM,
//         margin: const EdgeInsets.all(16),
//       );

//       Get.back();
//     }
//   }

//   @override
//   void dispose() {
//     _uiTimer?.cancel();
//     _tipTimer?.cancel();

//     _glow.dispose();
//     _spin.dispose();
//     _pulse.dispose();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final message = _messages[_messageIndex];

//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           color: Color(0xFF1E1226),
//           gradient: RadialGradient(
//             center: Alignment(0, -0.76),
//             radius: 1.2,
//             colors: [Color(0xFF3A2358), Color(0xFF1E1226)],
//             stops: [0.0, 0.7],
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Column(
//               children: [
//                 const Spacer(flex: 2),

//                 _buildAnimatedIcon(),

//                 const SizedBox(height: 30),

//                 AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 350),
//                   transitionBuilder: (child, animation) {
//                     return FadeTransition(
//                       opacity: animation,
//                       child: SlideTransition(
//                         position: Tween<Offset>(
//                           begin: const Offset(0, 0.15),
//                           end: Offset.zero,
//                         ).animate(animation),
//                         child: child,
//                       ),
//                     );
//                   },
//                   child: Column(
//                     key: ValueKey(_messageIndex),
//                     children: [
//                       Text(
//                         message.title,
//                         textAlign: TextAlign.center,
//                         style: Mp.f(22, FontWeight.w800, Colors.white),
//                       ),
//                       const SizedBox(height: 9),
//                       Text(
//                         message.subtitle,
//                         textAlign: TextAlign.center,
//                         style: Mp.f(
//                           13.5,
//                           FontWeight.w500,
//                           Colors.white.withValues(alpha: 0.62),
//                           h: 1.45,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 28),

//                 _buildProgress(),

//                 const SizedBox(height: 28),

//                 _buildSteps(),

//                 const SizedBox(height: 24),

//                 _buildTip(),

//                 const Spacer(flex: 3),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAnimatedIcon() {
//     return SizedBox(
//       width: 126,
//       height: 126,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           AnimatedBuilder(
//             animation: _glow,
//             builder: (_, __) {
//               final t = Curves.easeInOut.transform(_glow.value);

//               return Transform.scale(
//                 scale: 0.90 + (0.12 * t),
//                 child: Container(
//                   width: 120,
//                   height: 120,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: const Color(
//                       0xFFA78BFA,
//                     ).withValues(alpha: 0.20 + (0.18 * t)),
//                   ),
//                 ),
//               );
//             },
//           ),

//           AnimatedBuilder(
//             animation: _spin,
//             builder: (_, __) {
//               return Transform.rotate(
//                 angle: _spin.value * 2 * math.pi,
//                 child: CustomPaint(
//                   size: const Size(120, 120),
//                   painter: _RingPainter(progress: _progress),
//                 ),
//               );
//             },
//           ),

//           AnimatedBuilder(
//             animation: _pulse,
//             builder: (_, child) {
//               final scale = 1.0 + (_pulse.value * 0.035);

//               return Transform.scale(scale: scale, child: child);
//             },
//             child: Container(
//               width: 74,
//               height: 74,
//               alignment: Alignment.center,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(22),
//                 gradient: const LinearGradient(
//                   begin: Alignment(-0.342, -0.940),
//                   end: Alignment(0.342, 0.940),
//                   colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: const Color(0xFF8B5CF6).withValues(alpha: 0.65),
//                     blurRadius: 30,
//                     offset: const Offset(0, 14),
//                     spreadRadius: -10,
//                   ),
//                 ],
//               ),
//               child: const OnboardingLineIcon(
//                 'crown',
//                 size: 32,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProgress() {
//     final percent = (_progress * 100).round();

//     return Column(
//       children: [
//         Row(
//           children: [
//             Text(
//               'Building your week',
//               style: Mp.f(
//                 12,
//                 FontWeight.w600,
//                 Colors.white.withValues(alpha: 0.65),
//               ),
//             ),
//             const Spacer(),
//             AnimatedSwitcher(
//               duration: const Duration(milliseconds: 200),
//               child: Text(
//                 '$percent%',
//                 key: ValueKey(percent),
//                 style: Mp.f(12, FontWeight.w700, const Color(0xFFA78BFA)),
//               ),
//             ),
//           ],
//         ),

//         const SizedBox(height: 9),

//         ClipRRect(
//           borderRadius: BorderRadius.circular(20),
//           child: Container(
//             height: 7,
//             width: double.infinity,
//             color: Colors.white.withValues(alpha: 0.09),
//             child: Align(
//               alignment: Alignment.centerLeft,
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 180),
//                 curve: Curves.easeOut,
//                 width: MediaQuery.of(context).size.width * 0.8 * _progress,
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
//                   ),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSteps() {
//     return Obx(() {
//       final controllerSteps = _controller.steps;

//       return Column(
//         children: [
//           for (int i = 0; i < controllerSteps.length; i++)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: _buildStepRow(controllerSteps[i], i),
//             ),
//         ],
//       );
//     });
//   }

//   Widget _buildStepRow(dynamic step, int index) {
//     final isCurrent = index == _messageIndex;
//     final isDone = index < _messageIndex;

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
//       decoration: BoxDecoration(
//         color: isCurrent
//             ? Colors.white.withValues(alpha: 0.075)
//             : Colors.white.withValues(alpha: 0.035),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: isCurrent
//               ? const Color(0xFFA78BFA).withValues(alpha: 0.28)
//               : Colors.transparent,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.max,
//         children: [
//           // Status icon
//           SizedBox(
//             width: 26,
//             height: 26,
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 250),
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: isDone
//                     ? const Color(0xFF8B5CF6)
//                     : isCurrent
//                     ? const Color(0xFFA78BFA).withValues(alpha: 0.18)
//                     : Colors.white.withValues(alpha: 0.07),
//               ),
//               child: isDone
//                   ? const Icon(Icons.check, size: 15, color: Colors.white)
//                   : isCurrent
//                   ? const Padding(
//                       padding: EdgeInsets.all(7),
//                       child: CircularProgressIndicator(
//                         strokeWidth: 1.7,
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                           Color(0xFFA78BFA),
//                         ),
//                       ),
//                     )
//                   : null,
//             ),
//           ),

//           const SizedBox(width: 11),

//           // IMPORTANT: Expanded prevents Row overflow.
//           Expanded(
//             child: Text(
//               _stepTitle(step),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               softWrap: false,
//               style: Mp.f(
//                 12.5,
//                 isCurrent || isDone ? FontWeight.w600 : FontWeight.w500,
//                 isCurrent
//                     ? Colors.white
//                     : Colors.white.withValues(alpha: isDone ? 0.65 : 0.35),
//               ),
//             ),
//           ),

//           const SizedBox(width: 8),

//           if (isDone)
//             Flexible(
//               flex: 0,
//               child: Text(
//                 'Done',
//                 maxLines: 1,
//                 overflow: TextOverflow.clip,
//                 style: Mp.f(
//                   10.5,
//                   FontWeight.w600,
//                   Colors.white.withValues(alpha: 0.42),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   String _stepTitle(dynamic step) {
//     if (step == null) {
//       return 'Preparing your meals';
//     }

//     try {
//       final title = step.title;

//       if (title is String && title.trim().isNotEmpty) {
//         return title.trim();
//       }
//     } catch (_) {}

//     try {
//       final name = step.name;

//       if (name is String && name.trim().isNotEmpty) {
//         return name.trim();
//       }
//     } catch (_) {}

//     // Never return step.toString() here.
//     return 'Preparing your meals';
//   }

//   Widget _buildTip() {
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 350),
//       child: Container(
//         key: ValueKey(_tipIndex),
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
//         decoration: BoxDecoration(
//           color: Colors.white.withValues(alpha: 0.045),
//           borderRadius: BorderRadius.circular(14),
//         ),
//         child: Row(
//           children: [
//             const Icon(Icons.auto_awesome, size: 17, color: Color(0xFFA78BFA)),

//             const SizedBox(width: 10),

//             Expanded(
//               child: Text(
//                 _tips[_tipIndex],
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: Mp.f(
//                   11.5,
//                   FontWeight.w500,
//                   Colors.white.withValues(alpha: 0.52),
//                   h: 1.35,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _GenerationMessage {
//   final String title;
//   final String subtitle;
//   final String icon;

//   const _GenerationMessage({
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//   });
// }

// class _RingPainter extends CustomPainter {
//   final double progress;

//   const _RingPainter({required this.progress});

//   @override
//   void paint(Canvas canvas, Size size) {
//     const stroke = 5.5;

//     final center = Offset(size.width / 2, size.height / 2);

//     final radius = size.width / 2 - stroke / 2 - 2;

//     final track = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = stroke
//       ..color = Colors.white.withValues(alpha: 0.10);

//     final arc = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = stroke
//       ..strokeCap = StrokeCap.round
//       ..color = const Color(0xFFA78BFA);

//     canvas.drawCircle(center, radius, track);

//     // Ring visually grows with progress.
//     final visibleProgress = 0.15 + (progress * 0.75);

//     canvas.drawArc(
//       Rect.fromCircle(center: center, radius: radius),
//       -math.pi / 2,
//       2 * math.pi * visibleProgress.clamp(0.0, 0.90),
//       false,
//       arc,
//     );
//   }

//   @override
//   bool shouldRepaint(_RingPainter oldDelegate) {
//     return oldDelegate.progress != progress;
//   }
// }
