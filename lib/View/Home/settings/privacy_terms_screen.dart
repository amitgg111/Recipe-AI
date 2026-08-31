import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/remote_config_service.dart';
import 'package:recipe_ai/View/Home/settings/settings_common.dart';

import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

class PrivacyTermsScreen extends StatelessWidget {
  const PrivacyTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = RemoteConfigService.instance;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
          children: [
            SettingsUi.header('privacy_and_terms'.tr),
            const SizedBox(height: 6),

            // Hero
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.greenBgLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const OnboardingLineIcon(
                      'shield',
                      size: 26,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'privacy_hero'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),

            SettingsUi.card(
              rows: [
                SettingsUi.row(
                  leadingIcon: const OnboardingLineIcon(
                    'shield',
                    size: 21,
                    color: SettingsUi.rowIcon,
                  ),
                  label: 'privacy_policy'.tr,
                  onTap: () => LegalLinkLauncher.open(config.privacyPolicyUrl),
                ),
                SettingsUi.row(
                  leadingIcon: const OnboardingLineIcon(
                    'file',
                    size: 21,
                    color: SettingsUi.rowIcon,
                  ),
                  label: 'terms_of_service'.tr,
                  onTap: () => LegalLinkLauncher.open(config.termsOfServiceUrl),
                ),
                SettingsUi.row(
                  leadingIcon: const OnboardingLineIcon(
                    'sparkF2',
                    size: 21,
                    color: SettingsUi.rowIcon,
                  ),
                  label: 'refund_policy'.tr,
                  onTap: () => LegalLinkLauncher.open(config.refundPolicyUrl),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Center(
              child: Text(
                'Recipe AI · v1.0.0 · © 2026',
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
    );
  }
}
