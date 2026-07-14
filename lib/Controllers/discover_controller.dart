import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_ai/Service/auth_service.dart';

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
  });
}

class DiscoverController extends GetxController {
  final RxList<DiscoverRecipe> recipes = <DiscoverRecipe>[].obs;
  final RxBool isLoading = true.obs;
  final RxString selectedCategory = ''.obs;
  final RxString searchQuery = ''.obs;

  /// Original Discover recipe ids the current user has saved. Bookmarks observe
  /// this set so the saved icon flips live — e.g. when the saved copy is deleted
  /// from My Recipes / a cookbook, that path removes the id and the icon updates.
  final RxSet<String> savedOriginalIds = <String>{}.obs;

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
    // This controller is permanent, so it can outlive a logout/login. Re-fetch
    // the public feed whenever the signed-in user changes so a fresh login (or
    // switching accounts) always reloads posts instead of showing a stale or
    // empty list left over from before sign-in.
    _authSub = AuthService.authStateChanges.listen((user) {
      if (user != null) {
        fetchDiscoverRecipes();
      } else {
        recipes.clear();
      }
    });
    fetchDiscoverRecipes();
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }

  // Guards against overlapping fetches (onInit + the auth listener can both
  // fire on startup) so the feed isn't queried twice at once.
  bool _fetching = false;

  Future<void> fetchDiscoverRecipes() async {
    if (_fetching) return;
    _fetching = true;
    // Only take over the screen with a spinner on the FIRST load. Later
    // refreshes update the list in place, so re-entering Discover (or a
    // pull-to-refresh) never flashes back to a full-screen loader.
    if (recipes.isEmpty) isLoading.value = true;

    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      // Fan out every user's public-recipe query in PARALLEL instead of
      // awaiting them one-by-one. This turns N sequential network round-trips
      // (the slow part) into a single concurrent wave. Each query is guarded
      // so one user's permission/read error can't blank the whole feed.
      final perUser = await Future.wait(
        usersSnapshot.docs.map((userDoc) async {
          final userData = userDoc.data();
          final userName = userData['name']?.toString() ?? 'Chef';
          final userAvatar = userData['photoUrl']?.toString();

          try {
            // Only a single-field equality filter here — adding an orderBy
            // would need a composite index; we sort client-side instead.
            final recipesSnapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(userDoc.id)
                .collection('recipes')
                .where('visibility', isEqualTo: 'public')
                .limit(30)
                .get();

            final out = <DiscoverRecipe>[];
            for (final recipeDoc in recipesSnapshot.docs) {
              final data = recipeDoc.data();
              // Never surface soft-deleted recipes in Discover.
              if (data['isDeleted'] == true) continue;

              out.add(DiscoverRecipe(
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
                ingredients: List<String>.from(data['ingredients'] ?? []),
                instructions: List<String>.from(data['instructions'] ?? []),
                userId: userDoc.id,
                userName: userName,
                userAvatar: userAvatar,
                createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
                likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
                commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
                sharesCount: (data['sharesCount'] as num?)?.toInt() ?? 0,
                savesCount: (data['savesCount'] as num?)?.toInt() ?? 0,
              ));
            }
            return out;
          } catch (e) {
            log('Discover: skipped ${userDoc.id}: $e');
            return const <DiscoverRecipe>[];
          }
        }),
      );

      final allRecipes = perUser.expand((e) => e).toList();

      // Newest first, then shuffle for a varied feed (matches prior behaviour
      // but without needing a Firestore composite index).
      allRecipes.sort((a, b) {
        final ad = a.createdAt;
        final bd = b.createdAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
      allRecipes.shuffle();
      recipes.assignAll(allRecipes);
    } catch (e, stack) {
      // Surface the reason instead of hiding it — a missing index or a rules
      // denial here is exactly what leaves Discover blank.
      log('Discover fetch failed: $e');
      log(stack.toString());
    } finally {
      isLoading.value = false;
      _fetching = false;
    }
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
            .where((r) => _matchesAny(r, const [
                  'vegan', 'vegetarian', 'plant-based', 'plant based',
                ]))
            .toList();
        break;
      case 'Desserts':
        list = list
            .where((r) => _matchesAny(r, const [
                  'dessert', 'sweet', 'cake', 'cookie', 'brownie', 'pudding',
                  'ice cream', 'pastry', 'pie', 'tart', 'chocolate', 'halwa',
                  'kheer', 'ladoo', 'barfi',
                ]))
            .toList();
        break;
      default:
        // Meal / course categories — match the recipe's category or cuisine.
        if (sel.isNotEmpty) {
          final q = sel.toLowerCase();
          list = list
              .where((r) =>
                  (r.category ?? '').toLowerCase().contains(q) ||
                  (r.cuisine ?? '').toLowerCase().contains(q) ||
                  r.title.toLowerCase().contains(q))
              .toList();
        }
    }

    if (searchQuery.value.isNotEmpty) {
      // Recipe search — match on the recipe name / category / cuisine only.
      // The poster's name is intentionally NOT searched: a query should surface
      // posts by recipe, not by the user who shared them.
      final q = searchQuery.value.toLowerCase();
      list = list
          .where((r) =>
              r.title.toLowerCase().contains(q) ||
              (r.category ?? '').toLowerCase().contains(q) ||
              (r.cuisine ?? '').toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  /// Total engagement score used to rank the "Trending" filter.
  int _engagement(DiscoverRecipe r) =>
      r.likesCount + r.commentsCount + r.savesCount + r.sharesCount;

  /// True when any [keywords] appear in the recipe's title / category / cuisine.
  bool _matchesAny(DiscoverRecipe r, List<String> keywords) {
    final hay =
        '${r.title} ${r.category ?? ''} ${r.cuisine ?? ''}'.toLowerCase();
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
