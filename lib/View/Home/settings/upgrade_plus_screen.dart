import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/subscription_service.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

/// Upgrade to Plus paywall — a line-by-line port of design screen "71 · Upgrade
/// to Plus" (and its 71b "Monthly selected" variant): one screen with a
/// Monthly/Yearly toggle that swaps the CTA, caption and trial note.
///
/// No billing SDK yet — the CTA activates Plus directly via
/// [SubscriptionService.setPlus] so the whole gating system is usable. Swap that
/// call for a store purchase that ends in `setPlus(true)` when integrating IAP.
class UpgradePlusScreen extends StatefulWidget {
  const UpgradePlusScreen({super.key});

  @override
  State<UpgradePlusScreen> createState() => _UpgradePlusScreenState();
}

class _UpgradePlusScreenState extends State<UpgradePlusScreen>
    with SingleTickerProviderStateMixin {
  /// Yearly is selected by default (matches screen 71).
  bool _yearly = true;
  late final AnimationController _anim;

  // ── Design tokens (from the HTML) ──────────────────────────────────────────
  static const _bg = Color(0xFFFBF4EA);
  static const _ink = Color(0xFF2A211B);
  static const _muted = Color(0xFF8A7E70);
  static const _sub = Color(0xFF9A938A);
  static const _purple = Color(0xFF8B5CF6);
  static const _purpleDeep = Color(0xFF7A45E0);
  static const _grad1 = Color(0xFF9466F2);
  static const _grad2 = Color(0xFF6D3BD4);
  static const _cardBorder = Color(0xFFEFE6D6);

  static const _monthlyPrice = '₹199';
  static const _yearlyPrice = '₹1,700';
  static const _yearlyPerMonth = '₹142 / month';

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    await SubscriptionService.instance.setPlus(true);
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 2, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _closeButton(),
              _badge(),
              const SizedBox(height: 16),
              _plusPill(),
              const SizedBox(height: 13),
              Text(
                'plus_paywall_title'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  height: 1.12,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 9),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'plus_paywall_sub'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ..._benefits(),
              Container(height: 140, color: Colors.red, child: const Center(child: Text('MARK'))),
                            _footerLinks(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pieces ─────────────────────────────────────────────────────────────────

  Widget _washCircle(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0, 0.7],
          ),
        ),
      ),
    );
  }

  Widget _closeButton() {
    return Align(
      alignment: Alignment.centerRight,
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
          child: const OnboardingLineIcon('x', size: 18, color: _muted),
        ),
      ),
    );
  }

  Widget _badge() {
    return Center(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final float = math.sin(_anim.value * math.pi) * 3;
          final glow = 0.35 + 0.25 * _anim.value;
          return SizedBox(
            width: 92,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
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
                        color: _purple.withValues(alpha: glow),
                        blurRadius: 26,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, float),
                  child: const OnboardingLineIcon(
                    'crown',
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const Positioned(
                  top: 4,
                  right: 6,
                  child: OnboardingLineIcon(
                    'sparkF',
                    size: 15,
                    color: Color(0xFFF2A24C),
                  ),
                ),
                const Positioned(
                  bottom: 8,
                  left: 6,
                  child: OnboardingLineIcon('spark', size: 14, color: _purple),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _plusPill() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEFE6FB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'recipe_ai_plus'.tr,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _purpleDeep,
            letterSpacing: 0.66,
          ),
        ),
      ),
    );
  }

  List<Widget> _benefits() {
    const items = [
      ['sparkF2', 0xFF8B5CF6, 0xFFF4EEFD, 'bnf_imports', 'bnf_imports_sub'],
      ['chat', 0xFF2D6FE0, 0xFFE4ECFB, 'bnf_assistant', 'bnf_assistant_sub'],
      ['bowl', 0xFF1F8A5B, 0xFFEAF6F0, 'bnf_nutrition', 'bnf_nutrition_sub'],
      ['cal', 0xFFE0481F, 0xFFFCEAE3, 'bnf_mealplan', 'bnf_mealplan_sub'],
      ['ruler', 0xFFC0860F, 0xFFFCF3DE, 'bnf_converter', 'bnf_converter_sub'],
      ['file', 0xFF8B5CF6, 0xFFF4EEFD, 'bnf_pdf', 'bnf_pdf_sub'],
    ];
    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      widgets.add(_benefitCard(
        icon: it[0] as String,
        iconColor: Color(it[1] as int),
        iconBg: Color(it[2] as int),
        title: (it[3] as String).tr,
        subtitle: (it[4] as String).tr,
      ));
      if (i != items.length - 1) widgets.add(const SizedBox(height: 10));
    }
    return widgets;
  }

  Widget _benefitCard({
    required String icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
            spreadRadius: -18,
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
              color: iconBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: OnboardingLineIcon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _muted,
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
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const OnboardingLineIcon(
              'check',
              size: 13,
              color: Color(0xFF1F8A5B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _plans() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _planCard(
            selected: !_yearly,
            onTap: () => setState(() => _yearly = false),
            label: 'plan_monthly'.tr,
            price: _monthlyPrice,
            note: 'per_month'.tr,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _planCard(
            selected: _yearly,
            onTap: () => setState(() => _yearly = true),
            label: 'plan_yearly'.tr,
            price: _yearlyPrice,
            note: _yearlyPerMonth,
            badge: 'save_30'.tr,
          ),
        ),
      ],
    );
  }

  Widget _planCard({
    required bool selected,
    required VoidCallback onTap,
    required String label,
    required String price,
    required String note,
    String? badge,
  }) {
    final card = GestureDetector(
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
            color: selected ? _purple : _cardBorder,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                color: selected ? _purpleDeep : _muted,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              price,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              note,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? _purpleDeep : _sub,
              ),
            ),
          ],
        ),
      ),
    );

    if (badge == null) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: -10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_grad1, _grad2]),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _trialNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3E2BC)),
      ),
      child: Row(
        children: [
          const OnboardingLineIcon('sparkF', size: 15, color: Color(0xFFC0860F)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'trial_yearly_only'.tr,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7A5B12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cta() {
    final label = _yearly
        ? 'start_free_trial'.tr
        : 'subscribe_price'.trParams({'price': '$_monthlyPrice/month'});
    return GestureDetector(
      onTap: _subscribe,
      child: Container(
        width: double.infinity,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_grad1, _grad2],
          ),
          boxShadow: [
            BoxShadow(
              color: _purple.withValues(alpha: 0.6),
              blurRadius: 32,
              offset: const Offset(0, 16),
              spreadRadius: -12,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _footerLinks() {
    Widget dot() => Container(
          width: 3,
          height: 3,
          decoration: const BoxDecoration(
            color: Color(0xFFC7BCAC),
            shape: BoxShape.circle,
          ),
        );
    Widget link(String s) => Text(
          s,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _muted,
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        link('restore'.tr),
        const SizedBox(width: 16),
        dot(),
        const SizedBox(width: 16),
        link('terms'.tr),
        const SizedBox(width: 16),
        dot(),
        const SizedBox(width: 16),
        link('privacy_short'.tr),
      ],
    );
  }
}
