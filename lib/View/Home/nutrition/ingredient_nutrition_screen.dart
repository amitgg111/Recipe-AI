

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:recipe_ai/Model/nutrition_model.dart';
import 'package:recipe_ai/widgets/nutrition_animations.dart';
import 'package:recipe_ai/widgets/nutrition_widgets.dart';

/// Per-ingredient calorie breakdown (design screen 81). Shows each ingredient's
/// contribution to either one serving or the whole recipe (based on [perServing]),
/// largest first, with a purple bar sized against the biggest contributor.
class IngredientNutritionScreen extends StatelessWidget {
  final String recipeName;
  final NutritionModel nutrition;
  final bool perServing;

  const IngredientNutritionScreen({
    super.key,
    required this.recipeName,
    required this.nutrition,
    this.perServing = true,
  });

  // Ingredient calories are stored per-serving; scale up for whole-recipe mode.
  double _scaled(double perServe) =>
      perServing ? perServe : perServe * nutrition.servings;

  double get _headerKcal =>
      perServing ? nutrition.caloriesPerServing : nutrition.caloriesWholeRecipe;

  @override
  Widget build(BuildContext context) {
    final items = nutrition.ingredientsNutrition;
    // Progress bar % = ingredient calories ÷ whole (current-mode) total × 100
    // (spec step 5), so the largest contributor reads e.g. 43%, not 100%.
    final total = _headerKcal > 0
        ? _headerKcal
        : (items.isEmpty
              ? 1.0
              : items.map((e) => _scaled(e.calories)).reduce((a, b) => a + b));

    return Scaffold(
      backgroundColor: NutritionPalette.bg,
      body: RevealIn(
        duration: const Duration(milliseconds: 400),
        beginOffset: const Offset(0, 20),
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: NutritionPalette.cardBorder),
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
                            // Each ingredient card slides in from the right + fades.
                            for (var i = 0; i < items.length; i++)
                              RevealIn(
                                delay: Duration(milliseconds: 90 + i * 60),
                                beginOffset: const Offset(28, 0),
                                child: IngredientNutritionTile(
                                  name: items[i].name,
                                  kcal: _scaled(items[i].calories),
                                  fraction: _scaled(items[i].calories) / total,
                                  showDivider: i != items.length - 1,
                                ),
                              ),
                            if (items.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'nutrition_no_ingredient_data'.tr,
                                  style: NutritionPalette.font(
                                    size: 13,
                                    color: NutritionPalette.noteGrey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    NutritionDisclaimer(
                      text: 'nutrition_ai_estimates_disclaimer'.tr,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.3, -1),
          end: Alignment(0.3, 1),
          colors: [NutritionPalette.purple, NutritionPalette.purpleDark],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -50,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back<void>(),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'nutrition_per_ingredient_title'.tr,
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
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedCounter(
                          value: _headerKcal,
                          duration: const Duration(milliseconds: 900),
                          format: (v) => '${v.round()}',
                          style: NutritionPalette.font(
                            size: 30,
                            weight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          perServing
                              ? 'nutrition_kcal_per_serving_unit'.tr
                              : 'nutrition_kcal_serves'.trParams({
                                  'servings': '${nutrition.servings}',
                                }),
                          style: NutritionPalette.font(
                            size: 13,
                            weight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'nutrition_heres_what_makes_it_up'.tr,
                      style: NutritionPalette.font(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
