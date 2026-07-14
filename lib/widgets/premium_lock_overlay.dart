import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/subscription_service.dart';
import 'package:recipe_ai/View/Home/settings/upgrade_plus_screen.dart';
import 'package:recipe_ai/theme/app_colors.dart';

/// Small gold-gradient "PLUS" pill used to mark premium features.
class PlusBadge extends StatelessWidget {
  final double fontSize;
  final EdgeInsets padding;
  const PlusBadge({
    super.key,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.purpleLight, AppColors.purpleDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleDark.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded,
              size: fontSize + 2, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            "plus_badge".tr,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrap any premium widget with this. Plus users see [child] exactly as-is;
/// free users see it blurred + dimmed (still discoverable) behind a frosted
/// lock card with a PLUS badge and an "Unlock with Plus" CTA. Tapping anywhere
/// on the locked state runs [onUpgrade] (defaults to the upgrade dialog).
///
/// It reacts to the plan live via `Obx`, so unlocking (or a dev toggle) animates
/// the lock away without a manual rebuild.
class PremiumLockOverlay extends StatelessWidget {
  final Widget child;
  final String title;
  final String description;
  final VoidCallback? onUpgrade;

  /// Force the locked/unlocked state instead of deriving it from `isPlus`.
  final bool? locked;

  /// Blur strength applied to the underlying [child] when locked.
  final double blurSigma;

  /// Rounds the blur + overlay to match the wrapped card.
  final BorderRadius borderRadius;

  const PremiumLockOverlay({
    super.key,
    required this.child,
    this.title = 'Plus feature',
    this.description = 'Upgrade to Plus to unlock this.',
    this.onUpgrade,
    this.locked,
    this.blurSigma = 6,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLocked =
          locked ?? !SubscriptionService.instance.isPlusListenable.value;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: isLocked
            ? _locked(context)
            : KeyedSubtree(key: const ValueKey('unlocked'), child: child),
      );
    });
  }

  Widget _locked(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('locked'),
      onTap: () => onUpgrade != null
          ? onUpgrade!()
          : showUpgradeDialog(context, feature: title),
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            // The real content, blurred + dimmed so it's teased but unusable.
            ImageFiltered(
              imageFilter:
                  ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Opacity(
                opacity: 0.55,
                child: IgnorePointer(child: child),
              ),
            ),
            Positioned.fill(
              child: Container(
                color: AppColors.purpleBgLight.withValues(alpha: 0.35),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                child: _lockCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lockCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.purpleBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleDark.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.purpleBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded,
                color: AppColors.purpleDark, size: 22),
          ),
          const SizedBox(height: 10),
          const PlusBadge(),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            description,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.purpleLight, AppColors.purpleDark],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              "unlock_with_plus".tr,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The standard premium dialog shown whenever a locked feature is tapped.
/// "Not Now" dismisses; "Upgrade to Plus" opens the full upgrade screen.
Future<void> showUpgradeDialog(BuildContext context, {String? feature}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.purpleLight, AppColors.purpleDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              "unlock_plus_features".tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "upgrade_plus_description".tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Text(
                        "not_now".tr,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Get.to(() => const UpgradePlusScreen());
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.purpleLight, AppColors.purpleDark],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "upgrade_to_plus".tr,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
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
    ),
  );
}
