import 'package:recipe_ai/Helper/unit_converter.dart';

/// Reusable scaling for quantities and timers embedded in instruction text
/// (requirements 4 & 5).
///
/// Given one instruction step it will:
///   * scale + unit-convert any embedded measurement (e.g. "add 2 cups milk"
///     → "add 4 cups milk", or "add 473 ml milk" in metric), reusing the same
///     [UnitConverter] engine as the ingredient list so results stay
///     consistent, and
///   * scale any embedded duration linearly by the serving multiplier
///     (e.g. "cook for 10 minutes" → "cook for 15 minutes" at 1.5×).
///
/// It deliberately does NOT touch oven temperatures or pan dimensions (those
/// units are not in the measurement/duration patterns) so instructions stay
/// safe and sensible.
class InstructionScaler {
  InstructionScaler._();

  // Number token: mixed fraction, simple fraction, vulgar fraction, decimal or
  // integer — followed by a convertible cooking unit.
  static final RegExp _measure = RegExp(
    r'(\d+\s+\d+/\d+|\d+/\d+|[½¼¾⅓⅔⅛⅜⅝⅞]|\d+(?:\.\d+)?)\s*'
    r'(cups?|tbsps?|tablespoons?|tsps?|teaspoons?|milliliters?|millilitres?|ml|liters?|litres?|l|grams?|g|kilograms?|kg|ounces?|oz|pounds?|lbs?)\b',
    caseSensitive: false,
  );

  // A duration: number + a time unit.
  static final RegExp _duration = RegExp(
    r'(\d+(?:\.\d+)?)\s*(seconds?|secs?|minutes?|mins?|hours?|hrs?)\b',
    caseSensitive: false,
  );

  /// Scale + convert one instruction [step].
  static String scale(String step, double multiplier, UnitSystem system) {
    var result = step;

    // 1. Embedded measurements → reuse the ingredient engine on each match so
    //    the exact same scaling + conversion + formatting rules apply.
    result = result.replaceAllMapped(_measure, (m) {
      return UnitConverter.scaleAndConvert(m.group(0)!, multiplier, system);
    });

    // 2. Durations → linear scale by the serving multiplier (per product
    //    decision). Unit is preserved; temperatures are never matched here.
    if (multiplier != 1.0) {
      result = result.replaceAllMapped(_duration, (m) {
        final value = double.parse(m.group(1)!);
        final unit = m.group(2)!;
        return '${_formatDuration(value * multiplier)} $unit';
      });
    }

    return result;
  }

  /// Scale a whole list of steps.
  static List<String> scaleAll(
    List<String> steps,
    double multiplier,
    UnitSystem system,
  ) =>
      steps.map((s) => scale(s, multiplier, system)).toList();

  // Times read best as whole numbers; keep one decimal only when it matters.
  static String _formatDuration(double v) {
    if ((v - v.round()).abs() < 0.05) return v.round().toString();
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  // Exposed for callers that only want quantity scaling without durations.
  static String scaleQuantitiesOnly(
    String step,
    double multiplier,
    UnitSystem system,
  ) =>
      step.replaceAllMapped(_measure, (m) {
        return UnitConverter.scaleAndConvert(m.group(0)!, multiplier, system);
      });
}
