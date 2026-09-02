import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Controllers/discover_controller.dart';
import 'package:recipe_ai/Controllers/notification_controller.dart';
import 'package:recipe_ai/Controllers/profile_controller.dart';
import 'package:recipe_ai/Controllers/settings_controller.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/remote_config_service.dart';
import 'package:recipe_ai/Service/subscription_service.dart';
import 'package:recipe_ai/View/Auth/auth_wrapper.dart';
import 'package:recipe_ai/screens/auth/create_account_screen.dart';
import 'package:recipe_ai/View/Home/settings/help_center_screen.dart';
import 'package:recipe_ai/View/Home/settings/language_screen.dart';
import 'package:recipe_ai/View/Home/settings/manage_subscription_screen.dart';
import 'package:recipe_ai/View/Home/settings/notification_settings_screen.dart';
import 'package:recipe_ai/View/Home/settings/privacy_terms_screen.dart';
import 'package:recipe_ai/View/Home/settings/profile_view_screen.dart';
import 'package:recipe_ai/View/Home/settings/send_feedback_screen.dart';
import 'package:recipe_ai/View/Home/settings/settings_common.dart';
import 'package:recipe_ai/View/Home/settings/upgrade_plus_screen.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/sliding_segmented.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

// ⚠️ Adjust this import to wherever AllCuisinesScreen actually lives in your
// project (it's the same screen already used from CuisinesBody during
// onboarding — reused here as-is so both places stay in sync).
import 'package:recipe_ai/screens/onboarding/all_cuisines_screen.dart';

/// The "More" tab (bottom-nav index 4). Settings hub matching the HTML design.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
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
    final profileController = Get.find<ProfileController>();
    final settings = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'more'.tr,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: -0.4,
                  ),
                ),
              ),

              // ---- Profile card ----
              _profileCard(profileController),

              const SizedBox(height: 14),

              // ---- Membership card: the free "Upgrade" banner fades into the
              // active-plan card once the user is Plus (only premium difference).
              _membershipArea(),

              const SizedBox(height: 14),

              // ---- Import credits ----
              _creditsCard(),

              // ---- RECIPE AI PLUS section (shown to Plus users only) ----
              _premiumSection(),

              // ---- APP section ----
              SettingsUi.label('section_app'.tr),
              // Units (Metric/US) is a Plus feature, so the tile is shown to
              // Plus users only and hidden for free users. Obx keeps it live —
              // upgrading reveals the tile without leaving the screen.
              Obx(() {
                final plus =
                    SubscriptionService.instance.isPlusListenable.value;
                return SettingsUi.card(
                  rows: [
                    SettingsUi.row(
                      leadingIcon: const OnboardingLineIcon(
                        'bellSm',
                        color: SettingsUi.rowIcon,
                        size: 20,
                      ),
                      label: 'notifications'.tr,
                      onTap: () =>
                          Get.to(() => const NotificationSettingsScreen()),
                    ),
                    // Cuisine Preferences — reuses the same AllCuisinesScreen
                    // shown during onboarding, so the user can add/remove
                    // preferred cuisines any time. Discover's chip row
                    // ("All", <preferred cuisines>, Quick & Easy, ...) is
                    // refreshed as soon as they come back.
                    _cuisinePreferencesRow(),
                    if (plus) _unitsRow(settings),
                    SettingsUi.row(
                      leadingIcon: const OnboardingLineIcon(
                        'globe',
                        color: SettingsUi.rowIcon,
                        size: 20,
                      ),
                      label: 'language'.tr,
                      trailing: Obx(
                        () => Text(
                          settings.language.value,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                      onTap: () => Get.to(() => const LanguageScreen()),
                    ),
                  ],
                );
              }),

              // ---- SUPPORT section ----
              SettingsUi.label('section_support'.tr),
              SettingsUi.card(
                rows: [
                  SettingsUi.row(
                    leadingIcon: const OnboardingLineIcon(
                      'helpC',
                      color: SettingsUi.rowIcon,
                      size: 20,
                    ),
                    label: 'help_center'.tr,
                    onTap: () => Get.to(() => const HelpCenterScreen()),
                  ),
                  SettingsUi.row(
                    leadingIcon: const OnboardingLineIcon(
                      'flag',
                      color: SettingsUi.rowIcon,
                      size: 20,
                    ),
                    label: 'send_feedback'.tr,
                    onTap: () => Get.to(() => const SendFeedbackScreen()),
                  ),
                  SettingsUi.row(
                    leadingIcon: const OnboardingLineIcon(
                      'shield',
                      color: SettingsUi.rowIcon,
                      size: 20,
                    ),
                    label: 'privacy_and_terms'.tr,
                    onTap: () => Get.to(() => const PrivacyTermsScreen()),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ---- Log out ----
              _logoutButton(profileController),
              const SizedBox(height: 8),
              _deleteAccountButton(),

              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'Recipe AI · v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSubtle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Cuisine Preferences" settings row → opens AllCuisinesScreen (same one
  /// used in onboarding). On return, refreshes DiscoverController's
  /// preferred-cuisine list so the Discover chip row updates immediately
  /// without needing a full feed refetch.
  Widget _cuisinePreferencesRow() {
    return SettingsUi.row(
      leadingIcon: const OnboardingLineIcon(
        'flame',
        color: SettingsUi.rowIcon,
        size: 20,
      ),

      // label: 'Cuisine Preferences'.tr,
      label: 'select_cuisine'.tr,
      onTap: () async {
        await Get.to(() => const AllCuisinesScreen());

        if (Get.isRegistered<DiscoverController>()) {
          // await Get.find<DiscoverController>().refreshPreferredCuisines();
        }
      },
    );
  }

  Widget _profileCard(ProfileController profileController) {
    return GestureDetector(
      onTap: () => Get.to(() => const ProfileViewScreen()),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.surfaceBorder),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2A211B).withValues(alpha: 0.4),
              blurRadius: 26,
              offset: const Offset(0, 12),
              spreadRadius: -22,
            ),
          ],
        ),
        child: Row(
          children: [
            const ProfileAvatar(size: 54),
            const SizedBox(width: 13),

            Expanded(
              child: Obx(() {
                final email = FirebaseAuth.instance.currentUser?.email ?? '';
                final emailName = email.contains('@')
                    ? email.split('@').first
                    : '';

                final displayName =
                    profileController.name.value.trim().isNotEmpty &&
                        profileController.name.value.trim().toLowerCase() !=
                            'user'
                    ? profileController.name.value.trim()
                    : (emailName.isNotEmpty ? emailName : 'User');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              }),
            ),

            const OnboardingLineIcon(
              'chevR',
              color: SettingsUi.chevron,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _plusBanner() {
    return GestureDetector(
      onTap: () => Get.to(() => const UpgradePlusScreen()),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B5CF6), Color(0xFF6D3BD4)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, 16),
              spreadRadius: -16,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9466F2), Color(0xFF6D3BD4)],
                  ),
                ),
              ),
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF6D3BD4).withValues(alpha: 0.4),
                      ),
                      child: const OnboardingLineIcon(
                        'crown',
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'upgrade_to_plus'.tr,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'unlimited_imports_nutrition_ai'.tr,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xD9FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const OnboardingLineIcon(
                      'chevR',
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Free "Upgrade" banner ⇄ active-plan card, cross-faded on plan change.
  Widget _membershipArea() {
    return Obx(() {
      final plus = SubscriptionService.instance.isPlusListenable.value;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: plus
            ? KeyedSubtree(
                key: const ValueKey('plusCard'),
                child: _premiumMembershipCard(),
              )
            : KeyedSubtree(
                key: const ValueKey('freeCard'),
                child: _plusBanner(),
              ),
      );
    });
  }

  /// Active-plan card — identical geometry to [_plusBanner] (padding / radius /
  /// shadow / row layout); only the deeper gradient, the copy and the ACTIVE
  /// badge differ, so the two feel like the same card upgraded.
  Widget _premiumMembershipCard() {
    return GestureDetector(
      onTap: () => Get.to(() => const ManageSubscriptionScreen()),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, 16),
              spreadRadius: -16,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF9466F2), Color(0xFF6D3BD4)],
                ),
              ),
            ),
            // ─────────────────────────────
            // FULL CARD SHIMMER
            // ─────────────────────────────
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
                          end: Alignment(-1.0 + (t * 4.0), 0.0),
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
            // ─────────────────────────────
            // CARD CONTENT
            // ─────────────────────────────
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        child: const OnboardingLineIcon(
                          'crown',
                          size: 20,
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
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'plus_active_renews'.trParams({
                                'date': ManageSubscriptionScreen.renewDate,
                              }),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xD9FFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
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
                      ),
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
                        'plus_yearly_yr'.tr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xE6FFFFFF),
                        ),
                      ),

                      const Spacer(),

                      Text(
                        'manage_plan'.tr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// "RECIPE AI PLUS" feature list — inserted above the app settings for Plus
  /// users only, built from the same [SettingsUi] label / card / row widgets as
  /// every other section (no new tile widget, no design drift).
  Widget _premiumSection() {
    return Obx(() {
      final plus = SubscriptionService.instance.isPlusListenable.value;
      if (!plus) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsUi.label('recipe_ai_plus'.tr),
          SettingsUi.card(
            rows: [
              _premiumFeatureTile(
                'sparkF2',
                const Color(0xFF8B5CF6),
                'bnf_imports'.tr,
              ),
              _premiumFeatureTile(
                'chat',
                const Color(0xFF2D6FE0),
                'bnf_assistant'.tr,
              ),
              _premiumFeatureTile(
                'bowl',
                const Color(0xFF1F8A5B),
                'bnf_nutrition'.tr,
              ),
              _premiumFeatureTile(
                'cal',
                const Color(0xFFE0481F),
                'bnf_mealplan'.tr,
              ),
              _premiumFeatureTile(
                'ruler',
                const Color(0xFFC0860F),
                'bnf_converter'.tr,
              ),
              _premiumFeatureTile(
                'file',
                const Color(0xFF8B5CF6),
                'bnf_pdf'.tr,
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _premiumFeatureTile(String icon, Color color, String label) {
    return SettingsUi.row(
      leadingIcon: OnboardingLineIcon(icon, size: 20, color: color),
      label: label,
      onTap: () {},
      showChevron: false,
      trailing: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded, size: 17, color: color),
      ),
    );
  }

  Widget _creditsCard() {
    return Obx(() {
      final sub = SubscriptionService.instance;
      final plus = sub.isPlusListenable.value;
      final remaining = sub.freeCreditsListenable.value;
      const max = SubscriptionService.kWeeklyFreeCredits;
      final frac = plus ? 1.0 : (max == 0 ? 0.0 : remaining / max);
      final accent = plus ? AppColors.purpleDark : AppColors.primary;
      return GestureDetector(
        // Dev/testing shortcut: long-press to toggle Plus locally (no billing
        // integration yet). Remove once a real purchase flow is wired.
        onLongPress: () => sub.setPlus(!plus),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: plus ? AppColors.purpleBg : AppColors.goldBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: OnboardingLineIcon(
                    plus ? 'crown' : 'sparkF',
                    color: plus ? AppColors.purpleDark : AppColors.gold,
                    size: 25,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plus ? 'recipe_imports'.tr : 'import_credits'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      plus
                          ? 'unlimited_with_plus'.tr
                          : 'credits_left_week'.trParams({
                              'count': '$remaining',
                              'max':
                                  '${RemoteConfigService.instance.newUserCredit}',
                            }),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              // Plus → an infinity chip; Free → the weekly-credits progress bar.
              if (plus)
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.purpleBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.all_inclusive_rounded,
                    size: 18,
                    color: AppColors.purpleDark,
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 64,
                    height: 7,
                    child: Stack(
                      children: [
                        Container(color: const Color(0xFFF0EADD)),
                        FractionallySizedBox(
                          widthFactor: frac,
                          child: Container(color: accent),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _unitsRow(SettingsController settings) {
    return SettingsUi.row(
      leadingIcon: const OnboardingLineIcon(
        'ruler',
        color: SettingsUi.rowIcon,
        size: 20,
      ),
      label: 'units'.tr,
      showChevron: false,
      trailing: Obx(
        () => SlidingSegmented(
          labels: const ['Metric', 'US'],
          selectedIndex: settings.units.value == 'US' ? 1 : 0,
          onChanged: (i) => settings.setUnits(i == 0 ? 'Metric' : 'US'),
          trackColor: AppColors.tabBg,
          pillColor: Colors.white,
          trackRadius: 9,
          pillRadius: 7,
          trackPadding: 2,
          hPad: 11,
          vPad: 5,
          style: (active) => GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: active ? FontWeight.w800 : FontWeight.w700,
            color: active ? AppColors.textDark : AppColors.textLight,
          ),
          pillShadow: [
            BoxShadow(
              color: AppColors.textDark.withValues(alpha: 0.12),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoutButton(ProfileController profileController) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(profileController),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: Color(0xFFF0D6CE)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const OnboardingLineIcon(
          'logout',
          color: Color(0xFFE0481F),
          size: 20,
        ),
        label: Text(
          'log_out'.tr,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE0481F),
          ),
        ),
      ),
    );
  }

  Widget _deleteAccountButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: TextButton.icon(
        onPressed: _confirmDeleteAccount,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const OnboardingLineIcon(
          'trash',
          color: Color(0xFFB0453A),
          size: 19,
        ),
        label: Text(
          'delete_account'.tr,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB0453A),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(ProfileController profileController) {
    Get.dialog(
      _ConfirmDialog(
        title: 'Log out?',
        message: 'You can always sign back in with your account.',
        confirmLabel: 'Log out',
        confirmColor: const Color(0xFFE0481F),
        onConfirm: () async {
          Get.back();
          // Clear the local profile cache, sign out, then hard-reset navigation
          // to the auth gate so the user actually leaves the logged-in area
          // (works even if the AuthWrapper stream is slow to react).
          profileController.clearLocalData();
          try {
            await SubscriptionService.instance.onLogout(); // ← આ ઉમેરો
            await AuthService.logout();
          } catch (_) {}
          Get.offAll(() => const AuthWrapper());
        },
      ),
    );
  }

  void _confirmDeleteAccount() {
    Get.dialog(
      _ConfirmDialog(
        title: 'Delete account?',
        message:
            'This permanently deletes your account and cannot be undone. You may need to sign in again to confirm.',
        confirmLabel: 'Delete',
        confirmColor: const Color(0xFFB0453A),
        onConfirm: () async {
          Get.back(); // confirm dialog band karo
          // _showFullScreenLoader(); // full screen spinner batavo
          await _deleteAccount();
        },
      ),
    );
  }

  // void _showFullScreenLoader() {
  //   Get.dialog(
  //     PopScope(
  //       canPop: false, // back button thi band na thay
  //       child: Container(
  //         color: Colors.black.withValues(alpha: 0.55),
  //         alignment: Alignment.center,
  //         child: const CircularProgressIndicator(
  //           valueColor: AlwaysStoppedAnimation(Colors.white),
  //         ),
  //       ),
  //     ),
  //     barrierDismissible: false,
  //     barrierColor: Colors.transparent,
  //   );
  // }

  // Future<void> _deleteAccount() async {
  //   try {
  //     await AuthService.deleteAccountEverywhere();
  //     if (Get.isRegistered<NotificationController>()) {
  //       Get.find<NotificationController>().clear();
  //     }
  //     Get.back(); // loader band karo
  //     await Get.offAll(
  //       () => const CreateAccountScreen(),
  //       transition: Transition.noTransition,
  //     );
  //   } catch (_) {
  //     Get.back(); // error avya to pan loader band karvu jaruri
  //   }
  // }
  Future<void> _deleteAccount() async {
    // 1) Local state + navigation TARAT j — no loader, no wait.
    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().clear();
    }
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().clearLocalData();
    }

    Get.offAll(
      () => const CreateAccountScreen(),
      transition: Transition.noTransition,
    );

    // 2) Actual account + data deletion background ma — await NATHI karvanu.
    // User ne hવે kai j dikhatu nathi, screen already badlai gayi.
    unawaited(
      AuthService.deleteAccountEverywhere().catchError((e) {
        // Silent fail — user already navigated away. Chho to error log karo
        // / analytics send karo debugging mate.
        debugPrint('❌ Background account deletion failed: $e');
      }),
    );
  }
}

class _ConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final Future<void> Function() onConfirm;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.surfaceBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text(
                        'cancel'.tr,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : () async {
                              setState(() => _loading = true);
                              try {
                                await widget.onConfirm();
                              } finally {
                                if (mounted) {
                                  setState(() => _loading = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.confirmColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              widget.confirmLabel,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
