import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;
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

import 'package:recipe_ai/View/Home/import_processing_screen.dart';
import 'package:recipe_ai/View/Home/import_complete_screen.dart';
import 'package:recipe_ai/widgets/custom_snackbar.dart';
import 'package:recipe_ai/Service/subscription_service.dart';

/// Thrown when an imported image/post doesn't actually contain a recipe, so the
/// import is aborted (no recipe generated, no save) with a clear message.
class _NotARecipeException implements Exception {
  final String message;
  const _NotARecipeException(this.message);
  @override
  String toString() => message;
}

class RecipeImportService {
  static const int _maxInlineVideoBytes = 15 * 1024 * 1024;

  static final _urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);

  static String? extractUrl(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final match = _urlPattern.firstMatch(text.trim());
    if (match == null) return null;
    return match.group(0)!.replaceAll(RegExp(r'''[)\]}>"']+$'''), '');
  }

  static Future<String> askGemini(String prompt) async {
    log('start');
    final callable = FirebaseFunctions.instance.httpsCallable('askGemini');

    final result = await callable.call({'prompt': prompt});

    if (result.data['success'] == true) {
      log('finis');
      return result.data['text'];
    }

    throw Exception(result.data['error']);
  }

  static Future<void> importRecipeFromImage(
    BuildContext context,
    File imageFile,
  ) async {
    final totalStopwatch = Stopwatch()..start();

    log('========== IMAGE IMPORT STARTED ==========');

    await _runImport(
      loadingSteps: const [
        'Reading your image…',
        'Identifying ingredients…',
        'Building instructions…',
        'Saving your recipe…',
      ],
      errorMessage: 'Could not read recipe from image. Please try again.',
      import: (doneSignal) async {
        final uid = AuthService.currentUser?.uid;

        if (uid == null) {
          throw Exception('You must be logged in to save recipes.');
        }

        log('[PARALLEL] AI + IMAGE UPLOAD STARTED');

        final aiStopwatch = Stopwatch()..start();
        final uploadStopwatch = Stopwatch()..start();

        // બંને calls simultaneously start
        final aiFuture = getRecipeFromImage(imageFile).then((result) {
          aiStopwatch.stop();

          log(
            '[AI] COMPLETED: '
            '${aiStopwatch.elapsedMilliseconds} ms',
          );

          return result;
        });

        final uploadFuture = _uploadImageFile(imageFile, uid).then((result) {
          uploadStopwatch.stop();

          log(
            '[UPLOAD] COMPLETED: '
            '${uploadStopwatch.elapsedMilliseconds} ms',
          );

          return result;
        });

        // બંને parallel run થાય છે
        final results = await Future.wait([aiFuture, uploadFuture]);

        final recipeData = results[0] as Map<String, dynamic>;

        final firebaseImageUrl = results[1] as String?;

        // Validation
        if (!_isRecipeResult(recipeData)) {
          throw const _NotARecipeException(
            "This image isn't a recipe. Please add a photo of a "
            "dish or a recipe card.",
          );
        }

        final recipe = SavedRecipe.fromGeminiResponse(recipeData);

        await _saveRecipeAndNavigate(
          recipe: recipe,
          sourceUrl: 'gemini_image_import',
          firebaseImageUrl: firebaseImageUrl,
          doneSignal: doneSignal,
        );

        totalStopwatch.stop();

        log(
          '========== IMAGE IMPORT COMPLETED ==========\n'
          'TOTAL TIME: '
          '${totalStopwatch.elapsedMilliseconds} ms '
          '(${totalStopwatch.elapsed.inSeconds}s)',
        );
      },
    );
  }

  static Future<Map<String, dynamic>> getRecipeFromImage(File image) async {
    final stopwatch = Stopwatch()..start();

    final callable = FirebaseFunctions.instance.httpsCallable(
      'analyzeRecipeImage',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );

    final originalBytes = await image.readAsBytes();

    log(
      'ORIGINAL IMAGE SIZE: '
      '${(originalBytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
    );

    // Same 1020px cap as the stored image — fewer vision tiles, so lower token
    // cost per import.
    final compressedBytes = await _compressImageBytes(originalBytes);

    if (compressedBytes == null || compressedBytes.isEmpty) {
      throw Exception('Failed to compress image.');
    }

    log(
      'COMPRESSED IMAGE SIZE: '
      '${(compressedBytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
    );

    final result = await callable.call({
      'image': base64Encode(compressedBytes),
    });

    final data = Map<String, dynamic>.from(result.data);

    if (data['success'] != true) {
      throw Exception(data['error']);
    }

    stopwatch.stop();

    log(
      'TOTAL IMAGE AI TIME: '
      '${stopwatch.elapsedMilliseconds} ms '
      '(${stopwatch.elapsed.inSeconds}s)',
    );

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
    bool isVideoImport = false,
    Completer<void>? doneSignal,
  }) async {
    final uid = AuthService.currentUser?.uid;

    if (uid == null) {
      throw Exception('You must be logged in to save recipes.');
    }

    log('========== SAVE RECIPE STARTED ==========');
    log('Recipe: ${recipe.title}');
    log('Source: $sourceUrl');
    log('firebaseImageUrl: ${firebaseImageUrl ?? "null"}');
    log('remoteImageUrl: ${remoteImageUrl ?? "null"}');
    log('isVideoImport: $isVideoImport');

    String? imageUrl;

    // ============================================================
    // CASE 1: VIDEO IMPORT
    // ============================================================
    //
    // Video has no direct recipe image.
    //
    // Therefore:
    // ❌ Do not use video thumbnail
    // ❌ Do not use Picsum placeholder
    // ❌ Do not use TheMealDB/Wikipedia image
    //
    // ✅ Generate a new AI food image in background.
    //
    if (isVideoImport) {
      imageUrl = '';

      log(
        '[VIDEO IMPORT] No existing image found. '
        'AI image generation will start.',
      );
    }

    // ============================================================
    // CASE 2: IMAGE / SOCIAL IMAGE IMPORT
    // ============================================================
    //
    // Existing image should always be used.
    //
    // Priority:
    // 1. Uploaded Firebase image
    // 2. Remote social image
    // 3. Image URL returned by AI
    //
    // ❌ AI image generation is NOT done.
    //
    if (!isVideoImport) {
      imageUrl = firebaseImageUrl ?? remoteImageUrl ?? '';

      log(
        '[IMAGE IMPORT] Existing Firebase image selected: '
        '${imageUrl.isEmpty ? "NO IMAGE" : imageUrl}',
      );
    }

    // ============================================================
    // CASE 3: NO IMAGE AVAILABLE
    // ============================================================
    //
    // This is mainly for recipe-name import.
    //
    // Example:
    // Recipe name → AI recipe generated → no image
    //
    // Therefore:
    // ✅ Save recipe first
    // ✅ Generate AI image in background
    //
    bool needsImageGeneration = false;

    if (!isVideoImport &&
        (imageUrl == null || imageUrl.isEmpty) &&
        sourceUrl != 'social_caption_import' &&
        sourceUrl != 'social_video_share' &&
        !sourceUrl.startsWith('http')) {
      needsImageGeneration = true;

      imageUrl = '';

      log(
        '[NO IMAGE] No existing image found. '
        'AI image generation will start.',
      );
    }

    // ============================================================
    // CONSUME CREDIT
    // ============================================================

    final hasCredit = await SubscriptionService.instance.consumeCredit();

    if (!hasCredit) {
      throw Exception('Not enough credits to save this recipe.');
    }

    // ============================================================
    // SAVE RECIPE TO FIRESTORE
    // ============================================================

    final docRef = await FirebaseFirestore.instance.collection('recipes').add({
      'title': recipe.title,
      'description': recipe.description,

      // For image import:
      //     Existing image URL
      //
      // For video/name import:
      //     Empty initially.
      //     Firebase Function will update it after AI generation.
      'imageUrl': imageUrl ?? '',

      'sourceUrl': sourceUrl,

      'prepTime': recipe.prepTime,
      'cookTime': recipe.cookTime,
      'totalTime': recipe.totalTime,
      'servings': recipe.servings.toString(),

      'category': recipe.category,
      'cuisine': recipe.cuisine,
      'keywords': recipe.keywords,

      'ingredients': recipe.ingredients,
      'instructions': recipe.instructions,

      'ingredientSections': recipe.ingredientSections
          .map((e) => {'name': e.name, 'items': e.items})
          .toList(),

      'instructionSections': recipe.instructionSections
          .map((e) => {'name': e.name, 'steps': e.steps})
          .toList(),
      'isPublic': false,
      'recipeSource': 'imported',
      'originalRecipeId': null,
      'ownerId': uid,
      'isDeleted': false,

      'likesCount': 0,
      'commentsCount': 0,
      'savesCount': 0,
      'sharesCount': 0,
      'viewsCount': 0,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    log('[FIRESTORE] Recipe saved: ${docRef.id}');

    // ============================================================
    // AI IMAGE GENERATION
    // ============================================================
    //
    // VIDEO:
    // ✅ Always generate AI image
    //
    // IMAGE:
    // ❌ Never generate AI image
    //
    // RECIPE NAME / NO IMAGE:
    // ✅ Generate AI image
    //
    if (isVideoImport || needsImageGeneration) {
      log(
        '[AI IMAGE] Starting background image generation | '
        'recipeId=${docRef.id}',
      );

      unawaited(
        _generateRealImageInBackground(
          recipeId: docRef.id,
          title: recipe.title,
          description: recipe.description,
        ),
      );
    } else {
      log(
        '[AI IMAGE] Generation SKIPPED. '
        'Existing image is already available.',
      );
    }

    // ============================================================
    // CREATE UI MODEL
    // ============================================================

    final recipeModel = RecipeModel(
      id: docRef.id,
      title: recipe.title,
      description: recipe.description,

      // For video/name import this is initially empty.
      // The recipe detail screen can listen to Firestore updates
      // and receive the generated image later.
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

    // ============================================================
    // COMPLETE PROCESSING SCREEN
    // ============================================================

    if (doneSignal != null && !doneSignal.isCompleted) {
      doneSignal.complete();

      await Future.delayed(const Duration(milliseconds: 350));
    }

    // ============================================================
    // NAVIGATE TO COMPLETE SCREEN
    // ============================================================

    Get.off(
      () => ImportCompleteScreen(recipe: recipeModel),
      transition: Transition.fadeIn,
    );

    log('========== SAVE RECIPE COMPLETED ==========');
  }

  static Future<void> _generateRealImageInBackground({
    required String recipeId,
    required String title,
    String? description,
    String? imagePrompt,
  }) async {
    try {
      log(
        '[AI IMAGE] Generation STARTED | '
        'recipeId=$recipeId',
      );

      final callable = FirebaseFunctions.instance.httpsCallable(
        'generateRecipeImage',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      );

      final result = await callable.call({
        'recipeId': recipeId,

        // IMPORTANT:
        // Cloud Function expects recipe object
        'recipe': {
          'title': title,
          'description': description ?? '',
          'imagePrompt': imagePrompt ?? '',
        },
      });

      final data = Map<String, dynamic>.from(result.data);

      log(
        '[AI IMAGE] Generation COMPLETED | '
        'recipeId=$recipeId',
      );

      log('[AI IMAGE] Response: $data');

      if (data['success'] != true) {
        log(
          '[AI IMAGE] Generation FAILED | '
          '${data['error']}',
        );
        return;
      }

      final imageUrl = data['imageUrl']?.toString();

      if (imageUrl == null || imageUrl.isEmpty) {
        log('[AI IMAGE] imageUrl is empty');
        return;
      }

      // If Cloud Function does not update Firestore itself,
      // update it here.
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .update({
            'imageUrl': imageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      log(
        '[AI IMAGE] Firestore image URL updated SUCCESS | '
        'recipeId=$recipeId',
      );
    } catch (e, stack) {
      log('[AI IMAGE] Generation FAILED: $e');
      log(stack.toString());
    }
  }

  static Future<String?> _uploadImageFile(File imageFile, String uid) async {
    try {
      final originalBytes = await imageFile.readAsBytes();

      log(
        '[ImageUpload] Original size: '
        '${(originalBytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      final compressedBytes = await _compressImageBytes(originalBytes);

      if (compressedBytes == null || compressedBytes.isEmpty) {
        log('[ImageUpload] Compression failed');
        return null;
      }

      log(
        '[ImageUpload] Compressed size: '
        '${(compressedBytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      final fileName = 'recipe_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('recipes')
          .child(fileName);

      await ref.putData(
        compressedBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public,max-age=31536000',
        ),
      );

      return await ref.getDownloadURL();
    } catch (e, stack) {
      log('[ImageUpload] ERROR: $e');
      log(stack.toString());
      return null;
    }
  }

  /// Runs an import behind the processing screen. Returns `true` when the
  /// import completed successfully (and the complete/review screen is shown),
  /// or `false` when it failed (processing dismissed + error snackbar).
  //

  static Future<bool> _runImport({
    required List<String> loadingSteps,
    required String errorMessage,
    required Future<void> Function(Completer<void> doneSignal) import,
  }) async {
    final doneSignal = Completer<void>();

    Get.to(
      () => ImportProcessingScreen(
        steps: loadingSteps,
        doneSignal: doneSignal.future,
      ),
      transition: Transition.fadeIn,
    );

    try {
      await import(doneSignal);
      return true;
    } catch (e, stack) {
      log('Import error: $e');
      log(stack.toString());

      if (!doneSignal.isCompleted) doneSignal.complete();

      Get.back();

      final notRecipe = e is _NotARecipeException;
      CustomSnackbar.show(
        title: notRecipe ? 'Not a recipe' : 'Error',
        message: notRecipe ? e.message : errorMessage,
        type: SnackbarType.error,
      );
      return false;
    }
  }

  /// A recipe result is only real when the AI flagged it as a recipe AND it
  /// has a real title AND it actually contains ingredients or steps. A photo of
  /// a person, a document, a landscape, etc. yields an `isRecipe:false` flag or
  /// an empty/"Unknown" title with no real content — so we abort instead of
  /// saving a made-up "Unknown Recipe".
  static bool _isRecipeResult(Map<String, dynamic> data) {
    // Explicit backend flag — the strongest signal.
    if (data['isRecipe'] == false) return false;

    bool nonEmptyList(dynamic v) => v is List && v.isNotEmpty;
    bool sectionsHaveEntries(dynamic v, String key) =>
        v is List &&
        v.any((s) => s is Map && s[key] is List && (s[key] as List).isNotEmpty);

    final hasIngredients =
        nonEmptyList(data['ingredients']) ||
        sectionsHaveEntries(data['ingredientSections'], 'items');
    final hasInstructions =
        nonEmptyList(data['instructions']) ||
        sectionsHaveEntries(data['instructionSections'], 'steps');

    // A genuine recipe always has a real title. An empty or placeholder title
    // ("Unknown"/"Untitled") means the AI didn't actually read a recipe — a
    // common shape for hallucinated non-food results — so treat it as not a
    // recipe. This also guards older backends that predate the isRecipe flag.
    final title = (data['title'] ?? '').toString().trim().toLowerCase();
    const placeholders = {'', 'unknown', 'unknown recipe', 'untitled', 'n/a'};
    final hasRealTitle = !placeholders.contains(title);

    return hasRealTitle && (hasIngredients || hasInstructions);
  }

  static Future<void> importRecipeFromGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final nav = Navigator.of(context);

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2000,
      maxHeight: 2000,
    );
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
      import: (doneSignal) async {
        final uid = AuthService.currentUser?.uid;
        if (uid == null) {
          if (!doneSignal.isCompleted) doneSignal.complete();
          if (Get.isDialogOpen ?? false) Get.back();
          CustomSnackbar.show(
            title: 'Error',
            message: 'You must be logged in to save recipes.',
            type: SnackbarType.error,
          );
          return;
        }

        final imageFile = File(image.path);

        final results = await Future.wait([
          getRecipeFromImage(imageFile),
          _uploadImageFile(imageFile, uid),
        ]);

        final recipeData = results[0] as Map<String, dynamic>;

        final firebaseImageUrl = results[1] as String?;

        if (!_isRecipeResult(recipeData)) {
          throw const _NotARecipeException(
            "This image isn't a recipe. Please go back and add a photo of a "
            "dish or a recipe card.",
          );
        }

        final recipe = SavedRecipe.fromGeminiResponse(recipeData);

        await _saveRecipeAndNavigate(
          recipe: recipe,
          sourceUrl: 'gemini_image_import',
          firebaseImageUrl: firebaseImageUrl,
          doneSignal: doneSignal,
        );
        // final recipe = SavedRecipe.fromGeminiResponse(recipeData);
        // final firebaseImageUrl = await _uploadImageFile(File(image.path), uid);
      },
    );
  }

  // ============================================================
  // SOCIAL CONTENT IMPORT
  // ============================================================

  static Future<void> importRecipeFromSocialContent({
    String? url,
    String? caption,
  }) async {
    final totalTimer = Stopwatch()..start();

    await _runImport(
      loadingSteps: const [
        'Reading social media content…',
        'Extracting recipe…',
        'Preparing ingredients…',
        'Saving your recipe…',
      ],
      errorMessage: 'Failed to import recipe from social media.',
      import: (doneSignal) async {
        try {
          log('========== SOCIAL IMPORT STARTED ==========');
          log('[SocialImport] URL: ${url ?? "null"}');
          log('[SocialImport] Caption available: ${caption != null}');

          if ((url == null || url.trim().isEmpty) &&
              (caption == null || caption.trim().isEmpty)) {
            throw Exception('No social content found.');
          }

          // ========================================================
          // STEP 1: AI RECIPE EXTRACTION
          // ========================================================

          final aiTimer = Stopwatch()..start();

          final recipeData = await getRecipeFromSocialContent(
            url: url,
            caption: caption,
          );

          aiTimer.stop();

          log(
            '[SocialImport] AI extraction DONE | '
            '${aiTimer.elapsedMilliseconds} ms',
          );

          if (recipeData.isEmpty) {
            throw Exception('Recipe data is empty.');
          }

          // ========================================================
          // STEP 2: VALIDATE RECIPE
          // ========================================================

          if (!_isRecipeResult(recipeData)) {
            throw const _NotARecipeException(
              "This social media content doesn't contain a valid recipe.",
            );
          }

          // ========================================================
          // STEP 3: CONVERT RECIPE
          // ========================================================

          final recipe = SavedRecipe.fromGeminiResponse(recipeData);

          log(
            '[SocialImport] Recipe parsed | '
            'title=${recipe.title}',
          );

          // ========================================================
          // STEP 4: SAVE RECIPE IMMEDIATELY
          // ========================================================
          //
          // Existing image from AI response is used immediately.
          // Original social thumbnail is processed in background.
          //

          final remoteImageUrl = recipeData['imageUrl']?.toString();

          final isVideoImport = _isVideoSocialContent(
            url: url,
            recipeData: recipeData,
          );

          log(
            '[SocialImport] Media type detected | '
            'isVideoImport=$isVideoImport | '
            'mediaType=${recipeData['mediaType']}',
          );

          await _saveRecipeAndNavigate(
            recipe: recipe,
            sourceUrl: url ?? 'social_caption_import',
            remoteImageUrl: remoteImageUrl,

            // Reel/Video => AI image generate
            // Image post => existing image use
            isVideoImport: isVideoImport,

            doneSignal: doneSignal,
          );
          log(
            '[SocialImport] RECIPE DISPLAYED | '
            '${totalTimer.elapsedMilliseconds} ms',
          );

          // ========================================================
          // STEP 5: BACKGROUND IMAGE PROCESSING
          // ========================================================
          //
          // Only possible when a real social URL exists.
          //

          if (url != null && url.trim().isNotEmpty && !isVideoImport) {
            unawaited(
              uploadSocialImageInBackground(recipe: recipe, sourceUrl: url),
            );
          }

          totalTimer.stop();

          log(
            '========== SOCIAL IMPORT COMPLETED ==========\n'
            'TOTAL TIME: '
            '${totalTimer.elapsedMilliseconds} ms '
            '(${totalTimer.elapsed.inSeconds}s)',
          );
        } catch (e, stack) {
          totalTimer.stop();

          log('[SocialImport] FAILED: $e');
          log(stack.toString());

          rethrow;
        }
      },
    );
  }

  static bool _isVideoSocialContent({
    required String? url,
    required Map<String, dynamic> recipeData,
  }) {
    // Backend value is the most reliable
    final mediaType = recipeData['mediaType']?.toString().toLowerCase().trim();

    if (mediaType == 'video' || mediaType == 'reel') {
      return true;
    }

    if (mediaType == 'image' || mediaType == 'photo') {
      return false;
    }

    // Fallback: Instagram Reel URL
    final normalizedUrl = url?.toLowerCase() ?? '';

    if (normalizedUrl.contains('/reel/') ||
        normalizedUrl.contains('/reels/') ||
        normalizedUrl.contains('/tv/')) {
      return true;
    }

    return false;
  }
  // ============================================================
  // SHARED IMAGE IMPORT
  // ============================================================

  static Future<void> importRecipeFromSharedImage(File imageFile) async {
    await _runImport(
      loadingSteps: const [
        'Reading shared image…',
        'Identifying ingredients…',
        'Building instructions…',
        'Saving your recipe…',
      ],
      errorMessage: 'Failed to import recipe from shared image.',
      import: (doneSignal) async {
        final uid = AuthService.currentUser?.uid;

        if (uid == null) {
          throw Exception('You must be logged in to save recipes.');
        }

        log('[SharedImage] AI + Firebase upload STARTED');

        // AI analysis and Firebase upload run in parallel.
        final results = await Future.wait([
          getRecipeFromImage(imageFile),
          _uploadImageFile(imageFile, uid),
        ]);

        final recipeData = results[0] as Map<String, dynamic>;
        final firebaseImageUrl = results[1] as String?;

        // ========================================================
        // VALIDATE RECIPE
        // ========================================================

        if (!_isRecipeResult(recipeData)) {
          throw const _NotARecipeException(
            "This image isn't a recipe. Please share a photo of "
            "a dish or a recipe card.",
          );
        }

        // ========================================================
        // CONVERT RECIPE
        // ========================================================

        final recipe = SavedRecipe.fromGeminiResponse(recipeData);

        // ========================================================
        // SAVE RECIPE
        // ========================================================

        await _saveRecipeAndNavigate(
          recipe: recipe,
          sourceUrl: 'shared_image_import',
          firebaseImageUrl: firebaseImageUrl,
          isVideoImport: false,
          doneSignal: doneSignal,
        );
      },
    );
  }

  // ============================================================
  // SHARED VIDEO IMPORT
  // ============================================================

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
      import: (doneSignal) async {
        log(
          '[SharedVideo] Import STARTED | '
          'sourceUrl=${sourceUrl ?? "null"}',
        );

        // ========================================================
        // STEP 1: AI VIDEO ANALYSIS
        // ========================================================

        final recipeData = await getRecipeFromVideo(
          videoFile,
          sourceUrl: sourceUrl,
        );

        if (recipeData.isEmpty) {
          throw Exception('Recipe data is empty.');
        }

        // ========================================================
        // STEP 2: VALIDATE RECIPE
        // ========================================================

        if (!_isRecipeResult(recipeData)) {
          throw const _NotARecipeException(
            "This video doesn't contain a valid recipe.",
          );
        }

        // ========================================================
        // STEP 3: CONVERT RECIPE
        // ========================================================

        final recipe = SavedRecipe.fromGeminiResponse(recipeData);

        // ========================================================
        // STEP 4: SAVE RECIPE
        // ========================================================
        //
        // Video has no direct image.
        // AI image generation starts in background
        // inside _saveRecipeAndNavigate().
        //

        await _saveRecipeAndNavigate(
          recipe: recipe,
          sourceUrl: sourceUrl ?? 'social_video_share',
          isVideoImport: true,
          doneSignal: doneSignal,
        );
      },
    );
  }

  static Future<Map<String, dynamic>> getRecipeFromSocialMedia(
    String sourceUrl,
  ) async {
    try {
      log('[SocialImport] Calling AI extraction API');

      final callable = FirebaseFunctions.instance.httpsCallable(
        'analyzeRecipeFromSocialMedia',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      );

      final result = await callable.call({'url': sourceUrl});

      final data = result.data;

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception('Invalid recipe response from AI');
    } catch (e, stack) {
      log('[SocialImport] AI extraction FAILED: $e');

      log(stack.toString());

      rethrow;
    }
  }

  static Future<bool> importRecipeFromName(String recipeName) async {
    final totalStart = DateTime.now();

    log('========== RECIPE NAME IMPORT STARTED ==========');

    return _runImport(
      loadingSteps: const [
        'Generating recipe...',
        'Preparing ingredients...',
        'Saving recipe...',
      ],
      errorMessage: 'Failed to generate recipe.',
      import: (doneSignal) async {
        final step1Start = DateTime.now();

        final uid = AuthService.currentUser?.uid;

        if (uid == null) {
          throw Exception('Login required');
        }

        log(
          '[1] User validation COMPLETED in '
          '${DateTime.now().difference(step1Start).inMilliseconds} ms',
        );

        log('[2] AI recipe generation STARTED');

        final aiStart = DateTime.now();

        final recipeData = await getRecipeFromName(recipeName);

        log(
          '[2] AI recipe generation COMPLETED in '
          '${DateTime.now().difference(aiStart).inMilliseconds} ms',
        );

        log('[3] SavedRecipe conversion STARTED');

        final conversionStart = DateTime.now();

        final recipe = SavedRecipe.fromGeminiResponse(recipeData);

        log(
          '[3] SavedRecipe conversion COMPLETED in '
          '${DateTime.now().difference(conversionStart).inMilliseconds} ms',
        );

        log('[4] Save recipe & navigate STARTED');

        final saveStart = DateTime.now();

        await _saveRecipeAndNavigate(
          recipe: recipe,
          sourceUrl: 'recipe_name_search',
          doneSignal: doneSignal,
        );

        log(
          '[4] Save recipe & navigate COMPLETED in '
          '${DateTime.now().difference(saveStart).inMilliseconds} ms',
        );

        log(
          '========== TOTAL TIME: '
          '${DateTime.now().difference(totalStart).inMilliseconds} ms '
          '==========',
        );
      },
    );
  }

  static Future<void> uploadSocialImageInBackground({
    required SavedRecipe recipe,
    required String sourceUrl,
  }) async {
    try {
      log(
        '[Background] Firebase image upload START | '
        'recipe=${recipe.title}',
      );

      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        log(
          '[Background] Upload skipped | '
          'user not logged in',
        );

        return;
      }

      // ============================================================
      // STEP 1: FETCH SOCIAL THUMBNAIL
      // ============================================================

      log('[Background] Fetching ORIGINAL SOCIAL THUMBNAIL START');

      final socialImageUrl = await _fetchSocialThumbnail(sourceUrl);

      log(
        '[Background] ORIGINAL SOCIAL THUMBNAIL DONE | '
        'found=${socialImageUrl != null}',
      );

      if (socialImageUrl == null || socialImageUrl.trim().isEmpty) {
        log('[Background] No social thumbnail found');

        return;
      }

      // ============================================================
      // STEP 2: DOWNLOAD ORIGINAL IMAGE
      // ============================================================

      log('[Background] Image download START');

      final response = await http
          .get(
            Uri.parse(_normalizeImageUrl(socialImageUrl)),
            headers: const {
              'User-Agent': 'Mozilla/5.0',
              'Referer': 'https://www.instagram.com/',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        log(
          '[Background] Image download FAILED | '
          'status=${response.statusCode}',
        );

        return;
      }

      final originalBytes = response.bodyBytes;

      if (originalBytes.isEmpty) {
        log('[Background] Empty image bytes');

        return;
      }

      log(
        '[Background] Image download SUCCESS | '
        'bytes=${originalBytes.length}',
      );

      // ============================================================
      // STEP 3: ALWAYS COMPRESS IMAGE
      // ============================================================

      log('[Background] Image compression START');

      final compressedBytes = await _compressImageBytes(originalBytes);

      if (compressedBytes == null || compressedBytes.isEmpty) {
        log('[Background] Image compression FAILED');

        return;
      }

      log(
        '[Background] Image compression DONE | '
        'original=${originalBytes.length} bytes | '
        'compressed=${compressedBytes.length} bytes',
      );

      // ============================================================
      // STEP 4: UPLOAD COMPRESSED IMAGE TO FIREBASE
      // ============================================================

      final fileName =
          'social_recipe_'
          '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('recipes')
          .child(fileName);

      await storageRef.putData(
        compressedBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public,max-age=31536000',
        ),
      );

      final firebaseImageUrl = await storageRef.getDownloadURL();

      log('[Background] Firebase upload SUCCESS');

      // ============================================================
      // STEP 5: FIND RECIPE WITHOUT COMPOSITE INDEX
      // ============================================================

      final snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .where('ownerId', isEqualTo: uid)
          .where('sourceUrl', isEqualTo: sourceUrl)
          .limit(10)
          .get();

      if (snapshot.docs.isEmpty) {
        log('[Background] Recipe not found');

        return;
      }

      QueryDocumentSnapshot<Map<String, dynamic>>? recipeDoc;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data['title'] == recipe.title) {
          recipeDoc = doc;
          break;
        }
      }

      if (recipeDoc == null) {
        log('[Background] Matching recipe not found');

        return;
      }

      // ============================================================
      // STEP 6: UPDATE FIRESTORE IMAGE URL
      // ============================================================

      await recipeDoc.reference.update({
        'imageUrl': firebaseImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('[Background] Firestore image URL updated SUCCESS');

      log('[Background] Social image processing COMPLETED');
    } catch (e, stack) {
      log('[Background] Social image upload FAILED: $e');

      log(stack.toString());
    }
  }

  /// Scrape a social post's own thumbnail (its `og:image` / `twitter:image`) so
  /// the imported recipe shows the actual reel/post preview. Uses a link-preview
  /// user agent (facebookexternalhit) that Instagram / TikTok / etc. serve their
  /// open-graph tags to (a plain bot UA gets a login wall with no image).
  static Future<String?> _fetchSocialThumbnail(String url) async {
    try {
      final resp = await http
          .get(
            Uri.parse(url),
            headers: const {
              'User-Agent':
                  'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
              'Accept': 'text/html,application/xhtml+xml',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final html = resp.body;

      String? firstOf(List<RegExp> patterns) {
        for (final p in patterns) {
          final m = p.firstMatch(html);
          final g = m?.group(1);
          if (g != null && g.trim().isNotEmpty) return g;
        }
        return null;
      }

      final img = firstOf([
        RegExp(
          r'''<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)''',
          caseSensitive: false,
        ),
        RegExp(
          r'''<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image''',
          caseSensitive: false,
        ),
        RegExp(
          r'''<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)''',
          caseSensitive: false,
        ),
        RegExp(
          r'''<meta[^>]+content=["']([^"']+)["'][^>]+name=["']twitter:image''',
          caseSensitive: false,
        ),
      ]);
      if (img == null) return null;

      return img
          .replaceAll('&amp;', '&')
          .replaceAll('&#x2F;', '/')
          .replaceAll('&#47;', '/')
          .trim();
    } catch (e) {
      log('Social thumbnail fetch failed: $e');
      return null;
    }
  }

  static String _normalizeImageUrl(String url) {
    return url
        .replaceAll('&amp;', '&')
        .replaceAll('&#x26;', '&')
        .replaceAll('&#38;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x2F;', '/')
        .replaceAll('&#47;', '/')
        .trim();
  }

  static Future<String?> uploadNetworkImage(String imageUrl, String uid) async {
    try {
      final normalizedUrl = _normalizeImageUrl(imageUrl);

      log('[NetworkImage] Download START');
      log('[NetworkImage] Normalized URL: $normalizedUrl');

      final response = await http
          .get(
            Uri.parse(normalizedUrl),
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
                  'AppleWebKit/605.1.15 '
                  '(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
              'Accept':
                  'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
              'Referer': 'https://www.instagram.com/',
            },
          )
          .timeout(const Duration(seconds: 20));

      log(
        '[NetworkImage] Status: ${response.statusCode} | '
        'Content-Type: ${response.headers['content-type']}',
      );

      if (response.statusCode != 200) {
        log(
          '[NetworkImage] Download FAILED | '
          'status=${response.statusCode}',
        );
        return null;
      }

      final compressedBytes = await _compressImageBytes(response.bodyBytes);

      if (compressedBytes == null || compressedBytes.isEmpty) {
        return null;
      }
      if (compressedBytes.isEmpty) {
        log('[NetworkImage] Empty image bytes');
        return null;
      }

      final decodedImage = img.decodeImage(compressedBytes);

      if (decodedImage == null) {
        log('[NetworkImage] Invalid image data');
        return null;
      }

      log(
        '[NetworkImage] Image validated | '
        'width=${decodedImage.width} | '
        'height=${decodedImage.height}',
      );

      final fileName =
          'social_recipe_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('recipes')
          .child(fileName);

      await ref.putData(
        compressedBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'source': 'social_media'},
        ),
      );

      final firebaseUrl = await ref.getDownloadURL();

      log('[NetworkImage] Firebase Upload SUCCESS');
      log('[NetworkImage] Firebase URL: $firebaseUrl');

      return firebaseUrl;
    } catch (e, stack) {
      log('[NetworkImage] Upload FAILED: $e');
      log(stack.toString());
      return null;
    }
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
      log('generateRecipeFromName response: ${jsonEncode(data)}');

      throw Exception(
        data['error']?.toString() ??
            data['message']?.toString() ??
            'Recipe generation failed',
      );
    }
    final recipeData = Map<String, dynamic>.from(data['recipe']);

    return recipeData;
  }

  /// Downscale + JPEG-encode an image. Used for BOTH the Storage upload and
  /// the Gemini vision call.
  ///
  /// 1020px @ q80 lands around 150KB, versus roughly 475KB average (up to
  /// 1.4MB) at the previous 1600/85. Recipe cards are ~1000px wide on a phone,
  /// so there is nothing visible to gain above this — and on a mobile
  /// connection those extra bytes were most of a second per image, which is
  /// what made the Discover feed feel slow.
  ///
  /// It also cuts Gemini cost: vision input is billed per 768x768 tile, so a
  /// 1600px photo is ~6 tiles where a 1020px one is ~2 — roughly a third of
  /// the image tokens per import.
  static Future<Uint8List?> _compressImageBytes(
    Uint8List originalBytes, {
    int maxWidth = 1020,
    int quality = 80,
  }) async {
    try {
      final decodedImage = img.decodeImage(originalBytes);

      if (decodedImage == null) {
        log('[ImageCompressor] Invalid image');
        return null;
      }

      final resizedImage = decodedImage.width > maxWidth
          ? img.copyResize(decodedImage, width: maxWidth)
          : decodedImage;

      final compressed = img.encodeJpg(resizedImage, quality: quality);

      final compressedBytes = Uint8List.fromList(compressed);

      log(
        '[ImageCompressor] '
        'original=${(originalBytes.length / 1024 / 1024).toStringAsFixed(2)} MB | '
        'compressed=${(compressedBytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      return compressedBytes;
    } catch (e, stack) {
      log('[ImageCompressor] FAILED: $e');
      log(stack.toString());
      return null;
    }
  }
}
