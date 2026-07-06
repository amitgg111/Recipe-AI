import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders the onboarding "line" icons from the exact SVG path data used by the
/// HTML design mock, so every onboarding screen shows identical, pixel-accurate
/// icons instead of approximate Material icons.
///
/// Style matches the HTML `sv(...)` helper: 24-unit viewBox, `fill:none`,
/// `stroke:currentColor`, round caps/joins, and each icon's own stroke width and
/// intrinsic render size (overridable via [size]).
class OnboardingLineIcon extends StatelessWidget {
  /// One of the keys in [_defs].
  final String name;

  /// Stroke (and, for filled sub-shapes, fill) colour.
  final Color color;

  /// Optional render size override; defaults to the icon's HTML size.
  final double? size;

  const OnboardingLineIcon(this.name, {super.key, required this.color, this.size});

  // Geometry copied verbatim from the HTML `I` icon set. `{c}` is replaced with
  // the icon colour for any filled sub-shapes (e.g. the camera's lens dot).
  static const Map<String, ({String body, double size, double sw})> _defs = {
    'camera': (
      body:
          '<rect x="3" y="7" width="18" height="13" rx="4"/><circle cx="12" cy="13.5" r="3.4"/><circle cx="17" cy="10.5" r="1" fill="{c}" stroke="none"/>',
      size: 22,
      sw: 1.9,
    ),
    'music': (
      body:
          '<circle cx="7" cy="18" r="2.6"/><circle cx="17" cy="16" r="2.6"/><path d="M9.6 18V5l9.4-2v13"/>',
      size: 22,
      sw: 1.9,
    ),
    'chat': (
      body: '<path d="M4 6a1 1 0 0 1 1-1h14a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H9l-4 4z"/>',
      size: 22,
      sw: 1.9,
    ),
    'pin': (
      body: '<circle cx="12" cy="10" r="7"/><path d="M12 17v4"/>',
      size: 18,
      sw: 1.9,
    ),
    'play': (
      body: '<path d="M7 5l12 7-12 7z"/>',
      size: 20,
      sw: 1.6,
    ),
    'globe': (
      body:
          '<circle cx="12" cy="12" r="8"/><path d="M4 12h16M12 4c2.5 2.4 2.5 13.6 0 16M12 4c-2.5 2.4-2.5 13.6 0 16"/>',
      size: 20,
      sw: 1.9,
    ),
    'bowl': (
      body:
          '<path d="M3.5 11h17a8.5 8.5 0 0 1-17 0z"/><path d="M9 7.5c.6-.7.6-1.6 0-2.6M12.5 7.5c.6-.7.6-1.6 0-2.6M16 7.5c.6-.7.6-1.6 0-2.6"/>',
      size: 22,
      sw: 1.9,
    ),
    'wallet': (
      body:
          '<rect x="3" y="6" width="18" height="13" rx="3"/><path d="M16 12h3.5v3H16a1.5 1.5 0 0 1 0-3z"/>',
      size: 22,
      sw: 1.9,
    ),
    'hat': (
      body:
          '<path d="M7 14h10v5H7z"/><path d="M7 14a3.2 3.2 0 0 1-1-6.2A3.2 3.2 0 0 1 11 6a3.2 3.2 0 0 1 6 1.8A3.2 3.2 0 0 1 17 14"/>',
      size: 22,
      sw: 1.9,
    ),
    'folder': (
      body:
          '<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
      size: 22,
      sw: 1.9,
    ),
    'cal': (
      body:
          '<rect x="3" y="4.5" width="18" height="16" rx="2.5"/><path d="M3 9.5h18M8 2.5v4M16 2.5v4"/>',
      size: 22,
      sw: 1.9,
    ),
    'search': (
      body: '<circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/>',
      size: 22,
      sw: 1.9,
    ),
    'book': (
      body:
          '<path d="M5 4h12a1 1 0 0 1 1 1v15H7a2 2 0 0 1-2-2z"/><path d="M5 17a2 2 0 0 1 2-2h11"/>',
      size: 22,
      sw: 1.9,
    ),
    'pencil': (
      body:
          '<path d="M4 20h4l10.5-10.5a2.1 2.1 0 0 0-3-3L5 17z"/><path d="M13.5 6.5l3 3"/>',
      size: 18,
      sw: 1.9,
    ),
    'hatBig': (
      body:
          '<path d="M7 14h10v5H7z"/><path d="M7 14a3.2 3.2 0 0 1-1-6.2A3.2 3.2 0 0 1 11 6a3.2 3.2 0 0 1 6 1.8A3.2 3.2 0 0 1 17 14"/><path d="M9.5 19v-3M14.5 19v-3"/>',
      size: 44,
      sw: 1.7,
    ),
  };

  static String hex(Color c) {
    int ch(double v) => (v * 255).round().clamp(0, 255);
    String h(int v) => v.toRadixString(16).padLeft(2, '0');
    return '#${h(ch(c.r))}${h(ch(c.g))}${h(ch(c.b))}';
  }

  @override
  Widget build(BuildContext context) {
    final def = _defs[name]!;
    final h = hex(color);
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
        'stroke="$h" stroke-width="${def.sw}" stroke-linecap="round" '
        'stroke-linejoin="round">${def.body.replaceAll('{c}', h)}</svg>';
    final s = size ?? def.size;
    return SvgPicture.string(svg, width: s, height: s);
  }
}
