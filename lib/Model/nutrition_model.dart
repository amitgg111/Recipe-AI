/// Nutrition data for a recipe.
///
/// All macro / fact values in this model are stored **per serving**. The
/// whole-recipe figures are simple multiples (`× servings`) exposed through the
/// `*Whole` getters, so the two tabs on the nutrition screen never disagree.
///
/// Values are estimates produced by [NutritionEstimator] from the recipe's
/// ingredient list — "AI estimates, not medical advice".
class NutritionModel {
  /// Per-serving totals.
  final double caloriesPerServing;
  final double protein; // g / serving
  final double carbs; // g / serving
  final double fat; // g / serving
  final double fiber; // g / serving
  final double sugar; // g / serving
  final double sodium; // mg / serving
  final double cholesterol; // mg / serving
  final double saturatedFat; // g / serving

  /// Number of servings the recipe yields (>= 1).
  final int servings;

  /// Per-ingredient contribution (per serving), largest first.
  final List<IngredientNutrition> ingredientsNutrition;

  final int unknownIngredientCount; // 👈 NEW

  const NutritionModel({
    required this.caloriesPerServing,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.cholesterol,
    required this.saturatedFat,
    required this.servings,
    required this.ingredientsNutrition,
    this.unknownIngredientCount = 0, // 👈 NEW WITH DEFAULT
  });
  bool get hasUnknownIngredients => unknownIngredientCount > 0;

  // ── Whole-recipe multiples ─────────────────────────────────────────────────
  double get caloriesWholeRecipe => caloriesPerServing * servings;
  double get proteinWhole => protein * servings;
  double get carbsWhole => carbs * servings;
  double get fatWhole => fat * servings;
  double get fiberWhole => fiber * servings;
  double get sugarWhole => sugar * servings;
  double get sodiumWhole => sodium * servings;
  double get cholesterolWhole => cholesterol * servings;
  double get saturatedFatWhole => saturatedFat * servings;

  bool get isEmpty => caloriesPerServing <= 0 && ingredientsNutrition.isEmpty;

  /// Convenience for one plated portion scaled by [servingCount] (meal plan).
  double caloriesForServings(double servingCount) =>
      caloriesPerServing * servingCount;

  static const NutritionModel empty = NutritionModel(
    caloriesPerServing: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    fiber: 0,
    sugar: 0,
    sodium: 0,
    cholesterol: 0,
    saturatedFat: 0,
    servings: 1,
    ingredientsNutrition: [],
  );

  Map<String, dynamic> toMap() => {
    'caloriesPerServing': caloriesPerServing,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'sugar': sugar,
    'sodium': sodium,
    'cholesterol': cholesterol,
    'saturatedFat': saturatedFat,
    'servings': servings,
    'ingredientsNutrition': ingredientsNutrition.map((e) => e.toMap()).toList(),
  };

  factory NutritionModel.fromMap(Map<String, dynamic> m) => NutritionModel(
    caloriesPerServing: (m['caloriesPerServing'] ?? 0).toDouble(),
    protein: (m['protein'] ?? 0).toDouble(),
    carbs: (m['carbs'] ?? 0).toDouble(),
    fat: (m['fat'] ?? 0).toDouble(),
    fiber: (m['fiber'] ?? 0).toDouble(),
    sugar: (m['sugar'] ?? 0).toDouble(),
    sodium: (m['sodium'] ?? 0).toDouble(),
    cholesterol: (m['cholesterol'] ?? 0).toDouble(),
    saturatedFat: (m['saturatedFat'] ?? 0).toDouble(),
    servings: (m['servings'] ?? 1).toInt(),
    ingredientsNutrition: ((m['ingredientsNutrition'] ?? []) as List)
        .map(
          (e) =>
              IngredientNutrition.fromMap(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
  );
}

/// One ingredient's contribution to a single serving.
class IngredientNutrition {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const IngredientNutrition({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };

  factory IngredientNutrition.fromMap(Map<String, dynamic> m) =>
      IngredientNutrition(
        name: (m['name'] ?? '').toString(),
        calories: (m['calories'] ?? 0).toDouble(),
        protein: (m['protein'] ?? 0).toDouble(),
        carbs: (m['carbs'] ?? 0).toDouble(),
        fat: (m['fat'] ?? 0).toDouble(),
      );
}
