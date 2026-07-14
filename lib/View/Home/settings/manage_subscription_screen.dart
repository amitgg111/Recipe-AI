import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/subscription_service.dart';
import 'package:recipe_ai/View/Home/settings/settings_common.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

/// "Manage subscription" — the Plus plan detail screen reached from the
/// membership card's "Manage plan" link. Shows the active plan, billing details
/// and a cancel action. No billing SDK yet, so the dates/method are the design
/// placeholders and Cancel just flips the local plan back to Free.
class ManageSubscriptionScreen extends StatelessWidget {
  const ManageSubscriptionScreen({super.key});

  // Design placeholders (shared with the membership card).
  static const String renewDate = '12 Jul 2026';
  static const String priceYr = '₹1,700/yr';
  static const String payment = 'UPI · ···· 8821';

  static const _purple = Color(0xFF7C3AED);
  static const _purple2 = Color(0xFF9333EA);
  static const _danger = Color(0xFFE0481F);

  // "Cancel subscription" opens a confirmation sheet first; only "Cancel
  // anyway" inside it actually flips the plan back to Free.
  void _confirmCancel() {
    Get.bottomSheet(
      const _CancelSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsUi.header('manage_subscription'.tr),
              const SizedBox(height: 18),
              _planCard(),
              SettingsUi.label('section_billing'.tr),
              SettingsUi.card(
                rows: [
                  SettingsUi.row(
                    leadingIcon: const OnboardingLineIcon(
                      'cal',
                      color: SettingsUi.rowIcon,
                      size: 20,
                    ),
                    label: 'next_billing_date'.tr,
                    showChevron: false,
                    trailing: _value(renewDate),
                  ),
                  SettingsUi.row(
                    leadingIcon: const OnboardingLineIcon(
                      'file',
                      color: SettingsUi.rowIcon,
                      size: 20,
                    ),
                    label: 'payment_method'.tr,
                    showChevron: false,
                    trailing: _value(payment),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _cancelButton(),
              const SizedBox(height: 12),
              Text(
                'keep_plus_until'.trParams({'date': renewDate}),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _value(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      );

  Widget _planCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_purple, _purple2],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -16,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  child: const OnboardingLineIcon(
                    'crown',
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recipe AI Plus',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      _PlanSub(),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _activeBadge(),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.white.withValues(alpha: 0.22),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 13),
            child: Row(
              children: [
                Text(
                  'renews_date'.trParams({'date': renewDate}),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xE6FFFFFF),
                  ),
                ),
                const Spacer(),
                const Text(
                  priceYr,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _activeBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'plus_active'.tr,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _cancelButton() {
    return GestureDetector(
      onTap: _confirmCancel,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _danger.withValues(alpha: 0.35)),
        ),
        child: Text(
          'cancel_subscription'.tr,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _danger,
          ),
        ),
      ),
    );
  }
}

class _PlanSub extends StatelessWidget {
  const _PlanSub();
  @override
  Widget build(BuildContext context) {
    return Text(
      'yearly_plan'.tr,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: Color(0xCCFFFFFF),
      ),
    );
  }
}

/// Confirmation sheet shown before cancelling. "Keep my Plus" dismisses it;
/// "Cancel anyway" flips the plan back to Free and returns to the previous
/// screen with a snackbar.
class _CancelSheet extends StatelessWidget {
  const _CancelSheet();

  static const _purple = Color(0xFF7C3AED);
  static const _purple2 = Color(0xFF9333EA);
  static const _danger = Color(0xFFE0481F);

  void _cancelAnyway() {
    Get.back(); // close the sheet
    SubscriptionService.instance.setPlus(false);
    Get.back(); // leave the manage screen
    CustomSnackbar.show(
      title: 'subscription_cancelled'.tr,
      message: 'keep_plus_until'
          .trParams({'date': ManageSubscriptionScreen.renewDate}),
      type: SnackbarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 22),
              // Crown badge
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.redBg,
                  shape: BoxShape.circle,
                ),
                child: const OnboardingLineIcon(
                  'crown',
                  size: 26,
                  color: _danger,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'cancel_plus_q'.tr,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              _subtitle(),
              const SizedBox(height: 18),
              _loseRow('lose_imports_assistant'.tr),
              const SizedBox(height: 10),
              _loseRow('lose_nutrition_converter'.tr),
              const SizedBox(height: 10),
              _loseRow('lose_pdfs'.tr),
              const SizedBox(height: 22),
              _keepButton(),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _cancelAnyway,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'cancel_anyway'.tr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _danger,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // "You'll keep Plus until <date>, then lose these:" with the date in bold.
  Widget _subtitle() {
    final full = 'keep_until_lose'
        .trParams({'date': ManageSubscriptionScreen.renewDate});
    const date = ManageSubscriptionScreen.renewDate;
    const base = TextStyle(
      fontSize: 13,
      height: 1.45,
      fontWeight: FontWeight.w500,
      color: AppColors.textMedium,
    );
    final idx = full.indexOf(date);
    if (idx < 0) {
      return Text(full, textAlign: TextAlign.center, style: base);
    }
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: full.substring(0, idx)),
          TextSpan(
            text: date,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          TextSpan(text: full.substring(idx + date.length)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _loseRow(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.close_rounded, size: 18, color: _danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _keepButton() {
    return GestureDetector(
      onTap: Get.back,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_purple, _purple2],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _purple.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Text(
          'keep_my_plus'.tr,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
