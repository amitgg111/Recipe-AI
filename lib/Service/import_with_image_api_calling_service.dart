import 'dart:async';
import 'dart:convert';
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

/// Thrown when the user has no import credits left (free tier, weekly limit
/// exhausted, not Plus). Thrown BEFORE any AI/network call is made, so a
/// user with 0 credits never triggers a paid Gemini/Storage call at all.
class _NoCreditException implements Exception {
  final String message;
  const _NoCreditException(this.message);
  @override
  String toString() => message;
}

class RecipeImportService {
  static const int _maxInlineVideoBytes = 15 * 1024 * 1024;

  static final _urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);

  /// True only for images WE generated and stored — a URL in our own Storage
  /// bucket under recipe_images/. Strict prefix match: a platform CDN
  /// thumbnail, a picsum placeholder, or a lookalike host
  /// (firebasestorage.googleapis.com.evil.com) must all fail this.
  static bool _isOurStorageImage(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith(
          'https://firebasestorage.googleapis.com/v0/b/',
        ) &&
        url.contains('/o/recipe_images%2F');
  }

  static String? extractUrl(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final match = _urlPattern.firstMatch(text.trim());
    if (match == null) return null;
    return match.group(0)!.replaceAll(RegExp(r'''[)\]}>"']+$'''), '');
  }

  /// Gate that MUST be called as the very first thing inside every import
  /// flow's `import:` callback — before any AI call, upload, or Cloud
  /// Function invocation. If the user has no free credits left (and isn't
  /// Plus), this throws immediately so no API call is ever made for that
  /// import. [SubscriptionService.canUseRecipeImport] is a local/cached,
  /// non-consuming check, so this is instant — no network round trip needed
  /// just to find out the user is out of credits.
  static void _ensureHasCredit() {
    if (!SubscriptionService.instance.canUseRecipeImport()) {
      throw const _NoCreditException(
        "You've used all your free imports for this week. "
        "Upgrade to Plus for unlimited imports.",
      );
    }
  }

  static Future<String> askGemini(String prompt) async {
    print('start');
    final callable = FirebaseFunctions.instance.httpsCallable('askGemini');

    final result = await callable.call({'prompt': prompt});

    if (result.data['success'] == true) {
      print('finis');
      return result.data['text'];
    }

    throw Exception(result.data['error']);
  }

  static Future<void> importRecipeFromImage(
    BuildContext context,
    File imageFile,
  ) async {
    final totalStopwatch = Stopwatch()..start();

    print('========== IMAGE IMPORT STARTED ==========');

    await _runImport(
      loadingSteps: const [
        'Reading your image…',
        'Identifying ingredients…',
        'Building instructions…',
        'Saving your recipe…',
      ],
      errorMessage: 'Could not read recipe from image. Please try again.',
      import: (doneSignal) async {
        // CREDIT CHECK FIRST — before any AI call or upload starts.
        _ensureHasCredit();

        final uid = AuthService.currentUser?.uid;

        if (uid == null) {
          throw Exception('You must be logged in to save recipes.');
        }

        print('[PARALLEL] AI + IMAGE UPLOAD STARTED');

        final aiStopwatch = Stopwatch()..start();
        final uploadStopwatch = Stopwatch()..start();

        // Both start at the same time, but we do NOT wait for the upload
        // before navigating — only the AI result gates navigation. The
        // upload keeps running in the background and updates Firestore
        // (via _saveRecipeAndNavigate's `pendingImageUpload`) whenever it
        // finishes; the ImportCompleteScreen hero already listens to the
        // Firestore doc via StreamBuilder, so the photo just fades in
        // whenever it's ready — it no longer blocks the recipe itself.
        final uploadFuture = _uploadImageFile(imageFile, uid).then((result) {
          uploadStopwatch.stop();

          print(
            '[UPLOAD] COMPLETED: '
            '${uploadStopwatch.elapsedMilliseconds} ms',
          );

          return result;
        });

        final recipeData = await getRecipeFromImage(imageFile);

        aiStopwatch.stop();

        print(
          '[AI] COMPLETED: '
          '${aiStopwatch.elapsedMilliseconds} ms',
        );

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
          // Not awaited here — navigation happens as soon as the recipe is
          // saved. The upload result (whenever it lands) is applied to
          // Firestore in the background.
          pendingImageUpload: uploadFuture,
          doneSignal: doneSignal,
        );

        totalStopwatch.stop();

        print(
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

    print(
      'ORIGINAL IMAGE SIZE: '
      '${(originalBytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
    );

    // Same 1020px cap as the stored image — fewer vision tiles, so lower token
    // cost per import.
    final compressedBytes = await _compressImageBytes(originalBytes);

    if (compressedBytes == null || compressedBytes.isEmpty) {
      throw Exception('Failed to compress image.');
    }

    print(
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

    print(
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
    // The caption is already enriched by the caller
    // (importRecipeFromSocialContent fetches the post's page on-device and
    // passes the full caption here).
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

  /// Generates a recipe image straight from a caption (PARALLEL path) — the
  /// backend identifies the dish from the caption, so this can run alongside
  /// recipe extraction. Returns the stored image URL, or null on any failure.
  static Future<String?> _generateImageFromCaption(String caption) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'generateRecipeImage',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      );
      final result = await callable.call({'caption': caption});
      final data = Map<String, dynamic>.from(result.data);
      if (data['success'] == true) {
        final imageUrl = data['imageUrl']?.toString() ?? '';
        if (imageUrl.isNotEmpty) return imageUrl;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches a social post's caption AND cover image from its public page using
  /// the facebookexternalhit crawler UA. On-device, so it uses the phone's
  /// residential/mobile IP — Instagram/TikTok serve the full og:description
  /// caption + og:image to that, unlike the backend's datacenter IP which is
  /// walled. Returns null on any failure so callers fall back to the old flow.
  static Future<({String? caption, String? imageUrl})?> _fetchSocialMeta(
    String url,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: const {
              'User-Agent':
                  'facebookexternalhit/1.1 '
                  '(+http://www.facebook.com/externalhit_uatext.php)',
              'Accept': 'text/html,application/xhtml+xml',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final body = response.body;
      // og:description carries the full caption (with the recipe); fall back to
      // og:title, which on Instagram also contains the caption.
      final rawCaption = _extractMetaContent(body, 'og:description') ??
          _extractMetaContent(body, 'og:title');
      final rawImage = _extractMetaContent(body, 'og:image');

      final caption = (rawCaption != null && rawCaption.trim().isNotEmpty)
          ? _decodeHtmlEntities(rawCaption).trim()
          : null;
      final imageUrl = (rawImage != null && rawImage.trim().isNotEmpty)
          ? _decodeHtmlEntities(rawImage).trim()
          : null;

      if (caption == null && imageUrl == null) return null;
      return (caption: caption, imageUrl: imageUrl);
    } catch (_) {
      // Any failure (timeout, wall, parse) → fall back to the existing flow.
      return null;
    }
  }

  /// Pulls the `content` of a `<meta property="…">` / `<meta name="…">` tag,
  /// handling both attribute orders. Instagram HTML-encodes real quotes inside
  /// the value (&quot; / &#039;), so the delimiter match is unambiguous.
  static String? _extractMetaContent(String html, String property) {
    final escaped = RegExp.escape(property);
    final forward = RegExp(
      '<meta[^>]+(?:property|name)=["\']$escaped["\'][^>]+'
      'content=["\']([^"\']*)["\']',
      caseSensitive: false,
    ).firstMatch(html);
    if (forward != null) return forward.group(1);

    final reverse = RegExp(
      '<meta[^>]+content=["\']([^"\']*)["\'][^>]+'
      '(?:property|name)=["\']$escaped["\']',
      caseSensitive: false,
    ).firstMatch(html);
    return reverse?.group(1);
  }

  /// Decodes the common HTML entities Instagram uses in og tags (&amp;, &quot;,
  /// numeric &#39; and &#x1f60b; emoji) so the caption reaches Gemini clean.
  static String _decodeHtmlEntities(String input) {
    var s = input
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');

    s = s.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
      final code = int.tryParse(m.group(1)!, radix: 16);
      return code != null ? String.fromCharCode(code) : m.group(0)!;
    });
    s = s.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1)!);
      return code != null ? String.fromCharCode(code) : m.group(0)!;
    });
    return s;
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
    // A Firebase Storage upload that is STILL RUNNING when we save/navigate.
    // We do not await this before showing the recipe — instead it's applied
    // to the Firestore doc in the background once it resolves, and the
    // ImportCompleteScreen hero (StreamBuilder on the recipe doc) picks the
    // new imageUrl up automatically.
    Future<String?>? pendingImageUpload,
  }) async {
    final uid = AuthService.currentUser?.uid;

    if (uid == null) {
      throw Exception('You must be logged in to save recipes.');
    }

    print('========== SAVE RECIPE STARTED ==========');
    print('Recipe: ${recipe.title}');
    print('Source: $sourceUrl');
    print('firebaseImageUrl: ${firebaseImageUrl ?? "null"}');
    print('remoteImageUrl: ${remoteImageUrl ?? "null"}');
    print('isVideoImport: $isVideoImport');
    print('pendingImageUpload: ${pendingImageUpload != null}');

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
      // Cover thumbnails from reels are unreliable (a title card, the wrong
      // frame), so they are never used. BUT extractRecipeFromSocialContent
      // already generates and stores a clean AI food image server-side for
      // video imports — and this branch used to discard it and fire a SECOND
      // generateRecipeImage call in the background. Every reel import paid
      // for two image generations and kept the worse-prompted one. Honor our
      // own Storage image; only regenerate when there genuinely isn't one.
      if (_isOurStorageImage(recipe.imageUrl)) {
        imageUrl = recipe.imageUrl;
        print('[VIDEO IMPORT] Using server-generated AI image.');
      } else {
        imageUrl = '';
      }

      print(
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
      imageUrl =
          firebaseImageUrl ??
          remoteImageUrl ??
          // A picsum URL is the server's "generation failed" placeholder —
          // treating it as a real image used to persist it forever and block
          // the background retry that would produce an actual food photo.
          ((recipe.imageUrl ?? '').isNotEmpty &&
                  !recipe.imageUrl!.contains('picsum.photos')
              ? recipe.imageUrl
              : null) ??
          '';
      print(
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
    // NOTE: skipped whenever a real upload is already in flight
    // (`pendingImageUpload`) — that upload will supply the real photo
    // shortly, so we must not also kick off a fake AI-generated one.
    //
    bool needsImageGeneration = false;

    if (!isVideoImport &&
        pendingImageUpload == null &&
        (imageUrl == null || imageUrl.isEmpty) &&
        sourceUrl != 'social_caption_import' &&
        sourceUrl != 'social_video_share' &&
        !sourceUrl.startsWith('http')) {
      needsImageGeneration = true;

      imageUrl = '';

      print(
        '[NO IMAGE] No existing image found. '
        'AI image generation will start.',
      );
    }

    // ============================================================
    // CONSUME CREDIT
    // ============================================================
    //
    // NOTE: The real gate is [_ensureHasCredit], called at the very start
    // of every import flow BEFORE any AI/network call. This transactional
    // consume is a safety net only — it guards the rare race where two
    // imports pass the upfront check at the same moment and only one
    // Firestore credit actually remains. It should not normally fire.
    //

    final hasCredit = await SubscriptionService.instance.consumeCredit();

    if (!hasCredit) {
      throw const _NoCreditException(
        "You've used all your free imports for this week. "
        "Upgrade to Plus for unlimited imports.",
      );
    }

    // ============================================================
    // SAVE RECIPE TO FIRESTORE
    // ============================================================

    final docRef = await FirebaseFirestore.instance.collection('recipes').add({
      'title': recipe.title,
      'description': recipe.description,

      // For image import:
      //     Existing image URL (or '' if the upload is still pending — see
      //     `pendingImageUpload` below, which fills this in shortly after).
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

    print('[FIRESTORE] Recipe saved: ${docRef.id}');

    // ============================================================
    // AI IMAGE GENERATION  /  BACKGROUND IMAGE UPLOAD
    // ============================================================
    //
    // VIDEO:
    // ✅ Always generate AI image
    //
    // IMAGE (upload still in flight):
    // ✅ Wait for the real upload in the background, then patch Firestore
    // ❌ Never generate an AI image
    //
    // RECIPE NAME / NO IMAGE:
    // ✅ Generate AI image
    //
    if (isVideoImport && pendingImageUpload != null) {
      // PARALLEL path: the caption-image was generated alongside extraction.
      // Apply it when ready; if it produced nothing, fall back to generating
      // from the extracted recipe title so a reel is never left imageless.
      print(
        '[PARALLEL IMAGE] Applying caption-image when ready | '
        'recipeId=${docRef.id}',
      );

      unawaited(
        _applyParallelImage(
          recipeId: docRef.id,
          parallelImage: pendingImageUpload,
          fallbackTitle: recipe.title,
          fallbackDescription: recipe.description,
        ),
      );
    } else if ((isVideoImport && (imageUrl == null || imageUrl.isEmpty)) ||
        needsImageGeneration) {
      print(
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
    } else if (pendingImageUpload != null) {
      print(
        '[IMAGE UPLOAD] Recipe shown now, waiting on upload in background | '
        'recipeId=${docRef.id}',
      );

      unawaited(
        _applyPendingImageUpload(
          recipeId: docRef.id,
          pendingUpload: pendingImageUpload,
        ),
      );
    } else {
      print(
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

      // For video/name/pending-upload imports this is initially empty.
      // The recipe detail / complete screen listens to Firestore updates
      // (StreamBuilder) and receives the image the moment it lands.
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

    print('========== SAVE RECIPE COMPLETED ==========');
  }

  /// Waits for a Storage upload that was already running when the recipe was
  /// saved/navigated-to, then patches the Firestore doc's `imageUrl`. Runs
  /// completely in the background — it must never block navigation, and a
  /// failure here should never crash or surface to the user (the recipe
  /// itself already saved fine; worst case the photo stays blank).
  static Future<void> _applyPendingImageUpload({
    required String recipeId,
    required Future<String?> pendingUpload,
  }) async {
    try {
      final url = await pendingUpload;

      if (url == null || url.isEmpty) {
        print(
          '[IMAGE UPLOAD] Background upload produced no URL | '
          'recipeId=$recipeId',
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .update({'imageUrl': url, 'updatedAt': FieldValue.serverTimestamp()});

      print(
        '[IMAGE UPLOAD] Firestore image URL updated SUCCESS | '
        'recipeId=$recipeId',
      );
    } catch (e, stack) {
      print('[IMAGE UPLOAD] Background apply FAILED: $e');
      print(stack.toString());
    }
  }

  /// Applies the PARALLEL caption-image to the recipe doc once it resolves. If
  /// the parallel generation produced nothing, falls back to generating from
  /// the extracted recipe title, so a reel is never left without an image.
  static Future<void> _applyParallelImage({
    required String recipeId,
    required Future<String?> parallelImage,
    required String fallbackTitle,
    String? fallbackDescription,
  }) async {
    try {
      final url = await parallelImage;
      if (url != null && url.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('recipes')
            .doc(recipeId)
            .update({
          'imageUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('[PARALLEL IMAGE] applied | recipeId=$recipeId');
        return;
      }
      print('[PARALLEL IMAGE] empty → AI-gen fallback | recipeId=$recipeId');
      await _generateRealImageInBackground(
        recipeId: recipeId,
        title: fallbackTitle,
        description: fallbackDescription,
      );
    } catch (e) {
      print('[PARALLEL IMAGE] failed → AI-gen fallback: $e');
      await _generateRealImageInBackground(
        recipeId: recipeId,
        title: fallbackTitle,
        description: fallbackDescription,
      );
    }
  }

  static Future<void> _generateRealImageInBackground({
    required String recipeId,
    required String title,
    String? description,
    String? imagePrompt,
  }) async {
    try {
      print(
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

      print(
        '[AI IMAGE] Generation COMPLETED | '
        'recipeId=$recipeId',
      );

      print('[AI IMAGE] Response: $data');

      if (data['success'] != true) {
        print(
          '[AI IMAGE] Generation FAILED | '
          '${data['error']}',
        );
        return;
      }

      final imageUrl = data['imageUrl']?.toString();

      if (imageUrl == null || imageUrl.isEmpty) {
        print('[AI IMAGE] imageUrl is empty');
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

      print(
        '[AI IMAGE] Firestore image URL updated SUCCESS | '
        'recipeId=$recipeId',
      );
    } catch (e, stack) {
      print('[AI IMAGE] Generation FAILED: $e');
      print(stack.toString());
    }
  }

  static Future<String?> _uploadImageFile(File imageFile, String uid) async {
    try {
      final originalBytes = await imageFile.readAsBytes();

      print(
        '[ImageUpload] Original size: '
        '${(originalBytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      final compressedBytes = await _compressImageBytes(originalBytes);

      if (compressedBytes == null || compressedBytes.isEmpty) {
        print('[ImageUpload] Compression failed');
        return null;
      }

      print(
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
      print('[ImageUpload] ERROR: $e');
      print(stack.toString());
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
      print('-------------Import error: $e');
      print(stack.toString());

      if (!doneSignal.isCompleted) doneSignal.complete();

      Get.back();

      final notRecipe = e is _NotARecipeException;
      final noCredit = e is _NoCreditException;

      CustomSnackbar.show(
        title: notRecipe
            ? 'Not a recipe'
            : noCredit
            ? 'No Credits Left'
            : 'Error',
        message: notRecipe
            ? e.message
            : noCredit
            ? e.message
            : errorMessage,
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
        // CREDIT CHECK FIRST — before any AI call or upload starts.
        _ensureHasCredit();

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

        // Kick the upload off, but only gate navigation on the AI result —
        // see importRecipeFromImage for the full explanation.
        final uploadFuture = _uploadImageFile(imageFile, uid);

        final recipeData = await getRecipeFromImage(imageFile);

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
          pendingImageUpload: uploadFuture,
          doneSignal: doneSignal,
        );
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
        // CREDIT CHECK FIRST — before any AI call starts.
        _ensureHasCredit();

        try {
          print('========== SOCIAL IMPORT STARTED ==========');
          print('[SocialImport] URL: ${url ?? "null"}');
          print('[SocialImport] Caption available: ${caption != null}');

          if ((url == null || url.trim().isEmpty) &&
              (caption == null || caption.trim().isEmpty)) {
            throw Exception('No social content found.');
          }

          // ========================================================
          // STEP 1: FETCH CAPTION + COVER ON-DEVICE (residential IP)
          // ========================================================
          //
          // The phone can read the post's og:description (full caption) and
          // og:image (cover) that Instagram walls from the backend's datacenter
          // IP. We fetch once, then run recipe extraction and image generation
          // in PARALLEL off the same caption.
          //
          String? enrichedCaption = caption;
          String? coverImage;
          if (url != null && url.trim().isNotEmpty) {
            final meta = await _fetchSocialMeta(url);
            if (meta != null) {
              final pageCaption = meta.caption;
              if (pageCaption != null && pageCaption.trim().isNotEmpty) {
                final shared = caption?.trim() ?? '';
                enrichedCaption = (shared.isEmpty || shared == url.trim())
                    ? pageCaption
                    : '$shared\n\n$pageCaption';
              }
              coverImage = meta.imageUrl;
            }
          }

          // Start image generation NOW (in parallel with extraction), from the
          // caption's dish — but only for VIDEO/reel URLs (image posts keep
          // their real photo) and only when the caption is rich enough to name
          // the dish. Otherwise no parallel image; _saveRecipeAndNavigate then
          // generates from the extracted recipe title, so it's never wrong.
          final looksLikeVideo = url != null &&
              (url.contains('/reel/') ||
                  url.contains('/reels/') ||
                  url.contains('/tv/'));
          final captionForImage = enrichedCaption?.trim() ?? '';
          final Future<String?>? parallelImage =
              (looksLikeVideo && captionForImage.length >= 25)
                  ? _generateImageFromCaption(captionForImage)
                  : null;

          // ========================================================
          // STEP 2: AI RECIPE EXTRACTION (parallel with the image above)
          // ========================================================

          final aiTimer = Stopwatch()..start();

          final recipeData = await getRecipeFromSocialContent(
            url: url,
            caption: enrichedCaption,
          );

          aiTimer.stop();

          print(
            '[SocialImport] AI extraction DONE | '
            '${aiTimer.elapsedMilliseconds} ms',
          );

          if (recipeData.isEmpty) {
            throw Exception('Recipe data is empty.');
          }

          // ========================================================
          // STEP 3: VALIDATE RECIPE
          // ========================================================

          if (!_isRecipeResult(recipeData)) {
            throw const _NotARecipeException(
              "This social media content doesn't contain a valid recipe.",
            );
          }

          // ========================================================
          // STEP 4: CONVERT + SAVE
          // ========================================================

          final recipe = SavedRecipe.fromGeminiResponse(recipeData);

          print(
            '[SocialImport] Recipe parsed | '
            'title=${recipe.title}',
          );

          final remoteImageUrl =
              coverImage ?? recipeData['imageUrl']?.toString();

          final isVideoImport = _isVideoSocialContent(
            url: url,
            recipeData: recipeData,
          );

          print(
            '[SocialImport] Media type detected | '
            'isVideoImport=$isVideoImport | '
            'mediaType=${recipeData['mediaType']}',
          );

          await _saveRecipeAndNavigate(
            recipe: recipe,
            sourceUrl: url ?? 'social_caption_import',
            remoteImageUrl: remoteImageUrl,

            // Reel/Video => image generated in PARALLEL (pendingImageUpload)
            // Image post => existing image use
            isVideoImport: isVideoImport,

            // The parallel caption-image (if any). _saveRecipeAndNavigate
            // applies it when ready and falls back to AI-gen-from-title if it
            // produced nothing.
            pendingImageUpload: parallelImage,

            doneSignal: doneSignal,
          );
          print(
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

          print(
            '========== SOCIAL IMPORT COMPLETED ==========\n'
            'TOTAL TIME: '
            '${totalTimer.elapsedMilliseconds} ms '
            '(${totalTimer.elapsed.inSeconds}s)',
          );
        } catch (e, stack) {
          totalTimer.stop();

          print('[SocialImport] FAILED: $e');
          print(stack.toString());

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
        // CREDIT CHECK FIRST — before any AI call or upload starts.
        _ensureHasCredit();

        final uid = AuthService.currentUser?.uid;

        if (uid == null) {
          throw Exception('You must be logged in to save recipes.');
        }

        print('[SharedImage] AI + Firebase upload STARTED');

        // AI analysis and Firebase upload start together, but only the AI
        // result gates navigation — the upload finishes in the background.
        final uploadFuture = _uploadImageFile(imageFile, uid);

        final recipeData = await getRecipeFromImage(imageFile);

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
          isVideoImport: false,
          pendingImageUpload: uploadFuture,
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
        // CREDIT CHECK FIRST — before any AI call starts.
        _ensureHasCredit();

        print(
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
      print('[SocialImport] Calling AI extraction API');

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
      print('[SocialImport] AI extraction FAILED: $e');

      print(stack.toString());

      rethrow;
    }
  }

  static Future<bool> importRecipeFromName(String recipeName) async {
    final totalStart = DateTime.now();

    print('========== RECIPE NAME IMPORT STARTED ==========');

    return _runImport(
      loadingSteps: const [
        'Found recipe title...',
        'Extracting ingredients...',
        'Reading the steps...',
        'Saving recipe...',
      ],
      errorMessage: 'Failed to generate recipe.',
      import: (doneSignal) async {
        // CREDIT CHECK FIRST — before any AI call starts.
        _ensureHasCredit();

        final step1Start = DateTime.now();

        final uid = AuthService.currentUser?.uid;

        if (uid == null) {
          throw Exception('Login required');
        }

        print(
          '[1] User validation COMPLETED in '
          '${DateTime.now().difference(step1Start).inMilliseconds} ms',
        );

        print('[2] AI recipe generation STARTED');

        final aiStart = DateTime.now();

        final recipeData = await getRecipeFromName(recipeName);

        print(
          '[2] AI recipe generation COMPLETED in '
          '${DateTime.now().difference(aiStart).inMilliseconds} ms',
        );

        print('[3] SavedRecipe conversion STARTED');

        final conversionStart = DateTime.now();

        final recipe = SavedRecipe.fromGeminiResponse(recipeData);

        print(
          '[3] SavedRecipe conversion COMPLETED in '
          '${DateTime.now().difference(conversionStart).inMilliseconds} ms',
        );

        print('[4] Save recipe & navigate STARTED');

        final saveStart = DateTime.now();

        await _saveRecipeAndNavigate(
          recipe: recipe,
          sourceUrl: 'recipe_name_search',
          doneSignal: doneSignal,
          firebaseImageUrl: recipe.imageUrl!.isNotEmpty ? recipe.imageUrl : null,
        );

        print(
          '[4] Save recipe & navigate COMPLETED in '
          '${DateTime.now().difference(saveStart).inMilliseconds} ms',
        );

        print(
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
      print(
        '[Background] Firebase image upload START | '
        'recipe=${recipe.title}',
      );

      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        print(
          '[Background] Upload skipped | '
          'user not logged in',
        );

        return;
      }

      // ============================================================
      // STEP 1: FETCH SOCIAL THUMBNAIL
      // ============================================================

      print('[Background] Fetching ORIGINAL SOCIAL THUMBNAIL START');

      final socialImageUrl = await _fetchSocialThumbnail(sourceUrl);

      print(
        '[Background] ORIGINAL SOCIAL THUMBNAIL DONE | '
        'found=${socialImageUrl != null}',
      );

      if (socialImageUrl == null || socialImageUrl.trim().isEmpty) {
        print('[Background] No social thumbnail found');

        return;
      }

      // ============================================================
      // STEP 2: DOWNLOAD ORIGINAL IMAGE
      // ============================================================

      print('[Background] Image download START');

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
        print(
          '[Background] Image download FAILED | '
          'status=${response.statusCode}',
        );

        return;
      }

      final originalBytes = response.bodyBytes;

      if (originalBytes.isEmpty) {
        print('[Background] Empty image bytes');

        return;
      }

      print(
        '[Background] Image download SUCCESS | '
        'bytes=${originalBytes.length}',
      );

      // ============================================================
      // STEP 3: ALWAYS COMPRESS IMAGE
      // ============================================================

      print('[Background] Image compression START');

      final compressedBytes = await _compressImageBytes(originalBytes);

      if (compressedBytes == null || compressedBytes.isEmpty) {
        print('[Background] Image compression FAILED');

        return;
      }

      print(
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

      print('[Background] Firebase upload SUCCESS');

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
        print('[Background] Recipe not found');

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
        print('[Background] Matching recipe not found');

        return;
      }

      // ============================================================
      // STEP 6: UPDATE FIRESTORE IMAGE URL
      // ============================================================

      await recipeDoc.reference.update({
        'imageUrl': firebaseImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('[Background] Firestore image URL updated SUCCESS');

      print('[Background] Social image processing COMPLETED');
    } catch (e, stack) {
      print('[Background] Social image upload FAILED: $e');

      print(stack.toString());
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
      print('Social thumbnail fetch failed: $e');
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

      print('[NetworkImage] Download START');
      print('[NetworkImage] Normalized URL: $normalizedUrl');

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

      print(
        '[NetworkImage] Status: ${response.statusCode} | '
        'Content-Type: ${response.headers['content-type']}',
      );

      if (response.statusCode != 200) {
        print(
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
        print('[NetworkImage] Empty image bytes');
        return null;
      }

      final decodedImage = img.decodeImage(compressedBytes);

      if (decodedImage == null) {
        print('[NetworkImage] Invalid image data');
        return null;
      }

      print(
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

      print('[NetworkImage] Firebase Upload SUCCESS');
      print('[NetworkImage] Firebase URL: $firebaseUrl');

      return firebaseUrl;
    } catch (e, stack) {
      print('[NetworkImage] Upload FAILED: $e');
      print(stack.toString());
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
      print('generateRecipeFromName response: ${jsonEncode(data)}');

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
        print('[ImageCompressor] Invalid image');
        return null;
      }

      final resizedImage = decodedImage.width > maxWidth
          ? img.copyResize(decodedImage, width: maxWidth)
          : decodedImage;

      final compressed = img.encodeJpg(resizedImage, quality: quality);

      final compressedBytes = Uint8List.fromList(compressed);

      print(
        '[ImageCompressor] '
        'original=${(originalBytes.length / 1024 / 1024).toStringAsFixed(2)} MB | '
        'compressed=${(compressedBytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      return compressedBytes;
    } catch (e, stack) {
      print('[ImageCompressor] FAILED: $e');
      print(stack.toString());
      return null;
    }
  }
}
