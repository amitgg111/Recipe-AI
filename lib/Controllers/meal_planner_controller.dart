import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
import 'package:recipe_ai/Helper/recipe_response_parser.dart';
import 'package:recipe_ai/Service/auth_service.dart';
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
    aiUsed.value = false;
    _pool.clear();
    meals.clear();
    final planCtrl = Get.find<MealPlanController>();
    final weekStart = planCtrl.selectedWeekStart.value;
    allowedDays = _allowedDayIndices(weekStart);
    if (allowedDays.isEmpty) {
      // Entire visible week is already in the past — nothing to generate.
      meals.value = [];
      steps.value = [
        GenStep('Nothing left to plan this week', MpStepState.done),
      ];
      return;
    }

    // Steps are revealed progressively; the AI step only appears if used.
    steps.value = [
      GenStep('Reading your preferences'),
      GenStep('Searching your Cookbook'),
      GenStep('Searching Community Recipes'),
      GenStep('Building your weekly meal plan'),
    ];

    // Step 1 — preferences.
    await _run(0, minMs: 500);

    // Step 2 — Cookbook (Priority 1). Never touch the network yet.
    steps[1].state = MpStepState.active;
    steps.refresh();
    final cookbook = searchCookbook();
    _pool.addAll(cookbook);
    await _settle(600);
    steps[1].state = MpStepState.done;
    steps.refresh();

    // Step 3 — Community (Priority 2). Only if the Cookbook isn't enough.
    steps[2].state = MpStepState.active;
    steps.refresh();
    if (_pool.length < target) {
      final community = await searchCommunityRecipes();
      mergeInto(_pool, community);
    }
    await _settle(600);
    steps[2].state = MpStepState.done;
    steps.refresh();

    // Step 4 — AI (Priority 3, LAST resort). Only the missing recipes.
    if (_pool.length < target) {
      aiUsed.value = true;
      // Insert the AI step before "Building…".
      steps.insert(
        3,
        GenStep('Generating missing recipes', MpStepState.active),
      );
      steps.refresh();
      final missing = target - _pool.length;
      final generated = await generateMissingRecipes(missing);
      mergeInto(_pool, generated);
      steps[3].state = MpStepState.done;
      steps.refresh();
    }

    // Final step — build & balance the week (always succeeds).
    final buildIdx = steps.length - 1;
    steps[buildIdx].state = MpStepState.active;
    steps.refresh();
    balanceMeals();
    await _settle(700);
    steps[buildIdx].state = MpStepState.done;
    steps.refresh();

    // Persist the generated week as a draft so it survives leaving the review
    // screen without applying (recoverable from Firebase, no longer memory-only).
    await _saveDraft();
  }

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
  Future<List<PlanRecipe>> generateMissingRecipes(int count) async {
    final n = math.min(count, _aiCap);
    final out = <PlanRecipe>[];

    final selectedGoals = goals.isNotEmpty ? goals : [goal.value];
    final extra = customPrompt.trim();
    final cuisine = selectedCuisine.trim();

    final slotCycle = ['breakfast', 'lunch', 'dinner'];

    for (var i = 0; i < n; i++) {
      final meal = slotCycle[i % slotCycle.length];

      // Rotate through selected goals
      final bias = selectedGoals[i % selectedGoals.length].aiBias;

      final name = [
        bias,
        if (cuisine.isNotEmpty) cuisine,
        if (extra.isNotEmpty) extra,
        meal,
        'recipe idea ${i + 1}',
      ].join(' ');

      try {
        final recipe = await RecipeImportService.getRecipeFromName(name);

        final pr = PlanRecipe.fromMap(
          'ai_${DateTime.now().microsecondsSinceEpoch}_$i',
          recipe,
          PlanSource.ai,
        );

        if (pr.title.trim().isNotEmpty) {
          out.add(pr);
        }
      } catch (_) {
        // Skip failed generation; plan continues
      }
    }

    return out;
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
  void shuffleMeal(int day, String slot) {
    if (!allowedDays.contains(day)) return; // never touch a past day

    if (_pool.length < 2) return;
    final current = _mealAt(day, slot);
    final sameDay = meals
        .where((m) => m.day == day && m.slot != slot)
        .map((m) => m.recipe.dedupeKey)
        .toSet();
    // Prefer other days' usage low, respect source priority order.
    final candidates = [..._pool]
      ..removeWhere(
        (r) =>
            r.dedupeKey == current.recipe.dedupeKey ||
            sameDay.contains(r.dedupeKey),
      )
      ..sort((a, b) => a.source.index.compareTo(b.source.index));
    if (candidates.isEmpty) return;
    // Pick randomly among the top-priority tier for variety.
    final topTier = candidates
        .where((r) => r.source == candidates.first.source)
        .toList();
    current.recipe = topTier[_rand.nextInt(topTier.length)];
    meals.refresh();
  }

  void shuffleDay(int day) {
    if (!allowedDays.contains(day)) return;
    for (final slot in slots) {
      shuffleMeal(day, slot);
    }
  }

  void shuffleWeek() {
    balanceMeals();
    _saveDraft(); // keep the recoverable draft in sync
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
      if (_dateOnly(date).isBefore(today))
        continue; // hard guard: skip past dates

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
