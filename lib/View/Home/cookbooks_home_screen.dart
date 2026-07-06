import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:recipe_ai/widgets/app_wordmark.dart';

/// Cookbooks (home) — pixel-matched to design "18 · Cookbooks (home)".
///
/// Design-only screen: static sample data + image views, the exact colours,
/// spacing and SVG icons from the reference. All icons are rendered from the
/// design's own SVG paths via [flutter_svg] so they match one-to-one.
class CookbooksHomeScreen extends StatefulWidget {
  const CookbooksHomeScreen({super.key});

  @override
  State<CookbooksHomeScreen> createState() => _CookbooksHomeScreenState();
}

class _CookbooksHomeScreenState extends State<CookbooksHomeScreen> {
  // 0 = Cookbooks, 1 = Recipes (visual toggle only — this is the Cookbooks tab).
  int _tab = 0;

  // Sample cookbooks (design only). `cells` are the 2×2 collage images; a null
  // cell renders the empty-photo placeholder like the reference.
  static const List<_Cb> _cookbooks = [
    _Cb('Weeknight Dinners', '18 recipes', [_img1, _img2, _img3, _img4]),
    _Cb('Sweet Treats', '12 recipes', [_img5, _img6, _img7, null]),
    _Cb('Healthy Bowls', '9 recipes', [_img4, _img8, _img2, _img1]),
    _Cb('Family Favorites', '6 recipes', [_img3, _img5, null, null]),
  ];

  static const _u = '?w=240&q=80&auto=format&fit=crop';
  static const _img1 =
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c$_u';
  static const _img2 =
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd$_u';
  static const _img3 =
      'https://images.unsplash.com/photo-1499636136210-6f4ee915583e$_u';
  static const _img4 =
      'https://images.unsplash.com/photo-1467003909585-2f8a72700288$_u';
  static const _img5 =
      'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38$_u';
  static const _img6 =
      'https://images.unsplash.com/photo-1476224203421-9ac39bcb3327$_u';
  static const _img7 =
      'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe$_u';
  static const _img8 =
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836$_u';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF4EA),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ── Scrollable content ─────────────────────────────────────────
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
                  child: Column(
                    children: [
                      _header(),
                      const SizedBox(height: 18),
                      _tabsRow(),
                      const SizedBox(height: 16),
                      _searchBar(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
                    child: _grid(),
                  ),
                ),
              ],
            ),

            // ── Floating add button ────────────────────────────────────────
            Positioned(right: 20, bottom: 104, child: _fab()),

            // ── Bottom navigation bar ──────────────────────────────────────
            const Positioned(left: 0, right: 0, bottom: 0, child: _BottomNav()),
          ],
        ),
      ),
    );
  }

  // ── Header: logo + "4/5" plan badge ──────────────────────────────────────
  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            AppLogo(size: 28),
            SizedBox(width: 8),
            AppWordmark(fontSize: 18, fontWeight: FontWeight.w800),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFCEFD0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Ico(_pSparkF, size: 15, color: '#F2623E', filled: true),
              const SizedBox(width: 5),
              Text(
                '4/5',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFC0860F),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Segmented tabs + sort button ─────────────────────────────────────────
  Widget _tabsRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1EBDF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [_segment('Cookbooks', 0), _segment('Recipes', 1)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFEDE3D2)),
            ),
            child: const Center(
              child: _Ico(_pSort, size: 16, color: '#9A938A'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _segment(String label, int index) {
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: active
              ? BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2A211B).withValues(alpha: 0.12),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                )
              : null,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? const Color(0xFF2A211B) : const Color(0xFF9A938A),
            ),
          ),
        ),
      ),
    );
  }

  // ── Search bar ───────────────────────────────────────────────────────────
  Widget _searchBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE3D2)),
      ),
      child: Row(
        children: [
          const _Ico(_pSearch, size: 20, color: '#A89F90'),
          const SizedBox(width: 10),
          Text(
            'Search cookbooks',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFA89F90),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2-column cookbook grid ───────────────────────────────────────────────
  Widget _grid() {
    final rows = <Widget>[];
    for (var i = 0; i < _cookbooks.length; i += 2) {
      final left = _cookbooks[i];
      final right = i + 1 < _cookbooks.length ? _cookbooks[i + 1] : null;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _cookbookCard(left)),
            const SizedBox(width: 16),
            Expanded(
              child: right == null ? const SizedBox() : _cookbookCard(right),
            ),
          ],
        ),
      );
      if (i + 2 < _cookbooks.length) rows.add(const SizedBox(height: 16));
    }
    return Column(children: rows);
  }

  Widget _cookbookCard(_Cb cb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEDE5D7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF0E7D6)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _cell(cb.cells[0])),
                      const SizedBox(width: 2),
                      Expanded(child: _cell(cb.cells[1])),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _cell(cb.cells[2])),
                      const SizedBox(width: 2),
                      Expanded(child: _cell(cb.cells[3])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          cb.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: const Color(0xFF2A211B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          cb.count,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF9A938A),
          ),
        ),
      ],
    );
  }

  // One collage cell: a food photo, or the empty-photo placeholder.
  Widget _cell(String? url) {
    return Container(
      color: const Color(0xFFE7DECE),
      child: url == null
          ? const Center(
              child: _Ico(_pPhoto, size: 20, color: '#CFC5B4', stroke: 1.7),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (c, child, p) =>
                  p == null ? child : const SizedBox.shrink(),
              errorBuilder: (c, e, s) => const Center(
                child: _Ico(_pPhoto, size: 20, color: '#CFC5B4', stroke: 1.7),
              ),
            ),
    );
  }

  // ── Floating add button ──────────────────────────────────────────────────
  Widget _fab() {
    return Container(
      width: 60,
      height: 60,

      decoration: BoxDecoration(
        color: const Color(0xFFF2623E),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF2623E).withValues(alpha: 0.7),
            blurRadius: 26,
            offset: const Offset(0, 12),
            spreadRadius: -6,
          ),
        ],
      ),
      child: const Center(
        child: _Ico(_pPlus, size: 26, color: '#FFFFFF', stroke: 2.3),
      ),
    );
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 88 + bottomInset,
      padding: EdgeInsets.only(top: 11, left: 6, right: 6, bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(top: BorderSide(color: Color(0xFFEFE6D6))),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NavItem(icon: _pBook, label: 'Cookbooks', active: true),
          _NavItem(icon: _pCompass, label: 'Discover'),
          _NavItem(icon: _pCal, label: 'Meal Plan'),
          _NavItem(icon: _pCart, label: 'Groceries'),
          _NavItem(icon: _pDots, label: 'More', filled: true),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool active;
  final bool filled;
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? '#F2623E' : '#B0A899';
    final textColor = active
        ? const Color(0xFFF2623E)
        : const Color(0xFFB0A899);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 30,
            alignment: Alignment.center,
            decoration: active
                ? BoxDecoration(
                    color: const Color(0xFFFCE3DB),
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
            child: _Ico(icon, size: 24, color: color, filled: filled),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── SVG icon renderer (exact design paths, viewBox 0 0 24 24) ──────────────
class _Ico extends StatelessWidget {
  final String paths;
  final double size;
  final String color; // '#RRGGBB'
  final double stroke;
  final bool filled;
  const _Ico(
    this.paths, {
    required this.size,
    required this.color,
    this.stroke = 1.9,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final attrs = filled
        ? 'fill="$color" stroke="none"'
        : 'fill="none" stroke="$color" stroke-width="$stroke" '
              'stroke-linecap="round" stroke-linejoin="round"';
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" $attrs>'
        '$paths</svg>';
    return SvgPicture.string(svg, width: size, height: size);
  }
}

// Design icon paths (verbatim from the reference's icon registry).
const _pSparkF =
    '<path d="M12 2l1.9 5.6L19.5 9.5 14 11.4 12 17l-1.9-5.6L4.5 9.5l5.6-1.9z"/>';
const _pSort =
    '<path d="M7 4v16M7 4L4 7M7 4l3 3M17 20V4M17 20l-3-3M17 20l3-3"/>';
const _pSearch = '<circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/>';
const _pPlus = '<path d="M12 5v14M5 12h14"/>';
const _pBook =
    '<path d="M5 4h12a1 1 0 0 1 1 1v15H7a2 2 0 0 1-2-2z"/>'
    '<path d="M5 17a2 2 0 0 1 2-2h11"/>';
const _pCompass =
    '<circle cx="12" cy="12" r="9"/><path d="M15.5 8.5l-2 5-5 2 2-5z"/>';
const _pCal =
    '<rect x="3" y="4.5" width="18" height="16" rx="2.5"/>'
    '<path d="M3 9.5h18M8 2.5v4M16 2.5v4"/>';
const _pCart =
    '<circle cx="9" cy="20" r="1.5"/><circle cx="18" cy="20" r="1.5"/>'
    '<path d="M3 4h2l2.3 12a1 1 0 0 0 1 .8h8.2a1 1 0 0 0 1-.8L20 8H6"/>';
const _pDots =
    '<circle cx="6" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/>'
    '<circle cx="18" cy="12" r="1.6"/>';
const _pPhoto =
    '<rect x="3" y="5" width="18" height="14" rx="2.5"/>'
    '<path d="M3 16l5-4 4 3 3-3 6 5"/><circle cx="8.5" cy="9.5" r="1.4"/>';

class _Cb {
  final String name;
  final String count;
  final List<String?> cells;
  const _Cb(this.name, this.count, this.cells);
}
