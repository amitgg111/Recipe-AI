import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Core/Theme/app_theme.dart';
import 'package:recipe_ai/Service/import_with_image_api_calling_service.dart';
import 'package:recipe_ai/Widget/custom_text.dart';

class ImportFromSocialScreen extends StatefulWidget {
  const ImportFromSocialScreen({super.key});

  @override
  State<ImportFromSocialScreen> createState() => _ImportFromSocialScreenState();
}

class _ImportFromSocialScreenState extends State<ImportFromSocialScreen> {
  final _urlController = TextEditingController();
  final _captionController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final url = _urlController.text.trim();
    final caption = _captionController.text.trim();

    if (url.isEmpty && caption.isEmpty) {
      Get.snackbar(
        'Missing content',
        'Paste an Instagram/Facebook link or recipe caption.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Navigator.of(context).pop();

    await RecipeImportService.importRecipeFromSocialContent(
      url: url.isNotEmpty ? url : null,
      caption: caption.isNotEmpty ? caption : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const CustomText(
          'Import from Social Media',
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              'Share from Instagram or Facebook to Recipe AI, or paste the post link below.',
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 24),
            const CustomText(
              'Post URL',
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://instagram.com/reel/...',
                filled: true,
                fillColor: AppTheme.surface(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const CustomText(
              'Caption (optional)',
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _captionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Paste recipe caption or description...',
                filled: true,
                fillColor: AppTheme.surface(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _import,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const CustomText(
                  'Extract Recipe',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
