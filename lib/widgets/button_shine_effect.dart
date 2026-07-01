import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A reusable premium "gloss/shine" overlay.
///
/// Wraps any widget (typically a button) and paints a soft, semi-transparent
/// white highlight that sweeps diagonally across it — starting off the left
/// edge, exiting off the right — then pauses briefly and repeats forever.
///
/// Design notes:
/// * Only the thin shine layer animates via [AnimatedBuilder] + [Transform.translate].
///   The wrapped [child] never rebuilds, and the moving layer is isolated in a
///   [RepaintBoundary], so it stays GPU-friendly at 60fps.
/// * The overlay is wrapped in [IgnorePointer], so taps pass straight through
///   to the [child] — the button's `onPressed`/logic is untouched.
/// * The shine is clipped to [borderRadius] so it respects the button's corners.
class ButtonShineEffect extends StatefulWidget {
  /// The widget to overlay the shine on (e.g. the existing button).
  final Widget child;

  /// Must match the wrapped button's corner radius so the shine is clipped
  /// exactly inside the button.
  final BorderRadius borderRadius;

  /// How long the highlight takes to travel across the button.
  final Duration sweepDuration;

  /// The idle gap between sweeps (the shine sits off-screen during this time).
  final Duration pauseDuration;

  /// Fraction of the button width the highlight occupies (≈ 0.20–0.30).
  final double widthFactor;

  /// Peak opacity of the white highlight (soft edges fade to 0).
  final double maxOpacity;

  /// Diagonal tilt of the highlight, in degrees.
  final double angleDegrees;

  /// When false, the shine is hidden and the animation is paused (e.g. while the
  /// button is disabled).
  final bool enabled;

  const ButtonShineEffect({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.sweepDuration = const Duration(milliseconds: 1500),
    this.pauseDuration = const Duration(milliseconds: 1500),
    this.widthFactor = 0.28,
    this.maxOpacity = 0.45,
    this.angleDegrees = -16,
    this.enabled = true,
  });

  @override
  State<ButtonShineEffect> createState() => _ButtonShineEffectState();
}

class _ButtonShineEffectState extends State<ButtonShineEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sweep;

  @override
  void initState() {
    super.initState();
    _setUpController();
  }

  void _setUpController() {
    final total = widget.sweepDuration + widget.pauseDuration;
    _controller = AnimationController(vsync: this, duration: total);

    // The sweep occupies the first part of each cycle; the remainder is the
    // pause (during which the highlight is parked off the right edge). Because
    // the highlight is fully off-screen at both ends of the sweep, the loop
    // restart is invisible — no flicker, no abrupt jump.
    final sweepFraction = total.inMilliseconds == 0
        ? 1.0
        : widget.sweepDuration.inMilliseconds / total.inMilliseconds;

    _sweep = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, sweepFraction, curve: Curves.linear),
    );

    if (widget.enabled) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant ButtonShineEffect oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.sweepDuration != widget.sweepDuration ||
        oldWidget.pauseDuration != widget.pauseDuration) {
      _controller.dispose();
      _setUpController();
      return;
    }

    if (widget.enabled && !_controller.isAnimating) {
      _controller
        ..reset()
        ..repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The button — never rebuilt by this widget.
        widget.child,
        // The animated shine layer, clipped to the button's shape and
        // non-interactive so taps reach the button.
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: widget.borderRadius,
                child: widget.enabled
                    ? _buildShine()
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final bandWidth = w * widget.widthFactor;

        // Travel fully off the left edge to fully off the right edge. Extra
        // margin accounts for the diagonal tilt widening the footprint.
        final startX = -bandWidth * 2.2;
        final endX = w + bandWidth * 1.2;

        // Built once (not per frame): the tilted, soft-edged white band.
        final band = Align(
          alignment: Alignment.centerLeft,
          child: Transform.rotate(
            angle: widget.angleDegrees * math.pi / 180.0,
            child: Container(
              width: bandWidth,
              // Taller than the button so the tilt still covers the corners.
              height: h * 2.6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: widget.maxOpacity * 0.35),
                    Colors.white.withValues(alpha: widget.maxOpacity),
                    Colors.white.withValues(alpha: widget.maxOpacity * 0.35),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                ),
              ),
            ),
          ),
        );

        return AnimatedBuilder(
          animation: _sweep,
          builder: (context, child) {
            final dx = startX + (endX - startX) * _sweep.value;
            return Transform.translate(
              offset: Offset(dx, 0),
              child: child,
            );
          },
          child: band,
        );
      },
    );
  }
}
