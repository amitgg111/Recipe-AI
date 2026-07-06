import 'package:recipe_ai/Helper/ingredient_scale_helper.dart';

/// The two measurement systems the app supports.
enum UnitSystem { metric, imperial }

/// The physical dimension a unit measures. Conversions only ever happen
/// between units of the same dimension.
enum UnitDimension { volume, mass, length, temperature, count }

/// A single, reusable Metric ↔ Imperial conversion engine.
///
/// This is the ONE place unit-conversion math lives (requirement 9) — every
/// screen should call this rather than re-implementing factors. It is pure and
/// UI-free so it can be unit-tested and used from controllers, services and
/// widgets alike.
///
/// Design:
///  * Each known unit maps to a canonical base unit for its dimension
///    (volume→ml, mass→g, length→cm) with a multiplicative factor.
///  * [convert] converts a value between any two same-dimension units.
///  * [toSystem] picks the most natural unit in the target system and converts,
///    e.g. 240 ml → "1 cup" (imperial) or 2 cup → "473 ml" (metric).
class UnitConverter {
  UnitConverter._();

  // ── Canonical factors (value * factor = value in the base unit) ───────────
  // Volume base = millilitre. Mass base = gram. Length base = centimetre.
  static const Map<String, double> _volumeToMl = {
    'ml': 1.0,
    'milliliter': 1.0,
    'millilitre': 1.0,
    'l': 1000.0,
    'liter': 1000.0,
    'litre': 1000.0,
    'tsp': 4.92892,
    'teaspoon': 4.92892,
    'tbsp': 14.7868,
    'tablespoon': 14.7868,
    'fl oz': 29.5735,
    'floz': 29.5735,
    'cup': 236.588,
    'pint': 473.176,
    'pt': 473.176,
    'quart': 946.353,
    'qt': 946.353,
    'gallon': 3785.41,
    'gal': 3785.41,
  };

  static const Map<String, double> _massToG = {
    'g': 1.0,
    'gram': 1.0,
    'gm': 1.0,
    'kg': 1000.0,
    'kilogram': 1000.0,
    'mg': 0.001,
    'oz': 28.3495,
    'ounce': 28.3495,
    'lb': 453.592,
    'lbs': 453.592,
    'pound': 453.592,
  };

  static const Map<String, double> _lengthToCm = {
    'cm': 1.0,
    'centimeter': 1.0,
    'centimetre': 1.0,
    'mm': 0.1,
    'm': 100.0,
    'inch': 2.54,
    'inches': 2.54,
    'in': 2.54,
    'ft': 30.48,
    'foot': 30.48,
    'feet': 30.48,
  };

  // Maps every recognised spelling/plural to ONE canonical short form, so
  // "tablespoon", "tablespoons", "tbsps" and "tbsp" all collapse to "tbsp".
  // Without this the spelled-out forms would be treated as distinct units and
  // wrongly considered "already metric".
  static const Map<String, String> _normalise = {
    'teaspoon': 'tsp', 'teaspoons': 'tsp', 'tsps': 'tsp',
    'tablespoon': 'tbsp', 'tablespoons': 'tbsp', 'tbsps': 'tbsp', 'tbs': 'tbsp',
    'cups': 'cup',
    'gram': 'g', 'grams': 'g', 'gm': 'g', 'gms': 'g',
    'kilogram': 'kg', 'kilograms': 'kg',
    'milligram': 'mg', 'milligrams': 'mg',
    'ounce': 'oz', 'ounces': 'oz',
    'pound': 'lb', 'pounds': 'lb', 'lbs': 'lb',
    'liter': 'l', 'liters': 'l', 'litre': 'l', 'litres': 'l',
    'milliliter': 'ml', 'milliliters': 'ml',
    'millilitre': 'ml', 'millilitres': 'ml',
    'centimeter': 'cm', 'centimeters': 'cm',
    'centimetre': 'cm', 'centimetres': 'cm',
    'inches': 'inch', 'in': 'inch',
    'foot': 'ft', 'feet': 'ft',
    'fluid ounce': 'fl oz', 'fluid ounces': 'fl oz', 'floz': 'fl oz',
    'gallon': 'gal', 'gallons': 'gal',
    'quart': 'qt', 'quarts': 'qt',
    'pint': 'pt', 'pints': 'pt',
  };

  /// Canonical short spelling for a recognised unit, or null if unknown.
  static String? _canonical(String unit) {
    final lower = unit.toLowerCase().trim();
    final u = _normalise[lower] ?? lower;
    if (_volumeToMl.containsKey(u) ||
        _massToG.containsKey(u) ||
        _lengthToCm.containsKey(u)) {
      return u;
    }
    return null;
  }

  /// The dimension of a recognised unit, or null if unknown.
  static UnitDimension? dimensionOf(String unit) {
    final u = _canonical(unit);
    if (u == null) return null;
    if (_volumeToMl.containsKey(u)) return UnitDimension.volume;
    if (_massToG.containsKey(u)) return UnitDimension.mass;
    if (_lengthToCm.containsKey(u)) return UnitDimension.length;
    return null;
  }

  /// True when [unit] is one this engine can convert.
  static bool isConvertible(String unit) => _canonical(unit) != null;

  // ── Core conversion ───────────────────────────────────────────────────────
  /// Convert [value] from [fromUnit] to [toUnit]. Returns null when the units
  /// are unknown or belong to different dimensions (caller keeps the original).
  static double? convert({
    required double value,
    required String fromUnit,
    required String toUnit,
  }) {
    final from = _canonical(fromUnit);
    final to = _canonical(toUnit);
    if (from == null || to == null) return null;

    final table = _tableFor(from);
    if (table == null || table != _tableFor(to)) return null; // different dims

    final base = value * table[from]!;
    return base / table[to]!;
  }

  static Map<String, double>? _tableFor(String canonicalUnit) {
    if (_volumeToMl.containsKey(canonicalUnit)) return _volumeToMl;
    if (_massToG.containsKey(canonicalUnit)) return _massToG;
    if (_lengthToCm.containsKey(canonicalUnit)) return _lengthToCm;
    return null;
  }

  /// °C → °F.
  static double celsiusToFahrenheit(double c) => c * 9 / 5 + 32;

  /// °F → °C.
  static double fahrenheitToCelsius(double f) => (f - 32) * 5 / 9;

  // ── System-aware conversion ───────────────────────────────────────────────
  /// A converted measurement: numeric [value] plus its [unit].
  ///
  /// Convert ([value], [unit]) into the most natural unit of [system]. If the
  /// unit is already in the target system, or isn't convertible, the input is
  /// returned unchanged (so callers can always display *something*).
  static ({double value, String unit}) toSystem(
    double value,
    String unit,
    UnitSystem system,
  ) {
    final canonical = _canonical(unit);
    final dim = canonical == null ? null : dimensionOf(canonical);
    if (canonical == null || dim == null) return (value: value, unit: unit);

    switch (dim) {
      case UnitDimension.volume:
        return system == UnitSystem.metric
            ? _bestMetricVolume(value, canonical)
            : _bestImperialVolume(value, canonical);
      case UnitDimension.mass:
        return system == UnitSystem.metric
            ? _bestMetricMass(value, canonical)
            : _bestImperialMass(value, canonical);
      case UnitDimension.length:
        return system == UnitSystem.metric
            ? (value: convert(value: value, fromUnit: canonical, toUnit: 'cm')!, unit: 'cm')
            : (value: convert(value: value, fromUnit: canonical, toUnit: 'inch')!, unit: 'inch');
      case UnitDimension.temperature:
      case UnitDimension.count:
        return (value: value, unit: unit);
    }
  }

  static const _imperialVolumeUnits = {'tsp', 'tbsp', 'fl oz', 'cup', 'pint', 'pt', 'quart', 'qt', 'gallon', 'gal'};
  static const _imperialMassUnits = {'oz', 'ounce', 'lb', 'lbs', 'pound'};

  static ({double value, String unit}) _bestMetricVolume(double v, String from) {
    if (!_imperialVolumeUnits.contains(from)) return (value: v, unit: from); // already metric
    final ml = convert(value: v, fromUnit: from, toUnit: 'ml')!;
    return ml >= 1000
        ? (value: ml / 1000, unit: 'l')
        : (value: ml, unit: 'ml');
  }

  static ({double value, String unit}) _bestImperialVolume(double v, String from) {
    if (_imperialVolumeUnits.contains(from)) return (value: v, unit: from); // already imperial
    final ml = convert(value: v, fromUnit: from, toUnit: 'ml')!;
    if (ml >= 236.588) return (value: ml / 236.588, unit: 'cup');
    if (ml >= 14.7868) return (value: ml / 14.7868, unit: 'tbsp');
    return (value: ml / 4.92892, unit: 'tsp');
  }

  static ({double value, String unit}) _bestMetricMass(double v, String from) {
    if (!_imperialMassUnits.contains(from)) return (value: v, unit: from); // already metric
    final g = convert(value: v, fromUnit: from, toUnit: 'g')!;
    return g >= 1000 ? (value: g / 1000, unit: 'kg') : (value: g, unit: 'g');
  }

  static ({double value, String unit}) _bestImperialMass(double v, String from) {
    if (_imperialMassUnits.contains(from)) return (value: v, unit: from); // already imperial
    final g = convert(value: v, fromUnit: from, toUnit: 'g')!;
    return g >= 453.592 ? (value: g / 453.592, unit: 'lb') : (value: g / 28.3495, unit: 'oz');
  }

  /// Human-friendly formatting of a converted quantity.
  ///
  /// Metric units read best as rounded decimals (e.g. "710 ml", "1.2 l") while
  /// imperial cooking units read best as fractions (e.g. "1 1/2 cup"), so the
  /// formatter is unit-aware. Imperial units reuse the app's existing
  /// fraction/decimal formatter so output matches everywhere else.
  static String format(double value, String unit) {
    final u = unit.toLowerCase();
    String number;
    if (u == 'ml' || u == 'g' || u == 'mg') {
      number = value.round().toString(); // whole numbers read best
    } else if (u == 'l' || u == 'kg') {
      number = _trimDecimal(value, 2);
    } else if (u == 'cm' || u == 'mm' || u == 'inch' || u == 'in') {
      number = _trimDecimal(value, 1);
    } else {
      // Imperial cooking units → fractions, matching the rest of the app.
      number = IngredientScaleHelper.formatDouble(value);
    }
    return unit.isEmpty ? number : '$number $unit';
  }

  static String _trimDecimal(double value, int places) {
    var s = value.toStringAsFixed(places);
    if (s.contains('.')) {
      while (s.endsWith('0')) {
        s = s.substring(0, s.length - 1);
      }
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    }
    return s;
  }

  // ── Whole-line conversion ─────────────────────────────────────────────────
  /// Convert the leading "value unit" of an ingredient/instruction fragment to
  /// [system], leaving the rest of the text untouched. Returns the input
  /// unchanged when there is no leading measurement, the unit is unknown, or it
  /// is already in the target system. Expects an already-serving-scaled string
  /// (ascii numbers/fractions), i.e. the output of
  /// [IngredientScaleHelper.scaleIngredient].
  static String applySystem(String line, UnitSystem system) {
    final trimmed = line.trimLeft();
    if (trimmed.isEmpty) return line;

    double? value;
    int consumed = 0;

    // "1 3/4" (mixed) → 1.75
    var m = RegExp(r'^(\d+)\s+(\d+)/(\d+)').firstMatch(trimmed);
    if (m != null) {
      value = double.parse(m.group(1)!) +
          double.parse(m.group(2)!) / double.parse(m.group(3)!);
      consumed = m.end;
    } else {
      // "3/4" (simple fraction)
      m = RegExp(r'^(\d+)/(\d+)').firstMatch(trimmed);
      if (m != null) {
        value = double.parse(m.group(1)!) / double.parse(m.group(2)!);
        consumed = m.end;
      } else {
        // "1.5" or "2" (decimal / integer)
        m = RegExp(r'^(\d+(?:\.\d+)?)').firstMatch(trimmed);
        if (m != null) {
          value = double.parse(m.group(1)!);
          consumed = m.end;
        }
      }
    }
    if (value == null) return line;

    final afterNumber = trimmed.substring(consumed);
    final unitMatch = RegExp(r'^\s+([a-zA-Z]+)').firstMatch(afterNumber);
    if (unitMatch == null) return line;

    final unit = unitMatch.group(1)!;
    if (!isConvertible(unit)) return line;

    final rest = afterNumber.substring(unitMatch.end);
    final converted = toSystem(value, unit, system);
    return '${format(converted.value, converted.unit)}$rest';
  }

  /// The single entry point display code should call for an ingredient line:
  /// scales by the serving [multiplier] AND converts to [system] in one step.
  static String scaleAndConvert(
    String line,
    double multiplier,
    UnitSystem system,
  ) {
    final scaled = IngredientScaleHelper.scaleIngredient(line, multiplier);
    return applySystem(scaled, system);
  }
}
