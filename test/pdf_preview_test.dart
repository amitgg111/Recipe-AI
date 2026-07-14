// Dev-only visual check: renders the real RecipePdfService to a file so the
// layout can be inspected (qlmanage). Not a behavioural assertion.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Model/nutrition_model.dart';
import 'package:recipe_ai/Model/recipe_section_model.dart';
import 'package:recipe_ai/Service/recipe_pdf_service.dart';

void main() {
  test('render sample recipe PDF', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final imgPath = Platform.environment['PDF_IMG'];
    final imageBytes =
        imgPath != null && File(imgPath).existsSync() ? File(imgPath).readAsBytesSync() : null;

    final recipe = RecipeModel(
      id: 'sample',
      title: 'Creamy Tuscan Chicken Pasta',
      description:
          'A restaurant-style one-pan dinner — juicy chicken in a garlicky '
          'sun-dried tomato & spinach cream sauce tossed through al dente '
          'pasta. Ready in under an hour.',
      imageUrl: 'https://example.com/x.jpg',
      sourceUrl: 'https://www.myfoodstory.com/creamy-tuscan-chicken-pasta',
      prepTime: '15 min',
      cookTime: '30 min',
      totalTime: '45 min',
      servings: '4',
      category: 'Main Course',
      cuisine: 'Italian',
      keywords: const ['pasta', 'chicken'],
      ingredients: const [
        '2 chicken breasts, sliced',
        '250 g penne pasta',
        '1 cup baby spinach',
        '½ cup sun-dried tomatoes',
        '1 cup heavy cream',
        '3 cloves garlic, minced',
        '½ cup grated parmesan',
        '2 tablespoons olive oil',
        '1 teaspoon Italian seasoning',
        'salt & pepper to taste',
      ],
      instructions: const [
        'Season the sliced chicken with salt, pepper and Italian seasoning.',
        'Heat olive oil in a large pan and sear the chicken until golden on both sides, then set aside.',
        'In the same pan, sauté the garlic and sun-dried tomatoes for 1 minute until fragrant.',
        'Pour in the heavy cream and bring to a gentle simmer, scraping up any browned bits.',
        'Stir in the parmesan until the sauce thickens, then fold through the spinach until wilted.',
        'Return the chicken to the pan and toss the cooked pasta through the sauce. Serve hot with extra parmesan.',
      ],
      ingredientSections: const [],
      instructionSections: const [],
    );

    const nutrition = NutritionModel(
      caloriesPerServing: 642,
      protein: 38,
      carbs: 54,
      fat: 28,
      fiber: 4,
      sugar: 6,
      sodium: 720,
      cholesterol: 120,
      saturatedFat: 12,
      servings: 4,
      ingredientsNutrition: [],
    );

    final bytes = await RecipePdfService.build(
      recipe,
      nutrition: nutrition,
      note:
          'Add a pinch of chilli flakes for heat. Leftovers keep in an airtight '
          'container in the fridge for up to 2 days — loosen with a splash of milk when reheating.',
      imageBytes: imageBytes,
    );

    final out = File(Platform.environment['PDF_OUT'] ?? 'build/sample_recipe.pdf');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(bytes);
    // ignore: avoid_print
    print('WROTE ${out.path} (${bytes.length} bytes)');
    expect(bytes.length, greaterThan(1000));
  });

  test('render compact grouped recipe PDF', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final recipe = RecipeModel(
      id: 'compact',
      title: 'Two-Layer Chocolate Cake',
      description: null,
      imageUrl: null,
      sourceUrl: '',
      prepTime: '20 min',
      cookTime: '35 min',
      totalTime: '55 min',
      servings: '8',
      category: 'Dessert',
      cuisine: null,
      keywords: const [],
      ingredients: const [],
      instructions: const [],
      ingredientSections: const [
        IngredientSection(name: 'For the sponge', items: [
          '2 cups all-purpose flour',
          '1¾ cups sugar',
          '¾ cup cocoa powder',
        ]),
      ],
      instructionSections: const [
        InstructionSection(name: 'Bake & frost', steps: [
          'Preheat the oven to 180°C and line two round tins.',
          'Whisk the dry ingredients, then beat in the eggs and milk until smooth, and bake for 35 minutes.',
          'Beat the butter, icing sugar and cocoa into a fluffy frosting, then sandwich and cover the cooled sponges.',
        ]),
      ],
    );

    final bytes = await RecipePdfService.build(
      recipe,
      note:
          'For a richer cake, replace ¼ cup of the milk with strong brewed coffee.',
    );
    final out = File(
        Platform.environment['PDF_OUT2'] ?? 'build/sample_recipe2.pdf');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(bytes);
    // ignore: avoid_print
    print('WROTE ${out.path} (${bytes.length} bytes)');
    expect(bytes.length, greaterThan(1000));
  });
}
