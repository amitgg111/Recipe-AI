import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';

/// Reusable "empty cookbook" plate illustration matching the HTML design:
/// a white plate (dashed ring + chef-hat icon) flanked by a fork and knife,
/// with three steam bars above — all gently bobbing (design `bob` keyframe:
/// translateY 0 → -13 → 0) behind a soft radial glow.
///
/// Self-contained and self-animating so it can be reused on any empty state.
class EmptyPlateIllustration extends StatefulWidget {
  const EmptyPlateIllustration({super.key});

  @override
  State<EmptyPlateIllustration> createState() => _EmptyPlateIllustrationState();
}

class _EmptyPlateIllustrationState extends State<EmptyPlateIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _steam1; // 3.0s
  late final AnimationController _steam2; // 3.4s (.3s delay)
  late final AnimationController _steam3; // 3.2s (.15s delay)
  late final AnimationController _plate; // 4.4s (.1s delay)

  @override
  void initState() {
    super.initState();
    _steam1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _steam2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    _steam3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _plate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4400),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _steam2.repeat();
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _steam3.repeat();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _plate.repeat();
    });
  }

  @override
  void dispose() {
    _steam1.dispose();
    _steam2.dispose();
    _steam3.dispose();
    _plate.dispose();
    super.dispose();
  }

  // bob: 0% → 0, 50% → -13, 100% → 0 (ease-in-out via cosine)
  double _bob(AnimationController c) =>
      -6.5 * (1 - math.cos(2 * math.pi * c.value));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      height: 206,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Radial glow
          Positioned(
            top: -47,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.13),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.66],
                ),
              ),
            ),
          ),
          // Fork (left)
          Positioned(
            left: 12,
            top: 46,
            child: CustomPaint(
              size: const Size(26, 116),
              painter: _ForkPainter(),
            ),
          ),
          // Knife (right)
          Positioned(
            right: 14,
            top: 46,
            child: CustomPaint(
              size: const Size(20, 116),
              painter: _KnifePainter(),
            ),
          ),
          // Steam bars (top, bobbing)
          Positioned(
            top: 4,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _steamBar(_steam1, 22, const Color(0xFFE7DBC8)),
                const SizedBox(width: 9),
                _steamBar(_steam2, 30, const Color(0xFFEBDFCB)),
                const SizedBox(width: 9),
                _steamBar(_steam3, 22, const Color(0xFFE7DBC8)),
              ],
            ),
          ),
          // Plate (centered, bobbing)
          AnimatedBuilder(
            animation: _plate,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _bob(_plate)),
              child: child,
            ),
            child: Container(
              width: 152,
              height: 152,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A211B).withValues(alpha: 0.45),
                    blurRadius: 44,
                    offset: const Offset(0, 24),
                    spreadRadius: -22,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: CustomPaint(
                size: const Size(108, 108),
                painter: _DashedRingPainter(color: const Color(0xFFE7DBC8)),
                child: const SizedBox(
                  width: 108,
                  height: 108,
                  child: Center(
                    child: CustomPaint(
                      size: Size(46, 44),
                      painter: _ChefHatPainter(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _steamBar(AnimationController c, double height, Color color) {
    return AnimatedBuilder(
      animation: c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _bob(c)),
        child: Opacity(opacity: 0.85, child: child),
      ),
      child: Container(
        width: 5,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _ForkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCDBBA1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final p = Path()
      ..moveTo(13, 50)
      ..lineTo(13, 108)
      ..moveTo(5, 6)
      ..lineTo(5, 26)
      ..moveTo(13, 6)
      ..lineTo(13, 26)
      ..moveTo(21, 6)
      ..lineTo(21, 26)
      ..moveTo(5, 26)
      ..cubicTo(5, 32, 8.6, 35, 13, 35)
      ..cubicTo(17.4, 35, 21, 32, 21, 26)
      ..moveTo(13, 35)
      ..lineTo(13, 50);
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KnifePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0xFFCDBBA1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = const Color(0xFFF1E6D2)
      ..style = PaintingStyle.fill;

    final blade = Path()
      ..moveTo(10, 6)
      ..cubicTo(4, 12, 4, 48, 10, 56)
      ..cubicTo(15, 49, 15, 13, 10, 6)
      ..close();
    canvas.drawPath(blade, fill);
    canvas.drawPath(blade, stroke);
    canvas.drawLine(const Offset(10, 56), const Offset(10, 108), stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChefHatPainter extends CustomPainter {
  final Color color;
  const _ChefHatPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    canvas.scale(s, s);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const r = Radius.circular(3.2);

    final top = Path()
      ..moveTo(7, 14)
      ..arcToPoint(const Offset(6, 7.8), radius: r, clockwise: true)
      ..arcToPoint(const Offset(11, 6), radius: r, clockwise: true)
      ..arcToPoint(const Offset(17, 7.8), radius: r, clockwise: true)
      ..arcToPoint(const Offset(17, 14), radius: r, clockwise: true);
    canvas.drawPath(top, paint);

    final band = Path()
      ..moveTo(7, 14)
      ..lineTo(17, 14)
      ..lineTo(17, 19)
      ..lineTo(7, 19)
      ..close();
    canvas.drawPath(band, paint);

    canvas.drawLine(const Offset(9.5, 19), const Offset(9.5, 16), paint);
    canvas.drawLine(const Offset(14.5, 19), const Offset(14.5, 16), paint);
  }

  @override
  bool shouldRepaint(covariant _ChefHatPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  _DashedRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashCount = 34;
    const dashArc = math.pi * 2 / dashCount;
    const gapFraction = 0.45;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * dashArc,
        dashArc * (1 - gapFraction),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
