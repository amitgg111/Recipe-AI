import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:recipe_ai/Model/nutrition_model.dart';
import 'package:recipe_ai/View/Home/nutrition/ingredient_nutrition_screen.dart';
import 'package:recipe_ai/widgets/nutrition_animations.dart';
import 'package:recipe_ai/widgets/nutrition_widgets.dart';

/// Full nutrition breakdown (design screens 80 / 80B).
///
/// A single screen with a Per serving / Whole recipe toggle. Every value —
/// calories, macros and full facts — switches between the per-serving figure
/// and its whole-recipe multiple.
class NutritionScreen extends StatefulWidget {
  final String recipeName;
  final NutritionModel nutrition;

  const NutritionScreen({
    super.key,
    required this.recipeName,
    required this.nutrition,
  });

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  bool _perServing = true;

  NutritionModel get n => widget.nutrition;

  // ── number formatting ──
  static String _grouped(num v) {
    final s = v.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  /// A per-serving figure scaled to the current mode (×servings for whole).
  double _scaled(double perServe) =>
      _perServing ? perServe : perServe * n.servings;

  // Macro grams shown on the chips (per current mode).
  double _grams(double perServe) => _scaled(perServe);

  // Fact formatters (spec step 8): grams → 1 decimal; mg → grouped integer.
  static String _fmtG(double v) =>
      'nutrition_unit_grams'.trParams({'value': v.toStringAsFixed(1)});
  static String _fmtMg(double v) =>
      'nutrition_unit_milligrams'.trParams({'value': _grouped(v)});

  /// Full-facts rows: (label, per-serving value, formatter).
  List<(String, double, String Function(double))> get _facts => [
    ('nutrition_fact_fiber'.tr, n.fiber, _fmtG),
    ('nutrition_fact_sugar'.tr, n.sugar, _fmtG),
    ('nutrition_fact_saturated_fat'.tr, n.saturatedFat, _fmtG),
    ('nutrition_fact_sodium'.tr, n.sodium, _fmtMg),
    ('nutrition_fact_cholesterol'.tr, n.cholesterol, _fmtMg),
  ];

  double get _kcal =>
      _perServing ? n.caloriesPerServing : n.caloriesWholeRecipe;

  /// Macro shares by calorie contribution (protein/carbs ×4, fat ×9).
  List<double> get _macroFractions {
    final p = n.protein * 4, c = n.carbs * 4, f = n.fat * 9;
    final t = p + c + f;
    if (t <= 0) return const [0.02, 0.02, 0.02];
    return [p / t, c / t, f / t];
  }

  @override
  Widget build(BuildContext context) {
    final frac = _macroFractions;
    return Scaffold(
      backgroundColor: NutritionPalette.bg,
      // Whole screen fades in and slides up 20px on open.
      body: RevealIn(
        duration: const Duration(milliseconds: 400),
        beginOffset: const Offset(0, 20),
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              Transform.translate(
                offset: const Offset(0, -26),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // macro chips — reveal one-by-one (scale 0.9→1.0 + fade)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: RevealIn.scale(
                              delay: const Duration(milliseconds: 200),
                              child: MacroCard(
                                grams: _grams(n.protein),
                                label: 'nutrition_macro_protein'.tr,
                                track: NutritionPalette.proteinTrack,
                                fill: NutritionPalette.protein,
                                fraction: frac[0],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RevealIn.scale(
                              delay: const Duration(milliseconds: 260),
                              child: MacroCard(
                                grams: _grams(n.carbs),
                                label: 'nutrition_macro_carbs'.tr,
                                track: NutritionPalette.carbsTrack,
                                fill: NutritionPalette.carbs,
                                fraction: frac[1],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RevealIn.scale(
                              delay: const Duration(milliseconds: 320),
                              child: MacroCard(
                                grams: _grams(n.fat),
                                label: 'nutrition_macro_fats'.tr,
                                track: NutritionPalette.fatTrack,
                                fill: NutritionPalette.fat,
                                fraction: frac[2],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // whole-recipe info card — appears/disappears smoothly
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: _perServing
                            ? const SizedBox(width: double.infinity)
                            : Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4EEFD),
                                      border: Border.all(
                                        color: const Color(0xFFE0D2F7),
                                      ),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.person_rounded,
                                          size: 18,
                                          color: NutritionPalette.purple,
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Text(
                                            'nutrition_whole_recipe_hint'.tr,
                                            style: NutritionPalette.font(
                                              size: 12.5,
                                              weight: FontWeight.w600,
                                              color: const Color(0xFF5A4A78),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                ],
                              ),
                      ),

                      // FULL FACTS
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 4, 2, 9),
                        child: Text(
                          _perServing
                              ? 'nutrition_full_facts'.tr
                              : 'nutrition_full_facts_whole_recipe'.tr,
                          style: NutritionPalette.font(
                            size: 12,
                            weight: FontWeight.w800,
                            color: NutritionPalette.muted,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: NutritionPalette.cardBorder,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2A211B,
                              ).withValues(alpha: 0.4),
                              blurRadius: 26,
                              offset: const Offset(0, 12),
                              spreadRadius: -22,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Column(
                            children: [
                              // Facts rows fade + slide up, one after another.
                              for (var i = 0; i < _facts.length; i++)
                                RevealIn(
                                  delay: Duration(milliseconds: 360 + i * 70),
                                  beginOffset: const Offset(0, 14),
                                  child: FactTile(
                                    label: _facts[i].$1,
                                    value: _scaled(_facts[i].$2),
                                    format: _facts[i].$3,
                                    showDivider: i != _facts.length - 1,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      NutritionButton(
                        label: 'nutrition_see_ingredient_breakdown'.tr,
                        onTap: () => Get.to(
                          () => IngredientNutritionScreen(
                            recipeName: widget.recipeName,
                            nutrition: n,
                            perServing:
                                _perServing, // <-- pass current toggle state
                          ),
                          transition: Transition.fadeIn,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      const SizedBox(height: 14),
                      NutritionDisclaimer(text: 'nutrition_disclaimer'.tr),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return ClipRect(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.3, -1),
            end: Alignment(0.3, 1),
            colors: [NutritionPalette.purple, NutritionPalette.purpleDark],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -60, right: -50, child: _wash(200, 0.18)),
            Positioned(bottom: -40, left: -40, child: _wash(170, 0.10)),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 42),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _iconButton(
                          Icons.arrow_back_rounded,
                          () => Get.back<void>(),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'nutrition'.tr,
                            style: NutritionPalette.font(
                              size: 17,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const PlusPill(
                          background: Color(0x38FFFFFF),
                          foreground: Colors.white,
                          glow: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.recipeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: NutritionPalette.font(
                        size: 13,
                        weight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentControl(
                      options: [
                        'nutrition_segment_per_serving'.tr,
                        'nutrition_segment_whole_recipe'.tr,
                      ],
                      selectedIndex: _perServing ? 0 : 1,
                      onChanged: (i) => setState(() => _perServing = i == 0),
                    ),
                    const SizedBox(height: 18),
                    // Ring scales 0.9 → 1.0 on load; arc + count animate inside.
                    RevealIn.scale(
                      delay: const Duration(milliseconds: 120),
                      duration: const Duration(milliseconds: 480),
                      child: NutritionRing(
                        kcal: _kcal,
                        label: _perServing
                            ? 'nutrition_kcal_per_serving'.tr
                            : 'nutrition_kcal_serves'.trParams({
                                'servings': '${n.servings}',
                              }),
                        valueFontSize: _perServing ? 42 : 38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, size: 20, color: Colors.white),
    ),
  );

  Widget _wash(double size, double opacity) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: opacity),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, 0.7],
        ),
      ),
    ),
  );
}
