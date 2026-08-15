import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:recipe_ai/Service/import_with_image_api_calling_service.dart';

/// Listens for content shared *into* the app from the OS share sheet
/// (Instagram / TikTok / Facebook links, images, reels) and routes it into the
/// recipe-import pipeline. Backed by receive_sharing_intent so it builds on
/// modern Xcode/Swift toolchains.
class ShareIntentService extends GetxService {
  bool _isProcessing = false;

  /// Media shared while the app was terminated (cold start). Held until the
  /// home screen is on-screen — see [consumePendingInitialShare]. Processing it
  /// during main()/splash would push the import's processing screen only for
  /// the splash → home redirect to immediately wipe it out, and the review
  /// screen would then pop up over home mid-flow.
  List<SharedMediaFile>? _pendingInitialMedia;

  Future<void> init() async {
    try {
      // Content shared while the app was terminated (cold start via share sheet).
      final initialMedia = await ReceiveSharingIntent.instance
          .getInitialMedia();
      if (initialMedia.isNotEmpty) {
        _pendingInitialMedia = initialMedia; // defer — see the field doc above.
      }
      // Tell the plugin we've consumed the initial intent so it isn't replayed
      // on the next launch.
      await ReceiveSharingIntent.instance.reset();

      // Content shared while the app is already running / backgrounded — no
      // navigation race here (home is already up), so handle it immediately.
      ReceiveSharingIntent.instance.getMediaStream().listen((
        sharedMedia,
      ) async {
        await _handleSharedMedia(sharedMedia);
      }, onError: (Object e) => log('Share stream error: $e'));
    } catch (e) {
      log('Share Handler Error: $e');
    }
  }

  /// Process a cold-start share once the home screen is visible. The import's
  /// processing screen is then pushed on top of home and stays until the API
  /// responds — after which the review screen replaces it. No-op if nothing is
  /// pending, and safe to call more than once.
  Future<void> consumePendingInitialShare() async {
    final media = _pendingInitialMedia;
    if (media == null) return;
    _pendingInitialMedia = null;
    await _handleSharedMedia(media);
  }

  Future<void> _handleSharedMedia(List<SharedMediaFile> media) async {
    if (media.isEmpty) return;
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Pull any shared text / URL. For text & url shares the value lives in
      // `path`; for media shares iOS may attach accompanying text in `message`.
      String? textContent;
      for (final item in media) {
        if (item.type == SharedMediaType.text ||
            item.type == SharedMediaType.url) {
          textContent = item.path;
          break;
        }
        if (item.message != null && item.message!.trim().isNotEmpty) {
          textContent ??= item.message;
        }
      }

      final sharedUrl = textContent != null
          ? RecipeImportService.extractUrl(textContent)
          : null;
      final caption = textContent?.trim();

      if (sharedUrl != null) {
        await RecipeImportService.importRecipeFromSocialContent(
          url: sharedUrl,
          caption: caption,
        );
        print("--------------------importRecipeFromSocialContent----------");

        return;
      }

      // Otherwise import the first shared video / image attachment.
      for (final item in media) {
        switch (item.type) {
          case SharedMediaType.video:
            await RecipeImportService.importRecipeFromSharedVideo(
              File(item.path),
            );
            print("--------------------importRecipeFromSharedVideo----------");
            return;
          case SharedMediaType.image:
            await RecipeImportService.importRecipeFromSharedImage(
              File(item.path),
            );
            print("--------------------importRecipeFromSharedImage----------");
            return;
          case SharedMediaType.file:
          case SharedMediaType.text:
          case SharedMediaType.url:
            continue;
        }
      }

      // Fallback: import from the caption text alone.
      if (caption != null && caption.isNotEmpty) {
        await RecipeImportService.importRecipeFromSocialContent(
          caption: caption,
        );

        print("--------------------importRecipeFromSocialContent----------");
      }
    } catch (e) {
      log('Share import error: $e');
    } finally {
      _isProcessing = false;
    }
  }
}
