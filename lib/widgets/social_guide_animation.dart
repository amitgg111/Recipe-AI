import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/widgets/app_wordmark.dart';

/// Which social platform's first slide to show.
enum GuidePlatform { instagram, tiktok, facebook }

/// Auto-cross-fading 3-slide "how to share" illustration matching the HTML
/// guide design: slide 0 (tap send) → slide 1 (tap share to) → slide 2
/// (tap Recipe AI), looping every 9s, with animated progress dots.
///
/// Slide 0 is platform-specific (Instagram post / TikTok video / Facebook
/// post); slides 1 and 2 are shared across platforms.
class SocialGuideAnimation extends StatefulWidget {
  final GuidePlatform platform;

  const SocialGuideAnimation({super.key, required this.platform});

  @override
  State<SocialGuideAnimation> createState() => _SocialGuideAnimationState();
}

class _SocialGuideAnimationState extends State<SocialGuideAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  static const _accent = Color(0xFFF2623E); // highlight ring
  static const _arrow = Color(0xFF3B7DE0); // arrow + label
  static const _foodUrl =
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&q=80&auto=format&fit=crop';

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 9))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Opacity of slide [i] (0..2) for the current loop position — a 3-window
  // crossfade (each slide owns 1/3 of the timeline, fading at its edges).
  double _slideOpacity(int i) {
    double d = _c.value - i / 3.0;
    d -= d.floorToDouble(); // wrap into [0,1)
    if (d >= 1 / 3) return 0;
    final local = d * 3; // 0..1 within this slide's window
    const fade = 0.14;
    if (local < fade) return local / fade;
    if (local > 1 - fade) return (1 - local) / fade;
    return 1;
  }

  int get _activeDot => (_c.value * 3).floor() % 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Opacity(opacity: _slideOpacity(0), child: _slide0()),
                  Opacity(opacity: _slideOpacity(1), child: _slide1()),
                  Opacity(opacity: _slideOpacity(2), child: _slide2()),
                ],
              );
            },
          ),
        ),
        // Progress dots
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 14),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final active = _activeDot;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final on = i == active;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: on ? 20 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3.5),
                    decoration: BoxDecoration(
                      color: on
                          ? const Color(0xFF2A211B)
                          : const Color(0xFFE2D8C7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Shared pieces ─────────────────────────────────────────────────────────

  Widget _food({double? width, double? height, BoxFit fit = BoxFit.cover}) {
    return Image.network(
      _foodUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEDE5D7)),
      loadingBuilder: (_, child, p) =>
          p == null ? child : Container(color: const Color(0xFFEDE5D7)),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 25,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        color: _arrow,
        letterSpacing: -0.25,
      ),
    );
  }

  Widget _arrowDown() =>
      CustomPaint(size: const Size(110, 74), painter: _ArrowPainter());

  // ── Slide 0 — platform specific ───────────────────────────────────────────

  Widget _slide0() {
    switch (widget.platform) {
      case GuidePlatform.instagram:
        return _slideInstagram();
      case GuidePlatform.tiktok:
        return _slideTikTok();
      case GuidePlatform.facebook:
        return _slideFacebook();
    }
  }

  Widget _slideInstagram() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              width: double.infinity,

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEFE6D6)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A211B).withValues(alpha: 0.45),
                    blurRadius: 38,
                    offset: const Offset(0, 20),
                    spreadRadius: -20,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFEDA77),
                                Color(0xFFDD2A7B),
                                Color(0xFF8134AF),
                              ],
                              stops: [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'recipe.app',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2A211B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 170, width: double.infinity, child: _food()),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.favorite_border,
                          size: 22,
                          color: Color(0xFF2A211B),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 20,
                          color: Color(0xFF2A211B),
                        ),
                        const SizedBox(width: 16),
                        _highlightRing(
                          size: 30,
                          child: const Icon(
                            Icons.send,
                            size: 15,
                            color: Color(0xFF2A211B),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.bookmark_border,
                          size: 22,
                          color: Color(0xFF2A211B),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 250,
          left: 150,
          child: Transform.rotate(angle: 0.3, child: _arrowDown()),
        ),
        Positioned(top: 300, left: 96, child: _label('tap send')),
      ],
    );
  }

  Widget _slideTikTok() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: double.infinity,
                height: 288,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(opacity: 0.82, child: _food()),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x1F000000), Color(0x80000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 11,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@recipe.app',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Container(
                            width: 88,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 9,
                      bottom: 16,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.favorite_border,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(height: 15),
                          const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(height: 15),
                          const Icon(
                            Icons.bookmark_border,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(height: 15),
                          _highlightRing(
                            size: 38,
                            fill: _accent.withValues(alpha: 0.32),
                            child: const Icon(
                              Icons.send,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 250,
          left: 150,
          child: Transform.rotate(angle: 0.35, child: _arrowDown()),
        ),
        Positioned(top: 300, left: 40, child: _label('tap send')),
      ],
    );
  }

  Widget _slideFacebook() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEAE6DE)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A211B).withValues(alpha: 0.45),
                    blurRadius: 38,
                    offset: const Offset(0, 20),
                    spreadRadius: -20,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1877F2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 84,
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE1ECFA),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFEBE3),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 170, width: double.infinity, child: _food()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _fbAction(
                          Icons.favorite_border,
                          'Like',
                          const Color(0xFF65676B),
                        ),
                        _fbAction(
                          Icons.chat_bubble_outline,
                          'Comment',
                          const Color(0xFF65676B),
                        ),
                        _highlightRing(
                          radius: 11,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.reply,
                                size: 14,
                                color: Color(0xFF1877F2),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'share'.tr,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1877F2),
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
            ),
          ),
        ),
        Positioned(
          top: 256,
          left: 120,
          child: Transform.rotate(angle: 0.3, child: _arrowDown()),
        ),
        Positioned(top: 296, left: 110, child: _label('tap send')),
      ],
    );
  }

  Widget _fbAction(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Slide 1 — the share sheet (shared) ────────────────────────────────────

  Widget _slide1() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: SizedBox(width: 300, height: 120, child: _food()),
              ),
              Transform.translate(
                offset: const Offset(0, -10),
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2A211B).withValues(alpha: 0.5),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                        spreadRadius: -18,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 34,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7E0D2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 30,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1EEE9),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.search,
                                size: 16,
                                color: Color(0xFFB0A899),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1EEE9),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(3, (_) => _circle(44)),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _dashedCircle(38),
                          Column(
                            children: [
                              _highlightRing(
                                size: 46,
                                child: const Icon(
                                  Icons.upload,
                                  size: 20,
                                  color: Color(0xFF2A211B),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'share_to'.tr,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8A7E70),
                                ),
                              ),
                            ],
                          ),
                          _circle(38),
                          _circle(38, color: const Color(0xFF25D366)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 300,
          left: 30,
          child: Transform.rotate(angle: -0.15, child: _arrowDown()),
        ),
        Positioned(top: 330, left: 120, child: _label('tap share to')),
      ],
    );
  }

  // ── Slide 2 — destinations, Recipe AI highlighted (shared) ────────────────

  Widget _slide2() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 300,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A211B).withValues(alpha: 0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    spreadRadius: -18,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 96,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEBE3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F3EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: _food(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE7E0D2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(height: 6),
                              FractionallySizedBox(
                                widthFactor: 0.55,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFEBE3),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (_) => _circle(42)),
                  ),
                  const SizedBox(height: 14),
                  Container(height: 1, color: const Color(0xFFF0ECE4)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _destGmail(),
                      Column(
                        children: [
                          _highlightRing(
                            size: 46,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _accent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(
                                Icons.restaurant_menu,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const AppWordmark(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ],
                      ),
                      _circle(
                        42,
                        color: const Color(0xFF2D6FE0),
                        child: const Icon(
                          Icons.chat_bubble,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      _circle(
                        42,
                        child: const Icon(
                          Icons.change_history,
                          size: 20,
                          color: Color(0xFF5A9E5E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 258,
          left: 150,
          child: Transform.rotate(angle: -0.5, child: _arrowDown()),
        ),
        Positioned(top: 360, left: 96, child: _label('tap Recipe AI')),
      ],
    );
  }

  Widget _destGmail() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFEFE6D6)),
      ),
      alignment: Alignment.center,
      child: Text(
        'M',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFD44638),
        ),
      ),
    );
  }

  // ── Small building blocks ─────────────────────────────────────────────────

  Widget _highlightRing({
    double? size,
    double radius = 23,
    Color fill = const Color(0xFFFDEEE8),
    EdgeInsets? padding,
    required Widget child,
  }) {
    return Container(
      width: size,
      height: size,
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(size != null ? size / 2 : radius),
        border: Border.all(color: _accent, width: 2.5),
      ),
      child: child,
    );
  }

  Widget _circle(
    double d, {
    Color color = const Color(0xFFEFEBE3),
    Widget? child,
  }) {
    return Container(
      width: d,
      height: d,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: child,
    );
  }

  Widget _dashedCircle(double d) {
    return CustomPaint(size: Size(d, d), painter: _DashedCircleBorder());
  }
}

/// Curved arrow pointing to a highlighted target (matches the guide arrows).
class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B7DE0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width, h = size.height;
    // curve from top-right down to bottom-left
    final path = Path()
      ..moveTo(w * 0.92, h * 0.1)
      ..cubicTo(w * 0.6, h * 0.15, w * 0.25, h * 0.35, w * 0.15, h * 0.85);
    canvas.drawPath(path, paint);
    // arrowhead at the end (bottom-left)
    final end = Offset(w * 0.15, h * 0.85);
    final head = Path()
      ..moveTo(end.dx - 1, end.dy - 15)
      ..lineTo(end.dx, end.dy)
      ..lineTo(end.dx + 13, end.dy - 8);
    canvas.drawPath(head, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedCircleBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8D0C2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashCount = 22;
    const dashArc = math.pi * 2 / dashCount;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * dashArc,
        dashArc * 0.55,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
