import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Model/saved_recipe_from_web_model.dart';

import 'package:recipe_ai/Service/auth_service.dart';

import 'package:recipe_ai/Model/recipe_section_model.dart';
import 'package:recipe_ai/View/Home/cookbooks_screen.dart';
import 'package:recipe_ai/View/Home/import_processing_screen.dart';
import 'package:recipe_ai/View/Home/import_complete_screen.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';

class RecipeImportService {
  RecipeImportService._();

  static const int _maxInlineVideoBytes = 15 * 1024 * 1024;

  static final _urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);

  static String? extractUrl(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final match = _urlPattern.firstMatch(text.trim());
    if (match == null) return null;
    return match.group(0)!.replaceAll(RegExp(r'''[)\]}>"']+$'''), '');
  }

  static Future<String> askGemini(String prompt) async {
    final callable = FirebaseFunctions.instance.httpsCallable('askGemini');

    final result = await callable.call({'prompt': prompt});

    if (result.data['success'] == true) {
      return result.data['text'];
    }

    throw Exception(result.data['error']);
  }

  static Future<Map<String, dynamic>> getRecipeFromImage(File image) async {
    final bytes = await image.readAsBytes();

    final callable = FirebaseFunctions.instance.httpsCallable(
      'analyzeRecipeImage',
    );

    final result = await callable.call({'image': base64Encode(bytes)});

    final data = Map<String, dynamic>.from(result.data);

    if (data['success'] != true) {
      throw Exception(data['error']);
    }

    return Map<String, dynamic>.from(data['recipe']);
  }

  static Future<Map<String, dynamic>> getRecipeFromSocialContent({
    String? url,
    String? caption,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'extractRecipeFromSocialContent',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );

    final result = await callable.call({
      if (url != null && url.isNotEmpty) 'url': url,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
    });

    final data = Map<String, dynamic>.from(result.data);

    if (data['success'] != true) {
      throw Exception(data['error']);
    }

    return Map<String, dynamic>.from(data['recipe']);
  }

  static Future<Map<String, dynamic>> getRecipeFromVideo(
    File videoFile, {
    String? sourceUrl,
  }) async {
    final bytes = await videoFile.readAsBytes();
    final extension = videoFile.path.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      'mkv' => 'video/x-matroska',
      _ => 'video/mp4',
    };

    final callable = FirebaseFunctions.instance.httpsCallable(
      'analyzeRecipeVideo',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 300)),
    );

    if (bytes.length <= _maxInlineVideoBytes) {
      final result = await callable.call({
        'video': base64Encode(bytes),
        'mimeType': mimeType,
        if (sourceUrl != null) 'sourceUrl': sourceUrl,
      });

      final data = Map<String, dynamic>.from(result.data);
      if (data['success'] != true) {
        throw Exception(data['error']);
      }
      return Map<String, dynamic>.from(data['recipe']);
    }

    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be logged in to import videos.');
    }

    final fileName =
        'video_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final ref = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(uid)
        .child('imports')
        .child(fileName);

    await ref.putData(bytes, SettableMetadata(contentType: mimeType));

    final result = await callable.call({
      'storagePath': ref.fullPath,
      'mimeType': mimeType,
      if (sourceUrl != null) 'sourceUrl': sourceUrl,
    });

    final data = Map<String, dynamic>.from(result.data);
    if (data['success'] != true) {
      throw Exception(data['error']);
    }
    return Map<String, dynamic>.from(data['recipe']);
  }

  static Future<void> _saveRecipeAndNavigate({
    required SavedRecipe recipe,
    required String sourceUrl,
    String? firebaseImageUrl,
    String? remoteImageUrl,
  }) async {
    final uid = AuthService.currentUser?.uid;

    if (uid == null) {
      throw Exception('You must be logged in to save recipes.');
    }

    final imageUrl =
        firebaseImageUrl ??
        remoteImageUrl ??
        (recipe.imageUrl?.isNotEmpty == true ? recipe.imageUrl : null);

    final docRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('recipes')
        .add({
          'title': recipe.title,
          'description': recipe.description,
          'imageUrl': imageUrl,
          'sourceUrl': sourceUrl,
          'prepTime': recipe.prepTime,
          'cookTime': recipe.cookTime,
          'totalTime': recipe.totalTime,
          'servings': recipe.servings.toString(),
          'category': recipe.category,
          'cuisine': recipe.cuisine,
          'keywords': recipe.keywords,
          'ingredientSections': recipe.ingredientSections
              .map((e) => {'name': e.name, 'items': e.items})
              .toList(),
          'instructionSections': recipe.instructionSections
              .map((e) => {'name': e.name, 'steps': e.steps})
              .toList(),
          'ingredients': recipe.ingredients,
          'instructions': recipe.instructions,
          'createdAt': FieldValue.serverTimestamp(),
        });

    final recipeModel = RecipeModel(
      id: docRef.id,
      title: recipe.title,
      description: recipe.description,
      imageUrl: imageUrl,
      sourceUrl: sourceUrl,
      prepTime: recipe.prepTime,
      cookTime: recipe.cookTime,
      totalTime: recipe.totalTime,
      servings: recipe.servings.toString(),
      category: recipe.category,
      cuisine: recipe.cuisine,
      keywords: recipe.keywords,
      ingredients: recipe.ingredients,
      instructions: recipe.instructions,
      ingredientSections: recipe.ingredientSections
          .map((e) => IngredientSection(name: e.name, items: e.items))
          .toList(),
      instructionSections: recipe.instructionSections
          .map((e) => InstructionSection(name: e.name, steps: e.steps))
          .toList(),
    );

    log("firebaseImageUrl = $firebaseImageUrl");
    log("remoteImageUrl = $remoteImageUrl");
    log("recipe.imageUrl = ${recipe.imageUrl}");
    log("final imageUrl = $imageUrl");

    Get.off(
      () => ImportCompleteScreen(recipe: recipeModel),
      transition: Transition.fadeIn,
    );
  }

  static Future<String?> _uploadImageFile(File imageFile, String uid) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileName = 'recipe_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('recipes')
          .child(fileName);

      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return ref.getDownloadURL();
    } catch (e) {
      log('Image upload error: $e');
      return null;
    }
  }

  static Future<void> _runImport({
    required List<String> loadingSteps,
    required String errorMessage,
    required Future<void> Function() import,
  }) async {
    Get.to(
      () => ImportProcessingScreen(steps: loadingSteps),
      transition: Transition.fadeIn,
    );

    try {
      await import();
    } catch (e, stack) {
      log('Import error: $e');
      log(stack.toString());

      Get.back();

      CustomSnackbar.show(
        title: 'Error',
        message: errorMessage,
        type: SnackbarType.error,
      );
    }
  }

  static Future<void> importRecipeFromGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final nav = Navigator.of(context);

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    nav.pop();

    await _runImport(
      loadingSteps: const [
        'Reading your image…',
        'Identifying ingredients…',
        'Building instructions…',
        'Saving your recipe…',
      ],
      errorMessage: 'Could not read recipe from image. Please try again.',
      import: () async {
        final uid = AuthService.currentUser?.uid;
        if (uid == null) {
          if (Get.isDialogOpen ?? false) Get.back();
          CustomSnackbar.show(
            title: 'Error',
            message: 'You must be logged in to save recipes.',
            type: SnackbarType.error,
          );
          return;
        }

        final recipeData = await getRecipeFromImage(File(image.path));
        final recipe = SavedRecipe.fromGeminiResponse(recipeData);
        final firebaseImageUrl = await _uploadImageFile(File(image.path), uid);

        await _saveRecipeAndNavigate(
          recipe: recipe,
          sourceUrl: 'gemini_image_import',
          firebaseImageUrl: firebaseImageUrl,
        );
      },
    );
  }

  static Future<void> importRecipeFromSharedImage(File imageFile) async {
    await _runImport(
      loadingSteps: const [
        'Reading shared image…',
        'Identifying ingredients…',
        'Building instructions…',
        'Saving your recipe…',
      ],
      errorMessage: 'Failed to import recipe from shared image.',
      import: () async {
        final uid = AuthService.currentUser?.uid;
        if (uid == null) {
          if (Get.isDialogOpen ?? false) Get.back();
          CustomSnackbar.show(
            title: 'Error',
            message: 'You must be logged in to save recipes.',
            type: SnackbarType.error,
          );
          return;
        }

        final recipeData = await getRecipeFromImage(imageFile);
        final recipe = SavedRecipe.fromGeminiResponse(recipeData);
        final firebaseImageUrl = await _uploadImageFile(imageFile, uid);

        await _saveRecipeAndNavigate(
          recipe: recipe,
          sourceUrl: 'instagram_share',
          firebaseImageUrl: firebaseImageUrl,
        );
      },
    );
  }

  static Future<void> importRecipeFromSharedVideo(
    File videoFile, {
    String? sourceUrl,
  }) async {
    await _runImport(
      loadingSteps: const [
        'Reading shared video…',
        'Analyzing cooking steps…',
        'Building recipe…',
        'Saving your recipe…',
      ],
      errorMessage: 'Failed to import recipe from shared video.',
      import: () async {
        final recipeData = await getRecipeFromVideo(
          videoFile,
          sourceUrl: sourceUrl,
        );
        final recipe = SavedRecipe.fromGeminiResponse(recipeData);

        await _saveRecipeAndNavigate(
          recipe: recipe,
          sourceUrl: sourceUrl ?? 'social_video_share',
        );
      },
    );
  }

  static Future<String?> uploadNetworkImage(String imageUrl, String uid) async {
    try {
      // final response = await http.get(Uri.parse(imageUrl));
      final response = await http.get(Uri.parse(imageUrl));

      final bytes = response.bodyBytes;

      log("Downloaded Size = ${bytes.length}");

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      log("Width=${frame.image.width} Height=${frame.image.height}");

      if (response.statusCode != 200) {
        log("Image download failed: ${response.statusCode}");
        return null;
      }

      final fileName = 'recipe_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('recipes')
          .child(fileName);

      await ref.putData(
        response.bodyBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await ref.getDownloadURL();

      log("Firebase Image URL: $downloadUrl");

      return downloadUrl;
    } catch (e) {
      log("uploadNetworkImage error: $e");
      return null;
    }
  }

  static Future<void> importRecipeFromSocialContent({
    String? url,
    String? caption,
  }) async {
    await _runImport(
      loadingSteps: const [
        'Reading post content…',
        'Extracting recipe details…',
        'Structuring ingredients…',
        'Saving your recipe…',
      ],
      errorMessage:
          'Could not extract recipe from this post. Try sharing the image or video directly.',
      import: () async {
        final uid = AuthService.currentUser?.uid;

        if (uid == null) {
          throw Exception('You must be logged in.');
        }

        final recipeData = await getRecipeFromSocialContent(
          url: url,
          caption: caption,
        );

        log("Recipe Data: ${jsonEncode(recipeData)}");

        final recipe = SavedRecipe.fromGeminiResponse(recipeData);

        log("Recipe Image URL: ${recipe.imageUrl}");

        String? firebaseImageUrl;

        // Try to save remote image into Firebase Storage
        if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty) {
          firebaseImageUrl = await uploadNetworkImage(recipe.imageUrl!, uid);

          log("firebaseImageUrl = $firebaseImageUrl");
        }

        await _saveRecipeAndNavigate(
          recipe: recipe,
          sourceUrl: url ?? recipe.sourceUrl ?? 'social_media_import',
          firebaseImageUrl: firebaseImageUrl,
          remoteImageUrl: firebaseImageUrl == null ? recipe.imageUrl : null,
        );
      },
    );
  }

  static Future<Map<String, dynamic>> getRecipeFromName(
    String recipeName,
  ) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'generateRecipeFromName',
    );

    final result = await callable.call({'recipeName': recipeName});

    final data = Map<String, dynamic>.from(result.data);

    if (data['success'] != true) {
      throw Exception('Recipe generation failed');
    }

    return Map<String, dynamic>.from(data['recipe']);
  }

  static Future<void> importRecipeFromName(String recipeName) async {
    await _runImport(
      loadingSteps: const [
        'Searching recipe...',
        'Generating ingredients...',
        'Generating instructions...',
        'Saving recipe...',
      ],
      errorMessage: 'Failed to generate recipe.',
      import: () async {
        final uid = AuthService.currentUser?.uid;

        if (uid == null) {
          throw Exception('Login required');
        }

        final recipeData = await getRecipeFromName(recipeName);

        final recipe = SavedRecipe.fromGeminiResponse(recipeData);

        String? firebaseImageUrl;

        if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty) {
          firebaseImageUrl = await uploadNetworkImage(recipe.imageUrl!, uid);
        }

        await _saveRecipeAndNavigate(
          recipe: recipe,
          sourceUrl: 'recipe_name_search',
          firebaseImageUrl: firebaseImageUrl,
        );
      },
    );
  }
}
