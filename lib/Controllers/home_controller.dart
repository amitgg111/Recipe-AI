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
  });

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
  @override
  void onInit() {
    super.onInit();
    fetchRecipes();
    fetchCookbooks();
  }

  void fetchCookbooks() {
    final uid = AuthService.currentUser?.uid;

    FirebaseFirestore.instance
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

    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('recipes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            recipes.value = snapshot.docs
                .map((doc) => RecipeModel.fromDocument(doc))
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
}
