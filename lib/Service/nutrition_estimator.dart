import 'package:recipe_ai/Model/nutrition_model.dart';
import 'package:recipe_ai/Helper/ingredient_density.dart';

/// Offline nutrition estimator.
///
/// There is no external food API, so nutrition is estimated locally: each
/// ingredient line is parsed into an approximate gram weight, matched against a
/// compact per-100 g food table, and summed. Whole-recipe totals are the sum of
/// every ingredient; per-serving divides by the serving count. These are
/// deliberately rough — surfaced everywhere as "AI estimates, not medical
/// advice".
class NutritionEstimator {
  const NutritionEstimator._();

  /// Build a [NutritionModel] from raw ingredient lines + serving count.
  static NutritionModel estimate({
    required List<String> ingredientLines,
    required int servings,
  }) {
    final srv = servings < 1 ? 1 : servings;

    double kcal = 0, p = 0, c = 0, f = 0;
    double fiber = 0, sugar = 0, sodium = 0, chol = 0, sat = 0;
    final perIngredientWhole = <IngredientNutrition>[];

    for (final raw in ingredientLines) {
      if (raw.trim().isEmpty) continue;
      final parsed = _parse(raw);
      if (parsed == null) continue;
      final food = _lookup(parsed.name);
      final factor = parsed.grams / 100.0;

      final iKcal = food.kcal * factor;
      final iP = food.protein * factor;
      final iC = food.carbs * factor;
      final iF = food.fat * factor;

      // Skip zero-calorie fillers (water, salt) from the visible breakdown but
      // still count their facts (sodium etc.).
      kcal += iKcal;
      p += iP;
      c += iC;
      f += iF;
      fiber += food.fiber * factor;
      sugar += food.sugar * factor;
      sodium += food.sodium * factor;
      chol += food.cholesterol * factor;
      sat += food.satFat * factor;

      if (iKcal >= 1) {
        perIngredientWhole.add(IngredientNutrition(
          name: parsed.name,
          calories: iKcal,
          protein: iP,
          carbs: iC,
          fat: iF,
        ));
      }
    }

    // Convert whole-recipe sums → per serving.
    IngredientNutrition perServe(IngredientNutrition w) => IngredientNutrition(
          name: w.name,
          calories: w.calories / srv,
          protein: w.protein / srv,
          carbs: w.carbs / srv,
          fat: w.fat / srv,
        );

    final perIngredient = perIngredientWhole.map(perServe).toList()
      ..sort((a, b) => b.calories.compareTo(a.calories));

    return NutritionModel(
      caloriesPerServing: kcal / srv,
      protein: p / srv,
      carbs: c / srv,
      fat: f / srv,
      fiber: fiber / srv,
      sugar: sugar / srv,
      sodium: sodium / srv,
      cholesterol: chol / srv,
      saturatedFat: sat / srv,
      servings: srv,
      ingredientsNutrition: perIngredient,
    );
  }

  // ── Ingredient line parsing ────────────────────────────────────────────────

  static const Map<String, double> _unicodeFractions = {
    '½': 0.5, '⅓': 1 / 3, '⅔': 2 / 3, '¼': 0.25, '¾': 0.75,
    '⅛': 0.125, '⅜': 0.375, '⅝': 0.625, '⅞': 0.875, '⅕': 0.2,
    '⅖': 0.4, '⅗': 0.6, '⅘': 0.8, '⅙': 1 / 6,
  };

  /// Units expressed in millilitres (volume) — converted to grams via density.
  static const Map<String, double> _volumeMl = {
    'cup': 240, 'cups': 240, 'c': 240,
    'tbsp': 15, 'tablespoon': 15, 'tablespoons': 15, 'tbs': 15, 'tbl': 15,
    'tsp': 5, 'teaspoon': 5, 'teaspoons': 5,
    'ml': 1, 'milliliter': 1, 'millilitre': 1, 'cc': 1,
    'l': 1000, 'liter': 1000, 'litre': 1000, 'liters': 1000, 'litres': 1000,
    'cl': 10, 'dl': 100,
    'floz': 30, 'quart': 946, 'pint': 473, 'gallon': 3785,
  };

  /// Units expressed directly in grams (weight).
  static const Map<String, double> _weightG = {
    'g': 1, 'gram': 1, 'grams': 1, 'gm': 1, 'gms': 1,
    'kg': 1000, 'kilogram': 1000, 'kilograms': 1000, 'kilo': 1000,
    'mg': 0.001,
    'oz': 28.35, 'ounce': 28.35, 'ounces': 28.35,
    'lb': 453.6, 'lbs': 453.6, 'pound': 453.6, 'pounds': 453.6,
  };

  /// Countable "units" → grams each (rough), when no weight/volume is given.
  static const Map<String, double> _countGrams = {
    'clove': 5, 'cloves': 5,
    'can': 400, 'cans': 400, 'tin': 400,
    'slice': 25, 'slices': 25,
    'pinch': 0.5, 'pinches': 0.5, 'dash': 0.5,
    'stick': 113, 'sticks': 113, // butter stick
    'sprig': 2, 'sprigs': 2,
    'bunch': 100, 'bunches': 100,
    'handful': 30,
    'package': 250, 'packet': 250, 'pkg': 250,
    'jar': 300, 'bottle': 300,
    'stalk': 40, 'stalks': 40,
    'head': 500, // e.g. head of cabbage/lettuce
    'ear': 100, // corn
  };

  /// Per-piece weight for whole-item ingredients (no unit, e.g. "2 eggs").
  static const Map<String, double> _pieceGrams = {
    'egg': 50, 'onion': 110, 'garlic': 5, 'tomato': 120, 'potato': 170,
    'carrot': 60, 'banana': 120, 'apple': 180, 'lemon': 60, 'lime': 45,
    'pepper': 120, 'avocado': 200, 'cucumber': 200, 'zucchini': 200,
    'chili': 15, 'chilli': 15, 'shallot': 40, 'scallion': 15,
    'mushroom': 20, 'orange': 130, 'chicken': 170, 'breast': 170,
    'thigh': 90, 'sausage': 75, 'eggplant': 250, 'aubergine': 250,
  };

  static _Parsed? _parse(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;

    // Strip leading filler words so a malformed line like "To 1 ½ tsp sugar"
    // still parses its quantity ("1 ½ tsp") and name ("sugar").
    s = s.replaceFirst(
        RegExp(r'^(to|for|of|about|approx\.?|around)\s+', caseSensitive: false),
        '');

    // Leading unicode fraction (e.g. "½ cup").
    double? qty;
    if (s.isNotEmpty && _unicodeFractions.containsKey(s[0])) {
      qty = _unicodeFractions[s[0]];
      s = s.substring(1).trim();
    } else {
      // Mixed / fraction / decimal / integer.
      final m = RegExp(r'^(\d+)\s+(\d+)\s*/\s*(\d+)').firstMatch(s) ?? // 1 1/2
          RegExp(r'^(\d+)\s*/\s*(\d+)').firstMatch(s) ?? // 3/4
          RegExp(r'^(\d+(?:\.\d+)?)').firstMatch(s); // 2 or 2.5
      if (m != null) {
        if (m.groupCount == 3) {
          qty = double.parse(m.group(1)!) +
              double.parse(m.group(2)!) / double.parse(m.group(3)!);
        } else if (m.groupCount == 2) {
          qty = double.parse(m.group(1)!) / double.parse(m.group(2)!);
        } else {
          qty = double.parse(m.group(1)!);
        }
        s = s.substring(m.end).trim();
        // A trailing unicode fraction right after an int, e.g. "1 ½".
        if (s.isNotEmpty && _unicodeFractions.containsKey(s[0])) {
          qty = qty + _unicodeFractions[s[0]]!;
          s = s.substring(1).trim();
        }
        // A range like "2-3" — first number already captured; drop "-3".
        s = s.replaceFirst(RegExp(r'^[-–]\s*\d+(?:\.\d+)?\s*'), '');
      }
    }

    // Optional unit word.
    String? unit;
    final wordMatch = RegExp(r'^([a-zA-Z]+)\.?\b').firstMatch(s);
    if (wordMatch != null) {
      final w = wordMatch.group(1)!.toLowerCase();
      if (_volumeMl.containsKey(w) ||
          _weightG.containsKey(w) ||
          _countGrams.containsKey(w)) {
        unit = w;
        s = s.substring(wordMatch.end).trim();
        // "of" filler: "2 cups of rice"
        s = s.replaceFirst(RegExp(r'^of\s+', caseSensitive: false), '');
      }
    }

    final name = _cleanName(s);
    if (name.isEmpty) return null;

    final grams = _toGrams(qty, unit, name);
    if (grams <= 0) return null;
    return _Parsed(name: name, grams: grams);
  }

  static double _toGrams(double? qty, String? unit, String name) {
    final q = qty ?? 1.0;
    if (unit != null) {
      if (_weightG.containsKey(unit)) return q * _weightG[unit]!;
      if (_volumeMl.containsKey(unit)) {
        return q * _volumeMl[unit]! * _densityFor(name);
      }
      if (_countGrams.containsKey(unit)) return q * _countGrams[unit]!;
    }
    // No recognised unit → treat the number as a count of whole pieces.
    return q * _pieceWeight(name);
  }

  /// Liquid densities (g/ml). [IngredientDensity] only covers dry solids and
  /// returns a middling 0.5 for liquids, so real densities are needed here for
  /// calorie maths (e.g. 2 tbsp oil = 30 ml × 0.92 ≈ 27 g, not 15 g).
  static const Map<String, double> _liquidDensity = {
    'honey': 1.42, 'syrup': 1.33, 'molasses': 1.4,
    'soy sauce': 1.15, 'soya sauce': 1.15, 'ketchup': 1.14, 'passata': 1.05,
    'juice': 1.04, 'milk': 1.03, 'cream': 1.0, 'yogurt': 1.03, 'yoghurt': 1.03,
    'curd': 1.03, 'vinegar': 1.01, 'water': 1.0, 'stock': 1.0, 'broth': 1.0,
    'wine': 0.99, 'oil': 0.92, 'ghee': 0.91, 'butter': 0.91,
  };

  static double _densityFor(String name) {
    final n = name.toLowerCase();
    for (final e in _liquidDensity.entries) {
      if (n.contains(e.key)) return e.value;
    }
    // Dry / solid goods (flour, sugar, rice, …) come from IngredientDensity.
    return IngredientDensity.gramsPerMl(name);
  }

  static double _pieceWeight(String name) {
    final n = name.toLowerCase();
    for (final e in _pieceGrams.entries) {
      if (n.contains(e.key)) return e.value;
    }
    return 100; // generic "1 unit" fallback
  }

  static String _cleanName(String s) {
    var out = s;
    // Drop parenthetical notes, any stray brackets, and everything after a
    // comma or "to taste"-style trailer.
    out = out.replaceAll(RegExp(r'\([^)]*\)'), ' ');
    out = out.replaceAll(RegExp(r'[()\[\]]'), ' ');
    final comma = out.indexOf(',');
    if (comma > 0) out = out.substring(0, comma);
    // Strip common prep/descriptor words.
    out = out.replaceAll(
        RegExp(
            r'\b(fresh|dried|chopped|minced|diced|sliced|grated|ground|to taste|large|medium|small|ripe|boneless|skinless|peeled|finely|roughly|optional|for garnish)\b',
            caseSensitive: false),
        ' ');
    out = out.replaceAll(RegExp(r'\s+'), ' ').trim();
    out = out.replaceAll(RegExp(r'^[^a-zA-Z]+'), '').trim();
    if (out.isEmpty) return out;
    return out[0].toUpperCase() + out.substring(1);
  }

  // ── Food table (per 100 g) ──────────────────────────────────────────────────
  // Order matters: more specific keywords first (checked left→right).
  static const List<_Food> _foods = [
    _Food(['coconut milk', 'coconut cream'], 230, 2.3, 6, 24,
        fiber: 0, sugar: 3, sodium: 15, satFat: 21),
    _Food(['coconut oil'], 862, 0, 0, 100, satFat: 87),
    _Food(['coconut'], 354, 3.3, 15, 33, fiber: 9, sugar: 6, satFat: 30),
    _Food(['olive oil'], 884, 0, 0, 100, satFat: 14),
    _Food(['vegetable oil', 'canola', 'sunflower oil', 'oil'], 884, 0, 0, 100,
        satFat: 12),
    _Food(['butter'], 717, 0.9, 0.1, 81, satFat: 51, cholesterol: 215),
    _Food(['ghee'], 900, 0, 0, 100, satFat: 62, cholesterol: 256),
    _Food(['chickpea', 'garbanzo'], 139, 8, 22, 2.6,
        fiber: 7, sodium: 240, satFat: 0.3),
    _Food(['lentil', 'dal', 'daal'], 116, 9, 20, 0.4, fiber: 8),
    _Food(['kidney bean', 'black bean', 'beans'], 127, 9, 23, 0.5, fiber: 6),
    _Food(['curry paste', 'curry powder', 'masala'], 150, 3, 12, 9,
        fiber: 3, sugar: 4, sodium: 1200, satFat: 3),
    _Food(['spinach'], 23, 2.9, 3.6, 0.4, fiber: 2.2, sugar: 0.4, sodium: 79),
    _Food(['kale'], 49, 4.3, 9, 0.9, fiber: 3.6),
    _Food(['lettuce'], 15, 1.4, 2.9, 0.2, fiber: 1.3),
    _Food(['broccoli'], 34, 2.8, 7, 0.4, fiber: 2.6),
    _Food(['cauliflower'], 25, 1.9, 5, 0.3, fiber: 2),
    _Food(['mushroom'], 22, 3.1, 3.3, 0.3, fiber: 1),
    _Food(['onion', 'shallot'], 40, 1.1, 9, 0.1, fiber: 1.7, sugar: 4.2),
    _Food(['garlic'], 149, 6.4, 33, 0.5, fiber: 2.1),
    _Food(['ginger'], 80, 1.8, 18, 0.8, fiber: 2),
    _Food(['tomato'], 18, 0.9, 3.9, 0.2, fiber: 1.2, sugar: 2.6, sodium: 5),
    _Food(['potato'], 77, 2, 17, 0.1, fiber: 2.1),
    _Food(['sweet potato'], 86, 1.6, 20, 0.1, fiber: 3),
    _Food(['carrot'], 41, 0.9, 10, 0.2, fiber: 2.8, sugar: 4.7),
    _Food(['bell pepper', 'capsicum', 'pepper'], 31, 1, 6, 0.3, fiber: 2.1),
    _Food(['chili', 'chilli', 'jalapeno'], 40, 1.9, 9, 0.4, fiber: 1.5),
    _Food(['cucumber'], 15, 0.7, 3.6, 0.1),
    _Food(['zucchini', 'courgette'], 17, 1.2, 3.1, 0.3),
    _Food(['eggplant', 'aubergine'], 25, 1, 6, 0.2, fiber: 3),
    _Food(['peas'], 81, 5.4, 14, 0.4, fiber: 5.7, sugar: 5.7),
    _Food(['corn', 'sweetcorn'], 86, 3.2, 19, 1.2, fiber: 2.7, sugar: 3.2),
    _Food(['avocado'], 160, 2, 9, 15, fiber: 7, satFat: 2.1),
    _Food(['rice', 'basmati', 'jasmine rice'], 360, 7, 80, 0.6,
        fiber: 1.3), // uncooked
    _Food(['pasta', 'spaghetti', 'noodle', 'macaroni'], 371, 13, 75, 1.5,
        fiber: 3),
    _Food(['bread', 'toast', 'bun'], 265, 9, 49, 3.2, fiber: 2.7, sodium: 490),
    _Food(['flour', 'maida'], 364, 10, 76, 1, fiber: 2.7),
    _Food(['oats', 'oatmeal'], 389, 17, 66, 7, fiber: 10),
    _Food(['quinoa'], 368, 14, 64, 6, fiber: 7),
    _Food(['sugar', 'caster sugar', 'brown sugar'], 387, 0, 100, 0, sugar: 100),
    _Food(['honey'], 304, 0.3, 82, 0, sugar: 82),
    _Food(['maple syrup'], 260, 0, 67, 0, sugar: 60),
    _Food(['chocolate', 'cocoa', 'cacao'], 546, 4.9, 61, 31,
        sugar: 48, satFat: 19),
    _Food(['egg'], 155, 13, 1.1, 11, cholesterol: 373, satFat: 3.3),
    _Food(['greek yogurt', 'yoghurt', 'yogurt', 'curd'], 59, 10, 3.6, 0.4,
        sugar: 3.6, satFat: 0.3),
    _Food(['cream cheese'], 342, 6, 4, 34, satFat: 19, cholesterol: 110),
    _Food(['cheese', 'cheddar', 'parmesan', 'mozzarella'], 402, 25, 1.3, 33,
        satFat: 19, sodium: 621, cholesterol: 105),
    _Food(['cream', 'heavy cream'], 340, 2, 3, 36, satFat: 23, cholesterol: 113),
    _Food(['milk'], 42, 3.4, 5, 1, sugar: 5, satFat: 0.6),
    _Food(['paneer', 'tofu'], 265, 18, 6, 20, satFat: 8),
    _Food(['chicken breast', 'chicken'], 165, 31, 0, 3.6,
        cholesterol: 85, satFat: 1),
    _Food(['beef', 'mince', 'steak'], 250, 26, 0, 15, satFat: 6, cholesterol: 90),
    _Food(['pork', 'bacon', 'ham'], 242, 27, 0, 14, satFat: 5, cholesterol: 80),
    _Food(['lamb', 'mutton'], 294, 25, 0, 21, satFat: 9),
    _Food(['salmon', 'tuna', 'fish', 'cod'], 208, 20, 0, 13,
        satFat: 3, cholesterol: 55),
    _Food(['shrimp', 'prawn'], 99, 24, 0.2, 0.3, cholesterol: 189, sodium: 111),
    _Food(['almond', 'cashew', 'walnut', 'nut', 'pecan'], 579, 21, 22, 50,
        fiber: 12, satFat: 3.7),
    _Food(['peanut butter'], 588, 25, 20, 50, satFat: 10),
    _Food(['peanut'], 567, 26, 16, 49, fiber: 8, satFat: 7),
    _Food(['soy sauce', 'soya sauce'], 53, 8, 4.9, 0, sodium: 5493),
    _Food(['vinegar'], 18, 0, 0.9, 0),
    _Food(['stock', 'broth', 'bouillon'], 15, 1, 1, 0.5, sodium: 400),
    _Food(['coriander', 'cilantro', 'parsley', 'basil', 'mint', 'herb'], 23, 2,
        4, 0.5, fiber: 2),
    _Food(['cumin', 'turmeric', 'paprika', 'spice', 'cinnamon', 'pepper'], 375,
        18, 44, 22, fiber: 10),
    _Food(['salt'], 0, 0, 0, 0, sodium: 38758),
    _Food(['lime', 'lemon'], 29, 1, 9, 0.2, fiber: 2.8),
    _Food(['water'], 0, 0, 0, 0),
    _Food(['banana'], 89, 1.1, 23, 0.3, fiber: 2.6, sugar: 12),
    _Food(['apple'], 52, 0.3, 14, 0.2, fiber: 2.4, sugar: 10),
    _Food(['berries', 'blueberry', 'strawberry', 'raspberry'], 57, 0.7, 14, 0.3,
        fiber: 2.4, sugar: 10),
    _Food(['orange'], 47, 0.9, 12, 0.1, fiber: 2.4, sugar: 9),
  ];

  static const _Food _fallback = _Food(['*'], 120, 4, 15, 4, fiber: 1.5);

  static _Food _lookup(String name) {
    final n = name.toLowerCase();
    for (final food in _foods) {
      for (final k in food.keywords) {
        if (n.contains(k)) return food;
      }
    }
    return _fallback;
  }
}

class _Parsed {
  final String name;
  final double grams;
  const _Parsed({required this.name, required this.grams});
}

/// Per-100 g nutrition for a group of ingredient keywords.
class _Food {
  final List<String> keywords;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium; // mg
  final double cholesterol; // mg
  final double satFat; // g

  const _Food(
    this.keywords,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat, {
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.cholesterol = 0,
    this.satFat = 0,
  });
}
