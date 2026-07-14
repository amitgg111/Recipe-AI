import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:recipe_ai/Model/nutrition_model.dart';
import 'package:recipe_ai/widgets/nutrition_widgets.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

/// Free-user teaser for the nutrition preview (recipe detail).
///
/// Keeps the "NUTRITION · Per 1 serving" heading readable, shows a yellow
/// "This is a Plus feature — Subscribe now…" banner, then blurs the real donut
/// + macro legend underneath. Tapping anywhere opens the upgrade dialog.
class NutritionLockedCard extends StatelessWidget {
  final NutritionModel nutrition;
  final VoidCallback onTap;

  const NutritionLockedCard({
    super.key,
    required this.nutrition,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = nutrition.protein * 4;
    final c = nutrition.carbs * 4;
    final f = nutrition.fat * 9;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: NutritionPalette.cardBorder),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2A211B).withValues(alpha: 0.4),
              blurRadius: 26,
              offset: const Offset(0, 12),
              spreadRadius: -22,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('nutrition'.tr.toUpperCase(),
                style: NutritionPalette.font(
                    size: 13,
                    weight: FontWeight.w800,
                    color: NutritionPalette.orange,
                    letterSpacing: 0.65)),
            const SizedBox(height: 2),
            Text('per_1_serving'.tr,
                style: NutritionPalette.font(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: NutritionPalette.noteGrey)),
            const SizedBox(height: 14),

            // ── yellow "Plus feature" banner ──
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF1C9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OnboardingLineIcon('crown',
                      size: 18, color: NutritionPalette.purple),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: NutritionPalette.font(
                          size: 13.5,
                          weight: FontWeight.w500,
                          color: NutritionPalette.ink,
                          height: 1.45,
                        ),
                        children: [
                          TextSpan(text: 'this_is_plus_feature'.tr),
                          TextSpan(
                            text: 'subscribe_now'.tr,
                            style: NutritionPalette.font(
                                size: 13.5,
                                weight: FontWeight.w800,
                                color: NutritionPalette.purpleDeep),
                          ),
                          TextSpan(text: 'unlock_nutrition_calculator'.tr),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── blurred real donut + macro legend (teased, unusable) ──
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Opacity(
                opacity: 0.85,
                child: IgnorePointer(
                  child: Row(
                    children: [
                      MacroDonut(
                        calories: nutrition.caloriesPerServing,
                        fractions: [c, p, f], // carbs, protein, fat
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: [
                            _legend('Protein',
                                '${nutrition.protein.toStringAsFixed(1)}g',
                                NutritionPalette.protein),
                            const SizedBox(height: 13),
                            _legend('Carbs',
                                '${nutrition.carbs.toStringAsFixed(1)}g',
                                NutritionPalette.carbs),
                            const SizedBox(height: 13),
                            _legend('Fats',
                                '${nutrition.fat.toStringAsFixed(1)}g',
                                NutritionPalette.fat),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(String label, String value, Color color) => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(label,
                style: NutritionPalette.font(
                    size: 13,
                    weight: FontWeight.w600,
                    color: NutritionPalette.factLabel)),
          ),
          Text(value,
              style: NutritionPalette.font(
                  size: 14,
                  weight: FontWeight.w800,
                  color: NutritionPalette.ink)),
        ],
      );
}
