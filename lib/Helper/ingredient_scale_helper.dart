class IngredientScaleHelper {
  static const Map<String, double> vulgarFractions = {
    '¼': 0.25,
    '½': 0.5,
    '¾': 0.75,
    '⅓': 0.3333333333333333,
    '⅔': 0.6666666666666666,
    '⅛': 0.125,
    '⅜': 0.375,
    '⅝': 0.625,
    '⅞': 0.875,
  };

  // static String formatDouble(double val) {
  //   if (val <= 0) return '';

  //   // Extract whole and fractional parts
  //   int whole = val.floor();
  //   double fraction = val - whole;

  //   // Handle rounding/precision issues
  //   if (fraction < 0.01) {
  //     return whole.toString();
  //   }
  //   if (fraction > 0.99) {
  //     return (whole + 1).toString();
  //   }

  //   // Find the closest common fraction
  //   final fractionTargets = [
  //     _FractionTarget(1, 8, 0.125),
  //     _FractionTarget(1, 4, 0.25),
  //     _FractionTarget(1, 3, 0.3333),
  //     _FractionTarget(3, 8, 0.375),
  //     _FractionTarget(1, 2, 0.5),
  //     _FractionTarget(5, 8, 0.625),
  //     _FractionTarget(2, 3, 0.6667),
  //     _FractionTarget(3, 4, 0.75),
  //     _FractionTarget(7, 8, 0.875),
  //   ];

  //   _FractionTarget? closest;
  //   double minDiff = 0.02; // Tolerance for matching a common fraction

  //   for (final target in fractionTargets) {
  //     double diff = (fraction - target.value).abs();
  //     if (diff < minDiff) {
  //       minDiff = diff;
  //       closest = target;
  //     }
  //   }

  //   if (closest != null) {
  //     if (whole > 0) {
  //       return '$whole ${closest.numerator}/${closest.denominator}';
  //     } else {
  //       return '${closest.numerator}/${closest.denominator}';
  //     }
  //   }

  //   // Otherwise, display as decimal with up to 2 decimal places
  //   String decimalStr = val.toStringAsFixed(2);
  //   // Remove trailing zeros and possible trailing dot
  //   if (decimalStr.endsWith('.00')) {
  //     return decimalStr.substring(0, decimalStr.length - 3);
  //   }
  //   if (decimalStr.contains('.')) {
  //     while (decimalStr.endsWith('0')) {
  //       decimalStr = decimalStr.substring(0, decimalStr.length - 1);
  //     }
  //     if (decimalStr.endsWith('.')) {
  //       decimalStr = decimalStr.substring(0, decimalStr.length - 1);
  //     }
  //   }
  //   return decimalStr;
  // }

  static String formatDouble(double val) {
    if (val < 0) return '';
    if (val == 0) return '0';

    int whole = val.floor();
    double fraction = val - whole;

    if (fraction < 0.01) {
      return whole.toString();
    }

    if (fraction > 0.99) {
      return (whole + 1).toString();
    }

    final fractionTargets = [
      _FractionTarget(1, 8, 0.125),
      _FractionTarget(1, 4, 0.25),
      _FractionTarget(1, 3, 0.3333),
      _FractionTarget(3, 8, 0.375),
      _FractionTarget(1, 2, 0.5),
      _FractionTarget(5, 8, 0.625),
      _FractionTarget(2, 3, 0.6667),
      _FractionTarget(3, 4, 0.75),
      _FractionTarget(7, 8, 0.875),
    ];

    _FractionTarget? closest;
    double minDiff = 0.02;

    for (final target in fractionTargets) {
      final diff = (fraction - target.value).abs();

      if (diff < minDiff) {
        minDiff = diff;
        closest = target;
      }
    }

    if (closest != null) {
      if (whole > 0) {
        return '$whole ${closest.numerator}/${closest.denominator}';
      }

      return '${closest.numerator}/${closest.denominator}';
    }

    var decimalStr = val.toStringAsFixed(2);

    while (decimalStr.contains('.') && decimalStr.endsWith('0')) {
      decimalStr = decimalStr.substring(0, decimalStr.length - 1);
    }

    if (decimalStr.endsWith('.')) {
      decimalStr = decimalStr.substring(0, decimalStr.length - 1);
    }

    return decimalStr;
  }

  static String scaleIngredient(String ingredient, double multiplier) {
    if (multiplier == 1.0) return ingredient;
    final trimmed = ingredient.trim();
    if (trimmed.isEmpty) return ingredient;

    // 1. Mixed vulgar fraction: e.g. "1 ½" or "1½"
    final vulgarMixedRegex = RegExp(r'^(\d+)\s*([¼½¾⅓⅔⅛⅜⅝⅞])');
    var match = vulgarMixedRegex.firstMatch(trimmed);
    if (match != null) {
      final whole = double.parse(match.group(1)!);
      final fracChar = match.group(2)!;
      final fracVal = vulgarFractions[fracChar] ?? 0.0;
      final totalVal = (whole + fracVal) * multiplier;
      final remaining = trimmed.substring(match.end);
      return '${formatDouble(totalVal)}$remaining';
    }

    // 2. Simple vulgar fraction: e.g. "½"
    final vulgarRegex = RegExp(r'^([¼½¾⅓⅔⅛⅜⅝⅞])');
    match = vulgarRegex.firstMatch(trimmed);
    if (match != null) {
      final fracChar = match.group(1)!;
      final fracVal = vulgarFractions[fracChar] ?? 0.0;
      final totalVal = fracVal * multiplier;
      final remaining = trimmed.substring(match.end);
      return '${formatDouble(totalVal)}$remaining';
    }

    // 3. Mixed fraction: e.g. "1 1/2" or "1-1/2" or "1  1/2"
    final mixedFractionRegex = RegExp(r'^(\d+)\s*[- ]\s*([1-9]\d*)/([1-9]\d*)');
    match = mixedFractionRegex.firstMatch(trimmed);
    if (match != null) {
      final whole = double.parse(match.group(1)!);
      final num = double.parse(match.group(2)!);
      final den = double.parse(match.group(3)!);
      final totalVal = (whole + (num / den)) * multiplier;
      final remaining = trimmed.substring(match.end);
      return '${formatDouble(totalVal)}$remaining';
    }

    // 4. Range of integers/decimals: e.g. "1-2" or "1 to 2" or "1.5 - 2.5"
    final rangeRegex = RegExp(r'^(\d+(?:\.\d+)?)\s*(-|to)\s*(\d+(?:\.\d+)?)');
    match = rangeRegex.firstMatch(trimmed);
    if (match != null) {
      final val1 = double.parse(match.group(1)!);
      final val2 = double.parse(match.group(3)!);
      final scaledVal1 = val1 * multiplier;
      final scaledVal2 = val2 * multiplier;

      final matchedText = match.group(0)!;
      final firstNumStr = match.group(1)!;
      final secondNumStr = match.group(3)!;
      final separatorWithSpaces = matchedText.substring(
        firstNumStr.length,
        matchedText.length - secondNumStr.length,
      );
      final remaining = trimmed.substring(match.end);

      return '${formatDouble(scaledVal1)}$separatorWithSpaces${formatDouble(scaledVal2)}$remaining';
    }

    // 5. Simple fraction: e.g. "1/2"
    final fractionRegex = RegExp(r'^([1-9]\d*)/([1-9]\d*)');
    match = fractionRegex.firstMatch(trimmed);
    if (match != null) {
      final num = double.parse(match.group(1)!);
      final den = double.parse(match.group(2)!);
      final totalVal = (num / den) * multiplier;
      final remaining = trimmed.substring(match.end);
      return '${formatDouble(totalVal)}$remaining';
    }

    // 6. Decimal/integer: e.g. "1.5" or "2"
    final decimalRegex = RegExp(r'^(\d+(?:\.\d+)?)');
    match = decimalRegex.firstMatch(trimmed);
    if (match != null) {
      final val = double.parse(match.group(1)!);
      final totalVal = val * multiplier;
      final remaining = trimmed.substring(match.end);
      return '${formatDouble(totalVal)}$remaining';
    }

    return ingredient;
  }
}

class _FractionTarget {
  final int numerator;
  final int denominator;
  final double value;

  _FractionTarget(this.numerator, this.denominator, this.value);
}
