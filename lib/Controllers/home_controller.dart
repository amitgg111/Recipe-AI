import 'dart:async';
import 'dart:developer';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_ai/Controllers/cookbook_controller.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Helper/recipe_response_parser.dart';
import 'package:recipe_ai/Model/recipe_section_model.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';

class RecipeModel {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String sourceUrl;
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

  /// "private" | "public" — canonical privacy field. [isPublic] mirrors it.
  final String visibility;
  final bool isDeleted;

  /// False when the document had no `visibility` field yet (needs migration).
  final bool visibilityWasStored;

  /// Aggregate social like count (from the recipe's `likesCount` field).
  final int likesCount;

  RecipeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.sourceUrl,
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
    this.visibility = 'private',
    this.isDeleted = false,
    this.visibilityWasStored = true,
    this.likesCount = 0,
  });

  bool get isPublic => visibility == 'public';

  factory RecipeModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final parsed = RecipeResponseParser.parse(data);

    return RecipeModel(
      id: doc.id,
      title: parsed.title.isNotEmpty ? parsed.title : 'Unknown Recipe',
      description: parsed.description,
      imageUrl: data['imageUrl']?.toString(),
      sourceUrl: data['sourceUrl']?.toString() ?? '',
      prepTime: parsed.prepTime,
      cookTime: parsed.cookTime,
      totalTime: parsed.totalTime,
      servings: parsed.servings.toString(),
      category: parsed.category,
      cuisine: parsed.cuisine,
      keywords: parsed.keywords,
      ingredients: parsed.ingredients,
      instructions: parsed.instructions,
      ingredientSections: parsed.ingredientSections,
      instructionSections: parsed.instructionSections,
      visibility: (data['visibility'] as String?) ??
          (data['isPublic'] == true ? 'public' : 'private'),
      isDeleted: data['isDeleted'] == true,
      visibilityWasStored: data.containsKey('visibility'),
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
    );
  }
  double get servingCount {
    if (servings == null) return 1;

    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(servings!);

    if (match == null) return 1;

    return double.tryParse(match.group(1)!) ?? 1;
  }
}

class HomeController extends GetxController {
  final RxList<RecipeModel> recipes = <RecipeModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxList<CookbookModel> cookbooks = <CookbookModel>[].obs;

  StreamSubscription? _authSub;
  StreamSubscription? _recipesSub;
  StreamSubscription? _cookbooksSub;

  @override
  void onInit() {
    super.onInit();
    // Re-fetch whenever auth changes. This fixes the case where the controller
    // is created (permanent) before the user has logged in — authStateChanges
    // emits the current user immediately and again on every sign-in/out.
    _authSub = AuthService.authStateChanges.listen((user) {
      if (user != null) {
        fetchRecipes();
        fetchCookbooks();
      } else {
        _recipesSub?.cancel();
        _cookbooksSub?.cancel();
        recipes.clear();
        cookbooks.clear();
        isLoading.value = false;
      }
    });
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _recipesSub?.cancel();
    _cookbooksSub?.cancel();
    super.onClose();
  }

  void fetchCookbooks() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    _cookbooksSub?.cancel();
    _cookbooksSub = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("cookbooks")
        .snapshots()
        .listen((snapshot) {
          cookbooks.value = snapshot.docs
              .map((e) => CookbookModel.fromDocument(e))
              .toList();
        });
  }

  void fetchRecipes() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    _recipesSub?.cancel();

    _recipesSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('recipes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            recipes.value = snapshot.docs
                .map((doc) => RecipeModel.fromDocument(doc))
                .where((r) => !r.isDeleted)
                .toList();
            isLoading.value = false;
          },
          onError: (error) {
            isLoading.value = false;
            CustomSnackbar.show(
              title: 'Error',
              message: 'Failed to fetch recipes: $error',
              type: SnackbarType.error,
            );
          },
        );
  }

  Future<void> deleteRecipe(RecipeModel recipe) async {
    try {
      final uid = AuthService.currentUser?.uid;

      if (uid == null) {
        CustomSnackbar.show(
          title: 'Error',
          message: 'User not logged in',
          type: SnackbarType.error,
        );

        return;
      }

      // Firebase Storage image delete
      if (recipe.imageUrl != null &&
          recipe.imageUrl!.isNotEmpty &&
          recipe.imageUrl!.startsWith('http')) {
        try {
          await FirebaseStorage.instance.refFromURL(recipe.imageUrl!).delete();
        } catch (e) {
          log("Image delete error: $e");
        }
      }

      // Firestore document delete
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('recipes')
          .doc(recipe.id)
          .delete();

      CustomSnackbar.show(
        title: 'Success',
        message: 'Recipe deleted successfully',
        type: SnackbarType.success,
      );
    } catch (e) {
      CustomSnackbar.show(
        title: 'Error',
        message: 'Failed to delete recipe',
        type: SnackbarType.error,
      );
    }
  }

  /// Owner-only: change a recipe's privacy. Writes the canonical [visibility]
  /// field plus the mirrored [isPublic] flag and an [updatedAt] stamp.
  Future<void> updateRecipeVisibility(String recipeId, bool isPublic) async {
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('recipes')
          .doc(recipeId)
          .update({
            'visibility': isPublic ? 'public' : 'private',
            'isPublic': isPublic,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      log("Visibility update error: $e");
    }
  }

  /// Silent migration: back-fill the `visibility` field on legacy documents
  /// that predate the privacy system (called when a recipe is opened).
  Future<void> migrateVisibility(String recipeId, String visibility) async {
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('recipes')
          .doc(recipeId)
          .update({
            'visibility': visibility,
            'isPublic': visibility == 'public',
          });
    } catch (_) {
      // best-effort; never blocks the UI
    }
  }
}
