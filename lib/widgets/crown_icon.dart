import 'package:flutter/material.dart';

/// The Plus / subscription mark — a clean, classic royal crown with three
/// jewel-tipped spikes on a gently curved band.
///
/// Drawn entirely with a [CustomPainter] so it stays crisp at any size (the
/// tiny 14px "PLUS" header badge as well as the large paywall tile) and needs
/// no image asset or brand-icon dependency.
class CrownIcon extends StatelessWidget {
  /// Side length of the (square) icon in logical pixels.
  final double size;
  final Color color;

  const CrownIcon({super.key, required this.size, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CrownIconPainter(color)),
    );
  }
}

class _CrownIconPainter extends CustomPainter {
  final Color color;
  const _CrownIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.round;

    // Spike apexes (a jewel sits on each); the centre spike is the tallest.
    final leftApex = Offset(0.14 * w, 0.37 * h);
    final midApex = Offset(0.50 * w, 0.15 * h);
    final rightApex = Offset(0.86 * w, 0.37 * h);

    // Valleys between the spikes.
    final leftValley = Offset(0.32 * w, 0.55 * h);
    final rightValley = Offset(0.68 * w, 0.55 * h);

    // Solid band with a gently curved bottom; the sides taper in a touch for
    // the classic flared-crown silhouette.
    final body = Path()
      ..moveTo(0.17 * w, 0.83 * h)
      ..lineTo(leftApex.dx, leftApex.dy)
      ..lineTo(leftValley.dx, leftValley.dy)
      ..lineTo(midApex.dx, midApex.dy)
      ..lineTo(rightValley.dx, rightValley.dy)
      ..lineTo(rightApex.dx, rightApex.dy)
      ..lineTo(0.83 * w, 0.83 * h)
      ..quadraticBezierTo(0.50 * w, 0.90 * h, 0.17 * w, 0.83 * h)
      ..close();
    canvas.drawPath(body, paint);

    // Rounded jewels on the three spike tips.
    final r = 0.075 * w;
    canvas.drawCircle(leftApex, r, paint);
    canvas.drawCircle(midApex, r, paint);
    canvas.drawCircle(rightApex, r, paint);
  }

  @override
  bool shouldRepaint(covariant _CrownIconPainter old) => old.color != color;
}
