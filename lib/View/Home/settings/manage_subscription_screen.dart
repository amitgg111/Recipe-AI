import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/revenuecat_service.dart';
import 'package:recipe_ai/View/Home/settings/settings_common.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

/// "Manage subscription" — the Plus plan detail screen. Shows the active plan
/// and billing details fetched from RevenueCat.
class ManageSubscriptionScreen extends StatelessWidget {
  const ManageSubscriptionScreen({super.key});

  static const _purple = Color(0xFF7C3AED);
  static const _purple2 = Color(0xFF9333EA);
  static const _danger = Color(0xFFE0481F);

  static String get renewDate {
    final active = RevenueCatService.instance.activeEntitlement;
    final isoDate = active?.expirationDate;
    if (isoDate == null) return 'N/A';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return 'N/A';
    }
  }

  String get _priceString {
    final activeId = RevenueCatService.instance.activeEntitlement?.productIdentifier;
    final service = RevenueCatService.instance;
    if (activeId != null) {
      if (service.yearly?.storeProduct.identifier == activeId) {
        return service.yearly?.storeProduct.priceString ?? '₹1,700/yr';
      }
      if (service.monthly?.storeProduct.identifier == activeId) {
        return service.monthly?.storeProduct.priceString ?? '₹200/mo';
      }
    }
    return '₹1,700/yr';
  }

  String get _planName {
    final activeId = RevenueCatService.instance.activeEntitlement?.productIdentifier;
    final service = RevenueCatService.instance;
    if (activeId != null) {
      if (service.monthly?.storeProduct.identifier == activeId) {
        // Fallback to English if translation is missing
        return 'monthly_plan'.tr == 'monthly_plan' ? 'Monthly Plan' : 'monthly_plan'.tr;
      }
    }
    return 'yearly_plan'.tr;
  }

  String get _paymentMethod {
    if (Platform.isIOS) {
      return 'App Store';
    } else if (Platform.isAndroid) {
      return 'Google Play';
    }
    return 'Store';
  }

  void _confirmCancel() {
    Get.bottomSheet(
      _CancelSheet(renewDate: renewDate),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          final renewDateStr = renewDate;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsUi.header('manage_subscription'.tr),
                const SizedBox(height: 18),
                _planCard(renewDateStr),
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
                      trailing: _value(renewDateStr),
                    ),
                    SettingsUi.row(
                      leadingIcon: const OnboardingLineIcon(
                        'file',
                        color: SettingsUi.rowIcon,
                        size: 20,
                      ),
                      label: 'payment_method'.tr,
                      showChevron: false,
                      trailing: _value(_paymentMethod),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _cancelButton(),
                const SizedBox(height: 12),
                Text(
                  'keep_plus_until'.trParams({'date': renewDateStr}),
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
          );
        }),
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

  Widget _planCard(String renewDateStr) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recipe AI Plus',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _PlanSub(planName: _planName),
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
                  'renews_date'.trParams({'date': renewDateStr}),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xE6FFFFFF),
                  ),
                ),
                const Spacer(),
                Text(
                  _priceString,
                  style: const TextStyle(
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
  final String planName;
  const _PlanSub({required this.planName});
  
  @override
  Widget build(BuildContext context) {
    return Text(
      planName,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: Color(0xCCFFFFFF),
      ),
    );
  }
}

/// Confirmation sheet shown before cancelling. "Keep my Plus" dismisses it;
/// "Cancel anyway" opens the native subscription management page.
class _CancelSheet extends StatelessWidget {
  final String renewDate;
  const _CancelSheet({required this.renewDate});

  static const _purple = Color(0xFF7C3AED);
  static const _purple2 = Color(0xFF9333EA);
  static const _danger = Color(0xFFE0481F);

  void _cancelAnyway() {
    Get.back(); // close the sheet
    // Open native subscription management (App Store / Play Store)
    RevenueCatService.instance.showManageSubscriptions();
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

  Widget _subtitle() {
    final full = 'keep_until_lose'.trParams({'date': renewDate});
    const base = TextStyle(
      fontSize: 13,
      height: 1.45,
      fontWeight: FontWeight.w500,
      color: AppColors.textMedium,
    );
    final idx = full.indexOf(renewDate);
    if (idx < 0) {
      return Text(full, textAlign: TextAlign.center, style: base);
    }
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: full.substring(0, idx)),
          TextSpan(
            text: renewDate,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          TextSpan(text: full.substring(idx + renewDate.length)),
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
