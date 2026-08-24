import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:recipe_ai/Service/recipe_social_service.dart';
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
  final List<IngredientSection> ingredientSections;
  final List<String> instructions;
  final String userId;
  final String userName;
  final String? userAvatar;
  final DateTime? createdAt;
  final DateTime? publishedAt;

  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int savesCount;

  final String? enTitle;
  final String? enDescription;
  final String? enCategory;
  final String? enCuisine;

  String get filterTitle => enTitle ?? title;
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
  final RxBool _isLoadingMore = false.obs;

  String _activeFirestoreFilter = 'All';
  DocumentSnapshot<Map<String, dynamic>>? _categoryLastDocument;
  bool _categoryHasMore = true;
  bool _categoryLoading = false;
  static const int _categoryPageSize = 20;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore.value;

  final List<DiscoverRecipe> _english = [];
  final Map<String, Map<String, dynamic>> _ownerProfileCache = {};
  final RxList<String> _preferredCuisines = <String>[].obs;

  // ── LIVE FEED (real-time add/remove of public recipes) ──
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _liveFeedSub;
  // How many newest matching public docs we keep a live eye on. Anything
  // outside this window is only refreshed by pagination/pull-to-refresh —
  // keeps read cost bounded while still catching "just published" / "just
  // made private" in real time for what the user is actually looking at.
  static const int _liveFeedWindow = 30;

  // ── TAB EXISTENCE (real-time: does this category/cuisine have ANY public
  // recipe right now?) — drives which chips are shown. Firestore-verified,
  // not just "is something currently loaded into `recipes`".
  final RxMap<String, bool> categoryHasData = <String, bool>{}.obs;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _existenceSubs = {};

  List<String> get preferredCuisines => _preferredCuisines.toList();

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
        return [
          'vegan',
          'Vegan',
          'VEGAN',
          'plant based',
          'plant-based',
          'plant based food',
        ];

      case 'desserts':
      case 'dessert':
        return [
          'dessert',
          'Dessert',
          'desserts',
          'Desserts',
          'sweet',
          'Sweet',
          'sweets',
          'Sweets',
          'sweet dish',
          'Sweet Dish',
          'sweet dishes',
          'Sweet Dishes',
          'pudding',
          'Pudding',
          'cake',
          'Cake',
          'cakes',
          'Cakes',
          'pastry',
          'Pastry',
          'pastries',
          'Pastries',
          'ice cream',
          'Ice Cream',
          'icecream',
          'Icecream',
          'baked dessert',
          'Baked Dessert',
        ];

      case 'breakfast':
        return [
          'breakfast',
          'Breakfast',
          'morning',
          'Morning',
          'morning meal',
          'Morning Meal',
          'brunch',
          'Brunch',
        ];

      case 'lunch':
        return [
          'lunch',
          'Lunch',
          'midday',
          'Midday',
          'midday meal',
          'Midday Meal',
        ];

      case 'dinner':
        return [
          'dinner',
          'Dinner',
          'evening meal',
          'Evening Meal',
          'supper',
          'Supper',
        ];

      case 'drinks':
      case 'drink':
        return [
          'drink',
          'Drink',
          'drinks',
          'Drinks',
          'beverage',
          'Beverage',
          'beverages',
          'Beverages',
          'juice',
          'Juice',
          'juices',
          'Juices',
          'smoothie',
          'Smoothie',
          'smoothies',
          'Smoothies',
          'shake',
          'Shake',
          'lassi',
          'shakes',
          'Shakes',
          'cocktail',
          'Cocktail',
          'mocktail',
          'Mocktail',
        ];

      default:
        return [category, category.toLowerCase(), category.toUpperCase()];
    }
  }

  bool _isBaseCategory(String value) {
    return _baseCategories.any(
      (category) => category.toLowerCase() == value.trim().toLowerCase(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB EXISTENCE LISTENERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Builds the "does at least 1 public recipe exist for this category /
  /// cuisine" query. `limit(1)` keeps it cheap; `.snapshots()` (not `.get()`)
  /// keeps it realtime so a tab appears/disappears the instant a recipe is
  /// published/unpublished — no app restart or manual refresh needed.
  Query<Map<String, dynamic>> _existenceQueryFor(String category) {
    final isBase = _isBaseCategory(category);
    final field = isBase ? 'category' : 'cuisine';
    final aliases = _categoryAliases(category);

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('recipes')
        .where('isPublic', isEqualTo: true);

    if (aliases.length == 1) {
      query = query.where(field, isEqualTo: aliases.first);
    } else {
      // Firestore whereIn supports up to 30 values.
      query = query.where(field, whereIn: aliases.take(30).toList());
    }

    return query.limit(10);
  }

  /// Keeps one lightweight realtime listener per base-category and per
  /// preferred cuisine, updating [categoryHasData]. Called whenever the set
  /// of preferred cuisines can have changed (login, onboarding update).
  void _setupCategoryExistenceListeners() {
    final wanted = <String>{
      ..._baseCategories,
      ...preferredCuisines.map(_canonicalCuisine).where((c) => c.isNotEmpty),
    };

    // Drop listeners for categories no longer relevant (e.g. user changed
    // their preferred cuisines).
    for (final key in _existenceSubs.keys.toList()) {
      if (!wanted.contains(key)) {
        _existenceSubs.remove(key)?.cancel();
        categoryHasData.remove(key);
      }
    }

    for (final cat in wanted) {
      if (_existenceSubs.containsKey(cat)) continue; // already listening

      final isBase = _isBaseCategory(cat);
      final field = isBase ? 'category' : 'cuisine';
      final aliases = _categoryAliases(cat);

      log(
        '👁️ Existence listener started: "$cat" | field=$field | aliases=$aliases',
      );

      final sub = _existenceQueryFor(cat).snapshots().listen(
        (snapshot) {
          final hasData = snapshot.docs.isNotEmpty;
          categoryHasData[cat] = hasData;

          // 👈 DEBUG: prints exactly what Firestore matched (or didn't) so
          // a mismatch between the stored category/cuisine value and the
          // expected aliases is visible immediately. Safe to remove later.
          log(
            '👁️ Existence["$cat"] -> hasData=$hasData '
            '(matched ${snapshot.docs.length} doc(s) on $field IN $aliases)',
          );

          // If the user is currently sitting on a tab that just emptied out
          // (its last public recipe went private/was deleted), don't leave
          // them stranded on a chip that's about to vanish — fall back to
          // "All" automatically.
          if (!hasData && selectedCategory.value == cat) {
            selectCategory('All');
          }
        },
        onError: (e) {
          log(
            '❌ Existence listener failed for "$cat" (field=$field, '
            'aliases=$aliases): $e\n'
            '   → this is almost always a MISSING FIRESTORE INDEX. '
            'Copy the link in this error (if any) into a browser and '
            'click "Create Index".',
          );
        },
      );

      _existenceSubs[cat] = sub;
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
    _isLoadingMore.value = _categoryLastDocument != null;

    try {
      final aliases = _categoryAliases(normalizedCategory);
      final isBaseCategory = _isBaseCategory(normalizedCategory);
      final List<DiscoverRecipe> allCategoryRecipes = [];

      log(
        '🔎 Fetching [$normalizedCategory] | '
        'type=${isBaseCategory ? 'CATEGORY' : 'CUISINE'} | '
        'aliases=$aliases',
      );

      for (final alias in aliases) {
        Query<Map<String, dynamic>> query;

        if (isBaseCategory) {
          query = FirebaseFirestore.instance
              .collection('recipes')
              .where('isPublic', isEqualTo: true)
              .where('category', isEqualTo: alias)
              .limit(_categoryPageSize);
        } else {
          query = FirebaseFirestore.instance
              .collection('recipes')
              .where('isPublic', isEqualTo: true)
              .where('cuisine', isEqualTo: alias)
              .limit(_categoryPageSize);
        }

        final snapshot = await query.get();

        log('🔎 Firestore [$alias] -> ${snapshot.docs.length} documents');

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

      final unique = <String, DiscoverRecipe>{};
      for (final recipe in allCategoryRecipes) {
        unique[recipe.id] = recipe;
      }
      final newRecipes = unique.values.toList();

      newRecipes.sort((a, b) {
        final aDate =
            a.publishedAt ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.publishedAt ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      final existingIds = _english.map((e) => e.id).toSet();
      final filteredNewRecipes = newRecipes
          .where((recipe) => !existingIds.contains(recipe.id))
          .toList();

      if (filteredNewRecipes.isNotEmpty) {
        _english.addAll(filteredNewRecipes);
        await _processAndAppend(filteredNewRecipes);
        _sortDiscoverRecipes();
      }

      if (filteredNewRecipes.isEmpty) {
        _categoryHasMore = false;
        log('⚠️ Category [$normalizedCategory] returned 0 NEW recipes');
      } else {
        log(
          '🍽️ Category [$normalizedCategory] '
          'loaded ${filteredNewRecipes.length} recipes',
        );
      }

      if (newRecipes.length < _categoryPageSize) {
        _categoryHasMore = false;
      }
    } catch (e, stack) {
      log('❌ Category recipe fetch failed [$normalizedCategory]: $e');
      log(stack.toString());
    } finally {
      _categoryLoading = false;
      _isLoadingMore.value = false;
      isLoading.value = false;
    }
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

      log('🍽️ Discover preferred cuisines: ${_preferredCuisines.join(', ')}');
    } catch (e, stack) {
      log('❌ Failed to load preferred cuisines: $e');
      log(stack.toString());
      _preferredCuisines.clear();
    }
  }

  Future<void> refreshPreferredCuisines() async {
    await _loadPreferredCuisines();
    _setupCategoryExistenceListeners();
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

    if (liked != null) {
      if (liked) {
        likedOriginalIds.add(recipeId);
      } else {
        likedOriginalIds.remove(recipeId);
      }
      likedOriginalIds.refresh();
    }

    if (saved != null) {
      if (saved) {
        savedOriginalIds.add(recipeId);
      } else {
        savedOriginalIds.remove(recipeId);
      }
      savedOriginalIds.refresh();
    }
  }

  Future<List<DiscoverRecipe>> _translateForFeed(
    List<DiscoverRecipe> list,
  ) async {
    if (list.isEmpty || !AiTranslationService.isTranslating) return list;

    var ready = await AiTranslationService.ensureReady().timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );

    if (!ready) {
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

  Future<void> refreshLanguage() async {
    recipes.assignAll(await _translateForFeed(_english));
    unawaited(_prewarmDetails(_english));
  }

  final RxString selectedCategory = ''.obs;
  final RxString searchQuery = ''.obs;

  final RxSet<String> savedOriginalIds = <String>{}.obs;
  final RxSet<String> likedOriginalIds = <String>{}.obs;

  final List<String> _baseCategories = [
    'Quick & Easy',
    'Vegan',
    'Desserts',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Drinks',
  ];

  /// Chips shown in the UI. "All" is always shown. Every other chip
  /// (preferred cuisine or base category) only appears once [categoryHasData]
  /// — populated from a live Firestore existence check — confirms it
  /// actually has at least one public recipe right now.
  List<String> get categories {
    final chips = <String>['All'];
    final seen = <String>{};

    for (final pref in preferredCuisines) {
      final label = _canonicalCuisine(pref);
      if (label.isEmpty) continue;
      if (categoryHasData[label] != true) continue; // Firestore-verified
      final key = label.toLowerCase();
      if (seen.add(key)) {
        chips.add(label);
      }
    }

    for (final cat in _baseCategories) {
      if (categoryHasData[cat] != true) continue; // Firestore-verified
      chips.add(cat);
    }

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
        _startLiveFeedListener(category: 'All');
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

        _liveFeedSub?.cancel();
        _liveFeedSub = null;

        for (final sub in _existenceSubs.values) {
          sub.cancel();
        }
        _existenceSubs.clear();
        categoryHasData.clear();
      }
    });
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _liveFeedSub?.cancel();

    for (final subscription in _socialCountSubscriptions.values) {
      subscription.cancel();
    }
    _socialCountSubscriptions.clear();

    for (final sub in _existenceSubs.values) {
      sub.cancel();
    }
    _existenceSubs.clear();

    super.onClose();
  }

  bool _fetching = false;

  /// Watches the newest [_liveFeedWindow] public recipes matching the given
  /// [category] (or the currently selected one) in real time.
  ///
  /// Uses `docChanges` (not a raw `snapshot.docs` diff) so BOTH directions
  /// are caught:
  ///  • `added`   → a recipe just entered the result set (freshly published,
  ///                or just edited into matching this category/cuisine)
  ///                → insert it into the feed live.
  ///  • `removed` → a recipe just LEFT the result set — deleted, OR a field
  ///                used in the `where` clause changed so it no longer
  ///                matches (e.g. `isPublic` flipped to false, or the
  ///                category/cuisine was edited) → pulled out of the feed
  ///                immediately, no refresh needed.
  void _startLiveFeedListener({String? category}) {
    _liveFeedSub?.cancel();

    final rawCat = (category ?? selectedCategory.value).trim();
    final lower = rawCat.toLowerCase();
    final isAllOrQuick =
        rawCat.isEmpty || lower == 'all' || lower == 'quick & easy';

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('recipes')
        .where('isPublic', isEqualTo: true);

    if (!isAllOrQuick) {
      final isBase = _isBaseCategory(rawCat);
      final field = isBase ? 'category' : 'cuisine';
      final aliases = _categoryAliases(rawCat);

      if (aliases.length == 1) {
        query = query.where(field, isEqualTo: aliases.first);
      } else {
        query = query.where(field, whereIn: aliases.take(30).toList());
      }
    }

    query = query
        .orderBy('publishedAt', descending: true)
        .limit(_liveFeedWindow);

    _liveFeedSub = query.snapshots().listen(
      (QuerySnapshot<Map<String, dynamic>> snapshot) async {
        try {
          final List<DocumentSnapshot<Map<String, dynamic>>> toAdd = [];
          final Set<String> toRemoveIds = {};

          for (final DocumentChange<Map<String, dynamic>> change
              in snapshot.docChanges) {
            switch (change.type) {
              case DocumentChangeType.added:
                toAdd.add(change.doc);
                break;
              case DocumentChangeType.removed:
                toRemoveIds.add(change.doc.id);
                break;
              case DocumentChangeType.modified:
                break;
            }
          }

          if (toRemoveIds.isNotEmpty) {
            recipes.removeWhere((r) => toRemoveIds.contains(r.id));
            _english.removeWhere((r) => toRemoveIds.contains(r.id));

            for (final id in toRemoveIds) {
              _socialCountSubscriptions.remove(id)?.cancel();
            }

            log(
              '🟡 Live[$rawCat]: removed ${toRemoveIds.length} recipe(s) '
              '(now private/deleted)',
            );
          }

          if (toAdd.isNotEmpty) {
            final knownIds = <String>{
              ..._english.map((r) => r.id),
              ...recipes.map((r) => r.id),
            };

            final freshDocs = toAdd
                .where((d) => !knownIds.contains(d.id))
                .toList();

            if (freshDocs.isNotEmpty) {
              final newRecipes = await _documentsToDiscoverRecipes(freshDocs);

              if (newRecipes.isNotEmpty) {
                _english.insertAll(0, newRecipes);
                recipes.insertAll(0, _projectFromCache(newRecipes));
                unawaited(_finishProcessing(newRecipes));
                _sortDiscoverRecipes();

                log('🟢 Live[$rawCat]: added ${newRecipes.length} recipe(s)');
              }
            }
          }
        } catch (e, st) {
          log('❌ Live feed processing error [$rawCat]: $e', stackTrace: st);
        }
      },
      onError: (e, st) {
        log('❌ Live feed listener failed [$rawCat]: $e', stackTrace: st);
      },
    );
  }

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

  Future<void> _processAndAppend(List<DiscoverRecipe> chunk) async {
    if (chunk.isEmpty) return;

    recipes.addAll(_projectFromCache(chunk));

    unawaited(_finishProcessing(chunk));
  }

  List<DiscoverRecipe> _projectFromCache(List<DiscoverRecipe> list) {
    if (!AiTranslationService.isTranslating) return list;
    String? tr(String? s) =>
        s == null ? null : AiTranslationService.cachedOrSelf(s);
    return list
        .map(
          (r) => r.copyWith(
            title: AiTranslationService.cachedOrSelf(r.title),
            description: tr(r.description),
            category: tr(r.category),
            cuisine: tr(r.cuisine),
            enTitle: r.title,
            enDescription: r.description,
            enCategory: r.category,
            enCuisine: r.cuisine,
          ),
        )
        .toList();
  }

  Future<void> _finishProcessing(List<DiscoverRecipe> chunk) async {
    try {
      if (AiTranslationService.isTranslating) {
        final translated = await _translateForFeed(chunk);
        for (final t in translated) {
          final i = recipes.indexWhere((r) => r.id == t.id);
          if (i != -1) recipes[i] = t;
        }
        recipes.refresh();
      }
    } catch (e) {
      log('Discover deferred translation failed: $e');
    }

    await _loadSocialStates(chunk);
    _listenToRecipeSocialCounts(chunk);
    unawaited(_prewarmDetails(chunk));
  }

  Future<void> fetchDiscoverRecipes({bool refresh = false}) async {
    if (_fetching || _isLoadingMore.value) return;

    if (refresh) {
      _fetching = true;

      try {
        await _loadPreferredCuisines();
        _setupCategoryExistenceListeners();

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
      _isLoadingMore.value = true;
    }

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('recipes')
          .where('isPublic', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
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
      final existingIds = <String>{
        ..._english.map((r) => r.id),
        ...recipes.map((r) => r.id),
      };

      final uniqueRecipes = newRecipes
          .where((r) => !existingIds.contains(r.id))
          .toList();

      if (uniqueRecipes.isEmpty) {
        return;
      }

      _english.addAll(uniqueRecipes);

      await _processAndAppend(uniqueRecipes);
      _sortDiscoverRecipes();
    } catch (e, stack) {
      log('❌ Discover pagination fetch failed: $e');
      log(stack.toString());
    } finally {
      isLoading.value = false;
      _fetching = false;
      _isLoadingMore.value = false;
    }
  }

  Future<List<DiscoverRecipe>> _documentsToDiscoverRecipes(
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (docs.isEmpty) return [];

    final ownerIds = <String>{};

    for (final doc in docs) {
      final data = doc.data();
      final ownerId = data?['ownerId']?.toString();

      if (ownerId != null && ownerId.isNotEmpty) {
        ownerIds.add(ownerId);
      }
    }

    final userProfiles = <String, Map<String, dynamic>>{};

    ownerIds.removeWhere((uid) {
      final cached = _ownerProfileCache[uid];
      if (cached == null) return false;
      userProfiles[uid] = cached;
      return true;
    });

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
          _ownerProfileCache[userDoc.id] = userProfiles[userDoc.id]!;
        }
      }
    }

    final result = <DiscoverRecipe>[];

    for (final recipeDoc in docs) {
      final data = recipeDoc.data();

      if (data == null) continue;

      if (data['isDeleted'] == true) {
        continue;
      }

      final ownerId = data['ownerId']?.toString() ?? '';
      final ownerData = userProfiles[ownerId] ?? {};

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

  /// Newest-first, keyed off `publishedAt` (falling back to `createdAt`) —
  /// matches the Firestore `orderBy('publishedAt', ...)` used everywhere
  /// this list is fetched, so live-inserted recipes land in the right spot
  /// instead of only sorting correctly by coincidence.
  void _sortDiscoverRecipes() {
    recipes.sort((a, b) {
      final aDate =
          a.publishedAt ??
          a.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          b.publishedAt ??
          b.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
  }

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

  Future<void> loadMoreRecipes() async {
    if (_fetching || _isLoadingMore.value) return;

    final category = selectedCategory.value.trim();

    if (category.isEmpty || category == 'All') {
      if (!_hasMore) return;
      await fetchDiscoverRecipes();
      return;
    }

    if (category == 'Quick & Easy') {
      if (!_hasMore) return;
      await fetchDiscoverRecipes();
      return;
    }

    if (!_categoryHasMore || _categoryLoading) {
      return;
    }

    await fetchCategoryRecipes(category: category, refresh: false);
  }

  List<DiscoverRecipe> get filteredRecipes {
    var list = recipes.toList();

    final sel = selectedCategory.value.trim();

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
        break;
    }

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
      final aDate =
          a.publishedAt ??
          a.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          b.publishedAt ??
          b.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return list;
  }

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

  final Map<String, _DiscoverFilterCache> _filterCache = {};

  String _filterKey(String filter) => filter.trim().toLowerCase();

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

    likedOriginalIds.addAll(cached.liked);
    savedOriginalIds.addAll(cached.saved);

    _fetching = false;
    _categoryLoading = false;
    _isLoadingMore.value = false;
    isLoading.value = false;

    unawaited(_loadSocialStates(cached.recipes));
  }

  Future<void> refreshCurrent() async {
    final cat = selectedCategory.value.trim();
    final lower = cat.toLowerCase();

    if (cat.isEmpty || lower == 'all' || lower == 'quick & easy') {
      await fetchDiscoverRecipes(refresh: true);
    } else {
      await fetchCategoryRecipes(category: cat, refresh: true);
    }

    _snapshotCurrentFilter();
  }

  Future<void> selectCategory(String cat) async {
    final category = cat.trim();

    if (category.isEmpty) return;

    log('🔘 Discover category selected: $category');

    _snapshotCurrentFilter();

    selectedCategory.value = category;

    final lower = category.toLowerCase();

    if (lower == 'quick & easy') {
      _activeFirestoreFilter = 'All';

      _categoryLastDocument = null;
      _categoryHasMore = true;

      if (recipes.isEmpty && _hasMore) {
        await fetchDiscoverRecipes(refresh: true);
      }

      _startLiveFeedListener(category: 'All');
      return;
    }

    if (_filterCache.containsKey(_filterKey(category))) {
      log('⚡ Discover cache hit: $category (instant)');
      _restoreFilter(category);
      _startLiveFeedListener(category: _activeFirestoreFilter);
      return;
    }

    if (lower == 'all') {
      _activeFirestoreFilter = 'All';

      _categoryLastDocument = null;
      _categoryHasMore = true;

      _categoryLoading = false;
      _isLoadingMore.value = false;

      await fetchDiscoverRecipes(refresh: true);
      _startLiveFeedListener(category: 'All');

      return;
    }

    _categoryLastDocument = null;
    _categoryHasMore = true;

    await fetchCategoryRecipes(category: category, refresh: true);
    _startLiveFeedListener(category: category);
  }
}
