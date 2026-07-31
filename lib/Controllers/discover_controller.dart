import 'dart:async';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:recipe_ai/Service/recipe_social_service.dart';
import 'package:recipe_ai/Controllers/onboarding_controller.dart';

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
  final List<String> instructions;
  final String userId;
  final String userName;
  final String? userAvatar;
  final DateTime? createdAt;

  // Social engagement counters (stored on the recipe document).
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int savesCount;

  // English originals, kept when [title]/[category]/[cuisine] hold a translated
  // value for display. The chip filters (Trending/Vegan/Desserts…) and category
  // matching are defined in English, so they read these — null falls back to the
  // main field, which for an untranslated recipe already IS English.
  final String? enTitle;
  final String? enDescription;
  final String? enCategory;
  final String? enCuisine;

  String get filterTitle => enTitle ?? title;

  /// English original of [description]. The feed sets it when it translates;
  /// an untranslated model's description already IS English. Detail screens
  /// translate from this so a translated description can never be fed back
  /// through ML Kit a second time.
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
    this.instructions = const [],
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.createdAt,
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
    String? category,
    String? cuisine,
    List<String>? ingredients,
    List<String>? instructions,
    String? enTitle,
    String? enDescription,
    String? enCategory,
    String? enCuisine,
  }) {
    return DiscoverRecipe(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl,
      category: category ?? this.category,
      cuisine: cuisine ?? this.cuisine,
      prepTime: prepTime,
      cookTime: cookTime,
      totalTime: totalTime,
      servings: servings,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      createdAt: createdAt,
      likesCount: likesCount,
      commentsCount: commentsCount,
      sharesCount: sharesCount,
      savesCount: savesCount,
      enTitle: enTitle ?? this.enTitle,
      enDescription: enDescription ?? this.enDescription,
      enCategory: enCategory ?? this.enCategory,
      enCuisine: enCuisine ?? this.enCuisine,
    );
  }
}

class DiscoverController extends GetxController {
  final RxList<DiscoverRecipe> recipes = <DiscoverRecipe>[].obs;
  final RxBool isLoading = true.obs;
  static const int _pageSize = 20;

  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;

  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  // English originals of the feed (Firestore is English). [recipes] holds the
  // translated-for-display copies; re-translation always starts from here.
  List<DiscoverRecipe> _english = [];

  /// The pre-translation (English) copy of a feed recipe, for logic that must
  /// key off English — e.g. ingredient→emoji matching, which uses an English
  /// keyword dictionary and would miss on a translated name. Null when the
  /// recipe isn't in the loaded feed; callers then fall back to the visible text.
  DiscoverRecipe? englishById(String id) {
    for (final r in _english) {
      if (r.id == id) return r;
    }
    return null;
  }

  List<String> get preferredCuisines {
    if (!Get.isRegistered<OnboardingController>()) {
      return const [];
    }

    final onboarding = Get.find<OnboardingController>();

    return onboarding.cuisines
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty && e != 'a bit of everything')
        .toList();
  }

  int _cuisinePriority(DiscoverRecipe recipe) {
    final preferences = preferredCuisines;

    if (preferences.isEmpty) {
      return 0;
    }

    final cuisine = recipe.filterCuisine.trim().toLowerCase();

    if (cuisine.isEmpty) {
      return 0;
    }

    for (var i = 0; i < preferences.length; i++) {
      if (cuisine == preferences[i]) {
        return preferences.length - i + 1;
      }
    }

    return 0;
  }

  /// Translate the CARD fields (title/description/category/cuisine) of every
  /// feed recipe into the current language, keeping the English originals for
  /// chip filtering. Ingredients/instructions are left English here and
  /// translated lazily by [translateForDetail] when a recipe is opened — so the
  /// feed stays fast even with a couple hundred recipes. No-op for English.
  Future<List<DiscoverRecipe>> _translateForFeed(
    List<DiscoverRecipe> list,
  ) async {
    if (list.isEmpty || !AiTranslationService.isTranslating) return list;
    await AiTranslationService.ensureReady();
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
  /// Called on card tap so the (potentially long) lists are only translated for
  /// the one recipe actually opened.
  Future<DiscoverRecipe> translateForDetail(DiscoverRecipe r) async {
    if (!AiTranslationService.isTranslating) return r;
    return r.copyWith(
      ingredients: await AiTranslationService.translateList(r.ingredients),
      instructions: await AiTranslationService.translateList(r.instructions),
    );
  }

  /// Re-translate the loaded feed after the app language changes.
  Future<void> refreshLanguage() async {
    recipes.assignAll(await _translateForFeed(_english));
    // The new language starts with an empty cache for the detail strings too,
    // so warm them again in the background.
    unawaited(_prewarmDetails(_english));
  }

  final RxString selectedCategory = ''.obs;
  final RxString searchQuery = ''.obs;

  /// Original Discover recipe ids the current user has saved. Bookmarks observe
  /// this set so the saved icon flips live — e.g. when the saved copy is deleted
  /// from My Recipes / a cookbook, that path removes the id and the icon updates.
  final RxSet<String> savedOriginalIds = <String>{}.obs;

  /// Original Discover recipe ids the current user has liked. Populated in one
  /// batched read per feed load (see [_loadSocialStates]) instead of each
  /// `_RecipeCard` querying Firestore individually — that per-card querying was
  /// the cause of the feed feeling slow/heavy to load.
  final RxSet<String> likedOriginalIds = <String>{}.obs;

  // Discover filter chips (match the design): a "smart" set first — Trending
  // (by engagement), Quick & Easy (short time), Vegan (plant-based) — then the
  // common meal/course categories.
  final List<String> categories = [
    'Trending',
    'Quick & Easy',
    'Vegan',
    'Desserts',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Drinks',
  ];

  StreamSubscription? _authSub;

  @override
  void onInit() {
    super.onInit();

    selectedCategory.value = 'Trending';

    _authSub = AuthService.authStateChanges.listen((user) {
      if (user != null) {
        fetchDiscoverRecipes(refresh: true);
      } else {
        recipes.clear();
        _english.clear();
        likedOriginalIds.clear();
        savedOriginalIds.clear();

        _lastDocument = null;
        _hasMore = true;
      }
    });

    fetchDiscoverRecipes(refresh: true);
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }

  // Guards against overlapping fetches (onInit + the auth listener can both
  // fire on startup) so the feed isn't queried twice at once.
  bool _fetching = false;

  /// Batch-loads which of [loaded] recipes the current user has liked/saved —
  /// ONE Firestore query each for the whole feed, instead of every
  /// `_RecipeCard` firing its own `isLiked`/`isSaved` read on build.
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

  Future<void> fetchDiscoverRecipes({bool refresh = false}) async {
    // Prevent duplicate requests.
    if (_fetching || _isLoadingMore) return;

    // Reset pagination when refreshing.
    if (refresh) {
      _lastDocument = null;
      _hasMore = true;

      recipes.clear();
      _english.clear();

      likedOriginalIds.clear();
      savedOriginalIds.clear();
    }

    // No more pages available.
    if (!_hasMore) return;

    final isFirstPage = _lastDocument == null;

    if (isFirstPage) {
      _fetching = true;

      if (recipes.isEmpty) {
        isLoading.value = true;
      }
    } else {
      _isLoadingMore = true;
    }

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('recipes')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      // First page:
      // _lastDocument == null
      //
      // Next page:
      // _lastDocument != null → start after last recipe
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final recipesSnapshot = await query.get();

      // No more documents.
      if (recipesSnapshot.docs.isEmpty) {
        _hasMore = false;
        return;
      }

      // Save cursor for next page.
      _lastDocument = recipesSnapshot.docs.last;

      // If returned documents are less than page size,
      // this is the last page.
      if (recipesSnapshot.docs.length < _pageSize) {
        _hasMore = false;
      }

      // Collect unique user IDs.
      final ownerIds = <String>{};

      for (final doc in recipesSnapshot.docs) {
        final ownerId = doc.data()['ownerId']?.toString();

        if (ownerId != null && ownerId.isNotEmpty) {
          ownerIds.add(ownerId);
        }
      }

      // Fetch all profiles in parallel.
      final userProfiles = <String, Map<String, dynamic>>{};

      if (ownerIds.isNotEmpty) {
        final userFutures = ownerIds.map((uid) {
          return FirebaseFirestore.instance.collection('users').doc(uid).get();
        });

        final userDocs = await Future.wait(userFutures);

        for (final userDoc in userDocs) {
          if (userDoc.exists) {
            userProfiles[userDoc.id] = userDoc.data() ?? {};
          }
        }
      }

      final newRecipes = <DiscoverRecipe>[];

      for (final recipeDoc in recipesSnapshot.docs) {
        final data = recipeDoc.data();

        // Skip deleted recipes.
        if (data['isDeleted'] == true) {
          continue;
        }

        final ownerId = data['ownerId']?.toString() ?? '';

        final ownerData = userProfiles[ownerId] ?? {};

        newRecipes.add(
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
            instructions: List<String>.from(data['instructions'] ?? const []),
            userId: ownerId,
            userName: ownerData['name']?.toString() ?? 'Chef',
            userAvatar: ownerData['photoUrl']?.toString(),
            createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
            likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
            commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
            sharesCount: (data['sharesCount'] as num?)?.toInt() ?? 0,
            savesCount: (data['savesCount'] as num?)?.toInt() ?? 0,
          ),
        );
      }

      // If this page only contained deleted recipes,
      // continue loading the next page automatically.
      if (newRecipes.isEmpty) {
        if (_hasMore) {
          await fetchDiscoverRecipes();
        }
        return;
      }

      // Store English originals.
      _english.addAll(newRecipes);

      // Translate only this page.
      final translatedRecipes = await _translateForFeed(newRecipes);

      // Append new page.
      recipes.addAll(translatedRecipes);

      // Load social states only for this page.
      await _loadSocialStates(newRecipes);

      // Warm the DETAIL strings for this page in the background, so tapping a
      // card opens an already-translated screen instead of flashing English.
      unawaited(_prewarmDetails(newRecipes));
    } catch (e, stack) {
      log('Discover pagination fetch failed: $e');
      log(stack.toString());
    } finally {
      isLoading.value = false;
      _fetching = false;
      _isLoadingMore = false;
    }
  }

  /// Pre-translate what the DETAIL screen will need for [list], in the
  /// background, right after a feed page lands.
  ///
  /// The feed itself only translates card fields (title/description/category/
  /// cuisine). Ingredients and instructions are left English, so opening a
  /// recipe used to hit a cold cache and render English for a beat before
  /// filling in. Splash-time prewarming cannot help either: it queries
  /// `ownerId == uid` while the feed is `isPublic == true` — disjoint sets, so
  /// public recipes were never warmed by anything.
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
    if (_fetching || _isLoadingMore || !_hasMore) return;

    await fetchDiscoverRecipes();
  }

  List<DiscoverRecipe> get filteredRecipes {
    var list = recipes.toList();
    final sel = selectedCategory.value;

    switch (sel) {
      case 'Trending':
        // Most engaged first (likes + comments + saves + shares).
        list.sort((a, b) => _engagement(b).compareTo(_engagement(a)));
        break;
      case 'Quick & Easy':
        // 30 minutes or less (total → cook → prep, whichever is available).
        list = list.where((r) {
          final m = _minutes(r);
          return m != null && m <= 30;
        }).toList();
        break;
      case 'Vegan':
        list = list
            .where(
              (r) => _matchesAny(r, const [
                'vegan',
                'vegetarian',
                'plant-based',
                'plant based',
              ]),
            )
            .toList();
        break;
      case 'Desserts':
        list = list
            .where(
              (r) => _matchesAny(r, const [
                'dessert',
                'sweet',
                'cake',
                'cookie',
                'brownie',
                'pudding',
                'ice cream',
                'pastry',
                'pie',
                'tart',
                'chocolate',
                'halwa',
                'kheer',
                'ladoo',
                'barfi',
              ]),
            )
            .toList();
        break;
      default:
        // Meal / course categories — the chip labels are English, so match the
        // recipe's ENGLISH category / cuisine / title (filter* fields).
        if (sel.isNotEmpty) {
          final q = sel.toLowerCase();
          list = list
              .where(
                (r) =>
                    r.filterCategory.toLowerCase().contains(q) ||
                    r.filterCuisine.toLowerCase().contains(q) ||
                    r.filterTitle.toLowerCase().contains(q),
              )
              .toList();
        }
    }

    if (searchQuery.value.isNotEmpty) {
      // Recipe search — match on the recipe name / category / cuisine only.
      // The poster's name is intentionally NOT searched: a query should surface
      // posts by recipe, not by the user who shared them. Match both the
      // displayed (translated) text AND the English original so a query typed in
      // either the app language or English still finds the recipe.
      final q = searchQuery.value.toLowerCase();
      bool hit(DiscoverRecipe r) {
        final hay =
            '${r.title} ${r.category ?? ''} ${r.cuisine ?? ''} '
                    '${r.filterTitle} ${r.filterCategory} ${r.filterCuisine}'
                .toLowerCase();
        return hay.contains(q);
      }

      list = list.where(hit).toList();
    }
    list.sort((a, b) {
      final aPriority = _cuisinePriority(a);
      final bPriority = _cuisinePriority(b);

      if (aPriority != bPriority) {
        return bPriority.compareTo(aPriority);
      }

      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    return list;
  }

  /// Total engagement score used to rank the "Trending" filter.
  int _engagement(DiscoverRecipe r) =>
      r.likesCount + r.commentsCount + r.savesCount + r.sharesCount;

  /// True when any [keywords] appear in the recipe's title / category / cuisine.
  bool _matchesAny(DiscoverRecipe r, List<String> keywords) {
    // Keywords are English, so match against the English originals (filter*).
    final hay = '${r.filterTitle} ${r.filterCategory} ${r.filterCuisine}'
        .toLowerCase();
    return keywords.any(hay.contains);
  }

  /// Best-effort minutes parsed from a time string ("30 min", "1 hour 20 mins",
  /// "1h 30m"). Returns null when no duration can be read.
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

  void selectCategory(String cat) {
    selectedCategory.value = cat;
  }
}
