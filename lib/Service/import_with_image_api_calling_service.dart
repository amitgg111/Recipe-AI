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
import 'package:recipe_ai/View/Home/import_processing_screen.dart';
import 'package:recipe_ai/View/Home/import_complete_screen.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
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

    var imageUrl =
        firebaseImageUrl ??
        remoteImageUrl ??
        (recipe.imageUrl?.isNotEmpty == true ? recipe.imageUrl : null);

    // No image from the import source (common for text / video / some social
    // imports) → fetch a dish-specific image from the recipe title so every
    // generated recipe still gets a picture.
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = await _resolveDishImage(recipe.title, uid);
    }

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
          // Privacy: AI / photo-imported recipes are private by default.
          'visibility': 'private',
          'isPublic': false,
          // Ownership: imported recipes MAY later be published by the user.
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

    // Count this import against the free-tier quota. Image / Text / Social all
    // route through here; Website imports use a separate path and stay free.
    // No-op for Plus users.
    await SubscriptionService.instance.incrementImportCount();

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

  /// Finds a dish-specific REAL food photo for [title] when the import produced
  /// none: TheMealDB → Wikipedia (food-validated) → a keyless AI photo as a last
  /// resort. Chosen images are stored in Firebase (durable). Null only for an
  /// empty title.
  static Future<String?> _resolveDishImage(String title, String uid) async {
    final q = title.trim();
    if (q.isEmpty) return null;

    // 1) TheMealDB — real photo for common (mostly Western) dishes.
    final mealDb = await _theMealDbImage(q);
    if (mealDb != null) return await uploadNetworkImage(mealDb, uid) ?? mealDb;

    // 2) Wikipedia — real photo of the best-matching FOOD article. Covers most
    // Indian/Asian dishes (Manchurian, Biryani, Dosa, Tikka Masala, …) and is
    // only used when the article is verified (by its categories) to be food, so
    // a name like "Rainbow Buddha Bowl" can never return a non-food image.
    final wiki = await _wikipediaFoodImage(q);
    if (wiki != null) return await uploadNetworkImage(wiki, uid) ?? wiki;

    // 3) Pollinations (keyless AI) — last resort. The `flux` model + a food-only
    // frame-filling prompt keeps it from drifting to scenery.
    final prompt =
        'extreme close-up professional food photograph of $q, '
        'the finished cooked dish, plated and filling the entire frame, '
        'ultra realistic, restaurant quality, natural lighting, appetizing, '
        'sharp focus, high detail, food only';
    return 'https://image.pollinations.ai/prompt/${Uri.encodeComponent(prompt)}'
        '?width=800&height=600&nologo=true&model=flux';
  }

  /// TheMealDB thumbnail for [q], or null.
  static Future<String?> _theMealDbImage(String q) async {
    try {
      final r = await http
          .get(Uri.parse(
            'https://www.themealdb.com/api/json/v1/1/search.php'
            '?s=${Uri.encodeQueryComponent(q)}',
          ))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final meals = (jsonDecode(r.body) as Map)['meals'];
        if (meals is List && meals.isNotEmpty) {
          final thumb = (meals.first as Map)['strMealThumb']?.toString();
          if (thumb != null && thumb.isNotEmpty) return thumb;
        }
      }
    } catch (e) {
      log('TheMealDB image lookup failed: $e');
    }
    return null;
  }

  /// Lead image of the best-matching Wikipedia article for [q], returned ONLY
  /// when that article is verified to be about food (via its categories).
  static Future<String?> _wikipediaFoodImage(String q) async {
    try {
      final uri = Uri.parse(
        'https://en.wikipedia.org/w/api.php?action=query&format=json'
        '&generator=search&gsrsearch=${Uri.encodeQueryComponent(q)}'
        '&gsrlimit=1&prop=pageimages%7Ccategories&piprop=thumbnail'
        '&pithumbsize=800&cllimit=60&redirects=1',
      );
      final r = await http.get(uri, headers: {
        'User-Agent': 'RecipeAI/1.0 (recipe image lookup)',
      }).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return null;
      final query = (jsonDecode(r.body) as Map)['query'] as Map?;
      final pages = query?['pages'] as Map?;
      if (pages == null || pages.isEmpty) return null;
      final page = pages.values.first as Map;
      final thumb = (page['thumbnail'] as Map?)?['source']?.toString();
      if (thumb == null || thumb.isEmpty) return null;
      final cats = (page['categories'] as List?) ?? [];
      final catText = cats
          .map((c) => (c as Map)['title']?.toString().toLowerCase() ?? '')
          .join(' ');
      const foodWords = [
        'cuisine', 'food', 'dish', 'cooking', 'recipe', 'curry', 'dessert',
        'snack', 'bread', 'rice', 'noodle', 'soup', 'stew', 'sauce',
        'beverage', 'drink', 'cake', 'meat', 'vegetable', 'seafood',
        'breakfast', 'street food', 'appetizer', 'salad', 'pasta', 'pizza',
      ];
      final isFood = foodWords.any((w) => catText.contains(w));
      return isFood ? thumb : null;
    } catch (e) {
      log('Wikipedia image lookup failed: $e');
      return null;
    }
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
      // Await so a transient getDownloadURL() failure is caught here (returns
      // null → recipe still saves without an image) instead of aborting import.
      return await ref.getDownloadURL();
    } catch (e) {
      log('Image upload error: $e');
      return null;
    }
  }

  /// Runs an import behind the processing screen. Returns `true` when the
  /// import completed successfully (and the complete/review screen is shown),
  /// or `false` when it failed (processing dismissed + error snackbar).
  static Future<bool> _runImport({
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
      return true;
    } catch (e, stack) {
      log('Import error: $e');
      log(stack.toString());

      Get.back();

      // A non-recipe image gets its own clear message instead of the generic one.
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

    final hasIngredients = nonEmptyList(data['ingredients']) ||
        sectionsHaveEntries(data['ingredientSections'], 'items');
    final hasInstructions = nonEmptyList(data['instructions']) ||
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

    // Downscale/compress the photo before base64-ing it to the AI — a smaller
    // payload uploads and analyses much faster while staying readable for OCR.
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
        // Stop here if the image isn't a recipe — no upload, no dish-image
        // fetch, no save (and no further AI calls).
        if (!_isRecipeResult(recipeData)) {
          throw const _NotARecipeException(
            "This image isn't a recipe. Please go back and add a photo of a "
            "dish or a recipe card.",
          );
        }
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
        if (!_isRecipeResult(recipeData)) {
          throw const _NotARecipeException(
            "This image isn't a recipe. Please go back and share a photo of a "
            "dish or a recipe card.",
          );
        }
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

  /// Scrape a social post's own thumbnail (its `og:image` / `twitter:image`) so
  /// the imported recipe shows the actual reel/post preview. Uses a link-preview
  /// user agent (facebookexternalhit) that Instagram / TikTok / etc. serve their
  /// open-graph tags to (a plain bot UA gets a login wall with no image).
  static Future<String?> _fetchSocialThumbnail(String url) async {
    try {
      final resp = await http.get(
        Uri.parse(url),
        headers: const {
          'User-Agent':
              'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
          'Accept': 'text/html,application/xhtml+xml',
        },
      ).timeout(const Duration(seconds: 10));
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
        RegExp(r'''<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)''',
            caseSensitive: false),
        RegExp(r'''<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image''',
            caseSensitive: false),
        RegExp(r'''<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)''',
            caseSensitive: false),
        RegExp(r'''<meta[^>]+content=["']([^"']+)["'][^>]+name=["']twitter:image''',
            caseSensitive: false),
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

        // Image = the reel/post's own thumbnail. Prefer whatever the AI/cloud
        // returned; otherwise scrape the shared post's og:image directly so the
        // recipe shows the actual social preview instead of a generic photo.
        var thumb =
            (recipe.imageUrl?.isNotEmpty == true) ? recipe.imageUrl : null;
        if ((thumb == null || thumb.isEmpty) && url != null && url.isNotEmpty) {
          thumb = await _fetchSocialThumbnail(url);
          log('Social thumbnail: $thumb');
        }

        // Re-host it on Firebase Storage (social CDN URLs expire) so it keeps
        // loading later.
        String? firebaseImageUrl;
        if (thumb != null && thumb.isNotEmpty) {
          firebaseImageUrl = await uploadNetworkImage(thumb, uid);
          log('firebaseImageUrl = $firebaseImageUrl');
        }

        await _saveRecipeAndNavigate(
          recipe: recipe,
          sourceUrl: url ?? recipe.sourceUrl ?? 'social_media_import',
          firebaseImageUrl: firebaseImageUrl,
          remoteImageUrl: firebaseImageUrl == null ? thumb : null,
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

  static Future<bool> importRecipeFromName(String recipeName) async {
    return _runImport(
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
