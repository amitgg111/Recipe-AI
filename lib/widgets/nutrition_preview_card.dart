import 'package:flutter/material.dart';

import 'package:recipe_ai/Model/nutrition_model.dart';
import 'package:recipe_ai/widgets/nutrition_animations.dart';
import 'package:recipe_ai/widgets/nutrition_widgets.dart';

/// The Nutrition preview card shown inside the recipe detail screen
/// (design 32d). Donut + macro legend + "View full breakdown" CTA.
///
/// This is the Plus-unlocked body; the recipe screen decides whether to show it
/// or a locked teaser.
class NutritionPreviewCard extends StatelessWidget {
  final NutritionModel nutrition;
  final int servings;
  final VoidCallback onViewBreakdown;

  const NutritionPreviewCard({
    super.key,
    required this.nutrition,
    required this.servings,
    required this.onViewBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final p = nutrition.protein * 4;
    final c = nutrition.carbs * 4;
    final f = nutrition.fat * 9;

    return RevealIn(
      duration: const Duration(milliseconds: 380),
      beginOffset: Offset.zero,
      beginScale: 0.96,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NUTRITION',
                  style: NutritionPalette.font(
                      size: 13,
                      weight: FontWeight.w800,
                      color: NutritionPalette.orange,
                      letterSpacing: 0.65)),
              const PlusPill(
                background: Color(0xFFF4EEFD),
                foreground: NutritionPalette.purpleDeep,
                glow: true,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('Per 1 serving · serves $servings',
              style: NutritionPalette.font(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: NutritionPalette.noteGrey)),
          const SizedBox(height: 14),
          Row(
            children: [
              MacroDonut(
                calories: nutrition.caloriesPerServing,
                fractions: [c, p, f], // carbs, protein, fat
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _legend('Protein', '${nutrition.protein.toStringAsFixed(1)}g',
                        NutritionPalette.protein),
                    const SizedBox(height: 13),
                    _legend('Carbs', '${nutrition.carbs.toStringAsFixed(1)}g',
                        NutritionPalette.carbs),
                    const SizedBox(height: 13),
                    _legend('Fats', '${nutrition.fat.toStringAsFixed(1)}g',
                        NutritionPalette.fat),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Press-scale + ink ripple on tap.
          PressableScale(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFBF7F0),
                border: Border.all(color: NutritionPalette.cardBorder),
                borderRadius: BorderRadius.circular(13),
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onViewBreakdown,
                  splashColor: NutritionPalette.purple.withValues(alpha: 0.12),
                  highlightColor:
                      NutritionPalette.purple.withValues(alpha: 0.06),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('View full breakdown',
                            style: NutritionPalette.font(
                                size: 14,
                                weight: FontWeight.w700,
                                color: NutritionPalette.ink)),
                        const SizedBox(width: 7),
                        const Icon(Icons.chevron_right_rounded,
                            size: 20, color: NutritionPalette.muted),
                      ],
                    ),
                  ),
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
                  size: 14, weight: FontWeight.w800, color: NutritionPalette.ink)),
        ],
      );
}
