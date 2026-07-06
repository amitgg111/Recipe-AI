import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:recipe_ai/widgets/crown_icon.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/screens/onboarding/trial_chooser_screen.dart';

class PlusComparisonScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  final VoidCallback? onClose;

  const PlusComparisonScreen({super.key, this.onContinue, this.onClose});

  @override
  State<PlusComparisonScreen> createState() => _PlusComparisonScreenState();
}

class _PlusComparisonScreenState extends State<PlusComparisonScreen>
    with TickerProviderStateMixin {
  // Continuous sheen sweep on the Plus column.
  late final AnimationController _sheenController;
  late final Animation<double> _sheenAnimation;

  // One-shot staggered entrance for the whole screen.
  late final AnimationController _entrance;
  late final Animation<double> _topFade;
  late final Animation<double> _badgeFade;
  late final Animation<Offset> _badgeSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _tableFade;
  late final Animation<Offset> _tableSlide;
  late final Animation<double> _tableScale;
  late final List<Animation<double>> _rowFades;
  late final List<Animation<Offset>> _rowSlides;
  late final List<Animation<double>> _checkScales;
  late final Animation<double> _ctaFade;
  late final Animation<Offset> _ctaSlide;
  late final Animation<double> _discFade;

  static double _cl(double v) => v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v);

  // Eased 0→1 sub-animation over [begin, end] of the entrance timeline.
  CurvedAnimation _c(
    double begin,
    double end, [
    Curve curve = Curves.easeOutCubic,
  ]) => CurvedAnimation(
    parent: _entrance,
    curve: Interval(begin, end, curve: curve),
  );

  // Upward slide (dy in fractions of the widget's own height) → rest.
  Animation<Offset> _slide(
    double begin,
    double end,
    double dy, [
    Curve curve = Curves.easeOutCubic,
  ]) => Tween<Offset>(
    begin: Offset(0, dy),
    end: Offset.zero,
  ).animate(_c(begin, end, curve));

  // Feature rows: (label, freeValue, plusValue)
  // plusValue: null means checkmark, String means text
  static const _features = <(String, String, String?)>[
    ('Recipe imports', '5 / week', 'Unlimited'),
    ('Recipe nutrition calculator', '—', null),
    ('Create shopping lists in seconds', '—', null),
    ('AI-powered cooking assistant', '—', null),
    ('Convert measurements', '—', null),
    ('Step-by-step cooking mode', '—', null),
    ('Print / export recipes', '—', null),
  ];

  @override
  void initState() {
    super.initState();

    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
    _sheenAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _sheenController, curve: Curves.easeInOut),
    );

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _topFade = _c(0.00, 0.22);
    _badgeFade = _c(0.08, 0.34);
    _badgeSlide = _slide(0.08, 0.34, 0.5);
    _titleFade = _c(0.16, 0.42);
    _titleSlide = _slide(0.16, 0.42, 0.5);
    _tableFade = _c(0.28, 0.56);
    _tableSlide = _slide(0.28, 0.56, 0.14);
    _tableScale = Tween<double>(begin: 0.96, end: 1.0).animate(_c(0.28, 0.56));

    const rowStart = 0.46;
    const rowStep = 0.045;
    const rowDur = 0.30;
    _rowFades = List.generate(_features.length, (i) {
      final s = rowStart + i * rowStep;
      return _c(_cl(s), _cl(s + rowDur));
    });
    _rowSlides = List.generate(_features.length, (i) {
      final s = rowStart + i * rowStep;
      return _slide(_cl(s), _cl(s + rowDur), 0.45);
    });
    _checkScales = List.generate(_features.length, (i) {
      final s = _cl(rowStart + i * rowStep + 0.02);
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _entrance,
          curve: Interval(s, _cl(s + rowDur), curve: Curves.easeOutBack),
        ),
      );
    });

    _ctaFade = _c(0.74, 0.96);
    _ctaSlide = _slide(0.74, 0.96, 0.5);
    _discFade = _c(0.86, 1.0);

    _entrance.forward();
  }

  @override
  void dispose() {
    _sheenController.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
          child: Column(
            children: [
              // Top bar: Row, justify space-between, height 36
              FadeTransition(
                opacity: _topFade,
                child: SizedBox(
                  height: 36,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left: flex 1 empty
                      const Expanded(child: SizedBox()),
                      // Center: logoPlus
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.purple,
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF8B5CF6,
                                  ).withValues(alpha: 0.7),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                            child: const AppLogoMark(
                              size: 23,
                              pleatColor: Color(0x808B5CF6),
                              sparkleColor: Color(0xFFEBDBFF),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Text.rich(
                            TextSpan(
                              text: 'Recipe AI ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                letterSpacing: -0.42,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Plus',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.purple,
                                    letterSpacing: -0.42,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Right: X button (34x34, border-radius 17)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap:
                                widget.onClose ??
                                () => Get.to(
                                  () => const TrialChooserScreen(),
                                  transition: Transition.noTransition,
                                ),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2A211B,
                                ).withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(17),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.textMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content (scrollable)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Title area: margin 20px 0 26px
                      const SizedBox(height: 20),
                      // Badge: MEMBER RESULTS
                      SlideTransition(
                        position: _badgeSlide,
                        child: FadeTransition(
                          opacity: _badgeFade,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.purpleBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  size: 12,
                                  color: Color(0xFF8B5CF6),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'MEMBER RESULTS',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF8B5CF6),
                                    letterSpacing: 0.24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Title
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleFade,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                height: 1.18,
                                letterSpacing: -0.52,
                              ),
                              children: [
                                TextSpan(
                                  text: '93% of members',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.purple,
                                    height: 1.18,
                                    letterSpacing: -0.52,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' reported improved cooking habits',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      // Comparison table
                      SlideTransition(
                        position: _tableSlide,
                        child: ScaleTransition(
                          scale: _tableScale,
                          child: FadeTransition(
                            opacity: _tableFade,
                            child: _buildComparisonTable(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              // ── Fixed bottom CTA — pinned outside the scroll view so it is
              // ALWAYS visible and never scrolls away (fixes the reported
              // scrolling / hidden-button issue).
              const SizedBox(height: 12),
              SlideTransition(
                position: _ctaSlide,
                child: FadeTransition(
                  opacity: _ctaFade,
                  child: PrimaryButton.purple(
                    label: 'Start my free week',
                    onPressed:
                        widget.onContinue ??
                        () => Get.to(
                          () => const TrialChooserScreen(),
                          transition: Transition.noTransition,
                        ),
                    enableBob: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _discFade,
                child: Text(
                  '7 days free · cancel anytime',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textLighter,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Wraps a comparison row with its staggered fade + slide reveal.
  Widget _revealRow(int i, Widget child) {
    return SlideTransition(
      position: _rowSlides[i],
      child: FadeTransition(opacity: _rowFades[i], child: child),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE6D6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A211B).withValues(alpha: 0.4),
            blurRadius: 44,
            offset: const Offset(0, 22),
            spreadRadius: -26,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column 1: What you get (flex 1)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  height: 56,
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.only(left: 16, bottom: 12),
                  child: Text(
                    'What you get',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB0A899),
                    ),
                  ),
                ),
                // Feature rows
                ...List.generate(_features.length, (i) {
                  return _revealRow(
                    i,
                    Container(
                      height: 62,
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.divider, width: 1),
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _features[i].$1,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                          height: 1.22,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Column 2: Free (width 64)
          SizedBox(
            width: 64,
            child: Column(
              children: [
                // Header
                Container(
                  height: 56,
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Free',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLighter,
                    ),
                  ),
                ),
                // Rows
                ...List.generate(_features.length, (i) {
                  final freeVal = _features[i].$2;
                  final isDash = freeVal == '—';
                  return _revealRow(
                    i,
                    Container(
                      height: 62,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.divider, width: 1),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        freeVal,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDash
                              ? const Color(0xFFD8D0C2)
                              : AppColors.textMedium,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Column 3: Plus (width 114) — gradient on the Container that
          // directly wraps the content Column so it always paints.
          SizedBox(
            width: 114,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF8B5CF6),
              ),
              child: Stack(
                children: [
                  // Content
                  Column(
                    children: [
                      // Header
                      Container(
                        height: 56,
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const CrownIcon(size: 15),

                            Text(
                              'PLUS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Rows
                      ...List.generate(_features.length, (i) {
                        final plusVal = _features[i].$3;
                        final isCheck = plusVal == null;
                        return _revealRow(
                          i,
                          Container(
                            height: 62,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: isCheck
                                ? ScaleTransition(
                                    scale: _checkScales[i],
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  )
                                : Text(
                                    plusVal,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        );
                      }),
                    ],
                  ),
                  // Sheen sweep overlay: a narrow white band that slides
                  // across the primary column (does not cover it).
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRect(
                        child: AnimatedBuilder(
                          animation: _sheenAnimation,
                          builder: (context, _) {
                            return FractionalTranslation(
                              translation: Offset(_sheenAnimation.value, 0),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0),
                                      Colors.white.withValues(alpha: 0.22),
                                      Colors.white.withValues(alpha: 0),
                                    ],
                                    stops: const [0.35, 0.5, 0.65],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
