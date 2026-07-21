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
    final needsWork = AiTranslationService.isTranslating; // non-English target
    if (needsWork) {
      Get.dialog(
        const Center(
          child: Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Padding(
              padding: EdgeInsets.all(22),
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );
    }
    try {
      await AiTranslationService.onLanguageChanged();
      // Re-translate every Firebase-backed surface that's already loaded.
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().refreshRecipesLanguage();
      }
      if (Get.isRegistered<DiscoverController>()) {
        await Get.find<DiscoverController>().refreshLanguage();
      }
      if (Get.isRegistered<GroceryStore>()) {
        await Get.find<GroceryStore>().refreshLanguage();
      }
      if (Get.isRegistered<MealPlanController>()) {
        await Get.find<MealPlanController>().refreshLanguage();
      }
    } catch (_) {
      // A translation hiccup must never block the language switch.
    } finally {
      if (needsWork && (Get.isDialogOpen ?? false)) Get.back();
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
          const OnboardingLineIcon('search', size: 20, color: AppColors.textHint),
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
        // Instant, no-restart switch + persist. Keep the settings row's label in
        // sync too, then rebuild so the checkmark and (now-translated) UI labels
        // update in place.
        await LanguageService.setLanguage(lang.code);
        _settings.setLanguage(lang.english);
        if (mounted) setState(() {});
        // Then translate the Firebase-backed CONTENT (recipes, discover feed,
        // groceries, meal plan) into the new language and re-render live.
        await _applyContentLanguage();
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
                child: const OnboardingLineIcon('check',
                    size: 15, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
