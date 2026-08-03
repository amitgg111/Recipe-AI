import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/View/Home/home_screen.dart';
import 'package:recipe_ai/View/Home/settings/upgrade_plus_screen.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:recipe_ai/Service/local_notification_service.dart';
import 'package:recipe_ai/Service/revenuecat_service.dart';
import 'package:recipe_ai/widgets/custom_snackbar.dart';
import 'package:get_storage/get_storage.dart';

class TrialChooserScreen extends StatefulWidget {
  const TrialChooserScreen({super.key});

  @override
  State<TrialChooserScreen> createState() => _TrialChooserScreenState();
}

class _TrialChooserScreenState extends State<TrialChooserScreen> {
  // Default stays on the free 7-day option (index 0), as before.
  int _selectedPlan = 0;
  bool _remindMe = true;
  bool _busy = false;

  final _rc = RevenueCatService.instance;
  final _box = GetStorage();

  @override
  void initState() {
    super.initState();
    // Make sure offerings are loading/loaded so the yearly card + button
    // reflect real store data as soon as possible.
    _rc.fetchOfferings();
  }

  // ── Store-sourced yearly plan (replaces the old hardcoded ₹99.00) ─────────

  Package? get _yearlyPkg => _rc.yearly;

  String get _yearlyPrice => _yearlyPkg?.storeProduct.priceString ?? '₹1,700';

  String get _yearlyName => _yearlyPkg?.storeProduct.title ?? 'plan_yearly'.tr;

  /// Trial length pulled from the yearly package's introductory offer
  /// (e.g. a 7-day free intro period). Falls back to 7 when offerings
  /// haven't loaded yet or there's no intro offer configured.
  int get _yearlyTrialDays {
    final intro = _yearlyPkg?.storeProduct.introductoryPrice;
    if (intro == null) return 7;
    final count = intro.periodNumberOfUnits;
    switch (intro.periodUnit) {
      case PeriodUnit.day:
        return count;
      case PeriodUnit.week:
        return count * 7;
      case PeriodUnit.month:
        return count * 30;
      case PeriodUnit.year:
        return count * 365;
      default:
        return 7;
    }
  }

  /// Price of the intro/trial period itself (e.g. "₹0.00" for a free trial
  /// on the yearly plan). Falls back to ₹0.00 if there's no intro offer or
  /// offerings haven't loaded.
  String get _yearlyIntroPrice =>
      _yearlyPkg?.storeProduct.introductoryPrice?.priceString ?? '₹0.00';

  /// Button label depends on which card is selected:
  ///  - Free (index 0): plain "Continue" — no purchase happens on tap.
  ///  - Yearly (index 1): "Redeem {trial days} days for {intro price}" —
  ///    tapping this actually purchases the yearly package.
  /// These are plain strings (not `.tr`) so the wording always matches
  /// exactly what was asked for — wire them into your localization files
  /// (e.g. `continue_label`, `redeem_trial_price`) when convenient.
  String get _buttonLabel {
    if (_busy) return 'please_wait'.tr;
    if (_selectedPlan == 0) return 'Continue';
    return 'Redeem $_yearlyTrialDays days for $_yearlyIntroPrice';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header image grid: height 230, no safe area padding
              _buildHeroImages(),
              // Content: padding 4px 26px 26px, margin-top -8px
              Transform.translate(
                offset: const Offset(0, -8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 4, 26, 26),
                  child: Column(
                    children: [
                      // Title
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            height: 1.18,
                            letterSpacing: -0.52,
                          ),
                          children: [
                            TextSpan(text: 'trial_title_1'.tr),
                            TextSpan(
                              text: 'trial_title_2'.tr,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.purple,
                                height: 1.18,
                                letterSpacing: -0.52,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 11),
                      // Trial option 1: FREE 7 day (unchanged, default-selected)
                      _buildPlanOption(
                        index: 0,
                        price: 'free_caps'.tr,
                        period: 'seven_day_trial'.tr,
                      ),
                      const SizedBox(height: 8),
                      // Trial option 2: dynamic yearly price + name straight
                      // from RevenueCat.
                      Obx(() {
                        _rc.offering.value; // rebuild when store data loads
                        return _buildPlanOption(
                          index: 1,
                          price: _yearlyPrice,
                          period: _yearlyName,
                        );
                      }),
                      const SizedBox(height: 8),
                      // Reminder toggle
                      _buildRemindToggle(),
                      const SizedBox(height: 8),
                      // View all plans link -> goes to the full paywall
                      GestureDetector(
                        onTap: () => Get.to(() => const UpgradePlusScreen()),
                        child: Text(
                          'view_all_plans'.tr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMedium,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.textMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Stats row
                      // _buildStatsRow(),
                      const SizedBox(height: 8),
                      // No payment row
                      _buildNoPaymentRow(),
                      const SizedBox(height: 14),
                      // Button — label switches based on selected plan.
                      Obx(() {
                        _rc.offering.value;
                        return PrimaryButton.purple(
                          label: _buttonLabel,
                          onPressed: _busy ? null : _onRedeemPressed,
                        );
                      }),
                      const SizedBox(height: 10),
                      // Disclaimer
                      Text(
                        'trial_disclaimer'.tr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textLighter,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Redeem/Continue button handler.
  ///
  ///  - Free plan selected (index 0): no purchase — just schedule/cancel the
  ///    reminder and continue to account creation, exactly like a plain
  ///    "Continue" action.
  ///  - Yearly plan selected (index 1): actually purchase the yearly package
  ///    via RevenueCat (its introductory offer covers the free/trial days).
  ///    - If offerings aren't available yet (RC not configured / not
  ///      loaded), fall back to proceeding so the app stays usable
  ///      pre-store-setup.
  ///    - If the user cancels, stay on this screen (no error, no nav).
  ///    - If it errors, show a snackbar and stay on this screen.
  Future<void> _onRedeemPressed() async {
    if (_busy) return;

    if (_selectedPlan == 0) {
      // Free trial — nothing to purchase, just continue.
      if (_remindMe) {
        final trialEndDate = _resolveTrialEndDate();
        await LocalNotificationService.instance.scheduleTrialEndReminder(
          trialEndDate: trialEndDate,
        );
      } else {
        await LocalNotificationService.instance.cancelTrialEndReminder();
      }
      await _markTrialChooserCompleted();
      if (!mounted) return;
      Get.offAll(() => const HomeScreen(), transition: Transition.noTransition);
      return;
    }

    // Yearly plan selected — this actually purchases it.
    setState(() => _busy = true);

    final pkg = _yearlyPkg;
    bool proceed;

    if (pkg == null) {
      // Offerings not configured/loaded yet — keep the flow usable.
      proceed = true;
    } else {
      try {
        proceed = await _rc.purchase(pkg);
      } catch (_) {
        if (mounted) {
          CustomSnackbar.show(
            title: 'purchase_failed'.tr,
            message: 'pdf_failed_msg'.tr,
            type: SnackbarType.error,
          );
        }
        if (mounted) setState(() => _busy = false);
        return;
      }
    }

    if (!proceed) {
      // User cancelled the purchase — stay on the screen, let them retry.
      if (mounted) setState(() => _busy = false);
      return;
    }

    if (_remindMe) {
      final trialEndDate = _resolveTrialEndDate();
      await LocalNotificationService.instance.scheduleTrialEndReminder(
        trialEndDate: trialEndDate,
      );
    } else {
      await LocalNotificationService.instance.cancelTrialEndReminder();
    }

    await _markTrialChooserCompleted();
    if (!mounted) return;
    Get.offAll(() => const HomeScreen(), transition: Transition.noTransition);
  }

  Future<void> _markTrialChooserCompleted() async {
    _box.write(
      'trial_chooser_completed_${FirebaseAuth.instance.currentUser?.uid ?? "guest"}',
      true,
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'trialChooserCompleted': true,
        'trialChooserCompletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Local flag is still enough to keep the user moving forward if the
      // network is unavailable during the transition.
    }
  }

  /// Prefer the real date RevenueCat reports for the active entitlement
  /// (accurate right after a purchase); fall back to a local estimate
  /// based on the selected plan's trial length otherwise — 7 days for the
  /// free plan, or the yearly package's live intro length for the yearly
  /// plan.
  DateTime _resolveTrialEndDate() {
    final isoDate =
        RevenueCatService.instance.activeEntitlement?.expirationDate;
    if (isoDate != null) {
      final parsed = DateTime.tryParse(isoDate);
      if (parsed != null) return parsed.toLocal();
    }
    final days = _selectedPlan == 0 ? 7 : _yearlyTrialDays;
    return DateTime.now().add(Duration(days: days));
  }

  Widget _buildHeroImages() {
    return SizedBox(
      height: 210,
      child: Stack(
        children: [
          // 3-column grid with 5px gap, opacity 0.96
          Opacity(
            opacity: 0.96,
            child: Row(
              children: [
                Expanded(
                  child: _HeroImage(
                    url:
                        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=240&q=80&auto=format&fit=crop',
                    fallback: Colors.orange.shade200,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _HeroImage(
                    url:
                        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=240&q=80&auto=format&fit=crop',
                    fallback: Colors.green.shade200,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _HeroImage(
                    url:
                        'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=240&q=80&auto=format&fit=crop',
                    fallback: Colors.red.shade200,
                  ),
                ),
              ],
            ),
          ),
          // Gradient overlay: linear-gradient 180deg, transparent 40% -> background 100%
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFBF4EA).withValues(alpha: 0),
                    const Color(0xFFFBF4EA),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ),
          // Close button: absolute top 14px, right 18px

          // "Healthy" tag: top 64, left 24, rotate -6deg
          Positioned(
            top: 64,
            left: 24,
            child: Transform.rotate(
              angle: -6 * 3.14159265 / 180,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldStar,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  'healthy'.tr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5A4410),
                  ),
                ),
              ),
            ),
          ),
          // "Fall recipes" tag: top 48, right 30, rotate 7deg
          Positioned(
            top: 48,
            right: 30,
            child: Transform.rotate(
              angle: 7 * 3.14159265 / 180,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.starOrange,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  'fall_recipes'.tr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5A3410),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 35,
            right: 18,
            child: GestureDetector(
              onTap: () async {
                await _markTrialChooserCompleted();
                if (!mounted) return;
                Get.offAll(
                  () => const HomeScreen(),
                  transition: Transition.noTransition,
                );
              },
              child: Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const OnboardingLineIcon(
                  'x',
                  size: 20,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption({
    required int index,
    required String price,
    required String period,
  }) {
    final isSelected = _selectedPlan == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.purple : AppColors.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                    spreadRadius: -16,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  period,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Container(
                width: 26,
                height: 26,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.purple,
                  shape: BoxShape.circle,
                ),
                child: const OnboardingLineIcon(
                  'check',
                  color: Colors.white,
                  size: 16,
                ),
              )
            else
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.unselectedBorder,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.purpleBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'remind_me_before_trial_ends'.tr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _remindMe = !_remindMe),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 27,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: _remindMe
                    ? AppColors.purple
                    : AppColors.unselectedBorder,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: _remindMe
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 21,
                height: 21,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildStatsRow() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       // 10M+ stat
  //       Column(
  //         children: [
  //           Text(
  //             '10M+',
  //             style: GoogleFonts.plusJakartaSans(
  //               fontSize: 18,
  //               fontWeight: FontWeight.w800,
  //               color: AppColors.textDark,
  //             ),
  //           ),
  //           Text(
  //             'happy_cooks'.tr,
  //             style: GoogleFonts.plusJakartaSans(
  //               fontSize: 11,
  //               fontWeight: FontWeight.w600,
  //               color: AppColors.textMedium,
  //             ),
  //           ),
  //         ],
  //       ),
  //       // Divider: 1px wide, 28px tall
  //       Container(
  //         width: 1,
  //         height: 28,
  //         color: AppColors.unselectedBorder,
  //         margin: const EdgeInsets.symmetric(horizontal: 22),
  //       ),
  //       // Stars + rating
  //       Column(
  //         children: [
  //           Row(
  //             children: List.generate(
  //               5,
  //               (_) => const OnboardingLineIcon(
  //                 'starF',
  //                 color: AppColors.goldStar,
  //                 size: 14,
  //               ),
  //             ),
  //           ),
  //           const SizedBox(height: 2),
  //           Text(
  //             'rating_4_8'.tr,
  //             style: GoogleFonts.plusJakartaSans(
  //               fontSize: 11,
  //               fontWeight: FontWeight.w600,
  //               color: AppColors.textMedium,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  Widget _buildNoPaymentRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const OnboardingLineIcon(
            'checkCircle',
            color: AppColors.green,
            size: 20,
          ),
          const SizedBox(width: 7),
          Text(
            'no_payment_now'.tr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String url;
  final Color fallback;

  const _HeroImage({required this.url, required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      height: double.infinity,
      width: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(color: fallback);
      },
      errorBuilder: (context, error, stack) => Container(color: fallback),
    );
  }
}
