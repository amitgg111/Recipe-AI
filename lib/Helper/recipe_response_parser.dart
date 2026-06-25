import 'package:recipe_ai/Model/recipe_section_model.dart';

/// Normalizes recipe JSON from Gemini API or Firestore into consistent fields.
class RecipeResponseParser {
  RecipeResponseParser._();

  // ── Title ─────────────────────────────────────────────────────────────────

  static String parseTitle(Map<String, dynamic> json) {
    for (final key in ['title', 'recipeName', 'name', 'recipe_title']) {
      final value = _cleanString(json[key]);
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  // ── Flat strings ──────────────────────────────────────────────────────────

  static String? parseOptionalString(dynamic value) => _cleanString(value);

  static int parseServings(dynamic value) {
    if (value == null) return 4;
    final text = value.toString().trim();
    final match = RegExp(r'\d+').firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 4;
    }
    return 4;
  }

  static List<String> parseKeywords(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  // ── Ingredients ───────────────────────────────────────────────────────────

  static String parseIngredientItem(dynamic item) {
    if (item == null) return '';
    if (item is String) return _cleanIngredientString(item);
    if (item is Map) {
      final map = Map<String, dynamic>.from(item);
      final qty = _cleanString(map['quantity'] ?? map['amount'] ?? map['qty']);
      final unit = _cleanString(map['unit']);
      final name = _cleanString(
        map['name'] ?? map['ingredient'] ?? map['item'] ?? map['text'],
      );
      final parts = <String>[];
      if (qty != null && qty.isNotEmpty) parts.add(qty);
      if (unit != null && unit.isNotEmpty) parts.add(unit);
      if (name != null && name.isNotEmpty) parts.add(name);
      if (parts.isNotEmpty) return parts.join(' ');
      return _cleanIngredientString(map.values.map((e) => e.toString()).join(' '));
    }
    return _cleanIngredientString(item.toString());
  }

  static List<String> parseFlatIngredients(dynamic raw) {
    if (raw == null) return [];
    if (raw is! List) return [];
    return raw
        .map(parseIngredientItem)
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static List<IngredientSection> parseIngredientSections(
    Map<String, dynamic> json,
  ) {
    final rawSections = json['ingredientSections'];
    if (rawSections is List && rawSections.isNotEmpty) {
      final sections = rawSections
          .whereType<Map>()
          .map((s) {
            final map = Map<String, dynamic>.from(s);
            final name = _cleanString(map['name'] ?? map['title'] ?? map['heading']);
            final items = _parseSectionItems(map['items'] ?? map['ingredients']);
            return IngredientSection(
              name: (name != null && name.isNotEmpty) ? name : null,
              items: items,
            );
          })
          .where((s) => s.items.isNotEmpty)
          .toList();
      if (sections.isNotEmpty) return sections;
    }

    final flat = parseFlatIngredients(json['ingredients']);
    if (flat.isEmpty) return [];

    final detected = _detectIngredientSections(flat);
    return detected.isNotEmpty ? detected : [IngredientSection(items: flat)];
  }

  // ── Instructions ──────────────────────────────────────────────────────────

  static String parseInstructionStep(dynamic item) {
    if (item == null) return '';
    if (item is String) return _cleanInstructionString(item);
    if (item is Map) {
      final map = Map<String, dynamic>.from(item);
      final text = _cleanString(map['text'] ?? map['step'] ?? map['instruction'] ?? map['name']);
      if (text != null && text.isNotEmpty) return _cleanInstructionString(text);
    }
    return _cleanInstructionString(item.toString());
  }

  static List<String> parseFlatInstructions(dynamic raw) {
    if (raw == null) return [];
    if (raw is String) {
      return _splitInstructionText(raw);
    }
    if (raw is! List) return [];
    return raw
        .expand((item) {
          if (item is String && item.contains('\n')) {
            return _splitInstructionText(item);
          }
          final step = parseInstructionStep(item);
          return step.isNotEmpty ? [step] : <String>[];
        })
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static List<InstructionSection> parseInstructionSections(
    Map<String, dynamic> json,
  ) {
    final rawSections = json['instructionSections'];
    if (rawSections is List && rawSections.isNotEmpty) {
      final sections = rawSections
          .whereType<Map>()
          .map((s) {
            final map = Map<String, dynamic>.from(s);
            final name = _cleanString(map['name'] ?? map['title'] ?? map['heading']);
            final steps = _parseSectionSteps(map['steps'] ?? map['instructions']);
            return InstructionSection(
              name: (name != null && name.isNotEmpty) ? name : null,
              steps: steps,
            );
          })
          .where((s) => s.steps.isNotEmpty)
          .toList();
      if (sections.isNotEmpty) return sections;
    }

    final flat = parseFlatInstructions(json['instructions']);
    if (flat.isEmpty) return [];

    final detected = _detectInstructionSections(flat);
    return detected.isNotEmpty ? detected : [InstructionSection(steps: flat)];
  }

  /// Full parse result used by both SavedRecipe and RecipeModel.
  static ParsedRecipeData parse(Map<String, dynamic> json) {
    final ingredientSections = parseIngredientSections(json);
    final instructionSections = parseInstructionSections(json);

    final ingredients = ingredientSections.isNotEmpty
        ? ingredientSections.expand((s) => s.items).toList()
        : parseFlatIngredients(json['ingredients']);

    final instructions = instructionSections.isNotEmpty
        ? instructionSections.expand((s) => s.steps).toList()
        : parseFlatInstructions(json['instructions']);

    return ParsedRecipeData(
      title: parseTitle(json),
      description: parseOptionalString(json['description']),
      prepTime: parseOptionalString(json['prepTime']),
      cookTime: parseOptionalString(json['cookTime']),
      totalTime: parseOptionalString(json['totalTime']),
      servings: parseServings(json['servings']),
      category: parseOptionalString(json['category']),
      cuisine: parseOptionalString(json['cuisine']),
      keywords: parseKeywords(json['keywords']),
      ingredients: ingredients,
      instructions: instructions,
      ingredientSections: ingredientSections.isNotEmpty
          ? ingredientSections
          : (ingredients.isEmpty
                ? <IngredientSection>[]
                : [IngredientSection(items: ingredients)]),
      instructionSections: instructionSections.isNotEmpty
          ? instructionSections
          : (instructions.isEmpty
                ? <InstructionSection>[]
                : [InstructionSection(steps: instructions)]),
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static List<String> _parseSectionItems(dynamic raw) {
    if (raw is! List) return [];
    return raw.map(parseIngredientItem).where((s) => s.isNotEmpty).toList();
  }

  static List<String> _parseSectionSteps(dynamic raw) {
    if (raw is String) return _splitInstructionText(raw);
    if (raw is! List) return [];
    return raw
        .expand((item) {
          if (item is String && item.contains('\n')) {
            return _splitInstructionText(item);
          }
          final step = parseInstructionStep(item);
          return step.isNotEmpty ? [step] : <String>[];
        })
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static List<IngredientSection> _detectIngredientSections(List<String> flatList) {
    if (flatList.isEmpty) return [];

    final sections = <IngredientSection>[];
    String? currentName;
    final currentItems = <String>[];

    void flush() {
      if (currentItems.isEmpty) return;
      sections.add(
        IngredientSection(
          name: currentName,
          items: List<String>.from(currentItems),
        ),
      );
      currentItems.clear();
    }

    for (final item in flatList) {
      if (_isSectionHeader(item)) {
        flush();
        currentName = item.endsWith(':')
            ? item.substring(0, item.length - 1).trim()
            : item.trim();
      } else {
        currentItems.add(item);
      }
    }
    flush();

    return sections.length > 1 ||
            (sections.length == 1 && sections.first.name != null)
        ? sections
        : [];
  }

  static List<InstructionSection> _detectInstructionSections(
    List<String> flatList,
  ) {
    if (flatList.isEmpty) return [];

    final sections = <InstructionSection>[];
    String? currentName;
    final currentSteps = <String>[];

    void flush() {
      if (currentSteps.isEmpty) return;
      sections.add(
        InstructionSection(
          name: currentName,
          steps: List<String>.from(currentSteps),
        ),
      );
      currentSteps.clear();
    }

    for (final step in flatList) {
      if (_isSectionHeader(step)) {
        flush();
        currentName = step.endsWith(':')
            ? step.substring(0, step.length - 1).trim()
            : step.trim();
      } else {
        currentSteps.add(step);
      }
    }
    flush();

    return sections.length > 1 ||
            (sections.length == 1 && sections.first.name != null)
        ? sections
        : [];
  }

  static bool _isSectionHeader(String text) {
    final t = text.trim();
    if (t.isEmpty) return false;

    // "For Manchurian Balls:" / "For the sauce:"
    if (RegExp(r'^for\b', caseSensitive: false).hasMatch(t) &&
        (t.endsWith(':') || t.split(' ').length <= 6)) {
      return !RegExp(r'\d').hasMatch(t);
    }

    if (t.endsWith(':') && t.length <= 80 && !RegExp(r'\d').hasMatch(t)) {
      return true;
    }

    if (t == t.toUpperCase() && t.length <= 50 && !RegExp(r'\d').hasMatch(t)) {
      return true;
    }

    return false;
  }

  static String? _cleanString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String _cleanIngredientString(String raw) {
    return raw
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
        .replaceAll(RegExp(r'^\s*[-•*]\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _cleanInstructionString(String raw) {
    var step = raw
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')
        .trim();
    step = step.replaceFirst(
      RegExp(
        r'^(step\s*\d+[:\.]?\s*|\d+[\.):]\s*|[-•*]\s*)',
        caseSensitive: false,
      ),
      '',
    );
    return step.trim();
  }

  static List<String> _splitInstructionText(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .map(_cleanInstructionString)
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

class ParsedRecipeData {
  final String title;
  final String? description;
  final String? prepTime;
  final String? cookTime;
  final String? totalTime;
  final int servings;
  final String? category;
  final String? cuisine;
  final List<String> keywords;
  final List<String> ingredients;
  final List<String> instructions;
  final List<IngredientSection> ingredientSections;
  final List<InstructionSection> instructionSections;

  const ParsedRecipeData({
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
  });
}
