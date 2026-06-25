import 'package:recipe_ai/Helper/recipe_response_parser.dart';

class RecipeIngredientSection {
  final String? name;
  final List<String> items;

  RecipeIngredientSection({this.name, required this.items});
}

class RecipeInstructionSection {
  final String? name;
  final List<String> steps;

  RecipeInstructionSection({this.name, required this.steps});
}

class SavedRecipe {
  final String title;
  final String description;

  final String? imageUrl;
  final String? sourceUrl;

  final String prepTime;
  final String cookTime;
  final String totalTime;

  final String category;
  final String cuisine;

  final List<String> keywords;

  final int servings;

  final List<String> ingredients;
  final List<String> instructions;

  final List<RecipeIngredientSection> ingredientSections;
  final List<RecipeInstructionSection> instructionSections;

  final Map<String, dynamic>? nutrition;

  final DateTime savedAt;

  SavedRecipe({
    required this.title,
    required this.description,
    this.imageUrl,
    this.sourceUrl,
    required this.prepTime,
    required this.cookTime,
    required this.totalTime,
    required this.category,
    required this.cuisine,
    required this.keywords,
    required this.servings,
    required this.ingredients,
    required this.instructions,
    required this.ingredientSections,
    required this.instructionSections,
    this.nutrition,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  factory SavedRecipe.fromGeminiResponse(Map<String, dynamic> json) {
    final parsed = RecipeResponseParser.parse(json);

    return SavedRecipe(
      title: parsed.title.isNotEmpty ? parsed.title : 'Untitled Recipe',
      description: parsed.description ?? '',

      imageUrl: json['imageUrl']?.toString(),
      sourceUrl: json['sourceUrl']?.toString(),

      prepTime: parsed.prepTime ?? '',
      cookTime: parsed.cookTime ?? '',
      totalTime: parsed.totalTime ?? '',

      category: parsed.category ?? '',
      cuisine: parsed.cuisine ?? '',

      keywords: parsed.keywords,

      servings: parsed.servings,

      ingredients: parsed.ingredients,
      instructions: parsed.instructions,

      ingredientSections: parsed.ingredientSections
          .map((e) => RecipeIngredientSection(name: e.name, items: e.items))
          .toList(),

      instructionSections: parsed.instructionSections
          .map((e) => RecipeInstructionSection(name: e.name, steps: e.steps))
          .toList(),

      nutrition: json['nutrition'] != null
          ? Map<String, dynamic>.from(json['nutrition'])
          : null,
    );
  }
}
