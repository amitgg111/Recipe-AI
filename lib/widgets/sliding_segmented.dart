import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// A content-sized segmented control whose white "pill" **slides and resizes**
/// between segments. Segment widths are measured from their labels (at the
/// active/bold weight) so widths stay stable and there's no layout jump when
/// the selection changes.
///
/// Used for the compact toggles (Day/Month, Metric/US, …). Pass [expand] for a
/// full-width variant with equal-width segments.
class SlidingSegmented extends StatefulWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  final Color trackColor;
  final Color pillColor;
  final double trackRadius;
  final double pillRadius;
  final double trackPadding;
  final double hPad; // segment horizontal padding
  final double vPad; // segment vertical padding

  /// When true the control fills its parent width with equal-width segments
  /// (the pill slides via [AnimatedAlign]). When false each segment is sized to
  /// its label and the pill slides + resizes via [AnimatedPositioned].
  final bool expand;

  /// Optional fixed segment height (only used in [expand] mode). When null the
  /// height is derived from [vPad] + the label height.
  final double? height;

  /// Optional hairline border around the track, so the container stays visible
  /// against a page background of a similar tone.
  final Color? trackBorder;

  /// Returns the text style for a segment given whether it is active.
  final TextStyle Function(bool active) style;
  final List<BoxShadow>? pillShadow;
  final Duration duration;

  const SlidingSegmented({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    required this.trackColor,
    required this.pillColor,
    required this.style,
    this.trackRadius = 11,
    this.pillRadius = 8,
    this.trackPadding = 3,
    this.hPad = 12,
    this.vPad = 6,
    this.expand = false,
    this.height,
    this.trackBorder,
    this.pillShadow,
    this.duration = const Duration(milliseconds: 240),
  });

  /// Inactive label colour used across all toggles (matches the HTML mockup).
  static const Color _inactive = Color(0xFF9A938A);

  /// Track fill + hairline border. The fill is the HTML's #F1EBDF; the border
  /// makes the container visible against the app's similar cream page.
  static const Color _trackFill = Color(0xFFF1EBDF);
  static const Color _trackEdge = Color(0xFFE3D9C6);

  /// Compact, content-sized toggle — matches the Day/Month toggle in the HTML
  /// (beige track radius 11, white pill radius 8, 12.5px Plus Jakarta Sans).
  /// Use for small inline toggles (Day/Month).
  factory SlidingSegmented.standard({
    Key? key,
    required List<String> labels,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
  }) {
    return SlidingSegmented(
      key: key,
      labels: labels,
      selectedIndex: selectedIndex,
      onChanged: onChanged,
      trackColor: _trackFill,
      trackBorder: _trackEdge,
      pillColor: AppColors.surface,
      trackRadius: 11,
      pillRadius: 8,
      trackPadding: 3,
      hPad: 12,
      vPad: 6,
      style: (active) => GoogleFonts.plusJakartaSans(
        fontSize: 12.5,
        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
        color: active ? AppColors.textDark : _inactive,
      ),
      pillShadow: const [
        BoxShadow(
          color: Color(0x1F2A211B), // rgba(42,33,27,.12)
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      ],
    );
  }

  /// Full-width tab bar — matches the Login/Sign up & Cookbooks/Recipes toggles
  /// in the HTML: equal-width segments (`flex:1`), beige track radius 12, white
  /// pill radius 9, 14px Plus Jakarta Sans. [height] is the segment height
  /// (38 for Login/Sign up, 36 for Cookbooks/Recipes).
  factory SlidingSegmented.tabs({
    Key? key,
    required List<String> labels,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
    double height = 38,
  }) {
    return SlidingSegmented(
      key: key,
      expand: true,
      height: height,
      labels: labels,
      selectedIndex: selectedIndex,
      onChanged: onChanged,
      trackColor: _trackFill,
      trackBorder: _trackEdge,
      pillColor: AppColors.surface,
      trackRadius: 12,
      pillRadius: 9,
      trackPadding: 3,
      vPad: 0,
      style: (active) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
        color: active ? AppColors.textDark : _inactive,
      ),
      pillShadow: const [
        BoxShadow(
          color: Color(0x1F2A211B), // rgba(42,33,27,.12)
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      ],
    );
  }

  @override
  State<SlidingSegmented> createState() => _SlidingSegmentedState();
}

class _SlidingSegmentedState extends State<SlidingSegmented> {
  @override
  void initState() {
    super.initState();
    // GoogleFonts loads fonts asynchronously. If we measure the labels before
    // the font is ready the segments come out too narrow (measured against a
    // fallback font) and long labels wrap. Re-measure once the fonts settle.
    if (!widget.expand) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        GoogleFonts.pendingFonts().then((_) {
          if (mounted) setState(() {});
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.expand) return _buildExpanded(context);
    return _buildMeasured(context);
  }

  /// Full-width, equal-width segments with an [AnimatedAlign] sliding pill.
  Widget _buildExpanded(BuildContext context) {
    final n = widget.labels.length;
    final align = n > 1 ? (2 * widget.selectedIndex / (n - 1) - 1) : 0.0;
    final stack = Stack(
      children: [
        // Sliding pill (behind the labels). heightFactor:1 is required — without
        // it the childless DecoratedBox collapses to 0 height and never shows.
        Positioned.fill(
          child: AnimatedAlign(
            duration: widget.duration,
            curve: Curves.easeInOut,
            alignment: Alignment(align, 0),
            child: FractionallySizedBox(
              widthFactor: n > 0 ? 1 / n : 1,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.pillColor,
                  borderRadius: BorderRadius.circular(widget.pillRadius),
                  boxShadow: widget.pillShadow,
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
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onChanged(i),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: widget.vPad),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: widget.duration,
                        style: widget.style(i == widget.selectedIndex),
                        child: Text(widget.labels[i]),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
    return Container(
      padding: EdgeInsets.all(widget.trackPadding),
      decoration: BoxDecoration(
        color: widget.trackColor,
        borderRadius: BorderRadius.circular(widget.trackRadius),
        border: widget.trackBorder != null
            ? Border.all(color: widget.trackBorder!)
            : null,
      ),
      child: widget.height != null
          ? SizedBox(height: widget.height, child: stack)
          : stack,
    );
  }

  /// Content-sized segments with an [AnimatedPositioned] slide + resize pill.
  Widget _buildMeasured(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final activeStyle = widget.style(true);

    // Measure each segment at the active (bold) weight → stable widths.
    final widths = <double>[];
    for (final label in widget.labels) {
      final tp = TextPainter(
        text: TextSpan(text: label, style: activeStyle),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widths.add(tp.width + widget.hPad * 2);
    }

    final total = widths.fold<double>(0, (a, b) => a + b);
    double left = 0;
    for (var i = 0; i < widget.selectedIndex && i < widths.length; i++) {
      left += widths[i];
    }
    final pillW = widths.isEmpty
        ? 0.0
        : widths[widget.selectedIndex.clamp(0, widths.length - 1)];

    return Container(
      padding: EdgeInsets.all(widget.trackPadding),
      decoration: BoxDecoration(
        color: widget.trackColor,
        borderRadius: BorderRadius.circular(widget.trackRadius),
        border: widget.trackBorder != null
            ? Border.all(color: widget.trackBorder!)
            : null,
      ),
      child: SizedBox(
        width: total,
        child: Stack(
          children: [
            // Sliding + resizing pill (behind the labels).
            AnimatedPositioned(
              duration: widget.duration,
              curve: Curves.easeInOut,
              left: left,
              width: pillW,
              top: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.pillColor,
                  borderRadius: BorderRadius.circular(widget.pillRadius),
                  boxShadow: widget.pillShadow,
                ),
              ),
            ),
            // Tappable labels (on top).
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.labels.length; i++)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onChanged(i),
                    child: SizedBox(
                      width: widths[i],
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: widget.vPad),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: widget.duration,
                            style: widget.style(i == widget.selectedIndex),
                            child: Text(
                              widget.labels[i],
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                            ),
                          ),
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
