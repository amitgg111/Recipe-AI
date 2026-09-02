import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
import 'package:recipe_ai/Helper/recipe_response_parser.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/analytics_service.dart';
import 'package:recipe_ai/Service/import_with_image_api_calling_service.dart';
import 'package:recipe_ai/Service/nutrition_estimator.dart';

/// The four one-tap goals shown in the "Plan my week" sheet.
enum MealGoal { healthy, highProtein, quickEasy, vegetarian }

extension MealGoalX on MealGoal {
  String get title {
    switch (this) {
      case MealGoal.healthy:
        return 'Eat healthy';
      case MealGoal.highProtein:
        return 'High protein';
      case MealGoal.quickEasy:
        return 'Quick & easy';
      case MealGoal.vegetarian:
        return 'Vegetarian';
    }
  }

  String get subtitle {
    switch (this) {
      case MealGoal.healthy:
        return 'Balanced, veg-forward meals';
      case MealGoal.highProtein:
        return 'Protein in every meal';
      case MealGoal.quickEasy:
        return 'Everything under 30 min';
      case MealGoal.vegetarian:
        return 'No meat this week';
    }
  }

  /// Short label used in the review-screen subtitle.
  String get shortLabel {
    switch (this) {
      case MealGoal.healthy:
        return 'Healthy';
      case MealGoal.highProtein:
        return 'High protein';
      case MealGoal.quickEasy:
        return 'Quick';
      case MealGoal.vegetarian:
        return 'Vegetarian';
    }
  }

  String get emoji {
    switch (this) {
      case MealGoal.healthy:
        return '🥗';
      case MealGoal.highProtein:
        return '🍗';
      case MealGoal.quickEasy:
        return '⚡';
      case MealGoal.vegetarian:
        return '🌱';
    }
  }

  /// Bias term folded into the AI recipe name so generated recipes fit the goal.
  String get aiBias {
    switch (this) {
      case MealGoal.healthy:
        return 'Healthy balanced';
      case MealGoal.highProtein:
        return 'High-protein';
      case MealGoal.quickEasy:
        return 'Quick 20-minute';
      case MealGoal.vegetarian:
        return 'Vegetarian';
    }
  }
}

/// Where a recipe in the plan came from — drives the source badge and the
/// mandatory Cookbook → Community → AI fallback priority.
enum PlanSource { cookbook, community, ai }

/// A generating-screen step and its live status.
enum MpStepState { pending, active, done }

class GenStep {
  final String label;
  MpStepState state;
  GenStep(this.label, [this.state = MpStepState.pending]);
}

/// A source-agnostic recipe used while planning. Normalises Cookbook
/// (RecipeModel), Community (Firestore) and AI (generated JSON) into one shape.
class PlanRecipe {
  final String id;
  final String title;
  final String? imageUrl;
  final String? cuisine;
  final String? category;
  final List<String> keywords;
  final List<String> ingredients;
  final List<String> instructions;
  final String? prepTime;
  final String? cookTime;
  final String? totalTime;
  final double servings;
  final PlanSource source;

  const PlanRecipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.cuisine,
    required this.category,
    required this.keywords,
    required this.ingredients,
    required this.instructions,
    required this.prepTime,
    required this.cookTime,
    required this.totalTime,
    required this.servings,
    required this.source,
  });

  String get dedupeKey => title.trim().toLowerCase();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'imageUrl': imageUrl,
    'cuisine': cuisine,
    'category': category,
    'keywords': keywords,
    'ingredients': ingredients,
    'instructions': instructions,
    'prepTime': prepTime,
    'cookTime': cookTime,
    'totalTime': totalTime,
    'servings': servings,
    'source': source.name,
  };

  factory PlanRecipe.fromJson(Map<String, dynamic> m) => PlanRecipe(
    id: m['id']?.toString() ?? '',
    title: m['title']?.toString() ?? '',
    imageUrl: m['imageUrl']?.toString(),
    cuisine: m['cuisine']?.toString(),
    category: m['category']?.toString(),
    keywords: (m['keywords'] as List?)?.map((e) => e.toString()).toList() ?? [],
    ingredients:
        (m['ingredients'] as List?)?.map((e) => e.toString()).toList() ?? [],
    instructions:
        (m['instructions'] as List?)?.map((e) => e.toString()).toList() ?? [],
    prepTime: m['prepTime']?.toString(),
    cookTime: m['cookTime']?.toString(),
    totalTime: m['totalTime']?.toString(),
    servings: (m['servings'] as num?)?.toDouble() ?? 4,
    source: PlanSource.values.firstWhere(
      (s) => s.name == m['source'],
      orElse: () => PlanSource.ai,
    ),
  );

  factory PlanRecipe.fromRecipeModel(RecipeModel r) => PlanRecipe(
    id: r.id,
    title: r.title,
    imageUrl: r.imageUrl,
    cuisine: r.cuisine,
    category: r.category,
    keywords: r.keywords,
    ingredients: r.ingredients,
    instructions: r.instructions,
    prepTime: r.prepTime,
    cookTime: r.cookTime,
    totalTime: r.totalTime,
    servings: r.servingCount,
    source: PlanSource.cookbook,
  );

  /// From a raw Firestore recipe map (community) or parsed AI recipe.
  factory PlanRecipe.fromMap(
    String id,
    Map<String, dynamic> data,
    PlanSource source,
  ) {
    final parsed = RecipeResponseParser.parse(data);
    return PlanRecipe(
      id: id,
      title: parsed.title.isNotEmpty
          ? parsed.title
          : (data['title']?.toString() ?? 'Recipe'),
      imageUrl: data['imageUrl']?.toString(),
      cuisine: parsed.cuisine,
      category: parsed.category,
      keywords: parsed.keywords,
      ingredients: parsed.ingredients,
      instructions: parsed.instructions,
      prepTime: parsed.prepTime,
      cookTime: parsed.cookTime,
      totalTime: parsed.totalTime,
      servings: double.tryParse('${parsed.servings}') ?? 4,
      source: source,
    );
  }
  PlanRecipe copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? cuisine,
    String? category,
    List<String>? keywords,
    List<String>? ingredients,
    List<String>? instructions,
    String? prepTime,
    String? cookTime,
    String? totalTime,
    double? servings,
    PlanSource? source,
  }) {
    return PlanRecipe(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      cuisine: cuisine ?? this.cuisine,
      category: category ?? this.category,
      keywords: keywords ?? this.keywords,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      totalTime: totalTime ?? this.totalTime,
      servings: servings ?? this.servings,
      source: source ?? this.source,
    );
  }
}

/// One meal in the generated week grid.
class PlannedMeal {
  final int day; // 0..6 (Mon..Sun)
  final String slot; // Breakfast | Lunch | Dinner
  PlanRecipe recipe;
  PlannedMeal({required this.day, required this.slot, required this.recipe});

  Map<String, dynamic> toJson() => {
    'day': day,
    'slot': slot,
    'recipe': recipe.toJson(),
  };

  factory PlannedMeal.fromJson(Map<String, dynamic> m) => PlannedMeal(
    day: (m['day'] as num?)?.toInt() ?? 0,
    slot: m['slot']?.toString() ?? 'Breakfast',
    recipe: PlanRecipe.fromJson(
      Map<String, dynamic>.from(m['recipe'] as Map? ?? {}),
    ),
  );
}

/// Drives the "Auto-fill my week" flow. Generation ALWAYS succeeds; the API is
/// the last resort — Cookbook first, then Community, then only the missing
/// recipes from AI. This priority is mandatory and never violated.

class MealPlannerController extends GetxController {
  final RxBool isRegenerating = false.obs;
  static MealPlannerController get to =>
      Get.isRegistered<MealPlannerController>()
      ? Get.find<MealPlannerController>()
      : Get.put(MealPlannerController(), permanent: true);

  // ── Inputs from the goal sheet ─────────────────────────────────────────────
  // `goal` kept for backward-compat (first selected goal); `goals` is the
  // source of truth for multi-select.
  final Rx<MealGoal> goal = MealGoal.healthy.obs;
  final RxList<MealGoal> goals = <MealGoal>[MealGoal.healthy].obs;
  String selectedCuisine = '';
  String customPrompt = '';
  int servings = 4;

  static const List<String> slots = ['Breakfast', 'Lunch', 'Dinner'];
  static const int days = 7;
  int get target =>
      slots.length * allowedDays.length; // was: slots.length * days

  /// Only generate at most this many recipes via AI in one run — the plan is
  /// always completed (repeats fill any remainder) so we never storm the API.
  static const int _aiCap = 8;
  final RxList<PlannedMeal> translatedMeals = <PlannedMeal>[].obs;

  final RxBool isTranslatingPlan = false.obs;
  // ── Live state ─────────────────────────────────────────────────────────────
  final RxList<GenStep> steps = <GenStep>[].obs;
  final RxList<PlannedMeal> meals = <PlannedMeal>[].obs;
  final RxBool aiUsed = false.obs;

  /// The unique recipe pool gathered this run — shuffles reuse it (no new API).
  final List<PlanRecipe> _pool = [];
  final _rand = math.Random();
  final Map<String, double> _calCache = {};
  final Map<String, double> _proteinCache = {};

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERATE
  // ═══════════════════════════════════════════════════════════════════════════
  List<int> allowedDays = List.generate(days, (i) => i);

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  bool _matchesCuisine(PlanRecipe r) {
    // જો કોઈ cuisine select નથી તો બધા cuisine allow
    if (selectedCuisine.trim().isEmpty) {
      return true;
    }
    // No cuisine selected = allow all cuisines
    if (selectedCuisine.isEmpty) return true;

    final recipeCuisine = r.cuisine?.trim().toLowerCase() ?? '';
    final selected = selectedCuisine.trim().toLowerCase();

    return recipeCuisine == selected;
  }

  List<int> _allowedDayIndices(DateTime weekStart) {
    final today = _dateOnly(DateTime.now());
    final indices = <int>[];
    for (var i = 0; i < days; i++) {
      final date = _dateOnly(weekStart.add(Duration(days: i)));
      if (!date.isBefore(today)) indices.add(i);
    }
    return indices;
  }

  Future<void> generateWeeklyPlan() async {
    final totalWatch = Stopwatch()..start();

    void logStep(String step, Stopwatch watch) {
      log(
        '⏱️ [WeeklyPlan] $step: '
        '${watch.elapsedMilliseconds} ms '
        '(${(watch.elapsedMilliseconds / 1000).toStringAsFixed(2)} sec)',
      );
    }

    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    log('🚀 [WeeklyPlan] generateWeeklyPlan START');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      aiUsed.value = false;
      _pool.clear();
      meals.clear();

      final planCtrl = Get.find<MealPlanController>();
      final weekStart = planCtrl.selectedWeekStart.value;

      log('📅 [WeeklyPlan] Week start: $weekStart');

      allowedDays = _allowedDayIndices(weekStart);

      log('📆 [WeeklyPlan] Allowed days: $allowedDays');

      if (allowedDays.isEmpty) {
        meals.value = [];
        steps.value = [
          GenStep('Nothing left to plan this week', MpStepState.done),
        ];

        totalWatch.stop();

        log(
          '⚠️ [WeeklyPlan] Nothing to generate. '
          'Total: ${totalWatch.elapsedMilliseconds} ms',
        );
        return;
      }

      steps.value = [
        GenStep('Reading your preferences'),
        GenStep('Searching your Cookbook'),
        GenStep('Searching Community Recipes'),
        GenStep('Building your weekly meal plan'),
      ];

      // ---------------------------------------------------------
      // STEP 1 — Preferences
      // ---------------------------------------------------------
      final step1Watch = Stopwatch()..start();

      log('▶️ [WeeklyPlan] STEP 1 START: Reading preferences');

      await _run(0, minMs: 500);

      step1Watch.stop();
      logStep('STEP 1 - Reading preferences', step1Watch);

      // ---------------------------------------------------------
      // STEP 2 — Cookbook
      // ---------------------------------------------------------
      final step2Watch = Stopwatch()..start();

      log('▶️ [WeeklyPlan] STEP 2 START: Searching Cookbook');

      steps[1].state = MpStepState.active;
      steps.refresh();

      final cookbook = searchCookbook();

      log('📚 [WeeklyPlan] Cookbook recipes found: ${cookbook.length}');

      _pool.addAll(cookbook);

      log('📦 [WeeklyPlan] Pool after Cookbook: ${_pool.length}/$target');

      await _settle(600);

      steps[1].state = MpStepState.done;
      steps.refresh();

      step2Watch.stop();
      logStep('STEP 2 - Searching Cookbook', step2Watch);

      // ---------------------------------------------------------
      // STEP 3 — Community
      // ---------------------------------------------------------
      final step3Watch = Stopwatch()..start();

      log('▶️ [WeeklyPlan] STEP 3 START: Searching Community');

      steps[2].state = MpStepState.active;
      steps.refresh();

      if (_pool.length < target) {
        final needed = target - _pool.length;

        log(
          '🌐 [WeeklyPlan] Cookbook insufficient. '
          'Need $needed more recipes.',
        );

        final community = await searchCommunityRecipes();

        log('🌐 [WeeklyPlan] Community recipes found: ${community.length}');

        mergeInto(_pool, community);

        log(
          '📦 [WeeklyPlan] Pool after Community: '
          '${_pool.length}/$target',
        );
      } else {
        log(
          '✅ [WeeklyPlan] Cookbook already has enough recipes. '
          'Skipping Community search.',
        );
      }

      await _settle(600);

      steps[2].state = MpStepState.done;
      steps.refresh();

      step3Watch.stop();
      logStep('STEP 3 - Searching Community', step3Watch);

      // ---------------------------------------------------------
      // STEP 4 — AI LAST RESORT
      // ---------------------------------------------------------
      if (_pool.length < target) {
        final aiWatch = Stopwatch()..start();

        aiUsed.value = true;

        final missing = target - _pool.length;

        log('🤖 [WeeklyPlan] STEP 4 START: AI Generation');
        log('🤖 [WeeklyPlan] AI needs to generate: $missing recipes');

        steps.insert(
          3,
          GenStep('Generating missing recipes', MpStepState.active),
        );
        steps.refresh();

        final generated = await generateMissingRecipes(missing);

        log('🤖 [WeeklyPlan] AI generated: ${generated.length} recipes');

        mergeInto(_pool, generated);

        log('📦 [WeeklyPlan] Pool after AI: ${_pool.length}/$target');

        steps[3].state = MpStepState.done;
        steps.refresh();

        aiWatch.stop();
        logStep('STEP 4 - AI Generation', aiWatch);
      } else {
        log('✅ [WeeklyPlan] Enough recipes found. AI generation skipped.');
      }

      // ---------------------------------------------------------
      // FINAL STEP — Build & Balance
      // ---------------------------------------------------------
      final buildWatch = Stopwatch()..start();

      log('▶️ [WeeklyPlan] FINAL STEP START: Build & Balance');

      final buildIdx = steps.length - 1;

      steps[buildIdx].state = MpStepState.active;
      steps.refresh();

      balanceMeals();

      log('🍽️ [WeeklyPlan] Meals after balance: ${meals.length}');

      await translateGeneratedWeek();

      log('🌐 [WeeklyPlan] Week translation completed');

      await _settle(700);

      steps[buildIdx].state = MpStepState.done;

      steps.refresh();

      buildWatch.stop();
      logStep('FINAL STEP - Build & Balance', buildWatch);

      // ---------------------------------------------------------
      // SAVE DRAFT
      // ---------------------------------------------------------
      final saveWatch = Stopwatch()..start();

      log('💾 [WeeklyPlan] Saving draft...');

      await _saveDraft();

      saveWatch.stop();
      logStep('Save Draft', saveWatch);

      // ---------------------------------------------------------
      // TOTAL TIME
      // ---------------------------------------------------------
      totalWatch.stop();

      log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      log('✅ [WeeklyPlan] generateWeeklyPlan COMPLETED');
      log('📦 [WeeklyPlan] Final pool: ${_pool.length}/$target');
      log('🍽️ [WeeklyPlan] Final meals: ${meals.length}');
      log('🤖 [WeeklyPlan] AI used: ${aiUsed.value}');
      log(
        '⏱️ [WeeklyPlan] TOTAL TIME: '
        '${totalWatch.elapsedMilliseconds} ms '
        '(${(totalWatch.elapsedMilliseconds / 1000).toStringAsFixed(2)} sec)',
      );
      log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, stackTrace) {
      totalWatch.stop();

      log('❌ [WeeklyPlan] ERROR: $e');
      log(
        '⏱️ [WeeklyPlan] Failed after: '
        '${totalWatch.elapsedMilliseconds} ms '
        '(${(totalWatch.elapsedMilliseconds / 1000).toStringAsFixed(2)} sec)',
      );
      log('📍 [WeeklyPlan] StackTrace: $stackTrace');

      rethrow;
    }
  }

  Future<void> translateGeneratedWeek() async {
    if (meals.isEmpty) {
      translatedMeals.clear();
      isTranslatingPlan.value = false;
      return;
    }

    isTranslatingPlan.value = true;

    try {
      final texts = <String>[];

      for (final meal in meals) {
        final recipe = meal.recipe;

        if (recipe.title.trim().isNotEmpty) {
          texts.add(recipe.title);
        }

        texts.addAll(recipe.ingredients.where((e) => e.trim().isNotEmpty));

        texts.addAll(recipe.instructions.where((e) => e.trim().isNotEmpty));

        if ((recipe.cuisine ?? '').trim().isNotEmpty) {
          texts.add(recipe.cuisine!.trim());
        }

        if ((recipe.category ?? '').trim().isNotEmpty) {
          texts.add(recipe.category!.trim());
        }
      }

      final uniqueTexts = texts
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      if (uniqueTexts.isEmpty) {
        translatedMeals.assignAll(meals);
        return;
      }

      final translated = await AiTranslationService.translateList(uniqueTexts);

      final translationMap = <String, String>{};

      for (int i = 0; i < uniqueTexts.length; i++) {
        translationMap[uniqueTexts[i]] = translated[i];
      }

      String tr(String value) {
        final clean = value.trim();

        if (clean.isEmpty) return value;

        return translationMap[clean] ?? value;
      }

      final translatedResult = <PlannedMeal>[];

      for (final meal in meals) {
        final recipe = meal.recipe;

        final translatedRecipe = recipe.copyWith(
          title: tr(recipe.title),
          ingredients: recipe.ingredients.map(tr).toList(),
          instructions: recipe.instructions.map(tr).toList(),
          cuisine: recipe.cuisine == null ? null : tr(recipe.cuisine!),
          category: recipe.category == null ? null : tr(recipe.category!),
        );

        translatedResult.add(
          PlannedMeal(day: meal.day, slot: meal.slot, recipe: translatedRecipe),
        );
      }

      translatedMeals.assignAll(translatedResult);
    } catch (e, stackTrace) {
      log('❌ [WeeklyPlan] Translation failed: $e');
      log('$stackTrace');

      translatedMeals.assignAll(meals);
    } finally {
      isTranslatingPlan.value = false;
    }
  }

  /// Move the recipe at [fromDay]/[fromSlot] to [toDay]/[toSlot]. If the
  /// destination already has a recipe, the two simply swap places — nothing
  /// is replaced/regenerated, only re-ordered.
  void reorderMeal({
    required int fromDay,
    required String fromSlot,
    required int toDay,
    required String toSlot,
  }) {
    if (!allowedDays.contains(fromDay) || !allowedDays.contains(toDay)) {
      return;
    }

    if (fromDay == toDay && fromSlot == toSlot) {
      return;
    }

    final fromIndex = meals.indexWhere(
      (m) => m.day == fromDay && m.slot == fromSlot,
    );

    final toIndex = meals.indexWhere((m) => m.day == toDay && m.slot == toSlot);

    if (fromIndex == -1 || toIndex == -1) return;

    final fromRecipe = meals[fromIndex].recipe;
    final toRecipe = meals[toIndex].recipe;

    meals[fromIndex].recipe = toRecipe;
    meals[toIndex].recipe = fromRecipe;

    // Keep translated meals in sync.
    if (translatedMeals.length == meals.length) {
      final translatedFromIndex = translatedMeals.indexWhere(
        (m) => m.day == fromDay && m.slot == fromSlot,
      );

      final translatedToIndex = translatedMeals.indexWhere(
        (m) => m.day == toDay && m.slot == toSlot,
      );

      if (translatedFromIndex != -1 && translatedToIndex != -1) {
        final translatedFromRecipe =
            translatedMeals[translatedFromIndex].recipe;

        final translatedToRecipe = translatedMeals[translatedToIndex].recipe;

        translatedMeals[translatedFromIndex].recipe = translatedToRecipe;

        translatedMeals[translatedToIndex].recipe = translatedFromRecipe;

        translatedMeals.refresh();
      }
    }

    meals.refresh();
  }

  // void reorderMeal({
  //   required int fromDay,
  //   required String fromSlot,
  //   required int toDay,
  //   required String toSlot,
  // }) {
  //   if (!allowedDays.contains(fromDay) || !allowedDays.contains(toDay)) return;
  //   if (fromDay == toDay && fromSlot == toSlot) return;

  //   final fromIndex = meals.indexWhere(
  //     (m) => m.day == fromDay && m.slot == fromSlot,
  //   );
  //   final toIndex = meals.indexWhere((m) => m.day == toDay && m.slot == toSlot);
  //   if (fromIndex == -1 || toIndex == -1) return;

  //   final fromRecipe = meals[fromIndex].recipe;
  //   final toRecipe = meals[toIndex].recipe;

  //   meals[fromIndex].recipe = toRecipe;
  //   meals[toIndex].recipe = fromRecipe;
  //   meals.refresh();
  // }

  Future<void> _run(int i, {int minMs = 500}) async {
    steps[i].state = MpStepState.active;
    steps.refresh();
    await _settle(minMs);
    steps[i].state = MpStepState.done;
    steps.refresh();
  }

  Future<void> _settle(int ms) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  // ═══════════════════════════════════════════════════════════════════════════
  // SOURCES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Priority 1 — the user's saved recipes, filtered to the goal(s). In-memory,
  /// no I/O. Only recipes matching AT LEAST ONE selected goal are considered.
  List<PlanRecipe> searchCookbook() {
    final home = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : null;

    final all = home?.recipes ?? const [];
    final matched = <PlanRecipe>[];

    for (final r in all) {
      final pr = PlanRecipe.fromRecipeModel(r);

      if (_matchesGoal(pr) && _matchesCuisine(pr)) {
        matched.add(pr);
      }
    }

    matched.shuffle(_rand);
    return matched;
  }

  /// Priority 2 — public Community recipes from Firebase, same goal filters.
  /// Queries the top-level `recipes` collection directly.

  Future<List<PlanRecipe>> searchCommunityRecipes() async {
    final out = <PlanRecipe>[];

    try {
      final db = FirebaseFirestore.instance;
      final uid = AuthService.currentUser?.uid;

      final snap = await db.collection('recipes').get();

      for (final d in snap.docs) {
        final data = d.data();

        if (data['isDeleted'] == true) continue;
        if (data['ownerId'] == uid) continue;

        final pr = PlanRecipe.fromMap(d.id, data, PlanSource.community);

        if (_matchesGoal(pr) && _matchesCuisine(pr)) {
          out.add(pr);
        }
      }
    } catch (_) {
      /* offline / permission — fall through to AI */
    }

    out.shuffle(_rand);
    return out;
  }

  /// Priority 3 — generate only the [count] missing recipes via the API,
  /// biased to the selected goal(s) + custom prompt. Cycles through every
  /// selected goal's bias so each goal gets fair representation. Never
  /// regenerates what we already have.
  // Future<List<PlanRecipe>> generateMissingRecipes(int count) async {
  //   final n = math.min(count, _aiCap);
  //   final out = <PlanRecipe>[];

  //   final selectedGoals = goals.isNotEmpty ? goals : [goal.value];
  //   final extra = customPrompt.trim();
  //   final cuisine = selectedCuisine.trim();

  //   final slotCycle = ['breakfast', 'lunch', 'dinner'];

  //   for (var i = 0; i < n; i++) {
  //     final meal = slotCycle[i % slotCycle.length];

  //     // Rotate through selected goals
  //     final bias = selectedGoals[i % selectedGoals.length].aiBias;

  //     final name = [
  //       bias,
  //       if (cuisine.isNotEmpty) cuisine,
  //       if (extra.isNotEmpty) extra,
  //       meal,
  //       'recipe idea ${i + 1}',
  //     ].join(' ');

  //     try {
  //       final recipe = await RecipeImportService.getRecipeFromName(name);

  //       final pr = PlanRecipe.fromMap(
  //         'ai_${DateTime.now().microsecondsSinceEpoch}_$i',
  //         recipe,
  //         PlanSource.ai,
  //       );

  //       if (pr.title.trim().isNotEmpty) {
  //         out.add(pr);
  //       }
  //     } catch (_) {
  //       // Skip failed generation; plan continues
  //     }
  //   }

  //   return out;
  // }

  Future<List<PlanRecipe>> generateMissingRecipes(int count) async {
    final totalWatch = Stopwatch()..start();

    final n = math.min(count, _aiCap);
    final out = <PlanRecipe>[];

    if (n <= 0) {
      log('🤖 [AI] Nothing to generate.');
      return out;
    }

    final selectedGoals = goals.isNotEmpty ? goals : [goal.value];
    final extra = customPrompt.trim();
    final cuisine = selectedCuisine.trim();

    const slotCycle = ['breakfast', 'lunch', 'dinner'];

    // Keep this at 3 to avoid hitting API/backend rate limits.
    const batchSize = 3;

    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    log('🤖 [AI] GENERATION START');
    log('🤖 [AI] Requested: $count');
    log('🤖 [AI] Actual generation count: $n');
    log('🤖 [AI] Batch size: $batchSize');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // ---------------------------------------------------------
    // Build all recipe requests first
    // ---------------------------------------------------------

    final requests = <Future<PlanRecipe?>>[];

    for (var i = 0; i < n; i++) {
      final meal = slotCycle[i % slotCycle.length];

      final bias = selectedGoals[i % selectedGoals.length].aiBias;

      final name = [
        bias,
        if (cuisine.isNotEmpty) cuisine,
        if (extra.isNotEmpty) extra,
        meal,
        'recipe idea ${i + 1}',
      ].join(' ');

      log('📝 [AI] Request ${i + 1}/$n: $name');

      requests.add(_generateSingleRecipe(name: name, index: i));
    }

    // ---------------------------------------------------------
    // Execute in parallel batches
    // ---------------------------------------------------------

    for (var start = 0; start < requests.length; start += batchSize) {
      final end = math.min(start + batchSize, requests.length);

      final batch = requests.sublist(start, end);

      final batchNumber = (start ~/ batchSize) + 1;

      final batchWatch = Stopwatch()..start();

      log(
        '🚀 [AI] Batch $batchNumber START '
        '(${batch.length} parallel requests)',
      );

      final results = await Future.wait(batch, eagerError: false);

      batchWatch.stop();

      for (final recipe in results) {
        if (recipe != null) {
          out.add(recipe);
        }
      }

      log(
        '✅ [AI] Batch $batchNumber DONE: '
        '${batchWatch.elapsedMilliseconds} ms '
        '(${(batchWatch.elapsedMilliseconds / 1000).toStringAsFixed(2)} sec)',
      );

      log(
        '📦 [AI] Successful recipes so far: '
        '${out.length}/$n',
      );
    }

    totalWatch.stop();

    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    log('🤖 [AI] GENERATION COMPLETE');
    log('🤖 [AI] Successful: ${out.length}/$n');
    log(
      '⏱️ [AI] Total generation time: '
      '${totalWatch.elapsedMilliseconds} ms '
      '(${(totalWatch.elapsedMilliseconds / 1000).toStringAsFixed(2)} sec)',
    );
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    return out;
  }

  Future<PlanRecipe?> _generateSingleRecipe({
    required String name,
    required int index,
  }) async {
    final watch = Stopwatch()..start();

    try {
      log('🤖 [AI] Recipe ${index + 1} START');

      final recipe = await RecipeImportService.getRecipeFromName(name);

      final pr = PlanRecipe.fromMap(
        'ai_${DateTime.now().microsecondsSinceEpoch}_$index',
        recipe,
        PlanSource.ai,
      );

      watch.stop();

      if (pr.title.trim().isEmpty) {
        log(
          '⚠️ [AI] Recipe ${index + 1} returned empty title '
          'after ${watch.elapsedMilliseconds} ms',
        );
        return null;
      }

      log(
        '✅ [AI] Recipe ${index + 1} DONE: '
        '"${pr.title}" '
        '${watch.elapsedMilliseconds} ms '
        '(${(watch.elapsedMilliseconds / 1000).toStringAsFixed(2)} sec)',
      );

      return pr;
    } catch (e) {
      watch.stop();

      log(
        '❌ [AI] Recipe ${index + 1} FAILED after '
        '${watch.elapsedMilliseconds} ms '
        '(${(watch.elapsedMilliseconds / 1000).toStringAsFixed(2)} sec): $e',
      );

      return null;
    }
  }

  /// Merge [incoming] into [pool], removing duplicates by title.
  void mergeInto(List<PlanRecipe> pool, List<PlanRecipe> incoming) {
    final seen = pool.map((e) => e.dedupeKey).toSet();
    for (final r in incoming) {
      if (r.title.trim().isEmpty) continue;
      if (seen.add(r.dedupeKey)) pool.add(r);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BALANCING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fill the 7×3 grid from [_pool] honouring the balancing rules:
  /// breakfast light · lunch balanced · dinner medium; no identical meal on
  /// consecutive days; no recipe more than twice a week; rotate cuisines.
  void balanceMeals() {
    final result = <PlannedMeal>[];
    if (_pool.isEmpty) {
      meals.value = result;
      return;
    }

    // Calorie tertiles bias slots (light breakfast → heavier dinner).
    final byCal = [..._pool]..sort((a, b) => _cal(a).compareTo(_cal(b)));
    final third = (byCal.length / 3).ceil().clamp(1, byCal.length);
    final light = byCal.take(third).toList();
    final heavy = byCal.reversed.take(third).toList();

    final usage = <String, int>{};
    // recipe used on a given day (any slot) — blocks consecutive-day repeats.
    final usedOnDay = List.generate(days, (_) => <String>{});

    PlanRecipe? pick(int day, String slot, Set<String> dayCuisines) {
      // Slot-biased candidate order, then the whole pool as fallback.
      final biased = slot == 'Breakfast'
          ? light
          : slot == 'Dinner'
          ? heavy
          : _pool;
      for (final relax in [0, 1, 2, 3]) {
        final ordered = [...biased, ..._pool]..shuffle(_rand);
        final seen = <String>{};
        for (final r in ordered) {
          if (!seen.add(r.dedupeKey)) continue;
          final count = usage[r.dedupeKey] ?? 0;
          final onPrevDay = day > 0 && usedOnDay[day - 1].contains(r.dedupeKey);
          final onThisDay = usedOnDay[day].contains(r.dedupeKey);
          final maxUse = relax >= 3 ? 3 : 2;
          if (count >= maxUse) continue; // rule: ≤2 per week (relax to 3 last)
          if (onThisDay) continue; // never twice on the same day
          if (relax < 1 && onPrevDay) continue; // no consecutive-day repeat
          if (relax < 2 &&
              r.cuisine != null &&
              r.cuisine!.isNotEmpty &&
              dayCuisines.contains(r.cuisine!.toLowerCase())) {
            continue; // rotate cuisines within a day
          }
          return r;
        }
      }
      return _pool[_rand.nextInt(_pool.length)];
    }

    for (final day in allowedDays) {
      final dayCuisines = <String>{};
      for (final slot in slots) {
        final r = pick(day, slot, dayCuisines)!;
        usage[r.dedupeKey] = (usage[r.dedupeKey] ?? 0) + 1;
        usedOnDay[day].add(r.dedupeKey);
        if (r.cuisine != null && r.cuisine!.isNotEmpty) {
          dayCuisines.add(r.cuisine!.toLowerCase());
        }
        result.add(PlannedMeal(day: day, slot: slot, recipe: r));
      }
    }

    meals.value = result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHUFFLE  (same priority: reuse the existing pool — never call AI now)
  // ═══════════════════════════════════════════════════════════════════════════

  PlannedMeal _mealAt(int day, String slot) =>
      meals.firstWhere((m) => m.day == day && m.slot == slot);

  /// Swap a single meal for a different recipe from the pool (Cookbook first,
  /// then Community, then AI), avoiding this-day repeats.
  // void shuffleMeal(int day, String slot) {
  //   if (!allowedDays.contains(day)) return; // never touch a past day

  //   if (_pool.length < 2) return;
  //   final current = _mealAt(day, slot);
  //   final sameDay = meals
  //       .where((m) => m.day == day && m.slot != slot)
  //       .map((m) => m.recipe.dedupeKey)
  //       .toSet();
  //   // Prefer other days' usage low, respect source priority order.
  //   final candidates = [..._pool]
  //     ..removeWhere(
  //       (r) =>
  //           r.dedupeKey == current.recipe.dedupeKey ||
  //           sameDay.contains(r.dedupeKey),
  //     )
  //     ..sort((a, b) => a.source.index.compareTo(b.source.index));
  //   if (candidates.isEmpty) return;
  //   // Pick randomly among the top-priority tier for variety.
  //   final topTier = candidates
  //       .where((r) => r.source == candidates.first.source)
  //       .toList();
  //   current.recipe = topTier[_rand.nextInt(topTier.length)];
  //   meals.refresh();
  // }
  void shuffleMeal(int day, String slot) {
    if (!allowedDays.contains(day)) return;

    if (_pool.length < 2) return;

    final current = _mealAt(day, slot);

    final sameDay = meals
        .where((m) => m.day == day && m.slot != slot)
        .map((m) => m.recipe.dedupeKey)
        .toSet();

    final candidates = [..._pool]
      ..removeWhere(
        (r) =>
            r.dedupeKey == current.recipe.dedupeKey ||
            sameDay.contains(r.dedupeKey),
      )
      ..sort((a, b) => a.source.index.compareTo(b.source.index));

    if (candidates.isEmpty) return;

    final topTier = candidates
        .where((r) => r.source == candidates.first.source)
        .toList();

    final newRecipe = topTier[_rand.nextInt(topTier.length)];

    current.recipe = newRecipe;
    meals.refresh();

    // Translate only the newly selected recipe.
    unawaited(_translateSingleMealForDisplay(day, slot, newRecipe));
  }

  Future<void> _translateSingleMealForDisplay(
    int day,
    String slot,
    PlanRecipe recipe,
  ) async {
    try {
      final texts = <String>[
        recipe.title,
        ...recipe.ingredients,
        ...recipe.instructions,
        if (recipe.cuisine != null) recipe.cuisine!,
        if (recipe.category != null) recipe.category!,
      ].map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();

      if (texts.isEmpty) return;

      final translated = await AiTranslationService.translateList(texts);

      final map = <String, String>{};

      for (int i = 0; i < texts.length; i++) {
        map[texts[i]] = translated[i];
      }

      String tr(String value) {
        return map[value.trim()] ?? value;
      }

      final translatedRecipe = recipe.copyWith(
        title: tr(recipe.title),
        ingredients: recipe.ingredients.map(tr).toList(),
        instructions: recipe.instructions.map(tr).toList(),
        cuisine: recipe.cuisine == null ? null : tr(recipe.cuisine!),
        category: recipe.category == null ? null : tr(recipe.category!),
      );

      final index = translatedMeals.indexWhere(
        (m) => m.day == day && m.slot == slot,
      );

      if (index == -1) return;

      translatedMeals[index].recipe = translatedRecipe;
      translatedMeals.refresh();
    } catch (e) {
      log('❌ [WeeklyPlan] Single meal translation failed: $e');
    }
  }

  void shuffleDay(int day) {
    if (!allowedDays.contains(day)) return;
    for (final slot in slots) {
      shuffleMeal(day, slot);
    }
  }

  Future<void> shuffleWeek() async {
    if (isRegenerating.value) return;

    isRegenerating.value = true;

    try {
      // Regenerate the complete week from scratch.
      // This keeps the same selected goals, cuisine, servings and prompt.
      await generateWeeklyPlan();
    } catch (_) {
      // Keep the existing plan visible if regeneration fails.
    } finally {
      isRegenerating.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APPLY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Write the generated week into the real meal plan. Community/AI recipes are
  /// copied into the user's cookbook first so every meal fully resolves.
  Future<void> applyToPlan() async {
    final plan = Get.find<MealPlanController>();
    final weekStart = plan.selectedWeekStart.value;
    final weekDays = plan.getDaysOfWeek(weekStart);
    final today = _dateOnly(DateTime.now());

    // Silent clear of the target week (avoids clearWeek()'s snackbar) so a
    // re-apply doesn't stack duplicate meals.
    await _clearWeekSilently(plan, weekStart);

    final idCache = <String, String?>{}; // dedupeKey → resolved recipeId
    for (final m in meals) {
      final date = weekDays[m.day];
      if (_dateOnly(date).isBefore(today)) {
        continue; // hard guard: skip past dates
      }

      final key = m.recipe.dedupeKey;
      String? recipeId;
      if (idCache.containsKey(key)) {
        recipeId = idCache[key];
      } else {
        recipeId = m.recipe.source == PlanSource.cookbook
            ? m.recipe.id
            : await _persistRecipe(m.recipe);
        idCache[key] = recipeId;
      }
      if (recipeId == null) continue;
      await plan.addMealPlanItem(
        date: date,
        mealType: m.slot,
        recipeId: recipeId,
        recipeTitle: m.recipe.title,
        recipeImageUrl: m.recipe.imageUrl,
      );
    }
    // Applied → the draft is no longer needed.
    await _clearDraft();
    await AnalyticsService.instance.trackEvent('apply_generated_meal_plan');
  }

  // ── Draft persistence (generated week, before/instead of Apply) ─────────────

  DocumentReference<Map<String, dynamic>>? get _draftRef {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meal_planner_draft')
        .doc('current');
  }

  Future<void> _saveDraft() async {
    if (meals.isEmpty) return;
    try {
      await _draftRef?.set({
        'goal': goal.value.name,
        'goals': goals.map((g) => g.name).toList(),
        'servings': servings,
        'aiUsed': aiUsed.value,
        'meals': meals.map((m) => m.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      /* best effort */
    }
  }

  Future<void> _clearDraft() async {
    try {
      await _draftRef?.delete();
    } catch (_) {}
  }

  /// True when a generated-but-not-applied week is saved in Firebase.
  Future<bool> hasDraft() async {
    try {
      final d = await _draftRef?.get();
      final list = d?.data()?['meals'] as List?;
      return (list?.isNotEmpty ?? false);
    } catch (_) {
      return false;
    }
  }

  /// Restore the saved draft into the controller so the review screen can
  /// resume it. Returns false if there's nothing to restore.
  Future<bool> loadDraft() async {
    try {
      final data = (await _draftRef?.get())?.data();
      final list = data?['meals'] as List?;
      if (list == null || list.isEmpty) return false;
      final restored = list
          .map((e) => PlannedMeal.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      // Recompute which days are still valid (date may have moved forward
      // since the draft was saved) and drop any meal that's now in the past.
      final planCtrl = Get.find<MealPlanController>();
      allowedDays = _allowedDayIndices(planCtrl.selectedWeekStart.value);
      restored.removeWhere((m) => !allowedDays.contains(m.day));

      if (restored.isEmpty) return false;

      meals.value = restored;
      _pool
        ..clear()
        ..addAll(
          {for (final m in restored) m.recipe.dedupeKey: m.recipe}.values,
        );
      final goalsRaw = data?['goals'] as List?;
      if (goalsRaw != null && goalsRaw.isNotEmpty) {
        final restoredGoals = goalsRaw
            .map(
              (name) => MealGoal.values.firstWhere(
                (g) => g.name == name,
                orElse: () => MealGoal.healthy,
              ),
            )
            .toSet()
            .toList();
        goals.value = restoredGoals;
        goal.value = restoredGoals.first;
      } else {
        final single = MealGoal.values.firstWhere(
          (g) => g.name == data?['goal'],
          orElse: () => MealGoal.healthy,
        );
        goal.value = single;
        goals.value = [single];
      }
      servings = (data?['servings'] as num?)?.toInt() ?? 4;
      aiUsed.value = data?['aiUsed'] == true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _clearWeekSilently(
    MealPlanController plan,
    DateTime weekStart,
  ) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    try {
      final start = plan.formatDatePublic(weekStart);
      final end = plan.formatDatePublic(weekStart.add(const Duration(days: 6)));
      final db = FirebaseFirestore.instance;
      final snap = await db
          .collection('users')
          .doc(uid)
          .collection('meal_plans')
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end)
          .get();
      final batch = db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    } catch (_) {
      /* best effort */
    }
  }

  /// Save a Community/AI recipe into `users/{uid}/recipes` and return its id.
  Future<String?> _persistRecipe(PlanRecipe r) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await FirebaseFirestore.instance.collection('recipes').add({
        'ownerId': uid,
        'title': r.title,
        'description': null,
        'imageUrl': r.imageUrl,
        'sourceUrl': '',
        'prepTime': r.prepTime,
        'cookTime': r.cookTime,
        'totalTime': r.totalTime,
        'servings': r.servings.round().toString(),
        'category': r.category,
        'cuisine': r.cuisine,
        'keywords': r.keywords,
        'ingredients': r.ingredients,
        'instructions': r.instructions,
        'ingredientSections': const [],
        'instructionSections': const [],
        'isPublic': false,
        'recipeSource': r.source == PlanSource.ai ? 'imported' : 'discovered',
        'isDeleted': false,
        'likesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GOAL MATCHING / CLASSIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  static const _meat = [
    'chicken',
    'beef',
    'pork',
    'mutton',
    'lamb',
    'fish',
    'shrimp',
    'prawn',
    'bacon',
    'ham',
    'turkey',
    'sausage',
    'salmon',
    'tuna',
    'meat',
    'gelatin',
    'anchovy',
    'crab',
    'lobster',
  ];
  static const _proteinRich = [
    'chicken',
    'beef',
    'egg',
    'paneer',
    'tofu',
    'lentil',
    'dal',
    'bean',
    'chickpea',
    'yogurt',
    'greek',
    'protein',
    'quinoa',
    'tempeh',
    'fish',
    'salmon',
    'turkey',
    'cottage cheese',
    'peanut',
  ];

  /// A recipe matches if it satisfies ANY of the currently selected goals
  /// (OR logic) — e.g. Vegetarian + Quick&Easy shows veg recipes AND quick
  /// recipes, not only the intersection.
  bool _matchesGoal(PlanRecipe r) {
    final selected = goals.isNotEmpty ? goals : [goal.value];
    for (final g in selected) {
      if (_matchesSingleGoal(r, g)) return true;
    }
    return false;
  }

  bool _matchesSingleGoal(PlanRecipe r, MealGoal g) {
    switch (g) {
      case MealGoal.vegetarian:
        return _isVegetarian(r);
      case MealGoal.quickEasy:
        return _minutes(r) > 0 && _minutes(r) <= 30;
      case MealGoal.highProtein:
        return _protein(r) >= 16 || _hasAny(r, _proteinRich);
      case MealGoal.healthy:
        // Lenient: veg-forward, or reasonable calories, or a healthy keyword.
        if (_isVegetarian(r)) return true;
        if (_hasAny(r, const [
          'salad',
          'bowl',
          'grilled',
          'baked',
          'healthy',
          'roasted',
          'steamed',
        ])) {
          return true;
        }
        final c = _cal(r);
        return c > 0 && c <= 650;
    }
  }

  bool _isVegetarian(PlanRecipe r) {
    final hay =
        '${r.title} ${r.ingredients.join(' ')} '
                '${r.keywords.join(' ')} ${r.category ?? ''}'
            .toLowerCase();
    for (final m in _meat) {
      if (hay.contains(m)) return false;
    }
    return true;
  }

  bool _hasAny(PlanRecipe r, List<String> terms) {
    final hay =
        '${r.title} ${r.keywords.join(' ')} '
                '${r.category ?? ''} ${r.cuisine ?? ''} ${r.ingredients.join(' ')}'
            .toLowerCase();
    return terms.any(hay.contains);
  }

  double _cal(PlanRecipe r) =>
      _calCache[r.dedupeKey] ??= _estimate(r).caloriesPerServing;

  double _protein(PlanRecipe r) =>
      _proteinCache[r.dedupeKey] ??= _estimate(r).protein;

  _Nut _estimate(PlanRecipe r) {
    if (r.ingredients.isEmpty) return const _Nut(0, 0);
    try {
      final n = NutritionEstimator.estimate(
        ingredientLines: r.ingredients,
        servings: r.servings.round().clamp(1, 20),
      );
      return _Nut(n.caloriesPerServing, n.protein);
    } catch (_) {
      return const _Nut(0, 0);
    }
  }

  /// Minutes parsed from the first non-empty time string. Mirrors the app's
  /// only time parser (DiscoverController._minutes).
  int _minutes(PlanRecipe r) {
    final t = [
      r.totalTime,
      r.cookTime,
      r.prepTime,
    ].firstWhere((e) => (e ?? '').trim().isNotEmpty, orElse: () => null);
    if (t == null) return 0;
    final s = t.toLowerCase();
    final h = RegExp(r'(\d+)\s*h').firstMatch(s);
    final m = RegExp(r'(\d+)\s*m').firstMatch(s);
    var total = 0;
    if (h != null) total += (int.tryParse(h.group(1)!) ?? 0) * 60;
    if (m != null) total += int.tryParse(m.group(1)!) ?? 0;
    if (total == 0) {
      final bare = RegExp(r'\d+').firstMatch(s);
      if (bare != null) total = int.tryParse(bare.group(0)!) ?? 0;
    }
    return total;
  }

  //------------------------------------------------------------------------
}

class _Nut {
  final double caloriesPerServing;
  final double protein;
  const _Nut(this.caloriesPerServing, this.protein);
}
