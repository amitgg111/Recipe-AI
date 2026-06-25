import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:share_handler/share_handler.dart';
import 'package:recipe_ai/Service/import_with_image_api_calling_service.dart';

class ShareIntentService extends GetxService {
  bool _isProcessing = false;

  Future<void> init() async {
    try {
      final initialMedia =
          await ShareHandlerPlatform.instance.getInitialSharedMedia();

      if (initialMedia != null) {
        await _handleSharedMedia(initialMedia);
      }

      ShareHandler.instance.sharedMediaStream.listen((sharedMedia) async {
        await _handleSharedMedia(sharedMedia);
      });
    } catch (e) {
      log('Share Handler Error: $e');
    }
  }

  Future<void> _handleSharedMedia(SharedMedia media) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final sharedUrl = RecipeImportService.extractUrl(media.content);
      final caption = media.content?.trim();

      if (sharedUrl != null) {
        await RecipeImportService.importRecipeFromSocialContent(
          url: sharedUrl,
          caption: caption,
        );
        return;
      }

      final attachments = media.attachments?.whereType<SharedAttachment>().toList() ??
          [];

      for (final attachment in attachments) {
        switch (attachment.type) {
          case SharedAttachmentType.video:
            await RecipeImportService.importRecipeFromSharedVideo(
              File(attachment.path),
            );
            return;
          case SharedAttachmentType.image:
            await RecipeImportService.importRecipeFromSharedImage(
              File(attachment.path),
            );
            return;
          case SharedAttachmentType.audio:
          case SharedAttachmentType.file:
            continue;
        }
      }

      if (caption != null && caption.isNotEmpty) {
        await RecipeImportService.importRecipeFromSocialContent(
          caption: caption,
        );
      }
    } catch (e) {
      log('Share import error: $e');
    } finally {
      _isProcessing = false;
    }
  }
}
