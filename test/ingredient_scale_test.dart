import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_ai/Helper/ingredient_scale_helper.dart';

void main() {
  group('IngredientScaleHelper unit tests', () {
    test('Should scale integers correctly', () {
      expect(IngredientScaleHelper.scaleIngredient('2 cups flour', 1.5), '3 cups flour');
      expect(IngredientScaleHelper.scaleIngredient('1 onion', 2.0), '2 onion');
    });

    test('Should scale decimals correctly', () {
      expect(IngredientScaleHelper.scaleIngredient('1.5 kg chicken', 2.0), '3 kg chicken');
      expect(IngredientScaleHelper.scaleIngredient('0.75 cups water', 2.0), '1 1/2 cups water');
      expect(IngredientScaleHelper.scaleIngredient('1.25 tsp oil', 2.0), '2 1/2 tsp oil');
    });

    test('Should scale simple vulgar fractions correctly', () {
      expect(IngredientScaleHelper.scaleIngredient('½ tsp salt', 3.0), '1 1/2 tsp salt');
      expect(IngredientScaleHelper.scaleIngredient('¼ cup sugar', 2.0), '1/2 cup sugar');
      expect(IngredientScaleHelper.scaleIngredient('¾ cup milk', 2.0), '1 1/2 cup milk');
    });

    test('Should scale mixed vulgar fractions correctly', () {
      expect(IngredientScaleHelper.scaleIngredient('1 ½ tsp salt', 2.0), '3 tsp salt');
      expect(IngredientScaleHelper.scaleIngredient('2 ¾ cup milk', 2.0), '5 1/2 cup milk');
    });

    test('Should scale simple fractions correctly', () {
      expect(IngredientScaleHelper.scaleIngredient('1/2 cup sugar', 2.0), '1 cup sugar');
      expect(IngredientScaleHelper.scaleIngredient('1/3 tsp salt', 2.0), '2/3 tsp salt');
      expect(IngredientScaleHelper.scaleIngredient('1/4 cup water', 3.0), '3/4 cup water');
    });

    test('Should scale mixed fractions correctly', () {
      expect(IngredientScaleHelper.scaleIngredient('1 1/2 cups flour', 2.0), '3 cups flour');
      expect(IngredientScaleHelper.scaleIngredient('1-1/2 cups flour', 2.0), '3 cups flour');
      expect(IngredientScaleHelper.scaleIngredient('2 1/4 cups sugar', 2.0), '4 1/2 cups sugar');
    });

    test('Should scale integer/decimal ranges correctly', () {
      expect(IngredientScaleHelper.scaleIngredient('1-2 tsp salt', 2.0), '2-4 tsp salt');
      expect(IngredientScaleHelper.scaleIngredient('1.5 to 2.5 cups flour', 2.0), '3 to 5 cups flour');
      expect(IngredientScaleHelper.scaleIngredient('1 - 3 cloves garlic', 2.0), '2 - 6 cloves garlic');
    });

    test('Should leave qualitative / text-only ingredients intact', () {
      expect(IngredientScaleHelper.scaleIngredient('Salt to taste', 2.0), 'Salt to taste');
      expect(IngredientScaleHelper.scaleIngredient('Fresh coriander leaves for garnish', 1.5), 'Fresh coriander leaves for garnish');
    });
  });
}
