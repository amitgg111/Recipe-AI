import 'dart:async';
import 'dart:developer';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_ai/Controllers/cookbook_controller.dart';
import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
import 'package:recipe_ai/Controllers/discover_controller.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/language_service.dart';
import 'package:recipe_ai/Service/recipe_social_service.dart';
import 'package:recipe_ai/Helper/recipe_response_parser.dart';
import 'package:recipe_ai/Helper/recipe_publish_policy.dart';
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

  /// The user's free-text note for this recipe (persisted on the recipe doc).
  final String? note;

  /// Cached nutrition estimate (per-serving map from [NutritionModel.toMap]),
  /// stored on the recipe doc so it isn't recomputed every session.
  final Map<String, dynamic>? nutritionData;

  /// "private" | "public" — derived locally from the Firestore `isPublic` bool.
  /// This is NOT stored in Firestore; only `isPublic` is persisted.
  final String visibility;
  final bool isDeleted;

  /// The owner favourited this recipe (heart on the card). Surfaces it in the
  /// Favorites list.
  final bool isFavorite;

  /// False when the document had no `isPublic` field yet (needs migration).
  final bool visibilityWasStored;

  /// Aggregate social like count (from the recipe's `likesCount` field).
  final int likesCount;

  /// Ownership provenance: 'userCreated' | 'imported' | 'discovered'.
  /// Recipes saved from Discover are 'discovered' and can never be published.
  final String recipeSource;

  /// For 'discovered' recipes, the id of the original Discover recipe this is a
  /// copy of. Null for user-created / imported recipes.
  final String? originalRecipeId;

  /// For 'discovered' recipes, the uid of the original recipe's owner — needed
  /// to clear the Discover "saved" marker when this copy is deleted.
  final String? savedFromOwnerId;

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
    this.note,
    this.nutritionData,
    this.visibility = 'private',
    this.isDeleted = false,
    this.visibilityWasStored = true,
    this.likesCount = 0,
    this.recipeSource = RecipePublishPolicy.sourceUserCreated,
    this.originalRecipeId,
    this.savedFromOwnerId,
    this.isFavorite = false,
  });

  bool get isPublic => visibility == 'public';

  /// True unless this recipe was saved from Discover — only user-created or
  /// imported recipes may be published.
  bool get canBePublished => RecipePublishPolicy.canPublish(recipeSource);

  /// True when this is a private copy saved out of the Discover feed.
  bool get isDiscoveredCopy => RecipePublishPolicy.isDiscovered(recipeSource);

  // RecipeModel copyWith({
  //   String? title,
  //   String? description,
  //   String? imageUrl,
  //   String? servings,
  //   List<String>? ingredients,
  //   List<String>? instructions,
  //   List<IngredientSection>? ingredientSections,
  //   List<InstructionSection>? instructionSections,
  //   String? note,
  //   Map<String, dynamic>? nutritionData,
  // }) {
  //   return RecipeModel(
  //     id: id,
  //     title: title ?? this.title,
  //     description: description ?? this.description,
  //     imageUrl: imageUrl ?? this.imageUrl,
  //     sourceUrl: sourceUrl,
  //     prepTime: prepTime,
  //     cookTime: cookTime,
  //     totalTime: totalTime,
  //     servings: servings ?? this.servings,
  //     category: category,
  //     cuisine: cuisine,
  //     keywords: keywords,
  //     ingredients: ingredients ?? this.ingredients,
  //     instructions: instructions ?? this.instructions,
  //     ingredientSections: ingredientSections ?? this.ingredientSections,
  //     instructionSections: instructionSections ?? this.instructionSections,
  //     note: note ?? this.note,
  //     nutritionData: nutritionData ?? this.nutritionData,
  //     visibility: visibility,
  //     isDeleted: isDeleted,
  //     visibilityWasStored: visibilityWasStored,
  //     likesCount: likesCount,
  //     recipeSource: recipeSource,
  //     originalRecipeId: originalRecipeId,
  //     savedFromOwnerId: savedFromOwnerId,
  //     isFavorite: isFavorite,
  //   );
  // }

  RecipeModel copyWith({
    String? title,
    String? description,
    String? imageUrl,
    String? servings,
    String? category,
    String? cuisine,
    List<String>? keywords,
    List<String>? ingredients,
    List<String>? instructions,
    List<IngredientSection>? ingredientSections,
    List<InstructionSection>? instructionSections,
    String? note,
    Map<String, dynamic>? nutritionData,
  }) {
    return RecipeModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceUrl: sourceUrl,
      prepTime: prepTime,
      cookTime: cookTime,
      totalTime: totalTime,
      servings: servings ?? this.servings,
      category: category ?? this.category,
      cuisine: cuisine ?? this.cuisine,
      keywords: keywords ?? this.keywords,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      ingredientSections: ingredientSections ?? this.ingredientSections,
      instructionSections: instructionSections ?? this.instructionSections,
      note: note ?? this.note,
      nutritionData: nutritionData ?? this.nutritionData,
      visibility: visibility,
      isDeleted: isDeleted,
      visibilityWasStored: visibilityWasStored,
      likesCount: likesCount,
      recipeSource: recipeSource,
      originalRecipeId: originalRecipeId,
      savedFromOwnerId: savedFromOwnerId,
      isFavorite: isFavorite,
    );
  }

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
      note: data['note']?.toString(),
      nutritionData: (data['nutrition'] as Map?)?.cast<String, dynamic>(),
      visibility: data['isPublic'] == true ? 'public' : 'private',
      isDeleted: data['isDeleted'] == true,
      visibilityWasStored: data.containsKey('isPublic'),
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      // Legacy Discover copies predate `recipeSource` but carry
      // `savedFromRecipeId`; resolveSource() infers 'discovered' for them so
      // they remain unpublishable even without a migration.
      recipeSource: RecipePublishPolicy.resolveSource(
        recipeSource: data['recipeSource'] as String?,
        savedFromRecipeId:
            data['savedFromRecipeId'] ?? data['originalRecipeId'],
      ),
      originalRecipeId:
          (data['originalRecipeId'] ?? data['savedFromRecipeId']) as String?,
      savedFromOwnerId: data['savedFromOwnerId'] as String?,
      isFavorite: data['isFavorite'] == true,
    );
  }
  double get servingCount {
    if (servings == null) return 1;

    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(servings!);

    if (match == null) return 1;

    return double.tryParse(match.group(1)!) ?? 1;
  }
}

// class HomeController extends GetxController {
//   final RxList<RecipeModel> recipes = <RecipeModel>[].obs;
//   final RxBool isLoading = true.obs;
//   final RxList<CookbookModel> cookbooks = <CookbookModel>[].obs;

//   StreamSubscription? _authSub;
//   StreamSubscription? _recipesSub;
//   StreamSubscription? _cookbooksSub;

//   @override
//   void onInit() {
//     super.onInit();
//     // Re-fetch whenever auth changes. This fixes the case where the controller
//     // is created (permanent) before the user has logged in — authStateChanges
//     // emits the current user immediately and again on every sign-in/out.
//     _authSub = AuthService.authStateChanges.listen((user) {
//       if (user != null) {
//         fetchRecipes();
//         fetchCookbooks();
//       } else {
//         _recipesSub?.cancel();
//         _cookbooksSub?.cancel();
//         recipes.clear();
//         cookbooks.clear();
//         isLoading.value = false;
//       }
//     });
//   }

//   @override
//   void onClose() {
//     _authSub?.cancel();
//     _recipesSub?.cancel();
//     _cookbooksSub?.cancel();
//     super.onClose();
//   }

//   void fetchCookbooks() {
//     final uid = AuthService.currentUser?.uid;
//     if (uid == null) return;

//     _cookbooksSub?.cancel();
//     _cookbooksSub = FirebaseFirestore.instance
//         .collection("users")
//         .doc(uid)
//         .collection("cookbooks")
//         .snapshots()
//         .listen((snapshot) {
//           cookbooks.value = snapshot.docs
//               .map((e) => CookbookModel.fromDocument(e))
//               .toList();
//         });
//   }

//   void fetchRecipes() {
//     final uid = AuthService.currentUser?.uid;
//     if (uid == null) {
//       isLoading.value = false;
//       return;
//     }
//     isLoading.value = true;
//     _recipesSub?.cancel();

//     _recipesSub = FirebaseFirestore.instance
//         .collection('recipes')
//         .where('ownerId', isEqualTo: uid) // માત્ર પોતાના recipes
//         // .orderBy('createdAt', descending: true)
//         .snapshots()
//         .listen(
//           (snapshot) {
//             log("Docs: ${snapshot.docs.length}");

//             for (final doc in snapshot.docs) {
//               log(doc.data().toString());
//             }
//             recipes.value = snapshot.docs
//                 .map((doc) => RecipeModel.fromDocument(doc))
//                 .where((r) => !r.isDeleted)
//                 .toList();
//             isLoading.value = false;
//           },
//           onError: (error) {
//             isLoading.value = false;
//             CustomSnackbar.show(
//               title: 'Error',
//               message: 'Failed to fetch recipes: $error',
//               type: SnackbarType.error,
//             );
//           },
//         );
//   }

//   /// Deletes the recipe (image, Firestore doc) and cascades to the meal plan,
//   /// grocery list, and every cookbook that references it. The `recipes`
//   /// stream drops it automatically. Returns `true` on success so callers can
//   /// safely navigate away only when the recipe is actually gone.
//   Future<bool> deleteRecipe(RecipeModel recipe) async {
//     try {
//       final uid = AuthService.currentUser?.uid;

//       if (uid == null) {
//         CustomSnackbar.show(
//           title: 'Error',
//           message: 'User not logged in',
//           type: SnackbarType.error,
//         );

//         return false;
//       }

//       // Firebase Storage image delete
//       if (recipe.imageUrl != null &&
//           recipe.imageUrl!.isNotEmpty &&
//           recipe.imageUrl!.startsWith('http')) {
//         try {
//           await FirebaseStorage.instance.refFromURL(recipe.imageUrl!).delete();
//         } catch (e) {
//           log("Image delete error: $e");
//         }
//       }

//       // Firestore document delete
//       await FirebaseFirestore.instance
//           .collection('recipes')
//           .doc(recipe.id)
//           .delete();

//       // Cascade: drop this recipe from the meal plan, the grocery list, and
//       // any cookbook that still references it, so nothing dangling remains
//       // after the recipe is gone (this is what was leaving cookbooks with a
//       // stale "1/2 recipes" count but nothing showing inside).
//       if (Get.isRegistered<MealPlanController>()) {
//         await Get.find<MealPlanController>().removeMealsByRecipe(recipe.id);
//       }
//       if (Get.isRegistered<GroceryStore>()) {
//         Get.find<GroceryStore>().removeGroceriesByRecipe(recipe.id);
//       }
//       if (Get.isRegistered<CookbookController>()) {
//         await Get.find<CookbookController>().removeRecipeFromAllCookbooks(
//           recipe.id,
//         );
//       }

//       // If this was a recipe saved from Discover, clear the "saved" marker on
//       // the original so its Discover bookmark flips back to un-saved. Only
//       // discovered copies carry these fields, so owned recipes are unaffected.
//       if (recipe.isDiscoveredCopy &&
//           recipe.originalRecipeId != null &&
//           recipe.savedFromOwnerId != null) {
//         await RecipeSocialService.setSave(
//           recipe.savedFromOwnerId!,
//           recipe.originalRecipeId!,
//           false,
//         );
//         // Flip the Discover bookmark live (if the feed is loaded).
//         if (Get.isRegistered<DiscoverController>()) {
//           Get.find<DiscoverController>().savedOriginalIds.remove(
//             recipe.originalRecipeId,
//           );
//         }
//       }

//       CustomSnackbar.show(
//         title: 'Success',
//         message: 'Recipe deleted successfully',
//         type: SnackbarType.success,
//       );
//       return true;
//     } catch (e) {
//       CustomSnackbar.show(
//         title: 'Error',
//         message: 'Failed to delete recipe',
//         type: SnackbarType.error,
//       );
//       return false;
//     }
//   }

//   /// Owner-only: change a recipe's privacy. Writes the canonical [visibility]
//   /// field plus the mirrored [isPublic] flag and an [updatedAt] stamp.
//   /// Toggle the owner's favourite flag on a recipe. The live recipes stream
//   /// re-emits, so the heart on cards and the Favorites list update in real time.
//   Future<void> toggleFavorite(String recipeId, bool isFavorite) async {
//     try {
//       final uid = AuthService.currentUser?.uid;
//       if (uid == null) return;
//       FirebaseFirestore.instance.collection('recipes').doc(recipeId).update({
//         'isFavorite': isFavorite,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       log('toggleFavorite error: $e');
//     }
//   }

//   /// Persist the user's free-text note on a recipe. The live recipes stream
//   /// re-emits, so the note survives app restarts and syncs across devices.
//   Future<void> setNote(String recipeId, String note) async {
//     try {
//       final uid = AuthService.currentUser?.uid;
//       if (uid == null) return;
//       await FirebaseFirestore.instance.collection('recipes').doc(recipeId).set({
//         'note': note,
//         'updatedAt': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//     } catch (e) {
//       log('setNote error: $e');
//     }
//   }

//   /// Persist a computed nutrition estimate so it isn't recomputed every session.
//   Future<void> setNutrition(
//     String recipeId,
//     Map<String, dynamic> nutrition,
//   ) async {
//     try {
//       final uid = AuthService.currentUser?.uid;
//       if (uid == null) return;
//       await FirebaseFirestore.instance.collection('recipes').doc(recipeId).set({
//         'nutrition': nutrition,
//       }, SetOptions(merge: true));
//     } catch (e) {
//       log('setNutrition error: $e');
//     }
//   }

//   /// Update a recipe's ingredients / instructions / servings (used by the AI
//   /// Cooking Assistant's swap & scale apply). Updates the in-memory list first
//   /// so the detail screen reflects it instantly, then persists to Firestore.
//   Future<void> updateRecipeContent(
//     String recipeId, {
//     List<String>? ingredients,
//     List<String>? instructions,
//     List<IngredientSection>? ingredientSections,
//     List<InstructionSection>? instructionSections,
//     String? servings,
//   }) async {
//     final idx = recipes.indexWhere((r) => r.id == recipeId);
//     if (idx != -1) {
//       recipes[idx] = recipes[idx].copyWith(
//         ingredients: ingredients,
//         instructions: instructions,
//         ingredientSections: ingredientSections,
//         instructionSections: instructionSections,
//         servings: servings,
//       );
//       recipes.refresh();
//     }
//     try {
//       final uid = AuthService.currentUser?.uid;
//       if (uid == null) return;
//       final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
//       if (ingredients != null) data['ingredients'] = ingredients;
//       if (instructions != null) data['instructions'] = instructions;
//       if (ingredientSections != null) {
//         data['ingredientSections'] = ingredientSections
//             .map((s) => s.toMap())
//             .toList();
//       }
//       if (instructionSections != null) {
//         data['instructionSections'] = instructionSections
//             .map((s) => s.toMap())
//             .toList();
//       }
//       if (servings != null) data['servings'] = servings;
//       await FirebaseFirestore.instance
//           .collection('recipes')
//           .doc(recipeId)
//           .set(data, SetOptions(merge: true));
//     } catch (e) {
//       log('updateRecipeContent error: $e');
//     }
//   }

//   Future<void> updateRecipeVisibility(String recipeId, bool isPublic) async {
//     try {
//       final uid = AuthService.currentUser?.uid;
//       if (uid == null) return;

//       // Publish guard (defense-in-depth): a recipe saved from Discover can
//       // never be made public, no matter which UI path calls this. The backend
//       // Firestore rules enforce the same, so a bypass is rejected there too.
//       if (isPublic) {
//         RecipeModel? r;
//         for (final e in recipes) {
//           if (e.id == recipeId) {
//             r = e;
//             break;
//           }
//         }
//         if (r != null && !r.canBePublished) {
//           log('Blocked publish of discovered recipe $recipeId');
//           return;
//         }
//       }

//       await FirebaseFirestore.instance
//           .collection('recipes')
//           .doc(recipeId)
//           .update({
//             'isPublic': isPublic,
//             'updatedAt': FieldValue.serverTimestamp(),
//           });
//     } catch (e) {
//       log("Visibility update error: $e");
//     }
//   }

//   /// Silent migration: back-fill the `visibility` field on legacy documents
//   /// that predate the privacy system (called when a recipe is opened).
//   Future<void> migrateVisibility(String recipeId, String visibility) async {
//     try {
//       final uid = AuthService.currentUser?.uid;
//       if (uid == null) return;
//       await FirebaseFirestore.instance
//           .collection('recipes')
//           .doc(recipeId)
//           .update({'isPublic': visibility == 'public'});
//     } catch (_) {
//       // best-effort; never blocks the UI
//     }
//   }
// }

class HomeController extends GetxController {
  // ───────────────────────────────────────────────────────────────────────────
  // Observable UI data
  // ───────────────────────────────────────────────────────────────────────────

  final RxList<RecipeModel> recipes = <RecipeModel>[].obs;

  final RxBool isLoading = true.obs;

  final RxList<CookbookModel> cookbooks = <CookbookModel>[].obs;

  // ───────────────────────────────────────────────────────────────────────────
  // English source recipes
  //
  // IMPORTANT:
  // Firestore data is always English.
  // This list always contains the original English recipe.
  //
  // `recipes` contains the currently translated recipe shown in UI.
  // ───────────────────────────────────────────────────────────────────────────

  List<RecipeModel> _englishRecipes = [];

  // ───────────────────────────────────────────────────────────────────────────
  // Firestore subscriptions
  // ───────────────────────────────────────────────────────────────────────────

  StreamSubscription? _authSub;
  StreamSubscription? _recipesSub;
  StreamSubscription? _cookbooksSub;

  // ───────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ───────────────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    _authSub = AuthService.authStateChanges.listen((user) {
      if (user != null) {
        fetchRecipes();
        fetchCookbooks();
      } else {
        _recipesSub?.cancel();
        _cookbooksSub?.cancel();

        _englishRecipes.clear();
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

  // ===========================================================================
  // COOKBOOKS
  // ===========================================================================

  void fetchCookbooks() {
    final uid = AuthService.currentUser?.uid;

    if (uid == null) return;

    _cookbooksSub?.cancel();

    _cookbooksSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cookbooks')
        .snapshots()
        .listen((snapshot) {
          cookbooks.value = snapshot.docs
              .map((doc) => CookbookModel.fromDocument(doc))
              .toList();
        });
  }

  // ===========================================================================
  // RECIPES
  // ===========================================================================

  void fetchRecipes() {
    final uid = AuthService.currentUser?.uid;

    if (uid == null) {
      isLoading.value = false;
      return;
    }

    isLoading.value = true;

    _recipesSub?.cancel();

    _recipesSub = FirebaseFirestore.instance
        .collection('recipes')
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .listen(
          (snapshot) async {
            log('Docs: ${snapshot.docs.length}');

            // ---------------------------------------------------------------------
            // STEP 1:
            // Read Firestore data as English.
            //
            // RecipeModel.fromDocument() MUST NOT translate anything.
            // ---------------------------------------------------------------------

            final englishRecipes = snapshot.docs
                .map((doc) => RecipeModel.fromDocument(doc))
                .where((recipe) => !recipe.isDeleted)
                .toList();

            // Store original English recipes.
            _englishRecipes = englishRecipes;

            // ---------------------------------------------------------------------
            // STEP 2:
            // Translate English recipes to current app language.
            // ---------------------------------------------------------------------

            final localizedRecipes = await Future.wait(
              englishRecipes.map(_translateRecipe),
            );

            // ---------------------------------------------------------------------
            // STEP 3:
            // Show translated recipes in UI.
            // ---------------------------------------------------------------------

            recipes.value = localizedRecipes;

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

  // ===========================================================================
  // LANGUAGE CHANGE
  // ===========================================================================

  /// Call this method after changing the app language.
  ///
  /// Example:
  ///
  /// await LanguageService.changeLanguage('hi');
  /// await Get.find<HomeController>().refreshRecipesLanguage();
  ///
  Future<void> refreshRecipesLanguage() async {
    if (_englishRecipes.isEmpty) {
      return;
    }

    try {
      isLoading.value = true;

      // Always translate from original English.
      //
      // DO NOT translate from `recipes`, because `recipes` may already
      // contain Hindi / Gujarati / Spanish etc.
      final localizedRecipes = await Future.wait(
        _englishRecipes.map(_translateRecipe),
      );

      recipes.value = localizedRecipes;
    } catch (e, stack) {
      log('refreshRecipesLanguage error: $e');
      log(stack.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // TRANSLATION
  // ===========================================================================

  Future<RecipeModel> _translateRecipe(RecipeModel recipe) async {
    final language = LanguageService.currentCode;

    // English = no translation needed.
    if (language == 'en') {
      return recipe;
    }

    try {
      final translatedTitle = await AiTranslationService.translate(
        recipe.title,
      );

      final translatedDescription = recipe.description == null
          ? null
          : await AiTranslationService.translate(recipe.description!);

      final translatedCategory = recipe.category == null
          ? null
          : await AiTranslationService.translate(recipe.category!);

      final translatedCuisine = recipe.cuisine == null
          ? null
          : await AiTranslationService.translate(recipe.cuisine!);

      final translatedKeywords = await AiTranslationService.translateList(
        recipe.keywords,
      );

      final translatedIngredients = await AiTranslationService.translateList(
        recipe.ingredients,
      );

      final translatedInstructions = await AiTranslationService.translateList(
        recipe.instructions,
      );

      // -----------------------------------------------------------------------
      // Ingredient sections
      // -----------------------------------------------------------------------

      final translatedIngredientSections = await Future.wait(
        recipe.ingredientSections.map((section) async {
          final translatedName = await AiTranslationService.translate(
            section.name,
          );

          final translatedItems = await AiTranslationService.translateList(
            section.items,
          );

          return IngredientSection(
            name: translatedName,
            items: translatedItems,
          );
        }),
      );

      // -----------------------------------------------------------------------
      // Instruction sections
      // -----------------------------------------------------------------------

      final translatedInstructionSections = await Future.wait(
        recipe.instructionSections.map((section) async {
          final translatedName = await AiTranslationService.translate(
            section.name,
          );

          final translatedSteps = await AiTranslationService.translateList(
            section.steps,
          );

          return InstructionSection(
            name: translatedName,
            steps: translatedSteps,
          );
        }),
      );

      return recipe.copyWith(
        title: translatedTitle,
        description: translatedDescription,
        category: translatedCategory,
        cuisine: translatedCuisine,
        keywords: translatedKeywords,
        ingredients: translatedIngredients,
        instructions: translatedInstructions,
        ingredientSections: translatedIngredientSections,
        instructionSections: translatedInstructionSections,
      );
    } catch (e, stack) {
      log('Recipe translation failed for ${recipe.id}: $e');

      log(stack.toString());

      // If translation fails, show English recipe.
      return recipe;
    }
  }

  // ===========================================================================
  // DELETE RECIPE
  // ===========================================================================

  Future<bool> deleteRecipe(RecipeModel recipe) async {
    try {
      final uid = AuthService.currentUser?.uid;

      if (uid == null) {
        CustomSnackbar.show(
          title: 'Error',
          message: 'User not logged in',
          type: SnackbarType.error,
        );

        return false;
      }

      // Delete Firebase Storage image.
      if (recipe.imageUrl != null &&
          recipe.imageUrl!.isNotEmpty &&
          recipe.imageUrl!.startsWith('http')) {
        try {
          await FirebaseStorage.instance.refFromURL(recipe.imageUrl!).delete();
        } catch (e) {
          log('Image delete error: $e');
        }
      }

      // Delete Firestore recipe.
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipe.id)
          .delete();

      // Remove from meal plan.
      if (Get.isRegistered<MealPlanController>()) {
        await Get.find<MealPlanController>().removeMealsByRecipe(recipe.id);
      }

      // Remove groceries.
      if (Get.isRegistered<GroceryStore>()) {
        Get.find<GroceryStore>().removeGroceriesByRecipe(recipe.id);
      }

      // Remove from cookbooks.
      if (Get.isRegistered<CookbookController>()) {
        await Get.find<CookbookController>().removeRecipeFromAllCookbooks(
          recipe.id,
        );
      }

      // Discover saved recipe cleanup.
      if (recipe.isDiscoveredCopy &&
          recipe.originalRecipeId != null &&
          recipe.savedFromOwnerId != null) {
        await RecipeSocialService.setSave(
          recipe.savedFromOwnerId!,
          recipe.originalRecipeId!,
          false,
        );

        if (Get.isRegistered<DiscoverController>()) {
          Get.find<DiscoverController>().savedOriginalIds.remove(
            recipe.originalRecipeId,
          );
        }
      }

      CustomSnackbar.show(
        title: 'Success',
        message: 'Recipe deleted successfully',
        type: SnackbarType.success,
      );

      return true;
    } catch (e) {
      log('deleteRecipe error: $e');

      CustomSnackbar.show(
        title: 'Error',
        message: 'Failed to delete recipe',
        type: SnackbarType.error,
      );

      return false;
    }
  }

  // ===========================================================================
  // FAVORITE
  // ===========================================================================

  Future<void> toggleFavorite(String recipeId, bool isFavorite) async {
    try {
      final uid = AuthService.currentUser?.uid;

      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .update({
            'isFavorite': isFavorite,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      log('toggleFavorite error: $e');
    }
  }

  // ===========================================================================
  // NOTE
  // ===========================================================================

  Future<void> setNote(String recipeId, String note) async {
    try {
      final uid = AuthService.currentUser?.uid;

      if (uid == null) return;

      await FirebaseFirestore.instance.collection('recipes').doc(recipeId).set({
        'note': note,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      log('setNote error: $e');
    }
  }

  // ===========================================================================
  // NUTRITION
  // ===========================================================================

  Future<void> setNutrition(
    String recipeId,
    Map<String, dynamic> nutrition,
  ) async {
    try {
      final uid = AuthService.currentUser?.uid;

      if (uid == null) return;

      await FirebaseFirestore.instance.collection('recipes').doc(recipeId).set({
        'nutrition': nutrition,
      }, SetOptions(merge: true));
    } catch (e) {
      log('setNutrition error: $e');
    }
  }

  // ===========================================================================
  // UPDATE RECIPE CONTENT
  // ===========================================================================

  Future<void> updateRecipeContent(
    String recipeId, {
    List<String>? ingredients,
    List<String>? instructions,
    List<IngredientSection>? ingredientSections,
    List<InstructionSection>? instructionSections,
    String? servings,
  }) async {
    final idx = recipes.indexWhere((recipe) => recipe.id == recipeId);

    // -------------------------------------------------------------------------
    // Update UI immediately.
    //
    // IMPORTANT:
    // This updates current localized UI data.
    // Firestore update below currently stores the passed values.
    // For AI swap flow, ideally send English values here.
    // -------------------------------------------------------------------------

    if (idx != -1) {
      recipes[idx] = recipes[idx].copyWith(
        ingredients: ingredients,
        instructions: instructions,
        ingredientSections: ingredientSections,
        instructionSections: instructionSections,
        servings: servings,
      );

      recipes.refresh();
    }

    try {
      final uid = AuthService.currentUser?.uid;

      if (uid == null) return;

      final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};

      if (ingredients != null) {
        data['ingredients'] = ingredients;
      }

      if (instructions != null) {
        data['instructions'] = instructions;
      }

      if (ingredientSections != null) {
        data['ingredientSections'] = ingredientSections
            .map((section) => section.toMap())
            .toList();
      }

      if (instructionSections != null) {
        data['instructionSections'] = instructionSections
            .map((section) => section.toMap())
            .toList();
      }

      if (servings != null) {
        data['servings'] = servings;
      }

      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      log('updateRecipeContent error: $e');
    }
  }

  // ===========================================================================
  // VISIBILITY
  // ===========================================================================

  Future<void> updateRecipeVisibility(String recipeId, bool isPublic) async {
    try {
      final uid = AuthService.currentUser?.uid;

      if (uid == null) return;

      if (isPublic) {
        RecipeModel? recipe;

        for (final item in recipes) {
          if (item.id == recipeId) {
            recipe = item;
            break;
          }
        }

        if (recipe != null && !recipe.canBePublished) {
          log('Blocked publish of discovered recipe $recipeId');

          return;
        }
      }

      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .update({
            'isPublic': isPublic,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      log('Visibility update error: $e');
    }
  }

  // ===========================================================================
  // VISIBILITY MIGRATION
  // ===========================================================================

  Future<void> migrateVisibility(String recipeId, String visibility) async {
    try {
      final uid = AuthService.currentUser?.uid;

      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .update({'isPublic': visibility == 'public'});
    } catch (_) {
      // Best effort.
    }
  }
}
