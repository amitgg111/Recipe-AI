import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_bottom_nav.dart';

class CookbooksEmptyScreen extends StatefulWidget {
  const CookbooksEmptyScreen({super.key});

  @override
  State<CookbooksEmptyScreen> createState() => _CookbooksEmptyScreenState();
}

class _CookbooksEmptyScreenState extends State<CookbooksEmptyScreen>
    with TickerProviderStateMixin {
  int _selectedNavIndex = 0;

  // bob (translateY 0 → -13 → 0) — steam bars + plate, staggered like the design
  late final AnimationController _steam1; // 3.0s
  late final AnimationController _steam2; // 3.4s, delay .3s
  late final AnimationController _steam3; // 3.2s, delay .15s
  late final AnimationController _plate; // 4.4s, delay .1s
  // ringpulse — FAB
  late final AnimationController _fab; // 2.4s

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
    _fab = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // staggered starts (delays from the design)
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
    _fab.dispose();
    super.dispose();
  }

  // bob keyframe: 0% → 0, 50% → -13, 100% → 0 (ease-in-out via cosine)
  double _bob(AnimationController c) => -6.5 * (1 - math.cos(2 * math.pi * c.value));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(child: _buildEmptyState()),
                const SizedBox(height: 88), // room for bottom nav
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNav(
                currentIndex: _selectedNavIndex,
                onTap: (i) => setState(() => _selectedNavIndex = i),
              ),
            ),
            _buildFAB(),
          ],
        ),
      ),
    );
  }

  // ── Header (logo + 5/5 badge + Cookbooks title) ───────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Recipe AI logo
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.2,
                      ),
                      children: [
                        const TextSpan(text: 'Recipe '),
                        TextSpan(
                          text: 'AI',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // 5/5 badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEFD0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '5/5',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFC0860F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Cookbooks',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.44,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state (illustration + copy + button) ────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIllustration(),
            const SizedBox(height: 20),
            Text(
              "Let's get cooking!",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                letterSpacing: -0.68,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              "Your cookbook is empty for now. Save your first recipe and it'll have a cozy home right here.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8A7E70),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () {},
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.7),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Add your first recipe',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return SizedBox(
      width: 230,
      height: 206,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Radial glow behind
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
          // Steam bars (top, each bobbing)
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
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bob(_plate)),
                child: child,
              );
            },
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
                painter: _DashedCirclePainter(color: const Color(0xFFE7DBC8)),
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
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bob(c)),
          child: Opacity(opacity: 0.85, child: child),
        );
      },
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

  // ── FAB with ring pulse ────────────────────────────────────────────────────

  Widget _buildFAB() {
    return Positioned(
      right: 20,
      bottom: 88 + 16,
      child: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ringpulse: scale .75 → 1.9, opacity .55 → 0
            AnimatedBuilder(
              animation: _fab,
              builder: (context, child) {
                final v = _fab.value;
                final scale = 0.75 + (1.9 - 0.75) * v;
                final opacity = v >= 0.7 ? 0.0 : 0.55 * (1 - v / 0.7);
                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Solid FAB
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.7),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────

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
      // handle
      ..moveTo(13, 50)
      ..lineTo(13, 108)
      // three tines
      ..moveTo(5, 6)
      ..lineTo(5, 26)
      ..moveTo(13, 6)
      ..lineTo(13, 26)
      ..moveTo(21, 6)
      ..lineTo(21, 26)
      // tine base
      ..moveTo(5, 26)
      ..cubicTo(5, 32, 8.6, 35, 13, 35)
      ..cubicTo(17.4, 35, 21, 32, 21, 26)
      // neck
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

    // blade
    final blade = Path()
      ..moveTo(10, 6)
      ..cubicTo(4, 12, 4, 48, 10, 56)
      ..cubicTo(15, 49, 15, 13, 10, 6)
      ..close();
    canvas.drawPath(blade, fill);
    canvas.drawPath(blade, stroke);

    // handle
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
    // viewBox 24x24 scaled to the given size
    final s = size.width / 24.0;
    canvas.scale(s, s);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const r = Radius.circular(3.2);

    // Puffy top: from (7,14) up and over to (17,14)
    final top = Path()
      ..moveTo(7, 14)
      ..arcToPoint(const Offset(6, 7.8), radius: r, clockwise: true)
      ..arcToPoint(const Offset(11, 6), radius: r, clockwise: true)
      ..arcToPoint(const Offset(17, 7.8), radius: r, clockwise: true)
      ..arcToPoint(const Offset(17, 14), radius: r, clockwise: true);
    canvas.drawPath(top, paint);

    // Band (rounded rect 7,14 → 17,19)
    final band = Path()
      ..moveTo(7, 14)
      ..lineTo(17, 14)
      ..lineTo(17, 19)
      ..lineTo(7, 19)
      ..close();
    canvas.drawPath(band, paint);

    // Two pleats on the band
    canvas.drawLine(const Offset(9.5, 19), const Offset(9.5, 16), paint);
    canvas.drawLine(const Offset(14.5, 19), const Offset(14.5, 16), paint);
  }

  @override
  bool shouldRepaint(covariant _ChefHatPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

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
      final startAngle = i * dashArc;
      final sweepAngle = dashArc * (1 - gapFraction);
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
