import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/settings_controller.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/discover_controller.dart';
import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
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
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final filtered = LanguageService.supported.where((l) {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _searchBar(),
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

  /// Prepare on-device translation for the freshly-selected language (downloads
  /// the ML Kit model the first time it's used) and re-translate any already
  /// loaded Firebase content so the switch is live — not on next launch. Shows a
  /// brief blocking loader while the model downloads.

  Future<void> _applyContentLanguage() async {
    try {
      // Language model should already be downloaded during
      // splash/login background preparation.
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
    } catch (_) {
      // Language change should never crash/block the app.
    }
  }

  Widget _searchBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorderLight),
      ),
      child: Row(
        children: [
          const OnboardingLineIcon(
            'search',
            size: 20,
            color: AppColors.textHint,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: 'search_languages'.tr,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageRow({required AppLanguage lang, required bool selected}) {
    return InkWell(
      onTap: () async {
        if (LanguageService.currentCode == lang.code) return;

        await LanguageService.setLanguage(lang.code);

        _settings.setLanguage(lang.english);

        if (mounted) {
          setState(() {});
        }
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
