import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/settings_controller.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/discover_controller.dart';
import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:recipe_ai/Service/analytics_service.dart';
import 'package:recipe_ai/Service/language_service.dart';
import 'package:recipe_ai/View/Home/settings/settings_common.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final _settings = Get.find<SettingsController>();
  final String _query = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen("LanguageScreen");
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    // Only the languages this user's country is rolled out to — English plus,
    // for India, Hindi. See LanguageService.enabledCountries.
    final options = LanguageService.selectableLanguages;
    // A search box over two rows is just noise.

    final filtered = options.where((l) {
      if (q.isEmpty) return true;
      return l.native.toLowerCase().contains(q) ||
          l.english.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
              child: SettingsUi.header('language'.tr),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                children: [
                  SettingsUi.card(
                    rows: [
                      for (final l in filtered)
                        _languageRow(
                          lang: l,
                          selected: LanguageService.currentCode == l.code,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Re-point the on-device translator at the freshly-selected language and
  /// re-translate the Firebase content that's already loaded, so the switch is
  /// live rather than "next launch". The model itself was downloaded in the
  /// background at splash, so this is normally cache-fast.
  Future<void> _applyContentLanguage(String code) async {
    try {
      // Language model should already be downloaded during
      // splash/login background preparation.

      log(code);
      if (!AiTranslationService.isPrewarmed(code)) {
        await AiTranslationService.waitUntilPrewarmed(
          code,
        ).timeout(const Duration(seconds: 6), onTimeout: () {});
      }
      await AiTranslationService.onLanguageChanged();

      // Refresh all Firebase-backed content in parallel.
      await Future.wait([
        if (Get.isRegistered<HomeController>())
          Get.find<HomeController>().refreshRecipesLanguage(),

        if (Get.isRegistered<DiscoverController>())
          Get.find<DiscoverController>().refreshLanguage(),

        if (Get.isRegistered<GroceryStore>())
          Get.find<GroceryStore>().refreshLanguage(),

        if (Get.isRegistered<MealPlanController>())
          Get.find<MealPlanController>().refreshLanguage(),
      ]);

      log("Done $code — refreshed  controller(s)   ---------------LANGUAGE");
    } catch (e) {
      log('❌ _applyContentLanguage failed for $code: $e');

      // Language change should never crash/block the app.
    }
  }

  Widget _languageRow({required AppLanguage lang, required bool selected}) {
    return InkWell(
      onTap: () async {
        if (LanguageService.currentCode == lang.code) return;

        final previousLanguage = LanguageService.currentCode;

        // Instant, no-restart switch + persist
        await LanguageService.setLanguage(lang.code);
        _settings.setLanguage(lang.english);
        if (mounted) setState(() {});

        // ✅ Analytics
        AnalyticsService.instance.trackEvent(
          "language_changed",
          parameters: {
            "from": previousLanguage,
            "to": lang.code,
            "language_name": lang.english,
          },
        );

        // Re-point translator + refresh content
        await _applyContentLanguage(lang.code);
      },
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.native,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    lang.english,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const OnboardingLineIcon(
                  'check',
                  size: 15,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
