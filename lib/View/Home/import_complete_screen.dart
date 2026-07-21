import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:recipe_ai/widgets/app_network_image.dart';
import 'package:recipe_ai/View/Auth/auth_wrapper.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/cookbook_controller.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
import 'package:recipe_ai/Controllers/settings_controller.dart';
import 'package:recipe_ai/Helper/unit_converter.dart';
import 'package:recipe_ai/Helper/premium_gate.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart';
import 'package:recipe_ai/View/Home/recipe_editor_screen.dart';
import 'package:recipe_ai/Controllers/nutrition_controller.dart';
import 'package:recipe_ai/Service/subscription_service.dart';
import 'package:recipe_ai/widgets/premium_lock_overlay.dart';
import 'package:recipe_ai/widgets/nutrition_preview_card.dart';
import 'package:recipe_ai/widgets/nutrition_locked_card.dart';
import 'package:recipe_ai/View/Home/nutrition/nutrition_screen.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:recipe_ai/widgets/tr_text.dart';

/// Import complete (review) screen — matches the HTML design: photo hero with
/// "Imported" badge, an AI-review banner, a source pill, orange meta row, and
/// white cards for ingredients (basket rows) and instructions (numbered steps).
class ImportCompleteScreen extends StatelessWidget {
  final RecipeModel recipe;

  const ImportCompleteScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return PopScope(
      // When this is the ONLY route (e.g. launched straight from a share
      // intent), a system-back pop would leave an empty, black navigator.
      // Allow the normal back only when a screen exists beneath; otherwise
      // route to the app home instead of a black screen.
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Get.offAll(() => const AuthWrapper());
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _hero(),
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 6, 22, 34),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _reviewBanner(),
                          const SizedBox(height: 16),
                          TrText(
                            recipe.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              height: 1.14,
                              letterSpacing: -0.5,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _sourcePill(),
                          const SizedBox(height: 14),
                          _metaRow(),
                          const SizedBox(height: 20),
                          _ingredientsCard(),
                          const SizedBox(height: 16),
                          _instructionsCard(),
                          const SizedBox(height: 16),
                          _nutritionCard(context),
                          const SizedBox(height: 20),
                          _saveButton(context),
                          const SizedBox(height: 10),
                          _editButton(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Top overlay bar (close + Imported badge)
            Positioned(
              top: topPad + 14,
              left: 18,
              right: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Pop back if a screen exists beneath. This screen is
                      // reached via Get.off (replacing the import/processing
                      // screen); if it ended up as the ONLY route, a bare pop
                      // would leave an empty, black navigator — so fall back to
                      // the app home instead.
                      final nav = Navigator.of(context);
                      if (nav.canPop()) {
                        nav.pop();
                      } else {
                        Get.offAll(() => const AuthWrapper());
                      }
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const OnboardingLineIcon(
                        'x',
                        size: 20,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const OnboardingLineIcon(
                          'check',
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'imported'.tr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hero ────────────────────────────────────────────────────────────────

  Widget _hero() {
    final hasImage = recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty;
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            AppNetworkImage(
              recipe.imageUrl!,
              fit: BoxFit.cover,
              cacheWidth: 900,
              // While the (often large, freshly-uploaded) image downloads, show
              // an animated shimmer skeleton so it reads as "loading", not
              // "missing". A failed load still falls back to the icon.
              placeholder: _heroLoading(),
              error: _heroFallback(),
            )
          else
            _heroFallback(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66140F0A),
                  Color(0x00140F0A),
                  Color(0x00140F0A),
                  AppColors.background,
                ],
                stops: [0.0, 0.32, 0.64, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroFallback() => Container(
    color: const Color(0xFFF0E6D6),
    child: const Center(
      child: Icon(
        Icons.restaurant_rounded,
        size: 60,
        color: AppColors.iconLight,
      ),
    ),
  );

  /// Animated shimmer skeleton shown while the hero image downloads.
  Widget _heroLoading() => Shimmer.fromColors(
    baseColor: AppColors.shimmerBase,
    highlightColor: AppColors.shimmerHighlight,
    period: const Duration(milliseconds: 1100),
    child: Container(
      color: AppColors.shimmerBase,
      child: const Center(
        child: Icon(Icons.image_rounded, size: 54, color: Color(0xFFD8CBB4)),
      ),
    ),
  );

  // ─── Review banner ─────────────────────────────────────────────────────────

  Widget _reviewBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingLineIcon('sparkF', size: 17, color: AppColors.gold),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'ai_pulled_from_source'.trParams({
                'source': _sourceInfo().banner,
              }),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AppColors.warningText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Source pill ───────────────────────────────────────────────────────────

  Widget _sourcePill() {
    final info = _sourceInfo();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: info.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          info.logo
              ? SizedBox(
                  width: 15,
                  height: 15,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: info.fg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const AppLogoMark(size: 11),
                  ),
                )
              : Icon(info.icon, size: 14, color: info.fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              info.pill,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: info.fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Meta row ──────────────────────────────────────────────────────────────

  Widget _metaRow() {
    final items = <Widget>[];
    void add(String iconName, String text) {
      if (items.isNotEmpty) {
        items.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 9),
            child: Text(
              '·',
              style: TextStyle(
                color: Color(0xFFD8CFC0),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }
      items.add(
        OnboardingLineIcon(iconName, size: 16, color: AppColors.primary),
      );
      items.add(const SizedBox(width: 6));
      items.add(
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textBodyDark,
          ),
        ),
      );
    }

    // First NON-EMPTY time — imported recipes often store totalTime as ""
    // (empty, not null) while cook/prep have a value, and `??` only skips null.
    final time = [
      recipe.totalTime,
      recipe.cookTime,
      recipe.prepTime,
    ].firstWhere((t) => t != null && t.trim().isNotEmpty, orElse: () => null);
    if (time != null) add('clock', time.trim());
    if (recipe.servings != null && recipe.servings!.isNotEmpty) {
      add('user', 'servings_count'.trParams({'count': '${recipe.servings}'}));
    }

    add('flame', _difficultyLabel());
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: items);
  }

  // ─── Difficulty (estimated: import sources never provide one) ───────────────

  int _totalMinutes() {
    final t = [
      recipe.totalTime,
      recipe.cookTime,
      recipe.prepTime,
    ].firstWhere((v) => v != null && v.trim().isNotEmpty, orElse: () => null);
    if (t == null) return 0;
    final hourMatch = RegExp(r'(\d+)\s*h', caseSensitive: false).firstMatch(t);
    final minMatch = RegExp(r'(\d+)\s*m', caseSensitive: false).firstMatch(t);
    var total = 0;
    if (hourMatch != null) {
      total += (int.tryParse(hourMatch.group(1)!) ?? 0) * 60;
    }
    if (minMatch != null) {
      total += int.tryParse(minMatch.group(1)!) ?? 0;
    }
    if (total == 0) {
      final bare = RegExp(r'\d+').firstMatch(t);
      if (bare != null) total = int.tryParse(bare.group(0)!) ?? 0;
    }
    return total;
  }

  String _difficultyLabel() {
    final ingredients = recipe.ingredients.length;
    final steps = recipe.instructions.length;
    final mins = _totalMinutes();
    var score = 0;
    if (ingredients >= 13) {
      score += 2;
    } else if (ingredients >= 8) {
      score += 1;
    }
    if (steps >= 11) {
      score += 2;
    } else if (steps >= 6) {
      score += 1;
    }
    if (mins >= 90) {
      score += 2;
    } else if (mins >= 45) {
      score += 1;
    }
    if (score >= 4) return 'difficulty_hard'.tr;
    if (score >= 2) return 'difficulty_medium'.tr;
    return 'difficulty_easy'.tr;
  }

  // ─── Ingredients card (with Units switcher — matches RecipeDetailScreen) ────

  Widget _ingredientsCard() {
    final grocery = Get.find<GroceryStore>();
    final settings = Get.find<SettingsController>();

    return Obx(() {
      final system = settings.unitSystem;
      final rows = <Widget>[];
      final hasSections = recipe.ingredientSections.any(
        (s) => s.items.isNotEmpty,
      );
      var count = 0;

      void addItem(String text, bool last) {
        final scaled = UnitConverter.scaleAndConvert(text, 1.0, system);
        final p = _parseIngredient(scaled);
        rows.add(
          _IngredientRow(
            emoji: grocery.emojiForIngredient(text),
            amtUnit: p.amtUnit,
            name: p.name,
            showDivider: !last,
          ),
        );
        count++;
      }

      if (hasSections) {
        final sections = recipe.ingredientSections
            .where((s) => s.items.isNotEmpty)
            .toList();
        for (var si = 0; si < sections.length; si++) {
          final s = sections[si];
          if (s.name != null && s.name!.isNotEmpty) {
            rows.add(_groupHeader(s.name!));
          }
          for (var i = 0; i < s.items.length; i++) {
            final isLastOverall =
                si == sections.length - 1 && i == s.items.length - 1;
            addItem(s.items[i], isLastOverall);
          }
        }
      } else {
        for (var i = 0; i < recipe.ingredients.length; i++) {
          addItem(recipe.ingredients[i], i == recipe.ingredients.length - 1);
        }
      }

      return _card(
        title: 'ingredients'.tr,
        count: 'count_found'.trParams({'count': '$count'}),
        children: [
          _buildUnitsBanner(settings),
          const SizedBox(height: 4),
          ...rows,
        ],
      );
    });
  }

  // Plus-only unit switcher (matches RecipeDetailScreen's HTML design)
  Widget _buildUnitsBanner(SettingsController settings) {
    if (!PremiumGate.unitConversionUnlocked) return _buildLockedUnitsBanner();

    final isUS = settings.units.value == 'US';
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 7, 9, 7),
      decoration: BoxDecoration(
        color: AppColors.purpleBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          OnboardingLineIcon('ruler', size: 16, color: AppColors.purple),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'units'.tr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5B3E8C),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _unitChip('unit_us'.tr, 'US', isUS, settings),
                _unitChip('metric'.tr, 'Metric', !isUS, settings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitChip(
    String label,
    String value,
    bool selected,
    SettingsController settings,
  ) {
    return GestureDetector(
      onTap: () => settings.setUnits(value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF9A938A),
          ),
        ),
      ),
    );
  }

  // Locked (Plus paywall) banner — shown when the premium flag is off.
  Widget _buildLockedUnitsBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 7, 9, 7),
      decoration: BoxDecoration(
        color: AppColors.purpleBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const OnboardingLineIcon('ruler', size: 16, color: AppColors.purple),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'units'.tr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5B3E8C),
              ),
            ),
          ),
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
            child: Opacity(
              opacity: 0.7,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        'unit_us'.tr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      child: Text(
                        'metric'.tr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF9A938A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _plusBadge(),
        ],
      ),
    );
  }

  Widget _plusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.purple,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OnboardingLineIcon('crown', size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            'plus'.tr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Instructions card ─────────────────────────────────────────────────────

  Widget _instructionsCard() {
    final rows = <Widget>[];
    final hasSections = recipe.instructionSections.any(
      (s) => s.steps.isNotEmpty,
    );
    var stepNum = 0;
    var total = hasSections
        ? recipe.instructionSections.fold<int>(0, (a, s) => a + s.steps.length)
        : recipe.instructions.length;

    void addStep(String text, bool last) {
      stepNum++;
      rows.add(
        _InstructionRow(number: stepNum, text: text, showDivider: !last),
      );
    }

    if (hasSections) {
      final sections = recipe.instructionSections
          .where((s) => s.steps.isNotEmpty)
          .toList();
      for (var si = 0; si < sections.length; si++) {
        final s = sections[si];
        if (s.name != null && s.name!.isNotEmpty)
          rows.add(_groupHeader(s.name!));
        for (var i = 0; i < s.steps.length; i++) {
          final isLastOverall =
              si == sections.length - 1 && i == s.steps.length - 1;
          addStep(s.steps[i], isLastOverall);
        }
      }
    } else {
      for (var i = 0; i < recipe.instructions.length; i++) {
        addStep(recipe.instructions[i], i == recipe.instructions.length - 1);
      }
    }

    return _card(
      title: 'instructions'.tr,
      count: 'count_steps'.trParams({'count': '$total'}),
      children: rows,
    );
  }

  Widget _card({
    required String title,
    required String count,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.06),
            blurRadius: 26,
            offset: const Offset(0, 12),
            spreadRadius: -22,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenBgLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }

  Widget _groupHeader(String name) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: TrText(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Nutrition card — matches RecipeDetailScreen: free users see the real
  //     values blurred behind the "Subscribe now" teaser (NutritionLockedCard),
  //     Plus users see the real preview. Estimated from the recipe ingredients.
  Widget _nutritionCard(BuildContext context) {
    final n = NutritionController.to.calculateNutrition(recipe);
    if (n.isEmpty) return const SizedBox.shrink();
    return Obx(() {
      final isPlus = SubscriptionService.instance.isPlusListenable.value;
      if (!isPlus) {
        return NutritionLockedCard(
          nutrition: n,
          onTap: () =>
              showUpgradeDialog(context, feature: 'nutrition_calculator'.tr),
        );
      }
      return NutritionPreviewCard(
        nutrition: n,
        servings: n.servings,
        onViewBreakdown: () => Get.to(
          () => NutritionScreen(recipeName: recipe.title, nutrition: n),
        ),
      );
    });
  }

  // ─── Save / Edit buttons ───────────────────────────────────────────────────

  Widget _saveButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCookbookPicker(context),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.6),
              blurRadius: 22,
              offset: const Offset(0, 12),
              spreadRadius: -12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const OnboardingLineIcon('book', size: 20, color: Colors.white),
            const SizedBox(width: 9),
            Text(
              'save_to_cookbook'.tr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.back();
        Get.to(() => RecipeEditorScreen(recipe: recipe));
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.unselectedBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const OnboardingLineIcon(
              'pencil',
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'edit_before_saving'.tr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCookbookPicker(BuildContext context) {
    final cookbookCtrl = Get.find<CookbookController>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CookbookPickerSheet(
        cookbookController: cookbookCtrl,
        recipeId: recipe.id,
        recipeImageUrl: recipe.imageUrl,
      ),
    );
  }

  // ─── Source detection ──────────────────────────────────────────────────────

  _SourceInfo _sourceInfo() {
    final raw = recipe.sourceUrl;
    final s = raw.toLowerCase();
    final handle = _handleFrom(raw);
    final suffix = handle != null
        ? 'source_handle_suffix'.trParams({'handle': handle})
        : 'source_handle_suffix'.trParams({'handle': 'recipe.app'});

    // Social platforms → "From <Platform> · @handle"
    if (s.contains('instagram')) {
      return _SourceInfo(
        'source_instagram'.tr,
        'source_pill_from_instagram'.trParams({'suffix': suffix}),
        AppColors.instagramBg,
        AppColors.instagram,
        Icons.camera_alt_rounded,
      );
    }
    if (s.contains('facebook')) {
      return _SourceInfo(
        'source_facebook'.tr,
        'source_pill_from_facebook'.trParams({'suffix': suffix}),
        AppColors.blueBg,
        AppColors.facebook,
        Icons.facebook_rounded,
      );
    }
    if (s.contains('tiktok')) {
      return _SourceInfo(
        'source_tiktok'.tr,
        'source_pill_from_tiktok'.trParams({'suffix': suffix}),
        AppColors.tiktokBg,
        AppColors.tiktok,
        Icons.music_note_rounded,
      );
    }
    // Text / name → "From text to generate" (never for real URLs, which must
    // fall through to the http branch below).
    if (!s.startsWith('http') &&
        (s.contains('recipe_name') ||
            s.contains('generated') ||
            s.contains('text') ||
            s.isEmpty)) {
      return _SourceInfo(
        'source_a_recipe_name'.tr,
        'source_pill_from_text'.tr,
        AppColors.purpleBg,
        AppColors.purple,
        Icons.auto_awesome_rounded,
        logo: true,
      );
    }
    // Photo / video / other social media → "From image/video to generate"
    if (!s.startsWith('http') &&
        (s.contains('image') ||
            s.contains('video') ||
            s.contains('gemini') ||
            s.contains('photo') ||
            s.contains('social') ||
            s.contains('media'))) {
      return _SourceInfo(
        'source_a_photo_or_video'.tr,
        'source_pill_from_image_video'.tr,
        AppColors.redBg,
        AppColors.primary,
        Icons.movie_creation_rounded,
      );
    }
    // A real website link.
    if (s.startsWith('http')) {
      final webSuffix = handle != null
          ? 'source_handle_suffix'.trParams({'handle': handle})
          : '';
      return _SourceInfo(
        'source_the_web'.tr,
        'source_pill_from_the_web'.trParams({'suffix': webSuffix}),
        AppColors.greenBgLight,
        AppColors.green,
        Icons.language_rounded,
      );
    }
    return _SourceInfo(
      'source_an_import'.tr,
      'source_pill_from_image_video'.tr,
      AppColors.redBg,
      AppColors.primary,
      Icons.movie_creation_rounded,
    );
  }

  /// Extracts a @handle from a real social/web URL, e.g.
  /// instagram.com/foodie/reel/… → "foodie". Returns null when the source is a
  /// non-URL marker (like `instagram_share`) or no handle is present.
  String? _handleFrom(String url) {
    if (!url.startsWith('http')) return null;
    try {
      final uri = Uri.parse(url);
      const skip = {
        'reel',
        'reels',
        'p',
        'tv',
        'stories',
        'share',
        'video',
        'videos',
        'watch',
        'posts',
        'photo',
        'story',
      };
      for (final seg in uri.pathSegments) {
        final clean = seg.replaceAll('@', '').trim();
        if (clean.length > 1 &&
            !skip.contains(clean.toLowerCase()) &&
            !clean.contains('.')) {
          return clean.length > 20 ? clean.substring(0, 20) : clean;
        }
      }
    } catch (_) {}
    return null;
  }

  _IngredientParts _parseIngredient(String text) {
    final t = text.trim();
    final m = RegExp(
      r'^([\d½¼¾⅓⅔⅛.\-/\s]+)?\s*(cups?|tbsps?|tablespoons?|tsps?|teaspoons?|g|grams?|kg|ml|l|oz|lbs?|pounds?|cans?|cloves?|pinch(?:es)?|slices?|pieces?|sticks?|bunch(?:es)?|handfuls?|sprigs?)?\b\.?\s*(?:of\s+)?(.*)$',
      caseSensitive: false,
    ).firstMatch(t);
    if (m != null) {
      final amt = (m.group(1) ?? '').trim();
      final unit = (m.group(2) ?? '').trim();
      final name = (m.group(3) ?? '').trim();
      final amtUnit = [amt, unit].where((e) => e.isNotEmpty).join(' ').trim();
      if (amtUnit.isNotEmpty && name.isNotEmpty) {
        return _IngredientParts(amtUnit: amtUnit, name: name);
      }
      if (amtUnit.isNotEmpty && name.isEmpty) {
        return _IngredientParts(amtUnit: '', name: amtUnit);
      }
    }
    return _IngredientParts(amtUnit: '', name: t);
  }
}

class _SourceInfo {
  final String banner; // used in the review banner sentence
  final String pill; // used in the source pill
  final Color bg;
  final Color fg;
  final IconData icon;
  final bool logo;
  _SourceInfo(
    this.banner,
    this.pill,
    this.bg,
    this.fg,
    this.icon, {
    this.logo = false,
  });
}

class _IngredientParts {
  final String amtUnit;
  final String name;
  _IngredientParts({required this.amtUnit, required this.name});
}

// ─────────────────────────────────────────────────────────────────────────────
// Ingredient row: basket icon + amtUnit + name
// ─────────────────────────────────────────────────────────────────────────────

class _IngredientRow extends StatelessWidget {
  final String emoji;
  final String amtUnit;
  final String name;
  final bool showDivider;

  const _IngredientRow({
    required this.emoji,
    required this.amtUnit,
    required this.name,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.divider))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.goldBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 12),
          if (amtUnit.isNotEmpty) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 54),
              child: Text(
                amtUnit,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: TrText(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textBodyDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Instruction row: numbered badge + step text
// ─────────────────────────────────────────────────────────────────────────────

class _InstructionRow extends StatelessWidget {
  final int number;
  final String text;
  final bool showDivider;

  const _InstructionRow({
    required this.number,
    required this.text,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 9, 0, 9),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.divider))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: AppColors.redBg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: TrText(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textBody,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
