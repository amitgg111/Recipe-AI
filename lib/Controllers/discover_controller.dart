import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:recipe_ai/Service/recipe_social_service.dart';
// `IngredientSection` (named group of ingredients, e.g. "For the batter")
// is the app's existing model — reused here rather than redeclared, so this
// file stays compatible with HomeController / RecipeEditorController /
// RecipeDetailScreen, which all import this same class from here. Declaring
// a second class with the same name in this file previously caused an
// "ambiguous import" error in every file that imported both this file and
// recipe_section_model.dart (HomeController does).
import 'package:recipe_ai/Model/recipe_section_model.dart';

class DiscoverRecipe {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? category;
  final String? cuisine;
  final String? prepTime;
  final String? cookTime;
  final String? totalTime;
  final String? servings;
  final List<String> ingredients;

  /// Optional grouped view of [ingredients] (e.g. "For the batter" / "For
  /// the tempering"). Empty when the recipe was authored/imported with a
  /// flat ingredient list only — callers should fall back to [ingredients]
  /// in that case.
  final List<IngredientSection> ingredientSections;

  final List<String> instructions;
  final String userId;
  final String userName;
  final String? userAvatar;
  final DateTime? createdAt;

  /// When the recipe was made public (shared to Discover). Discover shows the
  /// "x ago" from this, not [createdAt], so it reflects the share time — not
  /// when the recipe was originally authored. Null on legacy recipes published
  /// before this was tracked; callers fall back to [createdAt].
  final DateTime? publishedAt;

  // Social engagement counters (stored on the recipe document).
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int savesCount;

  // English originals, kept when [title]/[category]/[cuisine] hold a
  // translated value for display. The chip filters (Quick & Easy/Vegan/
  // Desserts…) and category matching are defined in English, so they read
  // these — null falls back to the main field, which for an untranslated
  // recipe already IS English.
  final String? enTitle;
  final String? enDescription;
  final String? enCategory;
  final String? enCuisine;

  String get filterTitle => enTitle ?? title;

  /// English original of [description]. The feed sets it when it
  /// translates; an untranslated model's description already IS English.
  /// Detail screens translate from this so a translated description can
  /// never be fed back through ML Kit a second time.
  String? get filterDescription => enDescription ?? description;
  String get filterCategory => enCategory ?? category ?? '';
  String get filterCuisine => enCuisine ?? cuisine ?? '';

  DiscoverRecipe({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.category,
    this.cuisine,
    this.prepTime,
    this.cookTime,
    this.totalTime,
    this.servings,
    this.ingredients = const [],
    this.ingredientSections = const [],
    this.instructions = const [],
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.createdAt,
    this.publishedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.savesCount = 0,
    this.enTitle,
    this.enDescription,
    this.enCategory,
    this.enCuisine,
  });

  DiscoverRecipe copyWith({
    String? title,
    String? description,
    String? imageUrl,
    String? category,
    String? cuisine,
    String? prepTime,
    String? cookTime,
    String? totalTime,
    String? servings,
    List<String>? ingredients,
    List<IngredientSection>? ingredientSections,
    List<String>? instructions,
    String? userId,
    String? userName,
    String? userAvatar,
    DateTime? createdAt,
    DateTime? publishedAt,

    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? savesCount,

    String? enTitle,
    String? enDescription,
    String? enCategory,
    String? enCuisine,
  }) {
    return DiscoverRecipe(
      id: id,

      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      cuisine: cuisine ?? this.cuisine,

      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      totalTime: totalTime ?? this.totalTime,
      servings: servings ?? this.servings,

      ingredients: ingredients ?? this.ingredients,
      ingredientSections: ingredientSections ?? this.ingredientSections,
      instructions: instructions ?? this.instructions,

      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,

      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      savesCount: savesCount ?? this.savesCount,

      enTitle: enTitle ?? this.enTitle,
      enDescription: enDescription ?? this.enDescription,
      enCategory: enCategory ?? this.enCategory,
      enCuisine: enCuisine ?? this.enCuisine,
    );
  }
}

/// A snapshot of one Discover filter's loaded feed, so returning to a
/// previously-viewed tab ("All" or a category/cuisine) restores instantly with
/// no re-fetch and no loading spinner.
class _DiscoverFilterCache {
  final List<DiscoverRecipe> recipes;
  final List<DiscoverRecipe> english;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
  final Set<String> liked;
  final Set<String> saved;

  _DiscoverFilterCache(
    this.recipes,
    this.english,
    this.cursor,
    this.hasMore,
    this.liked,
    this.saved,
  );
}

class DiscoverController extends GetxController {
  final RxList<DiscoverRecipe> recipes = <DiscoverRecipe>[].obs;
  final RxBool isLoading = true.obs;
  static const int _pageSize = 20;

  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;

  bool _hasMore = true;
  bool _isLoadingMore = false;
  // ------------------------------------------------------------
  // Category-specific pagination
  // ------------------------------------------------------------

  String _activeFirestoreFilter = 'All';

  DocumentSnapshot<Map<String, dynamic>>? _categoryLastDocument;

  bool _categoryHasMore = true;

  bool _categoryLoading = false;

  static const int _categoryPageSize = 20;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  // English originals of the feed (Firestore is English). [recipes] holds
  // the translated-for-display copies; re-translation always starts from
  // here.
  final List<DiscoverRecipe> _english = [];

  // Onboarding-selected cuisines. NOTE: these are no longer used to
  // prioritize/sort the feed — the feed is always newest-first. They are
  // used ONLY to build the extra cuisine chips shown right after "All" in
  // [categories], so the user's preferred cuisines are one tap away.
  final RxList<String> _preferredCuisines = <String>[].obs;

  List<String> get preferredCuisines => _preferredCuisines.toList();

  /// The pre-translation (English) copy of a feed recipe, for logic that
  /// must key off English — e.g. ingredient→emoji matching, which uses an
  /// English keyword dictionary and would miss on a translated name. Null
  /// when the recipe isn't in the loaded feed; callers then fall back to
  /// the visible text.
  DiscoverRecipe? englishById(String id) {
    for (final r in _english) {
      if (r.id == id) return r;
    }
    return null;
  }

  List<String> _categoryAliases(String category) {
    final key = category.trim().toLowerCase();

    switch (key) {
      case 'vegan':
        return ['vegan', 'Vegan', 'VEGAN'];

      case 'desserts':
        return ['dessert', 'Dessert', 'desserts', 'Desserts', 'sweet', 'Sweet'];

      case 'breakfast':
        return ['breakfast', 'Breakfast'];

      case 'lunch':
        return ['lunch', 'Lunch'];

      case 'dinner':
        return ['dinner', 'Dinner'];

      case 'drinks':
        return [
          'drink',
          'Drink',
          'drinks',
          'Drinks',
          'beverage',
          'Beverage',
          'beverages',
          'Beverages',
        ];

      default:
        return [category];
    }
  }

  Future<void> fetchCategoryRecipes({
    required String category,
    bool refresh = false,
  }) async {
    if (_categoryLoading) return;

    final normalizedCategory = category.trim();

    if (normalizedCategory.isEmpty ||
        normalizedCategory.toLowerCase() == 'all') {
      return;
    }

    // ------------------------------------------------------------
    // RESET CATEGORY
    // ------------------------------------------------------------

    if (refresh || _activeFirestoreFilter != normalizedCategory) {
      _categoryLastDocument = null;
      _categoryHasMore = true;
      _activeFirestoreFilter = normalizedCategory;

      recipes.clear();
      _english.clear();

      likedOriginalIds.clear();
      savedOriginalIds.clear();

      isLoading.value = true;
    }

    if (!_categoryHasMore) {
      isLoading.value = false;
      return;
    }

    _categoryLoading = true;
    _isLoadingMore = _categoryLastDocument != null;

    try {
      final aliases = _categoryAliases(normalizedCategory);

      final isBaseCategory = _isBaseCategory(normalizedCategory);

      final List<DiscoverRecipe> allCategoryRecipes = [];

      log(
        '🔎 Fetching [$normalizedCategory] | '
        'type=${isBaseCategory ? 'CATEGORY' : 'CUISINE'} | '
        'aliases=$aliases',
      );

      // ------------------------------------------------------------
      // FIRESTORE QUERY
      // ------------------------------------------------------------

      for (final alias in aliases) {
        Query<Map<String, dynamic>> query;

        if (isBaseCategory) {
          // --------------------------------------------------------
          // CATEGORY
          // Vegan / Desserts / Breakfast / Lunch / Dinner / Drinks
          // --------------------------------------------------------

          query = FirebaseFirestore.instance
              .collection('recipes')
              .where('isPublic', isEqualTo: true)
              .where('category', isEqualTo: alias)
              .limit(_categoryPageSize);
        } else {
          // --------------------------------------------------------
          // CUISINE
          // North Indian / South Indian / Italian / Mexican etc.
          // --------------------------------------------------------

          query = FirebaseFirestore.instance
              .collection('recipes')
              .where('isPublic', isEqualTo: true)
              .where('cuisine', isEqualTo: alias)
              .limit(_categoryPageSize);
        }

        final snapshot = await query.get();

        log(
          '🔎 Firestore [$alias] -> '
          '${snapshot.docs.length} documents',
        );

        // ----------------------------------------------------------
        // DEBUG EACH DOCUMENT
        // ----------------------------------------------------------

        for (final doc in snapshot.docs) {
          final data = doc.data();

          log(
            '🍛 Recipe: ${data['title']} | '
            'category=${data['category']} | '
            'cuisine=${data['cuisine']} | '
            'isPublic=${data['isPublic']}',
          );
        }

        if (snapshot.docs.isNotEmpty) {
          final parsed = await _documentsToDiscoverRecipes(snapshot.docs);

          allCategoryRecipes.addAll(parsed);
        }
      }

      // ------------------------------------------------------------
      // REMOVE DUPLICATES
      // ------------------------------------------------------------

      final unique = <String, DiscoverRecipe>{};

      for (final recipe in allCategoryRecipes) {
        unique[recipe.id] = recipe;
      }

      final newRecipes = unique.values.toList();

      // ------------------------------------------------------------
      // NEWEST FIRST
      // ------------------------------------------------------------

      newRecipes.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      // ------------------------------------------------------------
      // REMOVE ALREADY LOADED
      // ------------------------------------------------------------

      final existingIds = _english.map((e) => e.id).toSet();

      final filteredNewRecipes = newRecipes
          .where((recipe) => !existingIds.contains(recipe.id))
          .toList();

      // ------------------------------------------------------------
      // APPEND
      // ------------------------------------------------------------

      if (filteredNewRecipes.isNotEmpty) {
        _english.addAll(filteredNewRecipes);

        await _processAndAppend(filteredNewRecipes);

        _sortDiscoverRecipes();
      }

      // ------------------------------------------------------------
      // NO RESULTS
      // ------------------------------------------------------------

      if (filteredNewRecipes.isEmpty) {
        _categoryHasMore = false;

        log(
          '⚠️ Category [$normalizedCategory] '
          'returned 0 NEW recipes',
        );
      } else {
        log(
          '🍽️ Category [$normalizedCategory] '
          'loaded ${filteredNewRecipes.length} recipes',
        );
      }

      // ------------------------------------------------------------
      // END
      // ------------------------------------------------------------

      if (newRecipes.length < _categoryPageSize) {
        _categoryHasMore = false;
      }
    } catch (e, stack) {
      log(
        '❌ Category recipe fetch failed '
        '[$normalizedCategory]: $e',
      );

      log(stack.toString());
    } finally {
      _categoryLoading = false;
      _isLoadingMore = false;
      isLoading.value = false;
    }
  }

  bool _isBaseCategory(String value) {
    return _baseCategories.any(
      (category) => category.toLowerCase() == value.trim().toLowerCase(),
    );
  }

  Future<void> _loadPreferredCuisines() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      _preferredCuisines.clear();
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        _preferredCuisines.clear();
        return;
      }

      final data = userDoc.data() ?? {};

      final onboarding = data['onboarding'] as Map<String, dynamic>? ?? {};

      final cuisines = onboarding['cuisines'];

      if (cuisines is List) {
        _preferredCuisines.assignAll(
          cuisines
              .map((e) => e.toString().trim().toLowerCase())
              .where((e) => e.isNotEmpty && e != 'a bit of everything')
              .toList(),
        );
      } else {
        _preferredCuisines.clear();
      }

      log(
        '🍽️ Discover preferred cuisines: '
        '${_preferredCuisines.join(', ')}',
      );
    } catch (e, stack) {
      log('❌ Failed to load preferred cuisines: $e');
      log(stack.toString());

      _preferredCuisines.clear();
    }
  }

  /// Re-reads the user's onboarding cuisines (e.g. after they update them
  /// from Settings → Cuisine Preferences) and rebuilds the chip row.
  /// Does NOT touch the loaded feed — the feed itself never depends on
  /// cuisine preference, only on latest-first ordering.
  Future<void> refreshPreferredCuisines() async {
    await _loadPreferredCuisines();
  }

  String _normalizeCuisine(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _canonicalCuisine(String value) {
    final normalized = _normalizeCuisine(value);

    if (normalized.isEmpty) return '';

    return normalized
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  void updateRecipeSocial(
    String recipeId, {
    int? likes,
    int? saves,
    int? comments,
    bool? liked,
    bool? saved,
  }) {
    final index = recipes.indexWhere((r) => r.id == recipeId);

    if (index != -1) {
      final old = recipes[index];

      recipes[index] = old.copyWith(
        likesCount: likes ?? old.likesCount,
        savesCount: saves ?? old.savesCount,
        commentsCount: comments ?? old.commentsCount,
      );

      recipes.refresh();
    }

    // IMPORTANT:
    // PublicRecipeViewScreen -> DiscoverScreen
    // like state must also update the shared RxSet.
    if (liked != null) {
      if (liked) {
        likedOriginalIds.add(recipeId);
      } else {
        likedOriginalIds.remove(recipeId);
      }

      likedOriginalIds.refresh();
    }

    // Same for save/bookmark state.
    if (saved != null) {
      if (saved) {
        savedOriginalIds.add(recipeId);
      } else {
        savedOriginalIds.remove(recipeId);
      }

      savedOriginalIds.refresh();
    }
  }

  /// Translate the CARD fields (title/description/category/cuisine) of
  /// every feed recipe into the current language, keeping the English
  /// originals for chip filtering. Ingredients/instructions are left
  /// English here and translated lazily by [translateForDetail] when a
  /// recipe is opened — so the feed stays fast even with a couple hundred
  /// recipes. No-op for English.
  Future<List<DiscoverRecipe>> _translateForFeed(
    List<DiscoverRecipe> list,
  ) async {
    if (list.isEmpty || !AiTranslationService.isTranslating) return list;

    // First attempt — normally instant, since onLanguageChanged() already
    // ran right before this in _applyContentLanguage.
    var ready = await AiTranslationService.ensureReady().timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );

    if (!ready) {
      // A slow model download can still be finishing in the background
      // (ensureReady()'s `_preparing` future keeps running past our
      // timeout — only the wait gave up, not the download). Give it one
      // more, longer window instead of permanently falling back to English
      // with no retry.
      log('⚠️ Discover: translator not ready in 5s, retrying once (10s)…');
      ready = await AiTranslationService.ensureReady().timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
    }

    if (!ready) {
      log('❌ Discover: translator still not ready — showing English for now');
      return list;
    }

    return Future.wait(
      list.map((r) async {
        return r.copyWith(
          title: await AiTranslationService.translate(r.title),
          description: r.description == null
              ? null
              : await AiTranslationService.translate(r.description),
          category: r.category == null
              ? null
              : await AiTranslationService.translate(r.category),
          cuisine: r.cuisine == null
              ? null
              : await AiTranslationService.translate(r.cuisine),
          enTitle: r.title,
          enDescription: r.description,
          enCategory: r.category,
          enCuisine: r.cuisine,
        );
      }),
    );
  }

  /// Translate a single recipe's ingredients + steps for the detail screen.
  /// Called on card tap so the (potentially long) lists are only translated
  /// for the one recipe actually opened. Also translates [ingredientSections]
  /// (both the group name and each item) when present.
  Future<DiscoverRecipe> translateForDetail(DiscoverRecipe r) async {
    if (!AiTranslationService.isTranslating) return r;

    final translatedIngredients = await AiTranslationService.translateList(
      r.ingredients,
    );
    final translatedInstructions = await AiTranslationService.translateList(
      r.instructions,
    );

    var translatedSections = r.ingredientSections;

    if (r.ingredientSections.isNotEmpty) {
      translatedSections = await Future.wait(
        r.ingredientSections.map((section) async {
          final sectionName = section.name?.trim();

          final name = sectionName == null || sectionName.isEmpty
              ? section.name
              : await AiTranslationService.translate(sectionName);
          final items = await AiTranslationService.translateList(section.items);
          return section.copyWith(name: name, items: items);
        }),
      );
    }

    return r.copyWith(
      ingredients: translatedIngredients,
      instructions: translatedInstructions,
      ingredientSections: translatedSections,
    );
  }

  /// Re-translate the loaded feed after the app language changes.
  Future<void> refreshLanguage() async {
    recipes.assignAll(await _translateForFeed(_english));
    // The new language starts with an empty cache for the detail strings
    // too, so warm them again in the background.
    unawaited(_prewarmDetails(_english));
  }

  final RxString selectedCategory = ''.obs;
  final RxString searchQuery = ''.obs;

  /// Original Discover recipe ids the current user has saved. Bookmarks
  /// observe this set so the saved icon flips live — e.g. when the saved
  /// copy is deleted from My Recipes / a cookbook, that path removes the id
  /// and the icon updates.
  final RxSet<String> savedOriginalIds = <String>{}.obs;

  /// Original Discover recipe ids the current user has liked. Populated in
  /// one batched read per feed load (see [_loadSocialStates]) instead of
  /// each _RecipeCard querying Firestore individually — that per-card
  /// querying was the cause of the feed feeling slow/heavy to load.
  final RxSet<String> likedOriginalIds = <String>{}.obs;

  // Fixed chips shown after "All" and after the user's onboarding-cuisine
  // chips. See [categories] for how the full, dynamic chip row is built.
  final List<String> _baseCategories = [
    'Quick & Easy',
    'Vegan',
    'Desserts',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Drinks',
  ];

  /// Full, dynamic set of Discover filter chips:
  ///   All → <user's onboarding cuisines, in order> → Quick & Easy → Vegan
  ///   → Desserts → Breakfast → Lunch → Dinner → Drinks
  ///
  /// The cuisine chips come from [preferredCuisines] (onboarding selection)
  /// and are de-duplicated + title-cased for display. This list updates
  /// automatically whenever [_preferredCuisines] changes (feed refresh, or
  /// [refreshPreferredCuisines] after the user edits their cuisines in
  /// Settings) since it's built from the reactive list.
  List<String> get categories {
    final chips = <String>['All'];

    final seen = <String>{};
    for (final pref in preferredCuisines) {
      final label = _canonicalCuisine(pref);
      if (label.isEmpty) continue;
      final key = label.toLowerCase();
      if (seen.add(key)) {
        chips.add(label);
      }
    }

    chips.addAll(_baseCategories);
    return chips;
  }

  StreamSubscription? _authSub;
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
  _socialCountSubscriptions = {};
  @override
  void onInit() {
    super.onInit();

    selectedCategory.value = 'All';

    _authSub = AuthService.authStateChanges.listen((user) {
      if (user != null) {
        fetchDiscoverRecipes(refresh: true);
      } else {
        recipes.clear();
        _english.clear();
        for (final subscription in _socialCountSubscriptions.values) {
          subscription.cancel();
        }

        _socialCountSubscriptions.clear();
        likedOriginalIds.clear();
        savedOriginalIds.clear();

        _preferredCuisines.clear();

        _lastDocument = null;
        _hasMore = true;
      }
    });

    fetchDiscoverRecipes(refresh: true);
  }

  @override
  void onClose() {
    _authSub?.cancel();

    for (final subscription in _socialCountSubscriptions.values) {
      subscription.cancel();
    }

    _socialCountSubscriptions.clear();

    super.onClose();
  }

  // Guards against overlapping fetches (onInit + the auth listener can both
  // fire on startup) so the feed isn't queried twice at once.
  bool _fetching = false;

  void _listenToRecipeSocialCounts(List<DiscoverRecipe> loadedRecipes) {
    for (final recipe in loadedRecipes) {
      if (_socialCountSubscriptions.containsKey(recipe.id)) {
        continue;
      }

      final subscription = FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipe.id)
          .snapshots()
          .listen(
            (snapshot) {
              if (!snapshot.exists) return;

              final data = snapshot.data();
              if (data == null) return;

              final index = recipes.indexWhere((r) => r.id == recipe.id);

              if (index == -1) return;

              final old = recipes[index];

              final updated = old.copyWith(
                likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
                commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
                sharesCount: (data['sharesCount'] as num?)?.toInt() ?? 0,
                savesCount: (data['savesCount'] as num?)?.toInt() ?? 0,
              );

              recipes[index] = updated;
              recipes.refresh();

              // Keep English copy in sync too.
              final englishIndex = _english.indexWhere(
                (r) => r.id == recipe.id,
              );

              if (englishIndex != -1) {
                _english[englishIndex] = _english[englishIndex].copyWith(
                  likesCount: updated.likesCount,
                  commentsCount: updated.commentsCount,
                  sharesCount: updated.sharesCount,
                  savesCount: updated.savesCount,
                );
              }
            },
            onError: (error) {
              log(
                '❌ Realtime social count listener failed '
                'for ${recipe.id}: $error',
              );
            },
          );

      _socialCountSubscriptions[recipe.id] = subscription;
    }
  }

  /// Batch-loads which of [loaded] recipes the current user has
  /// liked/saved — ONE Firestore query each for the whole feed, instead of
  /// every _RecipeCard firing its own isLiked/isSaved read on build.

  Future<void> _loadSocialStates(List<DiscoverRecipe> loaded) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || uid.isEmpty || loaded.isEmpty) {
      return;
    }

    final ids = loaded.map((r) => r.id).toSet();

    try {
      final results = await Future.wait([
        RecipeSocialService.getLikedIds(uid, ids),
        RecipeSocialService.getSavedIds(uid, ids),
      ]);

      likedOriginalIds.addAll(results[0]);
      savedOriginalIds.addAll(results[1]);
    } catch (e) {
      log('Discover social-state batch load failed: $e');
    }
  }

  /// Translates, appends to [recipes]/[_english], loads social state and
  /// prewarms detail strings for one page of fetched recipes.
  Future<void> _processAndAppend(List<DiscoverRecipe> chunk) async {
    if (chunk.isEmpty) return;

    final translated = await _translateForFeed(chunk);

    recipes.addAll(translated);

    // Batch load for liked/saved state.
    await _loadSocialStates(chunk);

    // Realtime likes/comments/shares/saves counts.
    _listenToRecipeSocialCounts(chunk);

    unawaited(_prewarmDetails(chunk));
  }

  /// Fetches the Discover feed strictly newest-first, page by page. Cuisine
  /// preference is intentionally NOT used to reorder or prioritize
  /// anything here anymore — it only feeds the chip row (see [categories]).
  Future<void> fetchDiscoverRecipes({bool refresh = false}) async {
    if (_fetching || _isLoadingMore) return;

    if (refresh) {
      _fetching = true;

      try {
        // Still load onboarding cuisines — needed to build the chip row —
        // but no longer to influence sort order.
        await _loadPreferredCuisines();

        // Reset feed.
        _lastDocument = null;
        _hasMore = true;

        _categoryLastDocument = null;
        _categoryHasMore = true;
        _activeFirestoreFilter = 'All';

        recipes.clear();
        _english.clear();

        likedOriginalIds.clear();
        savedOriginalIds.clear();

        isLoading.value = true;
      } catch (e, stack) {
        log('❌ Discover refresh preparation failed: $e');
        log(stack.toString());

        _fetching = false;
        isLoading.value = false;
        return;
      }

      _fetching = false;
    }

    if (!_hasMore) return;

    final isFirstPage = _lastDocument == null;

    if (isFirstPage) {
      _fetching = true;
      isLoading.value = true;
    } else {
      _isLoadingMore = true;
    }

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('recipes')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
        return;
      }

      _lastDocument = snapshot.docs.last;

      if (snapshot.docs.length < _pageSize) {
        _hasMore = false;
      }

      final newRecipes = await _documentsToDiscoverRecipes(snapshot.docs);

      if (newRecipes.isEmpty) {
        if (_hasMore) {
          await fetchDiscoverRecipes();
        }
        return;
      }

      _english.addAll(newRecipes);

      await _processAndAppend(newRecipes);

      _sortDiscoverRecipes();
    } catch (e, stack) {
      log('❌ Discover pagination fetch failed: $e');
      log(stack.toString());
    } finally {
      isLoading.value = false;
      _fetching = false;
      _isLoadingMore = false;
    }
  }

  Future<List<DiscoverRecipe>> _documentsToDiscoverRecipes(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (docs.isEmpty) return [];

    final ownerIds = <String>{};

    for (final doc in docs) {
      final data = doc.data();
      log(
        '🍛 ${doc.id} | '
        'title=${data['title']} | '
        'category=${data['category']} | '
        'cuisine=${data['cuisine']} | '
        'isPublic=${data['isPublic']}',
      );
      final ownerId = data['ownerId']?.toString();

      if (ownerId != null && ownerId.isNotEmpty) {
        ownerIds.add(ownerId);
      }
      log('🔍 ${data['title']} -> cuisine=${data['cuisine']}');
    }

    final userProfiles = <String, Map<String, dynamic>>{};

    if (ownerIds.isNotEmpty) {
      final userDocs = await Future.wait(
        ownerIds.map(
          (uid) =>
              FirebaseFirestore.instance.collection('users').doc(uid).get(),
        ),
      );

      for (final userDoc in userDocs) {
        if (userDoc.exists) {
          userProfiles[userDoc.id] = userDoc.data() ?? {};
        }
      }
    }

    final result = <DiscoverRecipe>[];

    for (final recipeDoc in docs) {
      final data = recipeDoc.data();

      if (data['isDeleted'] == true) {
        continue;
      }

      final ownerId = data['ownerId']?.toString() ?? '';

      final ownerData = userProfiles[ownerId] ?? {};

      // ingredientSections: array of { name: string, items: string[] }.
      // Stored alongside the flat `ingredients` array — not every recipe
      // has it (older/imported recipes only have the flat list), so this
      // safely falls back to an empty list when absent or malformed.
      List<IngredientSection> sections = const [];
      final rawSections = data['ingredientSections'];
      if (rawSections is List) {
        sections = rawSections
            .whereType<Map>()
            .map((e) => IngredientSection.fromMap(Map<String, dynamic>.from(e)))
            .where((s) => s.items.isNotEmpty)
            .toList();
      }

      result.add(
        DiscoverRecipe(
          id: recipeDoc.id,
          title: data['title']?.toString() ?? 'Untitled',
          description: data['description']?.toString(),
          imageUrl: data['imageUrl']?.toString(),
          category: data['category']?.toString(),
          cuisine: data['cuisine']?.toString(),
          prepTime: data['prepTime']?.toString(),
          cookTime: data['cookTime']?.toString(),
          totalTime: data['totalTime']?.toString(),
          servings: data['servings']?.toString(),
          ingredients: List<String>.from(data['ingredients'] ?? const []),
          ingredientSections: sections,

          instructions: List<String>.from(data['instructions'] ?? const []),
          userId: ownerId,
          userName: ownerData['name']?.toString() ?? 'Chef',
          userAvatar: ownerData['photoUrl']?.toString(),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
          likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
          commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
          sharesCount: (data['sharesCount'] as num?)?.toInt() ?? 0,
          savesCount: (data['savesCount'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    return result;
  }

  /// Strictly newest-first. No cuisine-based prioritization.
  void _sortDiscoverRecipes() {
    recipes.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
  }

  /// Pre-translate what the DETAIL screen will need for [list], in the
  /// background, right after a feed page lands.
  ///
  /// The feed itself only translates card fields (title/description/
  /// category/cuisine). Ingredients and instructions are left English, so
  /// opening a recipe used to hit a cold cache and render English for a
  /// beat before filling in. Splash-time prewarming cannot help either: it
  /// queries ownerId == uid while the feed is isPublic == true — disjoint
  /// sets, so public recipes were never warmed by anything.
  ///
  /// Also prewarms ingredientSections (group names + items) so grouped
  /// ingredient cards don't show a beat of English either.
  ///
  /// Runs unawaited and strictly after the page is on screen, so it never
  /// delays the feed. translateList de-duplicates and writes the cache once.
  Future<void> _prewarmDetails(List<DiscoverRecipe> list) async {
    if (list.isEmpty || !AiTranslationService.isTranslating) return;
    try {
      final texts = <String>[];
      for (final r in list) {
        texts.addAll(r.ingredients);
        texts.addAll(r.instructions);
        for (final section in r.ingredientSections) {
          final sectionName = section.name?.trim();

          if (sectionName != null && sectionName.isNotEmpty) {
            texts.add(sectionName);
          }
          texts.addAll(section.items);
        }
        final t = r.prepTime;
        if (t != null && t.trim().isNotEmpty) texts.add(t);
        final c = r.cookTime;
        if (c != null && c.trim().isNotEmpty) texts.add(c);
        final o = r.totalTime;
        if (o != null && o.trim().isNotEmpty) texts.add(o);
      }
      if (texts.isEmpty) return;
      await AiTranslationService.translateList(texts);
      log('🔥 Discover: prewarmed ${texts.length} detail string(s)');
    } catch (e) {
      log('Discover detail prewarm failed: $e');
    }
  }

  // Future<void> loadMoreRecipes() async {
  //   if (_fetching || _isLoadingMore || !_hasMore) return;

  //   await fetchDiscoverRecipes();
  // }
  Future<void> loadMoreRecipes() async {
    if (_fetching || _isLoadingMore) return;

    final category = selectedCategory.value.trim();

    // ------------------------------------------------------------
    // ALL
    // ------------------------------------------------------------

    if (category.isEmpty || category == 'All') {
      if (!_hasMore) return;

      await fetchDiscoverRecipes();

      return;
    }

    // ------------------------------------------------------------
    // QUICK & EASY
    // ------------------------------------------------------------

    if (category == 'Quick & Easy') {
      /*
     * Quick & Easy uses the normal feed and filters by time.
     *
     * If there aren't enough quick recipes loaded,
     * load another normal page.
     */

      if (!_hasMore) return;

      await fetchDiscoverRecipes();

      return;
    }

    // ------------------------------------------------------------
    // CATEGORY
    // ------------------------------------------------------------

    if (!_categoryHasMore || _categoryLoading) {
      return;
    }

    await fetchCategoryRecipes(category: category, refresh: false);
  }

  List<DiscoverRecipe> get filteredRecipes {
    var list = recipes.toList();

    final sel = selectedCategory.value.trim();

    /*
   * IMPORTANT:
   *
   * Category-specific recipes are now fetched directly from Firestore.
   *
   * Therefore we should NOT again filter them using title/category
   * keywords here.
   */

    switch (sel) {
      case '':
      case 'All':
        break;

      case 'Quick & Easy':
        list = list.where((r) {
          final m = _minutes(r);
          return m != null && m <= 30;
        }).toList();
        break;

      default:
        /*
       * For:
       *
       * Vegan
       * Desserts
       * Breakfast
       * Lunch
       * Dinner
       * Drinks
       *
       * Firestore has already filtered the recipes.
       *
       * So do nothing here.
       */
        break;
    }

    // Search still works on loaded recipes.
    if (searchQuery.value.trim().isNotEmpty) {
      final q = searchQuery.value.trim().toLowerCase();

      list = list.where((r) {
        final hay =
            '${r.title} '
                    '${r.category ?? ''} '
                    '${r.cuisine ?? ''} '
                    '${r.filterTitle} '
                    '${r.filterCategory} '
                    '${r.filterCuisine}'
                .toLowerCase();

        return hay.contains(q);
      }).toList();
    }

    list.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    return list;
  }

  /// True when any [keywords] appear in the recipe's title / category /
  /// cuisine.

  /// Best-effort minutes parsed from a time string ("30 min", "1 hour 20
  /// mins", "1h 30m"). Returns null when no duration can be read.
  int? _minutes(DiscoverRecipe r) {
    final t = (r.totalTime?.isNotEmpty ?? false)
        ? r.totalTime!
        : (r.cookTime?.isNotEmpty ?? false)
        ? r.cookTime!
        : (r.prepTime ?? '');
    final s = t.toLowerCase();
    if (s.trim().isEmpty) return null;

    var total = 0;
    var found = false;
    final hr = RegExp(r'(\d+)\s*(?:h|hr|hrs|hour|hours)').firstMatch(s);
    if (hr != null) {
      total += int.parse(hr.group(1)!) * 60;
      found = true;
    }
    final mn = RegExp(r'(\d+)\s*(?:m|min|mins|minute|minutes)').firstMatch(s);
    if (mn != null) {
      total += int.parse(mn.group(1)!);
      found = true;
    }
    if (!found) {
      final n = RegExp(r'(\d+)').firstMatch(s);
      if (n != null) {
        total = int.parse(n.group(1)!);
        found = true;
      }
    }
    return found ? total : null;
  }

  // ── Per-filter cache (instant tab switching) ─────────────────────────────
  // Remembers each filter's loaded feed + pagination cursor so returning to a
  // tab shows its data immediately, instead of clearing the list and showing a
  // spinner while it re-fetches from Firestore.
  final Map<String, _DiscoverFilterCache> _filterCache = {};

  String _filterKey(String filter) => filter.trim().toLowerCase();

  /// Saves the currently-loaded filter's feed into the cache before switching
  /// away, so it can be restored instantly later.
  void _snapshotCurrentFilter() {
    if (recipes.isEmpty) return;
    final key = _filterKey(_activeFirestoreFilter);
    final isAll = key == 'all';
    _filterCache[key] = _DiscoverFilterCache(
      List.of(recipes),
      List.of(_english),
      isAll ? _lastDocument : _categoryLastDocument,
      isAll ? _hasMore : _categoryHasMore,
      Set.of(likedOriginalIds),
      Set.of(savedOriginalIds),
    );
  }

  /// Restores a cached filter's feed instantly (no clear, no spinner) and tops
  /// up its liked/saved state from Firestore in the background.
  void _restoreFilter(String category) {
    final key = _filterKey(category);
    final cached = _filterCache[key];
    if (cached == null) return;
    final isAll = key == 'all';

    recipes.assignAll(cached.recipes);
    _english
      ..clear()
      ..addAll(cached.english);

    _activeFirestoreFilter = isAll ? 'All' : category.trim();
    if (isAll) {
      _lastDocument = cached.cursor;
      _hasMore = cached.hasMore;
    } else {
      _categoryLastDocument = cached.cursor;
      _categoryHasMore = cached.hasMore;
    }
    // Restore the cached liked/saved state SYNCHRONOUSLY so hearts/bookmarks
    // render correct on the first frame (no empty→filled flash). The prior
    // fetch cleared these sets, so without this they'd flicker in late.
    likedOriginalIds.addAll(cached.liked);
    savedOriginalIds.addAll(cached.saved);

    _fetching = false;
    _categoryLoading = false;
    _isLoadingMore = false;
    isLoading.value = false;

    // Then top up from Firestore in the background (additive, no spinner) so a
    // like/save made on another tab is eventually reflected here too.
    unawaited(_loadSocialStates(cached.recipes));
  }

  /// Pull-to-refresh: re-fetch FRESH data for the CURRENTLY-selected tab (not
  /// always "All"). Bypasses the cache, then updates it so the refreshed data
  /// is what a later tab-switch restores.
  Future<void> refreshCurrent() async {
    final cat = selectedCategory.value.trim();
    final lower = cat.toLowerCase();

    if (cat.isEmpty || lower == 'all' || lower == 'quick & easy') {
      await fetchDiscoverRecipes(refresh: true);
    } else {
      await fetchCategoryRecipes(category: cat, refresh: true);
    }

    // Keep the cache in sync with the freshly-loaded data for this tab.
    _snapshotCurrentFilter();
  }

  Future<void> selectCategory(String cat) async {
    final category = cat.trim();

    if (category.isEmpty) return;

    log('🔘 Discover category selected: $category');

    // Save the outgoing filter's loaded feed so returning to it is instant.
    _snapshotCurrentFilter();

    selectedCategory.value = category;

    final lower = category.toLowerCase();

    // ------------------------------------------------------------
    // QUICK & EASY — a client-side filter over the All feed. Never fetched or
    // cached as its own tab; it reuses whatever the All feed currently holds.
    // ------------------------------------------------------------
    if (lower == 'quick & easy') {
      _activeFirestoreFilter = 'All';

      _categoryLastDocument = null;
      _categoryHasMore = true;

      if (recipes.isEmpty && _hasMore) {
        await fetchDiscoverRecipes(refresh: true);
      }

      return;
    }

    // ------------------------------------------------------------
    // CACHE HIT — show the previously-loaded feed instantly (no spinner).
    // ------------------------------------------------------------
    if (_filterCache.containsKey(_filterKey(category))) {
      log('⚡ Discover cache hit: $category (instant)');
      _restoreFilter(category);
      return;
    }

    // ------------------------------------------------------------
    // CACHE MISS — fetch from Firestore (with spinner), first time only.
    // ------------------------------------------------------------
    if (lower == 'all') {
      _activeFirestoreFilter = 'All';

      _categoryLastDocument = null;
      _categoryHasMore = true;

      // Cancel/reset category state
      _categoryLoading = false;
      _isLoadingMore = false;

      await fetchDiscoverRecipes(refresh: true);

      return;
    }

    // OTHER CATEGORY / CUISINE
    _categoryLastDocument = null;
    _categoryHasMore = true;

    await fetchCategoryRecipes(category: category, refresh: true);
  }
}
