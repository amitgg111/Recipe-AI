import 'package:recipe_ai/Model/recipe_section_model.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';

/// Everything a recipe screen needs to SHOW — already resolved to the right
/// language for the person looking at it. Never write this back to
/// Firestore; it's a display-only projection.
class LocalizedRecipe {
  final String title;
  final String? description;
  final String? prepTime;
  final String? cookTime;
  final String? totalTime;
  final String? servings;
  final String? category;
  final String? cuisine;
  final List<String> keywords;
  final List<String> ingredients;
  final List<String> instructions;
  final List<IngredientSection> ingredientSections;
  final List<InstructionSection> instructionSections;

  /// True when this is the OWNER's own original-language text (no
  /// translation applied) rather than the English copy translated into the
  /// viewer's selected app language.
  final bool isOriginalLanguage;

  LocalizedRecipe({
    required this.title,
    required this.description,
    required this.prepTime,
    required this.cookTime,
    required this.totalTime,
    required this.servings,
    required this.category,
    required this.cuisine,
    required this.keywords,
    required this.ingredients,
    required this.instructions,
    required this.ingredientSections,
    required this.instructionSections,
    required this.isOriginalLanguage,
  });
}

/// Resolves what to display for a recipe stored the way
/// `ImportWebController.saveRecipe` / `RecipeEditorController.saveRecipe`
/// write it: a canonical ENGLISH copy at the top level, plus an
/// `originalLanguageCode` + `original` snapshot capturing the text exactly
/// as the owner entered/imported it.
///
/// Rule:
/// - The recipe's OWNER sees the `original` snapshot as-is — Gujarati stays
///   Gujarati, no translation call, no delay.
/// - Anyone else sees the canonical English fields translated into THEIR own
///   currently selected app language via the existing on-device
///   [AiTranslationService] (which already no-ops when that language is
///   English, and serves from its cache when available).
///
/// Usage (in a recipe detail / list screen):
/// ```dart
/// final data = docSnapshot.data()!;
/// final localized = await RecipeLocalizer.resolve(
///   data,
///   currentUid: AuthService.currentUser?.uid,
/// );
/// // localized.title, localized.ingredients, etc. — display these, not
/// // data['title'] / data['ingredients'] directly.
/// ```
class RecipeLocalizer {
  RecipeLocalizer._();

  static Future<LocalizedRecipe> resolve(
    Map<String, dynamic> data, {
    required String? currentUid,
  }) async {
    final ownerId = data['ownerId'] as String?;
    final isOwner = currentUid != null && currentUid == ownerId;

    final originalLanguageCode = data['originalLanguageCode'] as String?;
    final original = data['original'] as Map<String, dynamic>?;

    final hasUsableOriginal =
        original != null &&
        originalLanguageCode != null &&
        originalLanguageCode != 'en' &&
        originalLanguageCode != 'und';

    if (isOwner && hasUsableOriginal) {
      return LocalizedRecipe(
        title: _str(original['title']) ?? _str(data['title']) ?? '',
        description: _str(original['description']),
        prepTime: _str(original['prepTime']),
        cookTime: _str(original['cookTime']),
        totalTime: _str(original['totalTime']),
        servings: _str(original['servings']),
        category: _str(original['category']),
        cuisine: _str(original['cuisine']),
        keywords: _strList(original['keywords']),
        ingredients: _strList(original['ingredients']),
        instructions: _strList(original['instructions']),
        ingredientSections: _ingredientSectionsFrom(
          original['ingredientSections'],
        ),
        instructionSections: _instructionSectionsFrom(
          original['instructionSections'],
        ),
        isOriginalLanguage: true,
      );
    }

    // Non-owner (or owner viewing an already-English recipe): translate the
    // canonical English copy into the viewer's currently selected app
    // language. AiTranslationService.translate/translateList already no-op
    // when that language IS English and serve from cache when available.
    final title = await AiTranslationService.translate(_str(data['title']));
    final description = await AiTranslationService.translate(
      _str(data['description']),
    );
    final prepTime = await AiTranslationService.translate(
      _str(data['prepTime']),
    );
    final cookTime = await AiTranslationService.translate(
      _str(data['cookTime']),
    );
    final totalTime = await AiTranslationService.translate(
      _str(data['totalTime']),
    );
    final servings = await AiTranslationService.translate(
      _str(data['servings']),
    );
    final category = await AiTranslationService.translate(
      _str(data['category']),
    );
    final cuisine = await AiTranslationService.translate(_str(data['cuisine']));

    final keywords = await AiTranslationService.translateList(
      _strList(data['keywords']),
    );
    final ingredients = await AiTranslationService.translateList(
      _strList(data['ingredients']),
    );
    final instructions = await AiTranslationService.translateList(
      _strList(data['instructions']),
    );

    final ingredientSections = await _translateIngredientSections(
      _ingredientSectionsFrom(data['ingredientSections']),
    );
    final instructionSections = await _translateInstructionSections(
      _instructionSectionsFrom(data['instructionSections']),
    );

    return LocalizedRecipe(
      title: title.isEmpty ? (_str(data['title']) ?? '') : title,
      description: description.isEmpty ? null : description,
      prepTime: prepTime.isEmpty ? null : prepTime,
      cookTime: cookTime.isEmpty ? null : cookTime,
      totalTime: totalTime.isEmpty ? null : totalTime,
      servings: servings.isEmpty ? null : servings,
      category: category.isEmpty ? null : category,
      cuisine: cuisine.isEmpty ? null : cuisine,
      keywords: keywords,
      ingredients: ingredients,
      instructions: instructions,
      ingredientSections: ingredientSections,
      instructionSections: instructionSections,
      isOriginalLanguage: false,
    );
  }

  // ── Section (de)serialization ─────────────────────────────────────────────
  // Mirrors the shape IngredientSection.toMap() / InstructionSection.toMap()
  // write: {'name': String?, 'items'|'steps': List<String>}.

  static List<IngredientSection> _ingredientSectionsFrom(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (m) => IngredientSection(
            name: _str(m['name']),
            items: _strList(m['items']),
          ),
        )
        .toList();
  }

  static List<InstructionSection> _instructionSectionsFrom(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (m) => InstructionSection(
            name: _str(m['name']),
            steps: _strList(m['steps']),
          ),
        )
        .toList();
  }

  static Future<List<IngredientSection>> _translateIngredientSections(
    List<IngredientSection> sections,
  ) async {
    final result = <IngredientSection>[];
    for (final section in sections) {
      final name = section.name == null || section.name!.isEmpty
          ? section.name
          : await AiTranslationService.translate(section.name);
      final items = await AiTranslationService.translateList(section.items);
      result.add(IngredientSection(name: name, items: items));
    }
    return result;
  }

  static Future<List<InstructionSection>> _translateInstructionSections(
    List<InstructionSection> sections,
  ) async {
    final result = <InstructionSection>[];
    for (final section in sections) {
      final name = section.name == null || section.name!.isEmpty
          ? section.name
          : await AiTranslationService.translate(section.name);
      final steps = await AiTranslationService.translateList(section.steps);
      result.add(InstructionSection(name: name, steps: steps));
    }
    return result;
  }

  // ── Misc helpers ───────────────────────────────────────────────────────────

  static String? _str(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  static List<String> _strList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
