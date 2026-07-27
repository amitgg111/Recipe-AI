import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:recipe_ai/Service/subscription_service.dart';
import 'package:recipe_ai/Service/revenuecat_service.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/widgets/app_logo.dart';

/// Upgrade to Plus paywall — a pixel port of design screens
/// "71 · Upgrade to Plus" (Yearly highlighted) and "71B · Monthly selected".
///
/// One screen with a Monthly/Yearly plan toggle that swaps: the highlighted
/// pricing card, the yellow "trial only on yearly" banner (shown when Monthly
/// is selected), the CTA label and the caption below it.
///
/// Animations mirror the HTML: `pulseGlow` on the badge, `floatUp` on the hat
/// and the two corner sparkles, and a `sheen` shimmer sweeping the CTA.
///
/// No billing SDK yet — the CTA activates Plus directly via
/// [SubscriptionService.setPlus]. Swap that for a store purchase that ends in
/// `setPlus(true)` when integrating IAP.
class UpgradePlusScreen extends StatefulWidget {
  const UpgradePlusScreen({super.key});

  @override
  State<UpgradePlusScreen> createState() => _UpgradePlusScreenState();
}

class _UpgradePlusScreenState extends State<UpgradePlusScreen>
    with TickerProviderStateMixin {
  /// Yearly is highlighted by default (matches the primary design, screen 71 —
  /// the plan the reference mock shows selected).
  bool _monthly = false;

  final _rc = RevenueCatService.instance;
  bool _busy = false;

  // ── Store-sourced plan data (price + name come from RevenueCat) ──────────────
  Package? get _monthlyPkg => _rc.monthly;
  Package? get _yearlyPkg => _rc.yearly;

  String get _monthlyPrice => _monthlyPkg?.storeProduct.priceString ?? '₹199';
  String get _yearlyPrice => _yearlyPkg?.storeProduct.priceString ?? '₹1,700';

  String get _monthlyName =>
      _cleanTitle(_monthlyPkg?.storeProduct.title) ?? 'plan_monthly'.tr;
  String get _yearlyName =>
      _cleanTitle(_yearlyPkg?.storeProduct.title) ?? 'plan_yearly'.tr;

  /// Store titles often read "Monthly (Recipe AI)" — drop the app-name suffix.
  String? _cleanTitle(String? t) {
    if (t == null || t.trim().isEmpty) return null;
    return t.split('(').first.trim();
  }

  /// Per-month equivalent for the yearly card, in the store's own currency.
  String get _yearlyPerMonth {
    final p = _yearlyPkg?.storeProduct;
    if (p == null) return '₹142 / month';
    final perMonth = (p.price / 12).round();
    final symbol =
        (RegExp(r'^[^0-9]*').firstMatch(p.priceString)?.group(0) ?? '').trim();
    return symbol.isNotEmpty
        ? 'price_per_month'.trParams({'price': '$symbol$perMonth'})
        : 'price_per_month'.trParams({'price': '$perMonth'});
  }

  /// Whether the selected plan carries an introductory (e.g. free-trial) offer.
  bool get _selectedHasTrial =>
      (_monthly ? _monthlyPkg : _yearlyPkg)?.storeProduct.introductoryPrice !=
      null;

  bool get _yearlyHasTrial =>
      _yearlyPkg == null || _yearlyPkg!.storeProduct.introductoryPrice != null;

  @override
  void initState() {
    super.initState();
    // (existing animation controllers set up below)
    _rc.fetchOfferings();
    _initAnimations();
  }

  // ── Palette (straight from the design) ──────────────────────────────────────
  static const _bg = Color(0xFFFBF4EA);
  static const _ink = Color(0xFF2A211B);
  static const _grey = Color(0xFF8A7E70);
  static const _purple = Color(0xFF8B5CF6);
  static const _purpleDeep = Color(0xFF7A45E0);
  static const _grad1 = Color(0xFF9466F2);
  static const _grad2 = Color(0xFF6D3BD4);

  // ── Animations ──
  late final AnimationController _glow; // pulseGlow 2.6s
  late final AnimationController _floatHat; // floatUp 3.4s
  late final AnimationController _floatS1; // floatUp 3.0s
  late final AnimationController _floatS2; // floatUp 3.6s

  void _initAnimations() {
    // repeat(reverse:true) → half the CSS cycle so a full round-trip matches.
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _floatHat = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _floatS1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _floatS2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    _floatHat.dispose();
    _floatS1.dispose();
    _floatS2.dispose();
    super.dispose();
  }

  TextStyle _font({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color color = _ink,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  Future<void> _subscribe() async {
    if (_busy) return;
    final pkg = _monthly ? _monthlyPkg : _yearlyPkg;

    // No package yet → RevenueCat isn't configured (keys not set) or offerings
    // haven't loaded. Keep the dev unlock so the app is usable before store
    // setup is finished.
    if (pkg == null) {
      await SubscriptionService.instance.setPlus(true);
      _onPlusActivated();
      return;
    }

    setState(() => _busy = true);
    try {
      final ok = await _rc.purchase(pkg);
      if (!mounted) return;
      if (ok) {
        _onPlusActivated();
      }
      // ok == false → user cancelled; leave the paywall open silently.
    } catch (_) {
      if (mounted) {
        CustomSnackbar.show(
          title: 'purchase_failed'.tr,
          message: 'pdf_failed_msg'.tr,
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await _rc.restore();
      if (!mounted) return;
      if (ok) {
        _onPlusActivated();
      } else {
        CustomSnackbar.show(
          title: 'nothing_to_restore'.tr,
          message: 'no_active_subscription_found'.tr,
          type: SnackbarType.info,
        );
      }
    } catch (_) {
      if (mounted) {
        CustomSnackbar.show(
          title: 'restore_failed'.tr,
          message: 'could_not_restore_purchases'.tr,
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onPlusActivated() {
    if (mounted) Navigator.of(context).pop();
    CustomSnackbar.show(
      title: 'welcome_to_plus'.tr,
      message: 'premium_features_unlocked'.tr,
      type: SnackbarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            // ── ambient colour washes ──
            Positioned(
              top: -30,
              left: -40,
              child: _wash(240, const Color(0x298B5CF6)),
            ),
            Positioned(
              top: 60,
              right: -50,
              child: _wash(200, const Color(0x21F2623E)),
            ),

            // ── content ──
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── animated hat badge ──
                    Center(child: _badge()),
                    const SizedBox(height: 18),

                    // ── RECIPE AI PLUS pill ──
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFE6FB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'recipe_ai_plus'.tr,
                          style: _font(
                            size: 11,
                            weight: FontWeight.w800,
                            color: _purpleDeep,
                            letterSpacing: 0.66,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),

                    // ── title ──
                    Text(
                      'upgrade_plus_title'.tr,
                      textAlign: TextAlign.center,
                      style: _font(
                        size: 27,
                        weight: FontWeight.w800,
                        color: _ink,
                        height: 1.12,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 9),

                    // ── subtitle ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'plus_paywall_sub'.tr,
                        textAlign: TextAlign.center,
                        style: _font(
                          size: 14,
                          weight: FontWeight.w500,
                          color: _grey,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── benefits ──
                    for (var i = 0; i < _features.length; i++) ...[
                      if (i != 0) const SizedBox(height: 10),
                      PremiumFeatureCard(feature: _features[i]),
                    ],
                    const SizedBox(height: 22),

                    // ── plans ──
                    // The cards stretch to a shared height so their bottoms
                    // line up; the SAVE badge is overlaid, centred over the
                    // Yearly (right) card, so it never affects card layout.
                    Obx(() {
                      // Depend on the offering so prices/names refresh once the
                      // store data loads. (offering is read via _rc.monthly.)
                      _rc.offering.value;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // IntrinsicHeight gives the stretch Row a concrete
                          // height (the SingleChildScrollView otherwise leaves
                          // the vertical axis unbounded), so both cards share the
                          // taller card's height and their bottoms line up.
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: PricingCard(
                                    selected: _monthly,
                                    title: _monthlyName,
                                    price: _monthlyPrice,
                                    note: 'per_month'.tr,
                                    highlightNoteWhenSelected: false,
                                    onTap: () =>
                                        setState(() => _monthly = true),
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: PricingCard(
                                    selected: !_monthly,
                                    title: _yearlyName,
                                    price: _yearlyPrice,
                                    note: _yearlyPerMonth,
                                    highlightNoteWhenSelected: true,
                                    onTap: () =>
                                        setState(() => _monthly = false),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // SAVE 30% badge — straddles the top edge of the
                          // Yearly card (mirrors the Row's right half).
                          Positioned(
                            top: -10,
                            left: 0,
                            right: 0,
                            child: Row(
                              children: [
                                const Expanded(child: SizedBox()),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Center(
                                    child: _saveBadge(selected: !_monthly),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),

                    // ── yellow trial banner (only when Monthly is selected) ──
                    if (_monthly && _yearlyHasTrial) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF6E6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF3E2BC)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Color(0xFFC0860F),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'trial_yearly_only'.tr,
                                style: _font(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF7A5B12),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── CTA ──
                    Obx(() {
                      _rc.offering.value; // rebuild when store prices load
                      final price = _monthly ? _monthlyPrice : _yearlyPrice;
                      final period = _monthly ? 'month'.tr : 'period_year'.tr;
                      final label = _busy
                          ? 'please_wait'.tr
                          : _selectedHasTrial
                          ? 'start_free_trial'.tr
                          : 'subscribe_price_period'.trParams({
                              'price': price,
                              'period': period,
                            });
                      return PrimaryGradientButton(
                        label: label,
                        onTap: _busy ? () {} : _subscribe,
                      );
                    }),
                    const SizedBox(height: 12),

                    // ── caption ──
                    Obx(() {
                      _rc.offering.value;
                      return Text(
                        _monthly
                            ? 'billed_monthly_note'.tr
                            : 'billed_yearly_cancel_anytime'.trParams({
                                'price': _yearlyPrice,
                              }),
                        textAlign: TextAlign.center,
                        style: _font(
                          size: 12,
                          weight: FontWeight.w600,
                          color: const Color(0xFFA8A092),
                        ),
                      );
                    }),
                    const SizedBox(height: 14),

                    // ── footer links ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _restore,
                          behavior: HitTestBehavior.opaque,
                          child: _footerLink('restore'.tr),
                        ),
                        _dot(),
                        _footerLink('terms'.tr),
                        _dot(),
                        _footerLink('privacy_short'.tr),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 8,
              right: 22,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _ink.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: _grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── the 88×88 animated hat badge ──
  Widget _badge() {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // pulsing gradient tile
          AnimatedBuilder(
            animation: _glow,
            builder: (_, child) {
              final t = Curves.easeInOut.transform(_glow.value);
              return Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_grad1, _grad2],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _purple.withValues(
                        alpha: 0.5 + 0.35 * t,
                      ), // .5 → .85
                      blurRadius: 30 + 10 * t, // 30 → 40
                      offset: Offset(0, 16 + 2 * t), // 16 → 18
                      spreadRadius: -12 + 2 * t, // -12 → -10
                    ),
                  ],
                ),
                child: child,
              );
            },
            // floating hat (white with purple pleat + gold sparkle)
            child: Center(
              child: _floatY(
                _floatHat,
                const AppLogoMark(
                  size: 58,
                  hatColor: Colors.white,
                  bandColor: Color(0xEBFFFFFF),
                  pleatColor: Color(0x8C8B5CF6), // rgba(139,92,246,.55)
                  sparkleColor: Color(0xFFFFE08A),
                ),
              ),
            ),
          ),
          // corner sparkles
          Positioned(
            top: -6,
            right: 2,
            child: _floatY(
              _floatS1,
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFFF2A24C),
                size: 18,
              ),
            ),
          ),
          Positioned(
            bottom: -2,
            left: 2,
            child: _floatY(
              _floatS2,
              const Icon(Icons.auto_awesome, color: _purple, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Wraps [child] in a smooth 0 → -8px → 0 vertical float driven by [c]
  /// (a reversing controller), matching the CSS `floatUp` keyframe.
  Widget _floatY(AnimationController c, Widget child) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, ch) {
        final t = Curves.easeInOut.transform(c.value);
        return Transform.translate(offset: Offset(0, -8 * t), child: ch);
      },
      child: child,
    );
  }

  /// The "SAVE 30%" pill. Gradient-filled/white when the yearly card is
  /// [selected]; pale lavender/purple otherwise (matches screens 71 / 71B).
  Widget _saveBadge({required bool selected}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      gradient: selected
          ? const LinearGradient(colors: [_grad1, _grad2])
          : null,
      color: selected ? null : const Color(0xFFEFE6FB),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      'save_30'.tr,
      style: _font(
        size: 9,
        weight: FontWeight.w800,
        color: selected ? Colors.white : _purpleDeep,
        letterSpacing: 0.3,
      ),
    ),
  );

  Widget _wash(double size, Color color) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.0, 0.7],
        ),
      ),
    ),
  );

  Widget _footerLink(String s) => Text(
    s,
    style: _font(size: 12, weight: FontWeight.w700, color: _grey),
  );

  Widget _dot() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    width: 3,
    height: 3,
    decoration: const BoxDecoration(
      color: Color(0xFFC7BCAC),
      shape: BoxShape.circle,
    ),
  );

  // ── Feature data ────────────────────────────────────────────────────────────
  static const List<_Feature> _features = [
    _Feature(
      Icons.auto_awesome_rounded,
      Color(0xFF8B5CF6),
      Color(0xFFF4EEFD),
      'bnf_imports',
      'bnf_imports_sub',
    ),
    _Feature(
      Icons.chat_bubble_rounded,
      Color(0xFF2D6FE0),
      Color(0xFFE4ECFB),
      'plus_feature_ai_assistant',
      'bnf_assistant_sub',
    ),
    _Feature(
      Icons.rice_bowl_rounded,
      Color(0xFF1F8A5B),
      Color(0xFFEAF6F0),
      'nutrition_calculator',
      'bnf_nutrition_sub',
    ),
    _Feature(
      Icons.calendar_month_rounded,
      Color(0xFFE0481F),
      Color(0xFFFCEAE3),
      'ai_meal_plan_autofill',
      'bnf_mealplan_sub',
    ),
    _Feature(
      Icons.straighten_rounded,
      Color(0xFFC0860F),
      Color(0xFFFCF3DE),
      'feature_measurement_converter',
      'feature_converter_subtitle',
    ),
    _Feature(
      Icons.picture_as_pdf_rounded,
      Color(0xFF8B5CF6),
      Color(0xFFF4EEFD),
      'bnf_pdf',
      'bnf_pdf_sub',
    ),
  ];
}

/// One row in the premium features list.
class _Feature {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  const _Feature(
    this.icon,
    this.iconColor,
    this.iconBg,
    this.title,
    this.subtitle,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Reusable widgets
// ══════════════════════════════════════════════════════════════════════════════

/// A single premium-feature card: colored icon · title/subtitle · green check.
class PremiumFeatureCard extends StatelessWidget {
  final _Feature feature;
  const PremiumFeatureCard({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE6D6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A211B).withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -20,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: feature.iconBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(feature.icon, size: 20, color: feature.iconColor),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2A211B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  feature.subtitle.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8A7E70),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF6F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 15,
              color: Color(0xFF1F8A5B),
            ),
          ),
        ],
      ),
    );
  }
}

/// A pricing option. Selected → light-purple gradient fill + 2px purple border.
///
/// The card fills whatever height it is given (so a Row of cards using
/// [CrossAxisAlignment.stretch] gets equal heights with aligned bottoms) and
/// keeps its content top-aligned. The "SAVE 30%" badge is drawn by the parent
/// as an overlay, so it never affects this card's size.
class PricingCard extends StatelessWidget {
  final bool selected;
  final String title;
  final String price;
  final String note;

  /// When true, the [note] line turns purple/bold while [selected]
  /// (yearly card). Monthly keeps its grey note even when selected.
  final bool highlightNoteWhenSelected;
  final VoidCallback onTap;

  const PricingCard({
    super.key,
    required this.selected,
    required this.title,
    required this.price,
    required this.note,
    required this.onTap,
    this.highlightNoteWhenSelected = false,
  });

  static const _purple = Color(0xFF8B5CF6);
  static const _purpleDeep = Color(0xFF7A45E0);
  static const _noteGrey = Color(0xFF9A938A);

  @override
  Widget build(BuildContext context) {
    final noteHot = selected && highlightNoteWhenSelected;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF7F1FE), Color(0xFFEFE6FB)],
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _purple : const Color(0xFFEFE6D6),
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                color: selected ? _purpleDeep : const Color(0xFF8A7E70),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              price,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2A211B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              note,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: noteHot ? FontWeight.w700 : FontWeight.w600,
                color: noteHot ? _purpleDeep : _noteGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width purple-gradient CTA button with a soft purple shadow and a
/// looping `sheen` shimmer sweeping left→right (matches the HTML).
class PrimaryGradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const PrimaryGradientButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  State<PrimaryGradientButton> createState() => _PrimaryGradientButtonState();
}

class _PrimaryGradientButtonState extends State<PrimaryGradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen;

  @override
  void initState() {
    super.initState();

    _sheen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.7),
              blurRadius: 32,
              offset: const Offset(0, 16),
              spreadRadius: -12,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Button background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9466F2), Color(0xFF6D3BD4)],
                  ),
                ),
              ),

              // Full button shimmer
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _sheen,
                  builder: (_, __) {
                    final t = _sheen.value;

                    return IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(-2.0 + (t * 4.0), -0.5),
                            end: Alignment(-1.0 + (t * 4.0), 0.5),
                            colors: const [
                              Color(0x00FFFFFF),
                              Color(0x25FFFFFF),
                              Color(0x70FFFFFF),
                              Color(0x25FFFFFF),
                              Color(0x00FFFFFF),
                            ],
                            stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Button text
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
