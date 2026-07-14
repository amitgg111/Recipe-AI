import 'package:flutter/material.dart';

/// Reusable, premium-feeling animation primitives for the Nutrition flow.
///
/// All motion is intentionally subtle: easeOutCubic, 200–900 ms, no bounce or
/// flash. Built on the lightweight implicit widgets (TweenAnimationBuilder /
/// AnimatedScale) wherever possible so there are no stray controllers, with a
/// single controller only where a delay or a repeat is genuinely required.
const _kCurve = Curves.easeOutCubic;

/// Counts a number from its previous value to [value] whenever [value] changes
/// (and from 0 on first mount). Formats through [format] so it can group
/// thousands, add units, round, etc.
class AnimatedCounter extends StatelessWidget {
  final double value;
  final String Function(double) format;
  final TextStyle style;
  final Duration duration;
  final Curve curve;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.format,
    required this.style,
    this.duration = const Duration(milliseconds: 700),
    this.curve = _kCurve,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (_, v, __) => Text(
        format(v),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// A horizontal progress bar whose fill grows from 0 → [fraction] on mount
/// (and re-animates from the current width when [fraction] changes).
class AnimatedBar extends StatelessWidget {
  final double fraction;
  final Color track;
  final Color? fill;
  final Gradient? gradient;
  final double height;
  final double radius;
  final double minFraction;
  final Duration duration;

  const AnimatedBar({
    super.key,
    required this.fraction,
    required this.track,
    this.fill,
    this.gradient,
    this.height = 4,
    this.radius = 2,
    this.minFraction = 0.02,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: height,
        color: track,
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
                begin: 0, end: fraction.clamp(minFraction, 1.0)),
            duration: duration,
            curve: _kCurve,
            builder: (_, f, __) => FractionallySizedBox(
              widthFactor: f,
              child: Container(
                decoration: BoxDecoration(color: fill, gradient: gradient),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Entrance animation: fades in while sliding from [beginOffset] and scaling up
/// from [beginScale], after an optional [delay] (used to stagger a list).
class RevealIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;
  final double beginScale;

  const RevealIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.beginOffset = const Offset(0, 20),
    this.beginScale = 1.0,
  });

  /// Convenience: a soft scale-in (0.9 → 1.0) with fade, no slide.
  const RevealIn.scale({
    Key? key,
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 420),
    double beginScale = 0.9,
  }) : this(
          key: key,
          child: child,
          delay: delay,
          duration: duration,
          beginOffset: Offset.zero,
          beginScale: beginScale,
        );

  @override
  State<RevealIn> createState() => _RevealInState();
}

class _RevealInState extends State<RevealIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: _kCurve);
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (!_disposed) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (_, child) {
        final v = _t.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(
              widget.beginOffset.dx * (1 - v),
              widget.beginOffset.dy * (1 - v),
            ),
            child: Transform.scale(
              scale: widget.beginScale + (1 - widget.beginScale) * v,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Wraps a tappable area so it dips to [pressedScale] on press and springs back
/// — the standard 1.0 → 0.97 → 1.0 button feedback.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final HitTestBehavior behavior;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: widget.behavior,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: _kCurve,
        child: widget.child,
      ),
    );
  }
}

/// Softly pulses its child's opacity between 0.8 and 1.0 on a slow ~2.5 s loop.
/// Deliberately gentle — a premium "live" glow, not a blink.
class GlowPulse extends StatefulWidget {
  final Widget child;
  const GlowPulse({super.key, required this.child});

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  )..repeat(reverse: true);
  late final Animation<double> _o =
      Tween<double>(begin: 0.8, end: 1.0).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _o, child: widget.child);
}

/// Cross-fade + subtle vertical slide used when a value/label swaps between the
/// Per-serving and Whole-recipe modes.
class SwapTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;
  const SwapTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: _kCurve,
      switchOutCurve: _kCurve,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.18),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
