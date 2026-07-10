import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Helper/recipe_publish_policy.dart';

/// The "Cannot Publish Recipe" popup shown whenever the user tries to make a
/// recipe that was saved from Discover public. Reused by every publish surface
/// (recipe detail, My Recipes, editor) so the wording stays identical.
///
/// It only informs — it never mutates any data; the caller keeps the toggle
/// OFF.
Future<void> showCannotPublishDialog() {
  return Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        RecipePublishPolicy.cannotPublishTitle,
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: const Text(RecipePublishPolicy.cannotPublishMessage),
      actions: [
        TextButton(
          onPressed: () {
            if (Get.isDialogOpen ?? false) Get.back();
          },
          child: const Text(
            'OK',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
    barrierDismissible: true,
  );
}
