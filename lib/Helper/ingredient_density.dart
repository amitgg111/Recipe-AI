/// Approximate densities (grams per millilitre) for common cooking
/// ingredients.
///
/// Recipes are usually written in volume units (cups / tbsp / tsp). Showing a
/// *solid* ingredient's volume as millilitres in Metric reads wrong ("296 ml
/// besan"), so we convert volume → weight using these reference densities to
/// get a sensible gram value instead. Densities are cooking approximations —
/// exact weight varies with packing, grind and brand — but they land far
/// closer than a raw millilitre figure.
///
/// Liquids are intentionally excluded: they stay in ml / fl oz.
class IngredientDensity {
  IngredientDensity._();

  /// Ingredients that should remain a VOLUME (never converted to weight).
  /// Matched as whole WORDS (see [isLiquid]) so "baking soda" isn't mistaken
  /// for a drink and "breadcrumb" isn't caught by "rum".
  static const List<String> _liquidKeywords = [
    'water', 'milk', 'oil', 'cream', 'juice', 'stock', 'broth', 'vinegar',
    'wine', 'beer', 'coffee', 'tea', 'sauce', 'syrup', 'honey',
    'extract', 'essence', 'buttermilk', 'yogurt', 'yoghurt', 'curd',
    'passata', 'puree', 'purée', 'ketchup', 'vanilla', 'liqueur', 'rum',
    'brandy', 'whiskey', 'vodka', 'soda water', 'club soda', 'cola',
  ];

  /// grams-per-millilitre for specific ingredients. Longest keyword match wins
  /// (so "rice flour" beats "rice", "brown sugar" beats "sugar").
  static const Map<String, double> _density = {
    // Flours & starches
    'besan': 0.45, 'gram flour': 0.45, 'chickpea flour': 0.45,
    'rice flour': 0.55, 'corn flour': 0.54, 'cornflour': 0.54,
    'corn starch': 0.54, 'cornstarch': 0.54, 'all-purpose flour': 0.53,
    'all purpose flour': 0.53, 'plain flour': 0.53, 'wheat flour': 0.53,
    'maida': 0.53, 'flour': 0.53, 'cocoa': 0.41, 'custard powder': 0.6,
    // Grains & cereals
    'semolina': 0.67, 'sooji': 0.67, 'suji': 0.67, 'rava': 0.67,
    'poha': 0.35, 'flattened rice': 0.35, 'oats': 0.41, 'oatmeal': 0.41,
    'quinoa': 0.7, 'couscous': 0.72, 'bulgur': 0.6, 'barley': 0.8,
    'rice': 0.85, 'basmati': 0.85, 'breadcrumb': 0.4, 'granola': 0.45,
    // Sugars & leaveners
    'brown sugar': 0.9, 'powdered sugar': 0.56, 'icing sugar': 0.56,
    'caster sugar': 0.85, 'sugar': 0.85, 'jaggery': 0.85, 'salt': 1.2,
    'baking powder': 0.9, 'baking soda': 0.9, 'yeast': 0.68,
    // Legumes
    'lentil': 0.85, 'dal': 0.85, 'chickpea': 0.8, 'kidney bean': 0.8,
    'black bean': 0.8, 'bean': 0.6,
    // Nuts & seeds
    'cashew': 0.5, 'almond': 0.48, 'peanut': 0.6, 'walnut': 0.42,
    'pistachio': 0.5, 'coconut': 0.35, 'sesame': 0.6, 'cumin': 0.55,
    'coriander seed': 0.45, 'carom': 0.55, 'mustard seed': 0.7, 'nut': 0.5,
    'seed': 0.55,
    // Dairy solids & fats
    'butter': 0.91, 'ghee': 0.91, 'margarine': 0.91, 'cheese': 0.4,
    'paneer': 0.6, 'chocolate chip': 0.7, 'chocolate': 0.7,
    // Fruit & veg (chopped/prepared)
    'onion': 0.5, 'tomato': 0.6, 'potato': 0.6, 'carrot': 0.55,
    'peas': 0.6, 'corn': 0.6, 'spinach': 0.25, 'cabbage': 0.35,
    'raisin': 0.66, 'sultana': 0.66, 'currant': 0.66, 'date': 0.7,
    // Generic seasonings
    'spice': 0.5, 'powder': 0.55, 'masala': 0.5, 'herb': 0.2,
  };

  /// Fallback density for an unrecognised solid (a middling dry-goods value).
  static const double _defaultSolid = 0.5;

  /// Whole-word matcher for the liquid keywords, compiled once. Word
  /// boundaries stop "baking soda" matching a drink, "breadcrumb" matching
  /// "rum", or "steak" matching "tea".
  static final RegExp _liquidRe = RegExp(
    r'\b(?:' + _liquidKeywords.map(RegExp.escape).join('|') + r')\b',
  );

  /// True when [name] names a liquid — kept as a volume, not weighed.
  static bool isLiquid(String name) => _liquidRe.hasMatch(name.toLowerCase());

  /// True when [name] should be weighed (any non-empty, non-liquid ingredient).
  static bool isSolid(String name) =>
      name.trim().isNotEmpty && !isLiquid(name);

  /// grams-per-millilitre for [name]: the most specific keyword match, else a
  /// generic dry-goods density.
  static double gramsPerMl(String name) {
    final l = name.toLowerCase();
    String? best;
    for (final key in _density.keys) {
      if (l.contains(key) && (best == null || key.length > best.length)) {
        best = key;
      }
    }
    return best != null ? _density[best]! : _defaultSolid;
  }
}
