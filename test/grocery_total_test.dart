import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_ai/Controllers/grocery_store_controller.dart';

/// Regression tests for GroceryStore.combineQuantities — the merged grocery
/// total must equal the sum of its parts. A non-greedy number regex used to
/// capture only the first digit of a multi-digit amount ("237 ml" → 2), which
/// produced garbage totals like "9 37 ml".
void main() {
  group('combineQuantities', () {
    test('sums multi-digit same-unit amounts', () {
      expect(GroceryStore.combineQuantities(['237 ML', '22 ML', '59 ML']),
          '318 ML');
      expect(GroceryStore.combineQuantities(['237 ML', '22 ML', '59 ML', '59 ML']),
          '377 ML');
      expect(GroceryStore.combineQuantities(['104 G', '65 G']), '169 G');
    });

    test('single amount passes through unchanged', () {
      expect(GroceryStore.combineQuantities(['532 ML']), '532 ML');
    });

    test('sums simple counts', () {
      expect(GroceryStore.combineQuantities(['2', '3']), '5');
    });
  });
}
