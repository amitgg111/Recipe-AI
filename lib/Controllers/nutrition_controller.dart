import 'package:get/get.dart';

import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
import 'package:recipe_ai/Model/nutrition_model.dart';
import 'package:recipe_ai/Service/nutrition_estimator.dart';

/// Aggregate nutrition for one day of the meal plan.
class DayNutrition {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final int mealCount;

  const DayNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealCount,
  });

  static const DayNutrition zero =
      DayNutrition(calories: 0, protein: 0, carbs: 0, fat: 0, mealCount: 0);

  bool get isEmpty => mealCount == 0 || calories <= 0;

  /// Macro split by calorie contribution (protein/carbs = 4, fat = 9 kcal/g).
  /// Returns fractions that always sum to 1 (falls back to equal thirds).
  List<double> get macroFractions {
    final pk = protein * 4, ck = carbs * 4, fk = fat * 9;
    final total = pk + ck + fk;
    if (total <= 0) return const [1 / 3, 1 / 3, 1 / 3];
    return [pk / total, ck / total, fk / total];
  }
}

/// Central nutrition engine (GetX). Estimates a recipe's nutrition from its
/// ingredient list, caches the result, and aggregates a day's meals for the
/// meal-plan "Today's Nutrition" card.
class NutritionController extends GetxController {
  /// Lazily-registered singleton so callers don't depend on registration order.
  static NutritionController get to => Get.isRegistered<NutritionController>()
      ? Get.find<NutritionController>()
      : Get.put(NutritionController(), permanent: true);

  final Map<String, NutritionModel> _cache = {};

  /// Flatten a recipe's ingredient lines (sections take priority over the flat
  /// list, matching how the detail screen renders them).
  List<String> ingredientLinesOf(RecipeModel r) {
    if (r.ingredientSections.isNotEmpty) {
      return [for (final s in r.ingredientSections) ...s.items];
    }
    return r.ingredients;
  }

  int _servingsOf(RecipeModel r) {
    final n = r.servingCount.round();
    return n < 1 ? 1 : n;
  }

  /// Main entry — nutrition for [recipe] (cached per recipe id + servings).
  /// Pass [servingsOverride] when the user changes servings on the detail
  /// screen so the cache stays correct.
  NutritionModel calculateNutrition(RecipeModel recipe, {int? servingsOverride}) {
    final defaultServings = _servingsOf(recipe);
    final servings = servingsOverride ?? defaultServings;
    final key = '${recipe.id}|$servings|${ingredientLinesOf(recipe).length}';

    // Reuse the estimate stored on the recipe doc when viewing at the recipe's
    // own serving count (values are per-serving, valid only at that count).
    if (servings == defaultServings && recipe.nutritionData != null) {
      return _cache[key] ??= NutritionModel.fromMap(recipe.nutritionData!);
    }

    final model = _cache[key] ??= NutritionEstimator.estimate(
      ingredientLines: ingredientLinesOf(recipe),
      servings: servings,
    );

    // Persist the default-servings estimate to Firestore once, so future
    // sessions read it instead of recomputing.
    if (servings == defaultServings &&
        recipe.nutritionData == null &&
        !model.isEmpty &&
        _persisted.add(recipe.id) &&
        Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().setNutrition(recipe.id, model.toMap());
    }
    return model;
  }

  /// Recipe ids whose nutrition we've already written this session (write-once).
  final Set<String> _persisted = {};

  /// Recompute for a new serving count (spec: `updateServing`). Cached.
  NutritionModel updateServing(RecipeModel recipe, int servings) =>
      calculateNutrition(recipe, servingsOverride: servings);

  double calculateWholeRecipe(NutritionModel n) => n.caloriesWholeRecipe;
  double calculatePerServing(NutritionModel n) => n.caloriesPerServing;

  /// Sum nutrition for every meal planned on [date]. Each planned meal counts
  /// as one serving of its recipe (serving count isn't stored per meal).
  DayNutrition calculateMealNutrition(DateTime date) {
    final meal = Get.isRegistered<MealPlanController>()
        ? Get.find<MealPlanController>()
        : null;
    final home = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : null;
    if (meal == null || home == null) return DayNutrition.zero;

    final key = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final items = meal.mealPlanItems.where((m) => m.date == key).toList();
    if (items.isEmpty) return DayNutrition.zero;

    double kcal = 0, p = 0, c = 0, f = 0;
    int counted = 0;
    for (final item in items) {
      final recipe =
          home.recipes.firstWhereOrNull((r) => r.id == item.recipeId);
      if (recipe == null) continue;
      final n = calculateNutrition(recipe);
      if (n.caloriesPerServing <= 0) continue;
      kcal += n.caloriesPerServing;
      p += n.protein;
      c += n.carbs;
      f += n.fat;
      counted++;
    }
    return DayNutrition(
      calories: kcal,
      protein: p,
      carbs: c,
      fat: f,
      mealCount: counted,
    );
  }

  /// Clear cached estimates (e.g. after a recipe's ingredients are edited).
  void invalidate(String recipeId) =>
      _cache.removeWhere((k, _) => k.startsWith('$recipeId|'));
}
