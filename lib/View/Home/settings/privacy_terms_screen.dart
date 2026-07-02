import 'package:flutter/material.dart';
import 'package:recipe_ai/View/Home/settings/settings_common.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyTermsScreen extends StatelessWidget {
  const PrivacyTermsScreen({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('could not launch');
    } catch (_) {
      CustomSnackbar.show(
        title: 'Unavailable',
        message: 'Could not open the link right now.',
        type: SnackbarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
          children: [
            SettingsUi.header('Privacy & terms'),
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
                    child: const Icon(Icons.shield_outlined,
                        size: 26, color: AppColors.green),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your data stays yours. We never sell your information.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
                  icon: Icons.shield_outlined,
                  label: 'Privacy policy',
                  onTap: () => _open('https://example.com/privacy'),
                ),
                SettingsUi.row(
                  icon: Icons.description_outlined,
                  label: 'Terms of service',
                  onTap: () => _open('https://example.com/terms'),
                ),
                SettingsUi.row(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Refund policy',
                  onTap: () => _open('https://example.com/refunds'),
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
