import 'package:flutter/material.dart';

/// The Recipe AI brand mark — a chef's hat with a sparkle.
///
/// Pixel-matched to the HTML design's `hatSvg` (viewBox `0 0 48 48`) and drawn
/// entirely with a [CustomPainter], so it needs no image asset and no extra
/// dependency (flutter_svg / icon_launcher etc.).
///
/// Defaults render the white-on-transparent variant used inside the orange
/// [AppLogo] badge. Pass custom colors for the light-on-dark splash variant.
class AppLogoMark extends StatelessWidget {
  /// Side length of the (square) mark in logical pixels.
  final double size;
  final Color hatColor;
  final Color bandColor;
  final Color pleatColor;
  final Color? sparkleColor;

  const AppLogoMark({
    super.key,
    required this.size,
    this.hatColor = Colors.white,
    this.bandColor = const Color(0xEBFFFFFF), // rgba(255,255,255,.92)
    this.pleatColor = const Color(0x80F2623E), // rgba(242,98,62,.5)
    this.sparkleColor = const Color(0xFFFFE3B0),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HatPainter(hatColor, bandColor, pleatColor, sparkleColor),
      ),
    );
  }
}

/// The full Recipe AI logo badge — an orange rounded square with the white
/// [AppLogoMark] centered inside. Matches the HTML `logoMark(sz)` helper.
class AppLogo extends StatelessWidget {
  /// Side length of the badge in logical pixels.
  final double size;

  const AppLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFF8763), Color(0xFFF2623E)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF2623E).withValues(alpha: 0.65),
            blurRadius: 14,
            offset: const Offset(0, 6),
            spreadRadius: -5,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: AppLogoMark(size: size * 0.68),
    );
  }
}

class _HatPainter extends CustomPainter {
  final Color hat;
  final Color band;
  final Color pleat;
  final Color? spark;

  const _HatPainter(this.hat, this.band, this.pleat, this.spark);

  @override
  void paint(Canvas canvas, Size size) {
    // Source coordinates are authored on a 48x48 grid.
    final s = size.width / 48.0;
    canvas.save();
    canvas.scale(s);

    // Puffy top of the chef's hat.
    final hatPath = Path()
      ..moveTo(14, 31)
      ..cubicTo(7, 31, 3.5, 24.5, 8.5, 20.5)
      ..cubicTo(4.5, 14.5, 11, 9.5, 16, 12.5)
      ..cubicTo(17, 5, 31, 5, 32, 12.5)
      ..cubicTo(37, 9.5, 43.5, 14.5, 39.5, 20.5)
      ..cubicTo(44.5, 24.5, 41, 31, 34, 31)
      ..close();
    canvas.drawPath(hatPath, Paint()..color = hat);

    // Hat band (base).
    final bandRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(13.5, 28.5, 21, 13.5),
      const Radius.circular(3.6),
    );
    canvas.drawRRect(bandRect, Paint()..color = band);

    // Three pleats on the band.
    final pleatPaint = Paint()
      ..color = pleat
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final x in const [19.0, 24.0, 29.0]) {
      canvas.drawLine(Offset(x, 32.5), Offset(x, 38), pleatPaint);
    }

    // Sparkle.
    if (spark != null) {
      final sparkPath = Path()
        ..moveTo(34.5, 8.5)
        ..lineTo(35.65, 11.85)
        ..lineTo(39, 13)
        ..lineTo(35.65, 14.15)
        ..lineTo(34.5, 17.5)
        ..lineTo(33.35, 14.15)
        ..lineTo(30, 13)
        ..lineTo(33.35, 11.85)
        ..close();
      canvas.drawPath(sparkPath, Paint()..color = spark!);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_HatPainter old) =>
      old.hat != hat ||
      old.band != band ||
      old.pleat != pleat ||
      old.spark != spark;
}
