import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Controllers/profile_controller.dart';
import 'package:recipe_ai/Controllers/settings_controller.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/subscription_service.dart';
import 'package:recipe_ai/View/Auth/auth_wrapper.dart';
import 'package:recipe_ai/View/Home/settings/help_center_screen.dart';
import 'package:recipe_ai/View/Home/settings/language_screen.dart';
import 'package:recipe_ai/View/Home/settings/notification_settings_screen.dart';
import 'package:recipe_ai/View/Home/settings/privacy_terms_screen.dart';
import 'package:recipe_ai/View/Home/settings/profile_view_screen.dart';
import 'package:recipe_ai/View/Home/settings/send_feedback_screen.dart';
import 'package:recipe_ai/View/Home/settings/settings_common.dart';
import 'package:recipe_ai/View/Home/settings/upgrade_plus_screen.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/sliding_segmented.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

/// The "More" tab (bottom-nav index 4). Settings hub matching the HTML design.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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

              // ---- Upgrade to Plus banner ----
              _plusBanner(),

              const SizedBox(height: 14),

              // ---- Import credits ----
              _creditsCard(),

              // ---- APP section ----
              SettingsUi.label('section_app'.tr),
              SettingsUi.card(
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
                  _unitsRow(settings),
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
              ),

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

  Widget _profileCard(ProfileController profileController) {
    final user = FirebaseAuth.instance.currentUser;
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName?.isNotEmpty == true
                        ? user!.displayName!
                        : 'User',
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
                    user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Plus',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Unlimited imports, nutrition & AI',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xD9FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
            const OnboardingLineIcon('chevR', color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _creditsCard() {
    return Obx(() {
      final sub = SubscriptionService.instance;
      final plus = sub.isPlusListenable.value;
      final used = sub.importCountListenable.value;
      const max = SubscriptionService.kFreeImportLimit;
      final remaining = (max - used).clamp(0, max);
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
                  const Text(
                    'Import credits',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    plus ? 'Unlimited imports' : '$remaining of $max left',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
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
          Get.back();
          await _deleteAccount();
        },
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      Get.find<ProfileController>().clearLocalData();
      await user.delete();
      // AuthWrapper reacts to authStateChanges and redirects automatically.
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Fall back to logout so the user can re-authenticate then retry.
        await AuthService.logout();
      }
    } catch (_) {}
  }
}

class _ConfirmDialog extends StatelessWidget {
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
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
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
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.surfaceBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
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
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
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
