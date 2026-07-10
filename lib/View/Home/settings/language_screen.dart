import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/settings_controller.dart';
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

  static const _languages = [
    ['English', 'English'],
    ['हिन्दी', 'Hindi'],
    ['Español', 'Spanish'],
    ['Français', 'French'],
    ['Deutsch', 'German'],
    ['Italiano', 'Italian'],
    ['日本語', 'Japanese'],
    ['中文', 'Chinese'],
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _languages.where((l) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return l[0].toLowerCase().contains(q) || l[1].toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
              child: SettingsUi.header('Language'),
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
                        Obx(
                          () => _languageRow(
                            native: l[0],
                            english: l[1],
                            selected: _settings.language.value == l[1],
                          ),
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
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                hintText: 'Search languages',
                hintStyle: TextStyle(
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

  Widget _languageRow({
    required String native,
    required String english,
    required bool selected,
  }) {
    return InkWell(
      onTap: () {
        _settings.setLanguage(english);
        Get.back();
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
                    native,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    english,
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
