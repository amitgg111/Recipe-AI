import 'dart:convert';
import 'package:get/get.dart';

import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
import 'package:recipe_ai/Model/recipe_section_model.dart';
import 'package:recipe_ai/Helper/ingredient_scale_helper.dart';
import 'package:recipe_ai/Service/import_with_image_api_calling_service.dart';

enum AiMsgRole { user, assistant }

/// One AI-suggested ingredient substitution.
class SwapOption {
  final String replacement; // full ingredient line incl. quantity
  final String note; // short "why"
  final bool vegan;
  const SwapOption(
      {required this.replacement, required this.note, this.vegan = false});
}

/// One row in the scaled-ingredients card (name · old qty → new qty).
class ScaleRow {
  final String name;
  final String oldQ;
  final String newQ;
  const ScaleRow(this.name, this.oldQ, this.newQ);
}

/// Deterministic scale result for a recipe → target servings.
class ScalePreview {
  final int fromServings;
  final int toServings;
  final List<ScaleRow> rows; // changed lines only (for the card)
  final List<String> newIngredients;
  final List<IngredientSection> newSections;
  const ScalePreview({
    required this.fromServings,
    required this.toServings,
    required this.rows,
    required this.newIngredients,
    required this.newSections,
  });
}

/// One active ingredient swap on a recipe. Drives the inline "SWAPPED" tag +
/// per-ingredient Undo shown directly on the swapped row in the ingredient list.
class SwapEntry {
  final String recipeId;
  final String oldLine; // original full line ("1 can coconut milk")
  final String newLine; // swapped-in full line ("1 cup heavy cream")
  final String oldName; // plain name of the original ("coconut milk")
  final String newName; // plain name of the replacement ("heavy cream")
  const SwapEntry({
    required this.recipeId,
    required this.oldLine,
    required this.newLine,
    required this.oldName,
    required this.newName,
  });
}

/// The last applied AI change for a recipe — drives the "AI swapped …/Scaled …"
/// banner + Undo on the recipe detail. Holds the pre-change snapshot for undo.
class AiChange {
  final String recipeId;
  final bool isSwap; // false → scale
  final String summary; // "coconut milk → heavy cream" / "2 → 4 servings"
  final List<String> origIngredients;
  final List<String> origInstructions;
  final List<IngredientSection> origSections;
  final List<InstructionSection> origInstructionSections;
  final String? origServings;
  const AiChange({
    required this.recipeId,
    required this.isSwap,
    required this.summary,
    required this.origIngredients,
    required this.origInstructions,
    required this.origSections,
    required this.origInstructionSections,
    required this.origServings,
  });
}

/// Backs the AI Cooking Assistant: AI-powered ingredient swaps, deterministic
/// serving scaling, and applying/undoing those to the recipe (with cascade to
/// the grocery list and instructions).
class AiAssistantController extends GetxController {
  static AiAssistantController get to =>
      Get.isRegistered<AiAssistantController>()
          ? Get.find<AiAssistantController>()
          : Get.put(AiAssistantController(), permanent: true);

  /// Last applied change, per recipe. Reactive so the detail banner updates.
  /// Used for the top scale banner (swaps use the inline per-row tag instead).
  final Rxn<AiChange> lastChange = Rxn<AiChange>();

  AiChange? changeFor(String recipeId) =>
      lastChange.value?.recipeId == recipeId ? lastChange.value : null;

  /// Active ingredient swaps (per recipe). Reactive so the ingredient list
  /// redraws the "SWAPPED" tag + inline Undo the moment a swap is applied/undone.
  final RxList<SwapEntry> swaps = <SwapEntry>[].obs;

  List<SwapEntry> swapsFor(String recipeId) =>
      swaps.where((e) => e.recipeId == recipeId).toList();

  /// The swap that produced [rawLine] (matched by exact line or ingredient
  /// name), so the detail row can show its "was …" original + Undo. null → none.
  SwapEntry? activeSwapForLine(String recipeId, String rawLine) {
    final name = nameOf(rawLine).toLowerCase();
    for (final e in swaps) {
      if (e.recipeId != recipeId) continue;
      if (e.newLine == rawLine) return e;
      if (e.newName.toLowerCase() == name) return e;
    }
    return null;
  }

  HomeController get _home => Get.find<HomeController>();

  // ── Ingredient helpers ──────────────────────────────────────────────────────

  /// All ingredient lines (sections take priority over the flat list).
  List<String> ingredientLinesOf(RecipeModel r) {
    if (r.ingredientSections.isNotEmpty) {
      return [for (final s in r.ingredientSections) ...s.items];
    }
    return r.ingredients;
  }

  int servingsOf(RecipeModel r) {
    final n = r.servingCount.round();
    return n < 1 ? 1 : n;
  }

  /// Strip a leading quantity + unit to get the plain ingredient name.
  String nameOf(String line) {
    var s = line.trim();
    s = s.replaceFirst(RegExp(r'^[\d¼½¾⅓⅔⅛⅜⅝⅞./\s-]+'), '');
    s = s.replaceFirst(
        RegExp(
            r'^(cups?|c|tbsps?|tbsp|tablespoons?|tsps?|tsp|teaspoons?|ml|milliliters?|l|liters?|litres?|g|grams?|gms?|kg|kilograms?|oz|ounces?|lb|lbs|pounds?|cans?|tins?|cloves?|slices?|pinch(?:es)?|sticks?|bunch(?:es)?|packs?|packets?|pkg|pieces?|sprigs?|dash(?:es)?|handful)\.?\s+',
            caseSensitive: false),
        '');
    s = s.replaceFirst(RegExp(r'^of\s+', caseSensitive: false), '');
    // Drop trailing prep notes after a comma ("chopped", "drained", …).
    final comma = s.indexOf(',');
    if (comma > 0) s = s.substring(0, comma);
    return s.trim();
  }

  /// The leading quantity part of [line] (everything scaleIngredient changes).
  String _qtyOf(String line, String scaled) {
    // Longest common suffix between original & scaled == the (unchanged) name.
    var i = 0;
    while (i < line.length &&
        i < scaled.length &&
        line[line.length - 1 - i] == scaled[scaled.length - 1 - i]) {
      i++;
    }
    return line.substring(0, line.length - i).trim();
  }

  // ── AI swaps ────────────────────────────────────────────────────────────────

  Future<List<SwapOption>> suggestSwaps(
      RecipeModel recipe, String ingredientLine) async {
    final prompt =
        'You are a helpful cooking assistant. The recipe is "${recipe.title}". '
        'A cook has run out of this ingredient: "$ingredientLine". '
        'Suggest exactly 2 practical substitutions that keep a similar result. '
        'Return ONLY minified JSON, no markdown, in exactly this shape: '
        '{"swaps":[{"replacement":"<a full ingredient line including a sensible quantity>",'
        '"note":"<short reason, max 5 words>","vegan":true or false}]}';
    final raw = await RecipeImportService.askGemini(prompt);
    return _parseSwaps(raw);
  }

  List<SwapOption> _parseSwaps(String raw) {
    try {
      var s = raw.trim();
      // Strip ```json fences / stray prose around the JSON object.
      final start = s.indexOf('{');
      final end = s.lastIndexOf('}');
      if (start >= 0 && end > start) s = s.substring(start, end + 1);
      final map = jsonDecode(s) as Map<String, dynamic>;
      final list = (map['swaps'] as List?) ?? const [];
      return [
        for (final e in list)
          SwapOption(
            replacement: (e['replacement'] ?? '').toString().trim(),
            note: (e['note'] ?? '').toString().trim(),
            vegan: e['vegan'] == true,
          ),
      ].where((o) => o.replacement.isNotEmpty).take(2).toList();
    } catch (_) {
      return const [];
    }
  }

  /// A free-form cooking question about the recipe (typed in the chat).
  Future<String> ask(RecipeModel recipe, String question) async {
    final ings = ingredientLinesOf(recipe).join('; ');
    final prompt =
        'You are a concise, friendly cooking assistant helping with the recipe '
        '"${recipe.title}". Ingredients: $ings. '
        'Answer this question in 1-3 short sentences: "$question"';
    return RecipeImportService.askGemini(prompt);
  }

  // ── Scale (deterministic) ────────────────────────────────────────────────────

  ScalePreview buildScalePreview(RecipeModel recipe, int target) {
    final from = servingsOf(recipe);
    final t = target < 1 ? 1 : target;
    final mult = from == 0 ? 1.0 : t / from;

    // Scale a list of lines (used for both the flat list and sections).
    List<String> scaleList(List<String> lines) => [
          for (final line in lines)
            line.trim().isEmpty
                ? line
                : IngredientScaleHelper.scaleIngredient(line, mult),
        ];

    final newIngredients = scaleList(recipe.ingredients);
    final newSections = [
      for (final s in recipe.ingredientSections)
        IngredientSection(name: s.name, items: scaleList(s.items)),
    ];

    // Rows for the card come from the canonical source only (sections if any,
    // else the flat list) so a recipe that stores both doesn't show doubles.
    final rows = <ScaleRow>[];
    for (final line in ingredientLinesOf(recipe)) {
      if (line.trim().isEmpty) continue;
      final scaled = IngredientScaleHelper.scaleIngredient(line, mult);
      if (scaled != line) {
        final oldQ = _qtyOf(line, scaled);
        final newQ = _qtyOf(scaled, line);
        if (oldQ.isNotEmpty || newQ.isNotEmpty) {
          rows.add(ScaleRow(nameOf(line), oldQ, newQ));
        }
      }
    }

    return ScalePreview(
      fromServings: from,
      toServings: t,
      rows: rows,
      newIngredients: newIngredients,
      newSections: newSections,
    );
  }

  Future<void> applyScale(RecipeModel recipe, ScalePreview p) async {
    _saveUndo(
      recipe,
      isSwap: false,
      summary: 'ai_scale_banner_summary'.trParams(
          {'from': '${p.fromServings}', 'to': '${p.toServings}'}),
    );
    await _home.updateRecipeContent(
      recipe.id,
      ingredients: p.newIngredients,
      ingredientSections: p.newSections,
      servings: '${p.toServings} servings',
    );
    _syncGroceries(recipe.id, _flat(p.newIngredients, p.newSections));
  }

  // ── Swap ────────────────────────────────────────────────────────────────────

  Future<void> applySwap(
      RecipeModel recipe, String oldLine, SwapOption chosen) async {
    final newLine = chosen.replacement;
    final oldName = nameOf(oldLine);
    final newName = nameOf(newLine);

    List<String> swapLines(List<String> lines) =>
        [for (final l in lines) l == oldLine ? newLine : l];

    final newIngredients = swapLines(recipe.ingredients);
    final newSections = [
      for (final s in recipe.ingredientSections)
        IngredientSection(name: s.name, items: swapLines(s.items)),
    ];

    // Instructions follow ingredients: swap the ingredient name where it
    // appears in the step text (case-insensitive).
    List<String> swapInSteps(List<String> steps) => [
          for (final step in steps)
            oldName.isEmpty
                ? step
                : step.replaceAll(
                    RegExp(RegExp.escape(oldName), caseSensitive: false),
                    newName),
        ];
    final newInstructions = swapInSteps(recipe.instructions);
    final newInstructionSections = [
      for (final s in recipe.instructionSections)
        InstructionSection(name: s.name, steps: swapInSteps(s.steps)),
    ];

    // Record the swap for the inline "SWAPPED" tag + per-row Undo. If this line
    // was itself a previous swap, keep pointing "was …" at the true original.
    SwapEntry? prior;
    for (final e in swaps) {
      if (e.recipeId == recipe.id && e.newLine == oldLine) {
        prior = e;
        break;
      }
    }
    swaps.removeWhere((e) => e.recipeId == recipe.id && e.newLine == oldLine);
    swaps.add(SwapEntry(
      recipeId: recipe.id,
      oldLine: prior?.oldLine ?? oldLine,
      newLine: newLine,
      oldName: prior?.oldName ?? oldName,
      newName: newName,
    ));

    await _home.updateRecipeContent(
      recipe.id,
      ingredients: newIngredients,
      ingredientSections: newSections,
      instructions: newInstructions,
      instructionSections: newInstructionSections,
    );
    _syncGroceries(recipe.id, _flat(newIngredients, newSections));
  }

  /// Undo a single ingredient swap: restore just that one line (and its name in
  /// the instructions), leaving any other swaps/scaling on the recipe intact.
  Future<void> undoSwap(RecipeModel recipe, SwapEntry e) async {
    bool byName(String l) => nameOf(l).toLowerCase() == e.newName.toLowerCase();
    List<String> revert(List<String> lines) =>
        [for (final l in lines) (l == e.newLine || byName(l)) ? e.oldLine : l];

    final newIngredients = revert(recipe.ingredients);
    final newSections = [
      for (final s in recipe.ingredientSections)
        IngredientSection(name: s.name, items: revert(s.items)),
    ];

    List<String> revertSteps(List<String> steps) => [
          for (final step in steps)
            e.newName.isEmpty
                ? step
                : step.replaceAll(
                    RegExp(RegExp.escape(e.newName), caseSensitive: false),
                    e.oldName),
        ];
    final newInstructions = revertSteps(recipe.instructions);
    final newInstructionSections = [
      for (final s in recipe.instructionSections)
        InstructionSection(name: s.name, steps: revertSteps(s.steps)),
    ];

    swaps.remove(e);

    await _home.updateRecipeContent(
      recipe.id,
      ingredients: newIngredients,
      ingredientSections: newSections,
      instructions: newInstructions,
      instructionSections: newInstructionSections,
    );
    _syncGroceries(recipe.id, _flat(newIngredients, newSections));
  }

  /// Undo every active swap on the recipe at once (top-banner "Undo").
  Future<void> undoAllSwaps(RecipeModel recipe) async {
    final list = swapsFor(recipe.id);
    if (list.isEmpty) return;

    List<String> revertAll(List<String> lines) {
      var out = List<String>.from(lines);
      for (final e in list) {
        out = [
          for (final l in out)
            (l == e.newLine ||
                    nameOf(l).toLowerCase() == e.newName.toLowerCase())
                ? e.oldLine
                : l,
        ];
      }
      return out;
    }

    List<String> revertAllSteps(List<String> steps) {
      var out = List<String>.from(steps);
      for (final e in list) {
        if (e.newName.isEmpty) continue;
        out = [
          for (final s in out)
            s.replaceAll(
                RegExp(RegExp.escape(e.newName), caseSensitive: false),
                e.oldName),
        ];
      }
      return out;
    }

    final newIngredients = revertAll(recipe.ingredients);
    final newSections = [
      for (final s in recipe.ingredientSections)
        IngredientSection(name: s.name, items: revertAll(s.items)),
    ];
    final newInstructions = revertAllSteps(recipe.instructions);
    final newInstructionSections = [
      for (final s in recipe.instructionSections)
        InstructionSection(name: s.name, steps: revertAllSteps(s.steps)),
    ];

    swaps.removeWhere((e) => e.recipeId == recipe.id);

    await _home.updateRecipeContent(
      recipe.id,
      ingredients: newIngredients,
      ingredientSections: newSections,
      instructions: newInstructions,
      instructionSections: newInstructionSections,
    );
    _syncGroceries(recipe.id, _flat(newIngredients, newSections));
  }

  // ── Undo ─────────────────────────────────────────────────────────────────────

  Future<void> undo() async {
    final c = lastChange.value;
    if (c == null) return;
    await _home.updateRecipeContent(
      c.recipeId,
      ingredients: c.origIngredients,
      ingredientSections: c.origSections,
      instructions: c.origInstructions,
      instructionSections: c.origInstructionSections,
      servings: c.origServings,
    );
    _syncGroceries(c.recipeId, _flat(c.origIngredients, c.origSections));
    lastChange.value = null;
  }

  void dismissBanner(String recipeId) {
    if (lastChange.value?.recipeId == recipeId) lastChange.value = null;
  }

  // ── internals ────────────────────────────────────────────────────────────────

  void _saveUndo(RecipeModel r,
      {required bool isSwap, required String summary}) {
    lastChange.value = AiChange(
      recipeId: r.id,
      isSwap: isSwap,
      summary: summary,
      origIngredients: List<String>.from(r.ingredients),
      origInstructions: List<String>.from(r.instructions),
      origSections: [
        for (final s in r.ingredientSections)
          IngredientSection(name: s.name, items: List<String>.from(s.items)),
      ],
      origInstructionSections: [
        for (final s in r.instructionSections)
          InstructionSection(name: s.name, steps: List<String>.from(s.steps)),
      ],
      origServings: r.servings,
    );
  }

  List<String> _flat(List<String> flat, List<IngredientSection> sections) {
    if (sections.isNotEmpty) return [for (final s in sections) ...s.items];
    return flat;
  }

  void _syncGroceries(String recipeId, List<String> newIngredients) {
    if (!Get.isRegistered<GroceryStore>()) return;
    final store = Get.find<GroceryStore>();
    // Only re-sync if this recipe's items are already on the list.
    if (store.items.any((i) => i.recipeId == recipeId)) {
      store.addFromRecipe(recipeId, newIngredients); // replaces existing
    }
  }
}
