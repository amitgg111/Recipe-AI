import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders the app's "line" icons from the exact SVG path data used by the HTML
/// design mock, so every screen shows identical, pixel-accurate icons instead of
/// approximate Material icons.
///
/// This registry is a 1:1 mirror of the HTML `I` icon set. Each entry keeps the
/// HTML icon's own path geometry, intrinsic render [size] and stroke width.
///
/// Stroked icons match the HTML `sv(...)` helper: 24-unit viewBox, `fill:none`,
/// `stroke:currentColor`, round caps/joins. Filled icons match `sf(...)`:
/// `fill:currentColor`, `stroke:none` — expressed here with `fill="{c}"
/// stroke="none"` on the shape(s), where `{c}` is replaced with [color].
class OnboardingLineIcon extends StatelessWidget {
  /// One of the keys in [_defs].
  final String name;

  /// Stroke (and, for filled sub-shapes, fill) colour.
  final Color color;

  /// Optional render size override; defaults to the icon's HTML size.
  final double? size;

  const OnboardingLineIcon(this.name, {super.key, required this.color, this.size});

  // Geometry copied verbatim from the HTML `I` icon set. `{c}` is replaced with
  // the icon colour for any filled shapes (fill:currentColor in the HTML).
  static const Map<String, ({String body, double size, double sw})> _defs = {
    // ── Navigation / chevrons ────────────────────────────────────────────────
    'back': (body: '<path d="M15 18l-6-6 6-6"/>', size: 22, sw: 1.9),
    'chevR': (body: '<path d="M9 6l6 6-6 6"/>', size: 18, sw: 1.9),
    'chevDown': (body: '<path d="M6 9l6 6 6-6"/>', size: 18, sw: 1.9),
    'x': (body: '<path d="M6 6l12 12M18 6L6 18"/>', size: 20, sw: 1.9),
    'sort': (
      body: '<path d="M7 4v16M7 4L4 7M7 4l3 3M17 20V4M17 20l-3-3M17 20l3-3"/>',
      size: 16,
      sw: 1.9,
    ),
    'swap': (
      body:
          '<path d="M7 4l-3 3 3 3"/><path d="M4 7h11a4 4 0 0 1 4 4"/><path d="M17 20l3-3-3-3"/><path d="M20 17H9a4 4 0 0 1-4-4"/>',
      size: 20,
      sw: 1.9,
    ),
    'plus': (body: '<path d="M12 5v14M5 12h14"/>', size: 26, sw: 2.3),
    'minus': (body: '<path d="M5 12h14"/>', size: 20, sw: 2.2),
    'check': (body: '<path d="M5 12l5 5 9-11"/>', size: 18, sw: 2.4),
    'checkCircle': (
      body: '<circle cx="12" cy="12" r="9"/><path d="M8 12l3 3 5-6"/>',
      size: 22,
      sw: 1.9,
    ),

    // ── Time / status ────────────────────────────────────────────────────────
    'clock': (
      body: '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5v5l3.2 2"/>',
      size: 15,
      sw: 1.9,
    ),
    'timerR': (
      body: '<path d="M4 12a8 8 0 1 1 2.4 5.7"/><path d="M4 18v-4h4"/>',
      size: 22,
      sw: 1.9,
    ),
    'play': (body: '<path d="M8 5v14l11-7z" fill="{c}" stroke="none"/>', size: 20, sw: 1.9),
    'pause': (body: '<path d="M9 5v14M15 5v14"/>', size: 20, sw: 2),
    'flame': (
      body:
          '<path d="M12 3c3 3.5 5 6 5 9a5 5 0 0 1-10 0c0-1.6.7-3 2-4 .3 1.2 1 2 2 2.2C12 9 11 6 12 3z"/>',
      size: 22,
      sw: 1.9,
    ),

    // ── Privacy / security ───────────────────────────────────────────────────
    'lock': (
      body:
          '<rect x="5" y="10.5" width="14" height="10" rx="3"/><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5"/>',
      size: 20,
      sw: 1.9,
    ),
    'lockF': (
      body:
          '<rect x="5" y="10.5" width="14" height="10" rx="3"/><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5"/>',
      size: 22,
      sw: 1.9,
    ),
    'lockLg': (
      body:
          '<rect x="5" y="10.5" width="14" height="10" rx="3"/><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5"/>',
      size: 28,
      sw: 1.8,
    ),
    'shield': (
      body:
          '<path d="M12 3l7 3v5c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6z"/><path d="M9 12l2 2 4-4"/>',
      size: 20,
      sw: 1.9,
    ),
    'eye': (
      body:
          '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7z"/><circle cx="12" cy="12" r="3"/>',
      size: 20,
      sw: 1.9,
    ),

    // ── People ───────────────────────────────────────────────────────────────
    'user': (
      body: '<circle cx="12" cy="8" r="4"/><path d="M5 20a7 7 0 0 1 14 0"/>',
      size: 20,
      sw: 1.9,
    ),
    'friend': (
      body:
          '<circle cx="9" cy="8" r="3"/><path d="M3.5 20a5.5 5.5 0 0 1 11 0"/><circle cx="17" cy="9.5" r="2.3"/><path d="M16 20a5 5 0 0 1 5-2.4"/>',
      size: 22,
      sw: 1.9,
    ),

    // ── Edit / files ─────────────────────────────────────────────────────────
    'pencil': (
      body:
          '<path d="M4 20h4l10.5-10.5a2.1 2.1 0 0 0-3-3L5 17z"/><path d="M13.5 6.5l3 3"/>',
      size: 18,
      sw: 1.9,
    ),
    'pencil2': (
      body:
          '<path d="M4 20h4l10.5-10.5a2.1 2.1 0 0 0-3-3L5 17z"/><path d="M13.5 6.5l3 3"/>',
      size: 19,
      sw: 1.9,
    ),
    'image': (
      body:
          '<rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="M3 16l5-4 4 3 3-3 6 5"/><circle cx="8.5" cy="9.5" r="1.4"/>',
      size: 19,
      sw: 1.9,
    ),
    'file': (
      body:
          '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/><path d="M9 13h6M9 17h4"/>',
      size: 22,
      sw: 1.9,
    ),
    'copy': (
      body:
          '<rect x="9" y="9" width="11" height="11" rx="2.5"/><path d="M5 15V5a2 2 0 0 1 2-2h8"/>',
      size: 20,
      sw: 1.9,
    ),
    'print': (
      body:
          '<path d="M7 9V4h10v5"/><rect x="6" y="14" width="12" height="7" rx="1.5"/><path d="M5 9h14a2 2 0 0 1 2 2v4h-3M5 15H3v-4a2 2 0 0 1 2-2"/><path d="M9 17h6"/>',
      size: 20,
      sw: 1.9,
    ),
    'trash': (
      body:
          '<path d="M5 7h14M10 7V5a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v2M7 7l1 12a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1l1-12"/>',
      size: 19,
      sw: 1.9,
    ),
    'trashLg': (
      body:
          '<path d="M5 7h14M10 7V5a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v2M7 7l1 12a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1l1-12M10 11v5M14 11v5"/>',
      size: 30,
      sw: 1.8,
    ),

    // ── Communication ────────────────────────────────────────────────────────
    'mail': (
      body: '<rect x="3" y="5" width="18" height="14" rx="3"/><path d="M4 7l8 6 8-6"/>',
      size: 20,
      sw: 1.9,
    ),
    'send': (body: '<path d="M22 2L11 13M22 2l-7 20-4-9-9-4z"/>', size: 20, sw: 1.9),
    'chat': (
      body: '<path d="M4 6a1 1 0 0 1 1-1h14a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H9l-4 4z"/>',
      size: 22,
      sw: 1.9,
    ),
    'comment': (
      body: '<path d="M21 11.5a8 8 0 0 1-11.5 7.2L4 20l1.3-5A8 8 0 1 1 21 11.5z"/>',
      size: 24,
      sw: 1.9,
    ),
    'share': (
      body:
          '<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="M8.6 13.5l6.8 4M15.4 6.5l-6.8 4"/>',
      size: 22,
      sw: 1.9,
    ),

    // ── Bell / flags ─────────────────────────────────────────────────────────
    'bell': (
      body:
          '<path d="M6 9a6 6 0 0 1 12 0c0 5 2 7 2 7H4s2-2 2-7z"/><path d="M10 21a2 2 0 0 0 4 0"/>',
      size: 30,
      sw: 1.7,
    ),
    'bellSm': (
      body:
          '<path d="M6 9a6 6 0 0 1 12 0c0 5 2 7 2 7H4s2-2 2-7z"/><path d="M10 21a2 2 0 0 0 4 0"/>',
      size: 20,
      sw: 1.9,
    ),
    'flag': (body: '<path d="M5 21V4M5 4h11l-2 4 2 4H5"/>', size: 20, sw: 1.9),

    // ── Bookmarks ────────────────────────────────────────────────────────────
    'bookmark': (
      body: '<path d="M6 4h12a1 1 0 0 1 1 1v15l-7-4-7 4V5a1 1 0 0 1 1-1z"/>',
      size: 20,
      sw: 1.9,
    ),
    'bookmark2': (
      body: '<path d="M6 4h12a1 1 0 0 1 1 1v15l-7-4-7 4V5a1 1 0 0 1 1-1z"/>',
      size: 22,
      sw: 1.9,
    ),

    // ── Navigation icons (bottom bar / discovery) ────────────────────────────
    'compass': (
      body: '<circle cx="12" cy="12" r="9"/><path d="M15.5 8.5l-2 5-5 2 2-5z"/>',
      size: 26,
      sw: 1.9,
    ),
    'cart': (
      body:
          '<circle cx="9" cy="20" r="1.5"/><circle cx="18" cy="20" r="1.5"/><path d="M3 4h2l2.3 12a1 1 0 0 0 1 .8h8.2a1 1 0 0 0 1-.8L20 8H6"/>',
      size: 22,
      sw: 1.9,
    ),
    'basket': (
      body:
          '<path d="M5 10l2-5M19 10l-2-5M3 10h18l-1.4 8.2a2 2 0 0 1-2 1.8H6.4a2 2 0 0 1-2-1.8z"/><path d="M9 14v2M15 14v2"/>',
      size: 17,
      sw: 1.9,
    ),
    'search': (
      body: '<circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/>',
      size: 22,
      sw: 1.9,
    ),
    'cal': (
      body:
          '<rect x="3" y="4.5" width="18" height="16" rx="2.5"/><path d="M3 9.5h18M8 2.5v4M16 2.5v4"/>',
      size: 22,
      sw: 1.9,
    ),
    'folder': (
      body:
          '<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
      size: 22,
      sw: 1.9,
    ),
    'book': (
      body:
          '<path d="M5 4h12a1 1 0 0 1 1 1v15H7a2 2 0 0 1-2-2z"/><path d="M5 17a2 2 0 0 1 2-2h11"/>',
      size: 22,
      sw: 1.9,
    ),
    'pin': (body: '<circle cx="12" cy="10" r="7"/><path d="M12 17v4"/>', size: 18, sw: 1.9),

    // ── Globes ───────────────────────────────────────────────────────────────
    'globe': (
      body:
          '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c2.8 2.6 2.8 15.4 0 18M12 3c-2.8 2.6-2.8 15.4 0 18"/>',
      size: 22,
      sw: 1.9,
    ),
    'globeG': (
      body:
          '<circle cx="12" cy="12" r="8"/><path d="M4 12h16M12 4c2.5 2.4 2.5 13.6 0 16M12 4c-2.5 2.4-2.5 13.6 0 16"/>',
      size: 20,
      sw: 1.9,
    ),

    // ── Settings / help ──────────────────────────────────────────────────────
    'ruler': (
      body: '<path d="M4 14L14 4l6 6L10 20z"/><path d="M8 8l2 2M11 5l2 2M5 11l2 2"/>',
      size: 20,
      sw: 1.9,
    ),
    'helpC': (
      body:
          '<circle cx="12" cy="12" r="9"/><path d="M9.5 9.5a2.5 2.5 0 0 1 4 1.8c0 1.5-2 2-2 3"/><circle cx="12" cy="16.5" r="0.9" fill="{c}" stroke="none"/>',
      size: 20,
      sw: 1.9,
    ),
    'logout': (
      body:
          '<path d="M14 4h4a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1h-4"/><path d="M9 12h11M16 8l4 4-4 4"/>',
      size: 20,
      sw: 1.9,
    ),
    'moon': (
      body: '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/>',
      size: 20,
      sw: 1.9,
    ),

    // ── Food / goals ─────────────────────────────────────────────────────────
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
    'hatBig': (
      body:
          '<path d="M7 14h10v5H7z"/><path d="M7 14a3.2 3.2 0 0 1-1-6.2A3.2 3.2 0 0 1 11 6a3.2 3.2 0 0 1 6 1.8A3.2 3.2 0 0 1 17 14"/><path d="M9.5 19v-3M14.5 19v-3"/>',
      size: 44,
      sw: 1.7,
    ),
    'chefHat': (
      body:
          '<path d="M7 14h10v6H7z"/><path d="M7 14a3.4 3.4 0 0 1-1-6.5A3.4 3.4 0 0 1 11 5.5a3.4 3.4 0 0 1 6.5 2A3.4 3.4 0 0 1 17 14"/>',
      size: 20,
      sw: 1.9,
    ),

    // ── Source icons ─────────────────────────────────────────────────────────
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

    // ── Stars / hearts (outline) ─────────────────────────────────────────────
    'starO': (
      body:
          '<path d="M12 3.5l2.6 5.3 5.8.9-4.2 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8-4.2-4.1 5.8-.9z"/>',
      size: 22,
      sw: 1.9,
    ),
    'heartO': (
      body:
          '<path d="M12 20s-7-4.6-7-9.3A3.7 3.7 0 0 1 12 7a3.7 3.7 0 0 1 7 3.7C19 15.4 12 20 12 20z"/>',
      size: 20,
      sw: 1.9,
    ),

    // ── Filled icons (fill:currentColor, stroke:none) — HTML `sf(...)` ────────
    'sparkF': (
      body:
          '<path d="M12 2l1.9 5.6L19.5 9.5 14 11.4 12 17l-1.9-5.6L4.5 9.5l5.6-1.9z" fill="{c}" stroke="none"/>',
      size: 15,
      sw: 1.9,
    ),
    'spark': (
      body:
          '<path d="M12 2l1.9 5.6L19.5 9.5 14 11.4 12 17l-1.9-5.6L4.5 9.5l5.6-1.9z" fill="{c}" stroke="none"/>',
      size: 14,
      sw: 1.9,
    ),
    'sparkF2': (
      body:
          '<path d="M12 2l1.9 5.6L19.5 9.5 14 11.4 12 17l-1.9-5.6L4.5 9.5l5.6-1.9z" fill="{c}" stroke="none"/>',
      size: 22,
      sw: 1.9,
    ),
    'sparkLg': (
      body:
          '<path d="M12 2l1.9 5.6L19.5 9.5 14 11.4 12 17l-1.9-5.6L4.5 9.5l5.6-1.9z" fill="{c}" stroke="none"/>',
      size: 30,
      sw: 1.9,
    ),
    'starF': (
      body:
          '<path d="M12 3l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.9 6.8 19.2l1-5.8L3.5 9.2l5.9-.9z" fill="{c}" stroke="none"/>',
      size: 18,
      sw: 1.9,
    ),
    'heart': (
      body:
          '<path d="M12 20s-7-4.6-7-9.3A3.7 3.7 0 0 1 12 7a3.7 3.7 0 0 1 7 3.7C19 15.4 12 20 12 20z" fill="{c}" stroke="none"/>',
      size: 17,
      sw: 1.9,
    ),
    'crown': (
      body:
          '<path d="M4 8l4 3.5L12 4l4 7.5L20 8l-1.6 10H5.6z" fill="{c}" stroke="none"/>',
      size: 20,
      sw: 1.9,
    ),
    'dots': (
      body:
          '<circle cx="6" cy="12" r="1.6" fill="{c}" stroke="none"/><circle cx="12" cy="12" r="1.6" fill="{c}" stroke="none"/><circle cx="18" cy="12" r="1.6" fill="{c}" stroke="none"/>',
      size: 22,
      sw: 1.9,
    ),
    'grip': (
      body:
          '<circle cx="9" cy="6" r="1.3" fill="{c}" stroke="none"/><circle cx="15" cy="6" r="1.3" fill="{c}" stroke="none"/><circle cx="9" cy="12" r="1.3" fill="{c}" stroke="none"/><circle cx="15" cy="12" r="1.3" fill="{c}" stroke="none"/><circle cx="9" cy="18" r="1.3" fill="{c}" stroke="none"/><circle cx="15" cy="18" r="1.3" fill="{c}" stroke="none"/>',
      size: 18,
      sw: 1.9,
    ),
    'verified': (
      body:
          '<path d="M12 2l2.2 1.6 2.7-.2 1 2.5 2.3 1.4-.7 2.6.7 2.6-2.3 1.4-1 2.5-2.7-.2L12 22l-2.2-1.6-2.7.2-1-2.5-2.3-1.4.7-2.6L4.5 11l2.3-1.4 1-2.5 2.7.2z" fill="{c}" stroke="none"/><path d="M9 12l2 2 4-4" stroke="#ffffff" stroke-width="2" fill="none"/>',
      size: 16,
      sw: 1.9,
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
