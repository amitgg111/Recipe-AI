import 'dart:async';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

/// Import processing screen — a pixel match of the HTML "Reading your recipe"
/// design: orbiting CSS-drawn produce around a pulsing chef-hat, an animated
/// gradient progress bar, and a live checklist.
class ImportProcessingScreen extends StatefulWidget {
  final List<String> steps;

  const ImportProcessingScreen({
    super.key,
    this.steps = const [
      'Found recipe title',
      'Extracting ingredients',
      'Reading the steps',
      'Saving your recipe',
    ],
  });

  @override
  State<ImportProcessingScreen> createState() => ImportProcessingScreenState();
}

class ImportProcessingScreenState extends State<ImportProcessingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbit;
  late final AnimationController _pulse;
  late final AnimationController _bar;

  int _activeStep = 0;
  final List<_StepStatus> _status = [];
  Timer? _advance;

  static const _c1 = Color(0xFFFF8763);
  static const _c2 = Color(0xFFF2623E);

  @override
  void initState() {
    super.initState();
    // orbit 6s linear infinite (HTML @keyframes orbit / orbitr).
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    // ringpulse 2.2s ease-out infinite.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    // barfill 3.2s (8%→88%). Ping-pong keeps the fill seamless (no snap-reset).
    _bar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    for (var i = 0; i < widget.steps.length; i++) {
      _status.add(i == 0 ? _StepStatus.inProgress : _StepStatus.pending);
    }
    _scheduleAdvance();
  }

  void _scheduleAdvance() {
    _advance = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      if (_activeStep < widget.steps.length - 1) {
        setState(() {
          _status[_activeStep] = _StepStatus.completed;
          _activeStep++;
          _status[_activeStep] = _StepStatus.inProgress;
        });
        _scheduleAdvance();
      }
    });
  }

  @override
  void dispose() {
    _advance?.cancel();
    _orbit.dispose();
    _pulse.dispose();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
            child: Column(
              children: [
                // Brand: app logo + name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppLogo(size: 34),
                    const SizedBox(width: 9),
                    AppWordmark(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ],
                ),
                const SizedBox(height: 38),

                // Food-themed AI scan animation
                _scanAnimation(),

                const SizedBox(height: 34),
                Text(
                  'Reading your recipe…',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Our AI is pulling out every detail so you don't have to.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 22),

                _progressBar(),

                const SizedBox(height: 22),
                ...List.generate(
                  widget.steps.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _checkRow(widget.steps[i], _status[i]),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Scan animation ─────────────────────────────────────────────────────────

  Widget _scanAnimation() {
    return RepaintBoundary(
      child: SizedBox(
        width: 230,
        height: 230,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // radial glow (200×200)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _c2.withValues(alpha: 0.14),
                    _c2.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.66],
                ),
              ),
            ),
            // dashed orbit ring (188×188)
            const CustomPaint(
              size: Size(188, 188),
              painter: _DashedCirclePainter(color: Color(0xFFE7DBC8)),
            ),
            // orbiting produce (group rotates; each item counter-rotates upright)
            AnimatedBuilder(
              animation: _orbit,
              builder: (_, __) {
                final angle = _orbit.value * 2 * math.pi;
                return Transform.rotate(
                  angle: angle,
                  child: SizedBox(
                    width: 188,
                    height: 188,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _orbitFood(const Alignment(0, -1), angle, _tomato()),
                        _orbitFood(const Alignment(1, 0), angle, _lemon()),
                        _orbitFood(const Alignment(0, 1), angle, _broccoli()),
                        _orbitFood(const Alignment(-1, 0), angle, _onion()),
                      ],
                    ),
                  ),
                );
              },
            ),
            // center pulsing chef-hat
            _centerHat(),
          ],
        ),
      ),
    );
  }

  Widget _orbitFood(Alignment align, double angle, Widget food) {
    return Align(
      alignment: align,
      child: Transform.rotate(angle: -angle, child: food), // keep upright
    );
  }

  // ── CSS-drawn produce (verbatim shapes/colours from the HTML) ──────────────

  // Tomato: 30 circle, radial highlight, little green leaf.
  Widget _tomato() {
    return SizedBox(
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
                center: Alignment(-0.36, -0.4), // circle at 32% 30%
                radius: 0.85,
                colors: [Color(0xFFFF6F52), Color(0xFFE5402A)],
              ),
            ),
          ),
          Positioned(
            top: -4,
            left: 11,
            child: Transform.rotate(
              angle: 20 * math.pi / 180,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF3E8E4F),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ), // 50% 50% 50% 0
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Lemon: 32×24 ellipse.
  Widget _lemon() {
    return Container(
      width: 32,
      height: 24,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.elliptical(16, 12)),
        gradient: RadialGradient(
          center: Alignment(-0.36, -0.4),
          radius: 0.85,
          colors: [Color(0xFFFFE05A), Color(0xFFEBAE14)],
        ),
      ),
    );
  }

  // Broccoli: thin green stem + two florets.
  Widget _broccoli() {
    return SizedBox(
      width: 26,
      height: 26,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 7,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF3E8E4F),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            top: 1,
            left: 2,
            child: Transform.rotate(
              angle: -30 * math.pi / 180,
              child: _floret(
                const BorderRadius.only(
                  topLeft: Radius.circular(5.5),
                  topRight: Radius.circular(5.5),
                  bottomRight: Radius.circular(5.5),
                ),
              ), // 50% 50% 50% 0
            ),
          ),
          Positioned(
            top: 6,
            right: 2,
            child: Transform.rotate(
              angle: 30 * math.pi / 180,
              child: _floret(
                const BorderRadius.only(
                  topLeft: Radius.circular(5.5),
                  topRight: Radius.circular(5.5),
                  bottomLeft: Radius.circular(5.5),
                ),
              ), // 50% 50% 0 50%
            ),
          ),
        ],
      ),
    );
  }

  Widget _floret(BorderRadius radius) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: const Color(0xFF54B069),
        borderRadius: radius,
      ),
    );
  }

  // Onion/garlic bulb: 28×30 with an asymmetric bulb radius.
  Widget _onion() {
    return Container(
      width: 28,
      height: 30,
      decoration: const BoxDecoration(
        // 50% 50% 48% 48% / 60% 60% 40% 40%
        borderRadius: BorderRadius.only(
          topLeft: Radius.elliptical(14, 18),
          topRight: Radius.elliptical(14, 18),
          bottomRight: Radius.elliptical(13.44, 12),
          bottomLeft: Radius.elliptical(13.44, 12),
        ),
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.4), // circle at 35% 30%
          radius: 0.85,
          colors: [Colors.white, Color(0xFFEFE6D6)],
        ),
      ),
    );
  }

  Widget _centerHat() {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ringpulse: single expanding solid circle behind the hat
          // (scale .75→1.9, opacity .55→0 by 70%, 2.2s ease-out). It starts
          // smaller than the 88px hat, so each loop restart hides behind it.
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) {
              final t = Curves.easeOut.transform(_pulse.value);
              final scale = 0.75 + (1.9 - 0.75) * t;
              final opacity = t < 0.7 ? 0.55 * (1 - t / 0.7) : 0.0;
              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _c2,
                    ),
                  ),
                ),
              );
            },
          ),
          // hat tile (160° gradient) with the white chef-hat line icon
          Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment(-0.342, -0.940), // 160deg
                end: Alignment(0.342, 0.940),
                colors: [_c1, _c2],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: _c2.withValues(alpha: 0.7),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                  spreadRadius: -10,
                ),
              ],
            ),
            child: const OnboardingLineIcon(
              'hatBig',
              color: Colors.black,
              size: 46,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Progress bar ─────────────────────────────────────────────────────────

  Widget _progressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 8,
        color: const Color(0xFFEEE3D2),
        child: AnimatedBuilder(
          animation: _bar,
          builder: (_, __) {
            final t = Curves.easeInOut.transform(_bar.value);
            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.08 + t * 0.80, // 8% → 88%
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_c1, _c2]),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Checklist row ─────────────────────────────────────────────────────────

  Widget _checkRow(String label, _StepStatus status) {
    late Widget icon;
    switch (status) {
      case _StepStatus.completed:
        // green pill + check (HTML #DBF0E7 / #1F7A5E)
        icon = _pill(
          const Color(0xFFDBF0E7),
          const OnboardingLineIcon('check', color: Color(0xFF1F7A5E), size: 15),
        );
        break;
      case _StepStatus.inProgress:
        // orange pill + clock (HTML #FCE3DB / #F2623E)
        icon = _pill(
          const Color(0xFFFCE3DB),
          const OnboardingLineIcon('clock', color: Color(0xFFF2623E), size: 15),
        );
        break;
      case _StepStatus.pending:
        icon = Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surfaceBorder, width: 2),
          ),
        );
        break;
    }

    return Row(
      children: [
        icon,
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: status == _StepStatus.pending
                  ? FontWeight.w500
                  : FontWeight.w700,
              color: status == _StepStatus.pending
                  ? AppColors.textHint
                  : const Color(0xFF2A211B),
            ),
          ),
        ),
      ],
    );
  }

  // 26×26 rounded-13 pill with a centered icon.
  Widget _pill(Color bg, Widget child) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

enum _StepStatus { pending, inProgress, completed }

/// Dashed circle outline used behind the orbiting produce.
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashCount = 46;
    const gapRatio = 0.45;
    const sweep = (2 * math.pi) / dashCount;
    const dash = sweep * (1 - gapRatio);
    for (var i = 0; i < dashCount; i++) {
      final start = i * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        dash,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}
