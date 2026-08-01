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
  /// The ENGLISH canonical `totalTime` exactly as Firestore stores it,
  /// regardless of which branch produced this projection.
  ///
  /// The editor derives a NUMBER and a hours/minutes UNIT from the total time,
  /// and both parsers are English-only (`RegExp(r'\d+')`, `contains('hour')`).
  /// Running them on the display string means Hindi "2 घंटे" yields unit
  /// 'minutes' — a 2-hour recipe saves as 2 minutes. Parse from this instead.
  final String? enTotalTime;

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
    required this.enTotalTime,
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
        enTotalTime: _str(data['totalTime']),
        isOriginalLanguage: true,
      );
    }

    // Non-owner (or owner viewing an already-English recipe): translate the
    // canonical English copy into the viewer's currently selected app
    // language. AiTranslationService.translate/translateList already no-op
    // when that language IS English and serve from cache when available.
    // ONE batched pass over every string this recipe needs.
    //
    // This used to be eight sequential `await translate()` calls followed by
    // three `translateList()` calls and two more for the sections — thirteen
    // round trips in series, each cache miss also rewriting the whole cache
    // blob to disk. On a cold cache that is the second or two the user sees
    // before a screen finally settles. Collected up front and translated in a
    // single batch, it is one round trip; afterwards every lookup below is a
    // synchronous cache read.
    const scalarKeys = [
      'title',
      'description',
      'prepTime',
      'cookTime',
      'totalTime',
      'servings',
      'category',
      'cuisine',
    ];
    const listKeys = ['keywords', 'ingredients', 'instructions'];

    final ingredientSectionsEn = _ingredientSectionsFrom(
      data['ingredientSections'],
    );
    final instructionSectionsEn = _instructionSectionsFrom(
      data['instructionSections'],
    );

    final pending = <String>[];
    for (final k in scalarKeys) {
      final v = _str(data[k]);
      if (v != null && v.trim().isNotEmpty) pending.add(v);
    }
    for (final k in listKeys) {
      pending.addAll(_strList(data[k]));
    }
    for (final s in ingredientSectionsEn) {
      if (s.name != null && s.name!.trim().isNotEmpty) pending.add(s.name!);
      pending.addAll(s.items);
    }
    for (final s in instructionSectionsEn) {
      if (s.name != null && s.name!.trim().isNotEmpty) pending.add(s.name!);
      pending.addAll(s.steps);
    }

    // Warms the cache for everything at once; translateList de-duplicates.
    await AiTranslationService.translateList(pending);

    // Now every read is a synchronous cache lookup.
    String tr(String? s) => AiTranslationService.cachedOrSelf(s);
    List<String> trList(List<String> xs) =>
        xs.map(AiTranslationService.cachedOrSelf).toList();

    final title = tr(_str(data['title']));
    final description = tr(_str(data['description']));
    final prepTime = tr(_str(data['prepTime']));
    final cookTime = tr(_str(data['cookTime']));
    final totalTime = tr(_str(data['totalTime']));
    final servings = tr(_str(data['servings']));
    final category = tr(_str(data['category']));
    final cuisine = tr(_str(data['cuisine']));

    final keywords = trList(_strList(data['keywords']));
    final ingredients = trList(_strList(data['ingredients']));
    final instructions = trList(_strList(data['instructions']));

    final ingredientSections = ingredientSectionsEn
        .map(
          (s) => IngredientSection(
            name: s.name == null ? null : tr(s.name),
            items: trList(s.items),
          ),
        )
        .toList();
    final instructionSections = instructionSectionsEn
        .map(
          (s) => InstructionSection(
            name: s.name == null ? null : tr(s.name),
            steps: trList(s.steps),
          ),
        )
        .toList();

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
      enTotalTime: _str(data['totalTime']),
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
