import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  final List<String> categories = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
    'Desserts',
    'Drinks',
    'Salads',
    'Soups',
    'Appetizers',
  ];

  @override
  void onInit() {
    super.onInit();
    selectedCategory.value = 'All';
    fetchDiscoverRecipes();
  }

  Future<void> fetchDiscoverRecipes() async {
    try {
      isLoading.value = true;

      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final List<DiscoverRecipe> allRecipes = [];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userName = userData['name']?.toString() ?? 'Chef';
        final userAvatar = userData['photoUrl']?.toString();

        final recipesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('recipes')
            .where('visibility', isEqualTo: 'public')
            .orderBy('createdAt', descending: true)
            .limit(30)
            .get();

        for (final recipeDoc in recipesSnapshot.docs) {
          final data = recipeDoc.data();
          // Never surface soft-deleted recipes in Discover.
          if (data['isDeleted'] == true) continue;
          final imageUrl = data['imageUrl']?.toString();

          allRecipes.add(DiscoverRecipe(
            id: recipeDoc.id,
            title: data['title']?.toString() ?? 'Untitled',
            description: data['description']?.toString(),
            imageUrl: imageUrl,
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
      }

      allRecipes.shuffle();
      recipes.assignAll(allRecipes);
    } catch (e) {
      // silently fail
    } finally {
      isLoading.value = false;
    }
  }

  List<DiscoverRecipe> get filteredRecipes {
    var list = recipes.toList();

    if (selectedCategory.value.isNotEmpty &&
        selectedCategory.value != 'All') {
      list = list
          .where((r) =>
              (r.category ?? '')
                  .toLowerCase()
                  .contains(selectedCategory.value.toLowerCase()) ||
              (r.cuisine ?? '')
                  .toLowerCase()
                  .contains(selectedCategory.value.toLowerCase()))
          .toList();
    }

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      list = list
          .where((r) =>
              r.title.toLowerCase().contains(q) ||
              (r.category ?? '').toLowerCase().contains(q) ||
              (r.cuisine ?? '').toLowerCase().contains(q) ||
              r.userName.toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  void selectCategory(String cat) {
    selectedCategory.value = cat;
  }
}
