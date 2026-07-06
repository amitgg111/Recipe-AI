import 'dart:async';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_logo.dart';

/// Import processing screen — matches the HTML "Import Processing" design:
/// a food-themed AI scan animation (orbiting produce around a pulsing
/// chef-hat), an animated gradient progress bar, and a live checklist.
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
    _orbit = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _bar = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat();

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
                    AppWordmark(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2),
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
          // radial glow
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
          // dashed orbit ring
          const CustomPaint(
            size: Size(188, 188),
            painter: _DashedCirclePainter(color: Color(0xFFE7DBC8)),
          ),
          // orbiting produce
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
                      _orbitItem(const Alignment(0, -1), '🍅', angle),
                      _orbitItem(const Alignment(1, 0), '🍋', angle),
                      _orbitItem(const Alignment(0, 1), '🥦', angle),
                      _orbitItem(const Alignment(-1, 0), '🧅', angle),
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

  Widget _orbitItem(Alignment align, String emoji, double angle) {
    return Align(
      alignment: align,
      child: Transform.rotate(
        angle: -angle, // keep upright
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }

  Widget _centerHat() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) {
              final v = _pulse.value;
              return Container(
                width: 88 * (1 + v * 0.7),
                height: 88 * (1 + v * 0.7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _c2.withValues(alpha: (1 - v) * 0.45),
                ),
              );
            },
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
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
            child: const AppLogoMark(size: 52),
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
                widthFactor: 0.08 + t * 0.92,
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
        icon = _badge(AppColors.greenBg, AppColors.green,
            const Icon(Icons.check_rounded, size: 16, color: AppColors.green));
        break;
      case _StepStatus.inProgress:
        icon = _badge(AppColors.redBg, AppColors.primary,
            const Icon(Icons.schedule_rounded, size: 15, color: AppColors.primary));
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
              fontWeight:
                  status == _StepStatus.pending ? FontWeight.w500 : FontWeight.w700,
              color: status == _StepStatus.pending
                  ? AppColors.textHint
                  : AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(Color bg, Color fg, Widget child) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
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
