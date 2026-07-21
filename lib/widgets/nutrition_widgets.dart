import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/widgets/nutrition_animations.dart';
import 'package:recipe_ai/widgets/tr_text.dart';

/// Shared palette for the Nutrition flow — pulled straight from the design.
class NutritionPalette {
  NutritionPalette._();
  static const bg = Color(0xFFFBF4EA);
  static const ink = Color(0xFF2A211B);
  static const purple = Color(0xFF8B5CF6);
  static const purpleDark = Color(0xFF6D3BD4);
  static const purpleDeep = Color(0xFF7A45E0);
  static const cardBorder = Color(0xFFEFE6D6);
  static const divider = Color(0xFFF4ECDF);
  static const factLabel = Color(0xFF5A5147);
  static const muted = Color(0xFFA89F90);
  static const noteGrey = Color(0xFF9A938A);
  static const macroLabel = Color(0xFF8A7E70);
  static const orange = Color(0xFFF2623E);

  // Macro colours: protein (pink), carbs (orange), fat (green) + light tracks.
  static const protein = Color(0xFFF08FB0);
  static const proteinTrack = Color(0xFFF4DCE6);
  static const carbs = Color(0xFFF2A24C);
  static const carbsTrack = Color(0xFFF8E6CF);
  static const fat = Color(0xFF7FD0A8);
  static const fatTrack = Color(0xFFD7EFE3);

  static const ingredientBarTrack = Color(0xFFF0EADD);
  static const ingredientIconBg = Color(0xFFF4EEFD);

  static TextStyle font(
          {required double size,
          FontWeight weight = FontWeight.w600,
          Color color = ink,
          double? height,
          double? letterSpacing}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
}

/// Small "crown · PLUS" badge used in nutrition headers and cards.
///
/// Pass [glow] to give it a slow, soft opacity pulse (premium "live" feel).
class PlusPill extends StatelessWidget {
  final Color background;
  final Color foreground;
  final bool glow;
  const PlusPill({
    super.key,
    required this.background,
    required this.foreground,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 12, color: foreground),
          const SizedBox(width: 4),
          Text('PLUS',
              style: NutritionPalette.font(
                  size: 10, weight: FontWeight.w800, color: foreground)),
        ],
      ),
    );
    return glow ? GlowPulse(child: pill) : pill;
  }
}

/// Big circular calorie ring (white on the purple header). Decorative fill
/// (matches the design's fixed ~75% arc); the number in the centre carries the
/// real value.
class NutritionRing extends StatelessWidget {
  final double size;

  /// Calorie value shown in the centre — counts up from 0 on load and animates
  /// old→new when the Per-serving / Whole-recipe mode changes.
  final double kcal;
  final String label;
  final double valueFontSize;
  final double progress;

  const NutritionRing({
    super.key,
    this.size = 172,
    required this.kcal,
    required this.label,
    this.valueFontSize = 42,
    this.progress = 0.75,
  });

  static String grouped(num v) {
    final s = v.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.814,
            height: size * 0.814,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          // Arc draws clockwise from 0 → progress on load.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, p, __) => CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(progress: p),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedCounter(
                value: kcal,
                duration: const Duration(milliseconds: 900),
                format: grouped,
                style: NutritionPalette.font(
                    size: valueFontSize,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: -1),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: NutritionPalette.font(
                      size: 11,
                      weight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 13.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - stroke / 2 - 4;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.22);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.02, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// Conic macro donut used inside the recipe-detail preview card.
class MacroDonut extends StatelessWidget {
  final double size;
  final double calories;
  final String unit;

  /// Fractions in [carbs, protein, fat] order (drawn orange, pink, green).
  final List<double> fractions;

  const MacroDonut({
    super.key,
    this.size = 104,
    required this.calories,
    this.unit = 'kcal',
    required this.fractions,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(fractions),
          ),
          Container(
            width: size * 0.73,
            height: size * 0.73,
            decoration:
                const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedCounter(
                  value: calories,
                  format: (v) => v.round().toString(),
                  style: NutritionPalette.font(
                      size: 21,
                      weight: FontWeight.w800,
                      color: NutritionPalette.ink,
                      height: 1),
                ),
                Text(unit,
                    style: NutritionPalette.font(
                        size: 10,
                        weight: FontWeight.w700,
                        color: NutritionPalette.noteGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> fractions; // carbs, protein, fat
  _DonutPainter(this.fractions);

  static const _colors = [
    NutritionPalette.carbs,
    NutritionPalette.protein,
    NutritionPalette.fat,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    var start = -math.pi / 2;
    final total =
        fractions.fold<double>(0, (a, b) => a + (b.isNaN ? 0 : b));
    final norm = total <= 0
        ? const [1 / 3, 1 / 3, 1 / 3]
        : fractions.map((f) => f / total).toList();
    for (var i = 0; i < norm.length; i++) {
      final sweep = 2 * math.pi * norm[i];
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = _colors[i % _colors.length];
      canvas.drawArc(rect, start, sweep + 0.004, true, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.fractions != fractions;
}

/// Per serving / Whole recipe segmented toggle on the purple header.
class SegmentControl extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const SegmentControl({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final n = options.length;
    // Sliding pill: the selected white pill slides between segments (rather than
    // fading in/out per segment). Equal-width segments, so the pill is 1/n wide
    // and its alignment maps the index onto [-1, 1]. Same look/size as before.
    final align = n > 1 ? (2 * selectedIndex / (n - 1) - 1) : 0.0;
    const duration = Duration(milliseconds: 240);
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 36,
        child: Stack(
          children: [
            // Sliding white pill (behind the labels).
            Positioned.fill(
              child: AnimatedAlign(
                duration: duration,
                curve: Curves.easeInOut,
                alignment: Alignment(align, 0),
                child: FractionallySizedBox(
                  widthFactor: n > 0 ? 1 / n : 1,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
            ),
            // Tappable labels (on top).
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(i),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: duration,
                          style: NutritionPalette.font(
                            size: 13,
                            weight: i == selectedIndex
                                ? FontWeight.w800
                                : FontWeight.w700,
                            color: i == selectedIndex
                                ? NutritionPalette.purpleDark
                                : Colors.white.withValues(alpha: 0.85),
                          ),
                          child: Text(options[i]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// White macro chip: value · label · thin coloured progress bar. The value
/// counts smoothly and the bar grows from 0 on load.
class MacroCard extends StatelessWidget {
  final double grams;
  final String label;
  final Color track;
  final Color fill;
  final double fraction;

  const MacroCard({
    super.key,
    required this.grams,
    required this.label,
    required this.track,
    required this.fill,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: NutritionPalette.cardBorder),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A211B).withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 16),
            spreadRadius: -20,
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedCounter(
            value: grams,
            format: (v) => '${v.toStringAsFixed(1)}g',
            style: NutritionPalette.font(
                size: 20, weight: FontWeight.w800, color: NutritionPalette.ink),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: NutritionPalette.font(
                  size: 11,
                  weight: FontWeight.w700,
                  color: NutritionPalette.macroLabel)),
          const SizedBox(height: 9),
          AnimatedBar(fraction: fraction, track: track, fill: fill),
        ],
      ),
    );
  }
}

/// One row in the "Full facts" card. The value counts smoothly when the
/// Per-serving / Whole-recipe mode changes.
class FactTile extends StatelessWidget {
  final String label;
  final double value;
  final String Function(double) format;
  final bool showDivider;

  const FactTile({
    super.key,
    required this.label,
    required this.value,
    required this.format,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: NutritionPalette.divider))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: NutritionPalette.font(
                    size: 14,
                    weight: FontWeight.w600,
                    color: NutritionPalette.factLabel)),
          ),
          AnimatedCounter(
            value: value,
            format: format,
            style: NutritionPalette.font(
                size: 14, weight: FontWeight.w800, color: NutritionPalette.ink),
          ),
        ],
      ),
    );
  }
}

/// One ingredient row on the per-ingredient screen.
class IngredientNutritionTile extends StatelessWidget {
  final String name;
  final double kcal;
  final double fraction;
  final bool showDivider;

  const IngredientNutritionTile({
    super.key,
    required this.name,
    required this.kcal,
    required this.fraction,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: NutritionPalette.divider))
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: NutritionPalette.ingredientIconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.shopping_basket_rounded,
                    size: 16, color: NutritionPalette.purple),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TrText(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NutritionPalette.font(
                        size: 14,
                        weight: FontWeight.w700,
                        color: NutritionPalette.ink)),
              ),
              const SizedBox(width: 8),
              AnimatedCounter(
                value: kcal,
                format: (v) => '${v.round()} kcal',
                style: NutritionPalette.font(
                    size: 14,
                    weight: FontWeight.w800,
                    color: NutritionPalette.purpleDeep),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: AnimatedBar(
              fraction: fraction,
              minFraction: 0.03,
              track: NutritionPalette.ingredientBarTrack,
              gradient: const LinearGradient(colors: [
                NutritionPalette.purple,
                NutritionPalette.purpleDark,
              ]),
              height: 7,
              radius: 4,
              duration: const Duration(milliseconds: 700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width purple gradient CTA with a trailing chevron.
class NutritionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const NutritionButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [NutritionPalette.purple, NutritionPalette.purpleDark],
          ),
          boxShadow: [
            BoxShadow(
              color: NutritionPalette.purple.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: -12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: NutritionPalette.font(
                    size: 14, weight: FontWeight.w700, color: Colors.white)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// AI disclaimer row (sparkle + muted text).
class NutritionDisclaimer extends StatelessWidget {
  final String text;
  const NutritionDisclaimer({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, size: 14, color: NutritionPalette.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: NutritionPalette.font(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: NutritionPalette.muted)),
          ),
        ],
      ),
    );
  }
}
