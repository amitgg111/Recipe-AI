import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/utils/validation_helper.dart';
import 'package:recipe_ai/Helper/recipe_publish_policy.dart';

import '../Controllers/home_controller.dart';
import '../Model/recipe_section_model.dart';
import '../Service/auth_service.dart';

/// Result of [RecipeEditorController._translateFieldsToEnglish]: every
/// user-facing text field of the recipe, already translated to English (or
/// left as-is when the recipe was already English / language couldn't be
/// determined). Kept as a small holder class rather than passing a dozen
/// separate variables around.
class _TranslatedRecipeFields {
  final String title;
  final String description;
  final String prepTime;
  final String cookTime;
  final String totalTime;
  final String servings;
  final String category;
  final String cuisine;
  final List<String> keywords;
  final List<IngredientSection> ingredientSections;
  final List<InstructionSection> instructionSections;

  _TranslatedRecipeFields({
    required this.title,
    required this.description,
    required this.prepTime,
    required this.cookTime,
    required this.totalTime,
    required this.servings,
    required this.category,
    required this.cuisine,
    required this.keywords,
    required this.ingredientSections,
    required this.instructionSections,
  });

  List<String> get ingredients =>
      ingredientSections.expand((s) => s.items).toList();

  List<String> get instructions =>
      instructionSections.expand((s) => s.steps).toList();
}

class RecipeEditorController extends GetxController {
  final RecipeModel? recipe;

  RecipeEditorController({this.recipe});

  bool get isEdit => recipe != null;

  // -----------------------------
  // Text Controllers
  // -----------------------------

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  final prepTimeController = TextEditingController();
  final cookTimeController = TextEditingController();
  final totalTimeController = TextEditingController();

  /// Unit paired with [totalTimeController]'s number: 'minutes' or 'hours'.
  /// Combined into the stored `totalTime` string on save (e.g. "50 minutes").
  final RxString totalTimeUnit = 'minutes'.obs;

  /// A recipe must keep at least this many ingredients / steps — the last few
  /// can't be deleted in the editor.
  static const int kMinItems = 3;

  final servingsController = TextEditingController();

  final categoryController = TextEditingController();
  final cuisineController = TextEditingController();

  // -----------------------------
  // Image
  // -----------------------------

  final Rx<File?> imageFile = Rx<File?>(null);
  final RxString imagePath = ''.obs;
  // -----------------------------
  // Tags
  // -----------------------------

  final RxList<String> tags = <String>[].obs;

  // -----------------------------
  // Ingredients (flat + sections)
  // -----------------------------

  final RxList<String> ingredients = <String>[].obs;
  final RxList<IngredientSection> ingredientSections =
      <IngredientSection>[].obs;

  // -----------------------------
  // Instructions (flat + sections)
  // -----------------------------

  final RxList<String> instructions = <String>[].obs;
  final RxList<InstructionSection> instructionSections =
      <InstructionSection>[].obs;

  // -----------------------------
  // Loading
  // -----------------------------

  final RxBool isSaving = false.obs;
  final RxBool imageRemoved = false.obs;
  final RxBool isPublic = false.obs;

  Future<void> removeImage() async {
    imageRemoved.value = true;

    imageFile.value = null;
    imagePath.value = '';
  }

  @override
  void onInit() {
    super.onInit();

    if (recipe != null) {
      _loadRecipe();
    } else {
      // A brand-new recipe starts with a sensible default serving count the
      // user can edit before saving.
      servingsController.text = '2';
      // Seed one default unnamed section so the "Add ingredient" / "Add step"
      // buttons render for a brand-new recipe (they only appear inside a
      // section). An unnamed section shows no header and matches the save-time
      // fallback, so the persisted shape is unchanged.
      ingredientSections.assignAll([const IngredientSection(items: [])]);
      instructionSections.assignAll([const InstructionSection(steps: [])]);
    }
  }

  void _loadRecipe() {
    if (recipe?.imageUrl != null) {
      imagePath.value = recipe!.imageUrl!;
    }
    titleController.text = recipe!.title;

    descriptionController.text = recipe!.description ?? '';

    prepTimeController.text = recipe!.prepTime ?? '';

    cookTimeController.text = recipe!.cookTime ?? '';

    // Split the stored total time ("50 mins" / "2 hours") into a number + unit
    // so the numeric field and the minutes/hours dropdown pre-fill correctly.
    final tt = recipe!.totalTime ?? '';
    totalTimeController.text = RegExp(r'\d+').firstMatch(tt)?.group(0) ?? '';
    totalTimeUnit.value = tt.toLowerCase().contains('h') ? 'hours' : 'minutes';

    servingsController.text = recipe!.servings ?? '';

    categoryController.text = recipe!.category ?? '';

    cuisineController.text = recipe!.cuisine ?? '';

    tags.assignAll(recipe!.keywords);

    isPublic.value = recipe!.isPublic;

    ingredients.assignAll(recipe!.ingredients);
    instructions.assignAll(recipe!.instructions);

    if (recipe!.ingredientSections.isNotEmpty &&
        recipe!.ingredientSections.any((s) => s.items.isNotEmpty)) {
      ingredientSections.assignAll(recipe!.ingredientSections);
    } else if (recipe!.ingredients.isNotEmpty) {
      ingredientSections.assignAll([
        IngredientSection(items: List.from(recipe!.ingredients)),
      ]);
    }

    if (recipe!.instructionSections.isNotEmpty &&
        recipe!.instructionSections.any((s) => s.steps.isNotEmpty)) {
      instructionSections.assignAll(recipe!.instructionSections);
    } else if (recipe!.instructions.isNotEmpty) {
      instructionSections.assignAll([
        InstructionSection(steps: List.from(recipe!.instructions)),
      ]);
    }
  }

  // ===================================================
  // IMAGE PICKER
  // ===================================================

  Future<void> pickImage() async {
    final picker = ImagePicker();

    // Compress + downscale at pick time so the upload on Save is small and
    // fast (a full-res photo can be several MB → this drops it to a few hundred
    // KB with no visible quality loss for a recipe photo).
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1280,
      maxHeight: 1280,
    );

    if (picked == null) return;

    imageRemoved.value = false;

    imageFile.value = File(picked.path);

    imagePath.value = picked.path;

    log("IMAGE PICKED => ${picked.path}");
  }

  Future<String?> uploadImageToFirebase(File image, String uid) async {
    try {
      final bytes = await image.readAsBytes();

      final fileName = 'recipe_${DateTime.now().millisecondsSinceEpoch}.jpg';
      log("FINAL IMAGE URL => $fileName");
      final ref = FirebaseStorage.instance
          .ref()
          .child('recipe_images')
          .child(uid)
          .child(fileName);

      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      log("UID => $uid");
      log("FILE EXISTS => ${await image.exists()}");
      log("PATH => ${image.path}");

      log("UPLOAD PATH => ${ref.fullPath}");
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // ===================================================
  // TAGS
  // ===================================================

  void addTag(String tag) {
    if (tag.trim().isEmpty) return;

    tags.add(tag.trim());
  }

  void removeTag(String tag) {
    tags.remove(tag);
  }

  // ===================================================
  // INGREDIENTS
  // ===================================================

  void addIngredient(String value) {
    if (value.trim().isEmpty) return;

    ingredients.add(value.trim());
  }

  void removeIngredient(int index) {
    ingredients.removeAt(index);
  }

  // ===================================================
  // INSTRUCTIONS
  // ===================================================

  void addInstruction(String value) {
    if (value.trim().isEmpty) return;

    instructions.add(value.trim());
  }

  void removeInstruction(int index) {
    instructions.removeAt(index);
  }

  // ===================================================
  // SECTION-BASED OPERATIONS
  // ===================================================

  void _syncFlatFromSections() {
    ingredients.assignAll(ingredientSections.expand((s) => s.items));
    instructions.assignAll(instructionSections.expand((s) => s.steps));
  }

  void addIngredientToSection(int sectionIdx, String value) {
    if (value.trim().isEmpty) return;
    final s = ingredientSections[sectionIdx];
    ingredientSections[sectionIdx] = IngredientSection(
      name: s.name,
      items: [...s.items, value.trim()],
    );
    _syncFlatFromSections();
  }

  void removeIngredientFromSection(int sectionIdx, int itemIdx) {
    // A recipe must keep at least [kMinItems] ingredients.
    if (ingredients.length <= kMinItems) {
      CustomSnackbar.show(
        title: 'Minimum reached',
        message:
            'A recipe needs at least $kMinItems ingredients — '
            'this one can’t be removed.',
        type: SnackbarType.error,
      );
      return;
    }
    final s = ingredientSections[sectionIdx];
    final newItems = List<String>.from(s.items)..removeAt(itemIdx);
    ingredientSections[sectionIdx] = IngredientSection(
      name: s.name,
      items: newItems,
    );
    _syncFlatFromSections();
  }

  void updateIngredientInSection(int sectionIdx, int itemIdx, String value) {
    final s = ingredientSections[sectionIdx];
    final newItems = List<String>.from(s.items);
    newItems[itemIdx] = value;
    ingredientSections[sectionIdx] = IngredientSection(
      name: s.name,
      items: newItems,
    );
    _syncFlatFromSections();
  }

  /// Drag-to-reorder an ingredient within its section. [oldIndex]/[newIndex]
  /// come straight from ReorderableListView (newIndex is in the pre-removal
  /// list, so it's adjusted here).
  void reorderIngredientInSection(int sectionIdx, int oldIndex, int newIndex) {
    if (sectionIdx < 0 || sectionIdx >= ingredientSections.length) return;
    final s = ingredientSections[sectionIdx];
    final items = List<String>.from(s.items);
    if (oldIndex < 0 || oldIndex >= items.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    newIndex = newIndex.clamp(0, items.length - 1);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    ingredientSections[sectionIdx] = IngredientSection(
      name: s.name,
      items: items,
    );
    _syncFlatFromSections();
  }

  void addIngredientGroup(String name) {
    ingredientSections.add(IngredientSection(name: name.trim(), items: []));
  }

  void addInstructionToSection(int sectionIdx, String value) {
    if (value.trim().isEmpty) return;
    final s = instructionSections[sectionIdx];
    instructionSections[sectionIdx] = InstructionSection(
      name: s.name,
      steps: [...s.steps, value.trim()],
    );
    _syncFlatFromSections();
  }

  void removeInstructionFromSection(int sectionIdx, int stepIdx) {
    // A recipe must keep at least [kMinItems] steps.
    if (instructions.length <= kMinItems) {
      CustomSnackbar.show(
        title: 'Minimum reached',
        message:
            'A recipe needs at least $kMinItems steps — '
            'this one can’t be removed.',
        type: SnackbarType.error,
      );
      return;
    }
    final s = instructionSections[sectionIdx];
    final newSteps = List<String>.from(s.steps)..removeAt(stepIdx);
    instructionSections[sectionIdx] = InstructionSection(
      name: s.name,
      steps: newSteps,
    );
    _syncFlatFromSections();
  }

  void updateInstructionInSection(int sectionIdx, int stepIdx, String value) {
    final s = instructionSections[sectionIdx];
    final newSteps = List<String>.from(s.steps);
    newSteps[stepIdx] = value;
    instructionSections[sectionIdx] = InstructionSection(
      name: s.name,
      steps: newSteps,
    );
    _syncFlatFromSections();
  }

  /// Drag-to-reorder a step within its section. [oldIndex]/[newIndex] come
  /// straight from ReorderableListView (newIndex is in the pre-removal list).
  void reorderInstructionInSection(int sectionIdx, int oldIndex, int newIndex) {
    if (sectionIdx < 0 || sectionIdx >= instructionSections.length) return;
    final s = instructionSections[sectionIdx];
    final steps = List<String>.from(s.steps);
    if (oldIndex < 0 || oldIndex >= steps.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    newIndex = newIndex.clamp(0, steps.length - 1);
    final step = steps.removeAt(oldIndex);
    steps.insert(newIndex, step);
    instructionSections[sectionIdx] = InstructionSection(
      name: s.name,
      steps: steps,
    );
    _syncFlatFromSections();
  }

  void addInstructionGroup(String name) {
    instructionSections.add(InstructionSection(name: name.trim(), steps: []));
  }

  // ===================================================
  // TRANSLATE-TO-ENGLISH (mirrors ImportWebController's approach)
  // ===================================================

  /// Detects the dominant language across the recipe's OWN text (title,
  /// description, a few ingredients/steps combined into one sample — more
  /// reliable than checking short strings one at a time) and, if it isn't
  /// already English, translates every text field using ONE shared
  /// translator instance. This mirrors
  /// `ImportWebController._translateRecipeToEnglish` so a recipe typed
  /// manually in Gujarati (or any other language) ends up stored in English
  /// exactly like a web-imported one — the on-screen text the user typed is
  /// left untouched; only what gets SAVED is translated.
  Future<_TranslatedRecipeFields> _translateFieldsToEnglish() async {
    final rawTitle = titleController.text.trim();
    final rawDescription = descriptionController.text.trim();
    final rawPrepTime = prepTimeController.text.trim();
    final rawCookTime = cookTimeController.text.trim();
    final rawTotalTime = _composedTotalTime();
    final rawServings = servingsController.text.trim();
    final rawCategory = categoryController.text.trim();
    final rawCuisine = cuisineController.text.trim();
    final rawKeywords = tags.toList();
    final rawIngredientSections = ingredientSections.isNotEmpty
        ? ingredientSections.toList()
        : [IngredientSection(items: ingredients.toList())];
    final rawInstructionSections = instructionSections.isNotEmpty
        ? instructionSections.toList()
        : [InstructionSection(steps: instructions.toList())];

    final fallback = _TranslatedRecipeFields(
      title: rawTitle,
      description: rawDescription,
      prepTime: rawPrepTime,
      cookTime: rawCookTime,
      totalTime: rawTotalTime,
      servings: rawServings,
      category: rawCategory,
      cuisine: rawCuisine,
      keywords: rawKeywords,
      ingredientSections: rawIngredientSections,
      instructionSections: rawInstructionSections,
    );

    // Detect language ONCE using a combined sample of the recipe's own text.
    final sample = <String>[
      rawTitle,
      if (rawDescription.isNotEmpty) rawDescription,
      ...fallback.ingredients.take(3),
      ...fallback.instructions.take(2),
    ];

    final detected = await AiTranslationService.detectDominantLanguage(sample);
    log('🌍 Recipe language: $detected');

    if (detected == 'en' || detected == 'und') {
      // Already English, or couldn't reliably tell — save exactly as typed.
      return fallback;
    }

    final translator = await AiTranslationService.prepareTranslatorFor(
      detected,
    );
    if (translator == null) {
      log(
        '⚠️ Could not prepare translator for $detected — saving original text',
      );
      return fallback;
    }

    Future<String> t(String text) async {
      if (text.trim().isEmpty) return text;
      return AiTranslationService.translateWithTranslator(translator, text);
    }

    try {
      final title = await t(rawTitle);
      final description = await t(rawDescription);
      final prepTime = await t(rawPrepTime);
      final cookTime = await t(rawCookTime);
      final totalTime = await t(rawTotalTime);
      final servings = await t(rawServings);
      final category = await t(rawCategory);
      final cuisine = await t(rawCuisine);

      final keywords = <String>[];
      for (final keyword in rawKeywords) {
        final translated = await t(keyword);
        if (translated.trim().isNotEmpty) keywords.add(translated.trim());
      }

      final translatedIngredientSections = <IngredientSection>[];
      for (final section in rawIngredientSections) {
        final sectionName = (section.name == null || section.name!.isEmpty)
            ? section.name
            : await t(section.name!);
        final items = <String>[];
        for (final item in section.items) {
          final translated = await t(item);
          items.add(translated.trim().isEmpty ? item : translated.trim());
        }
        translatedIngredientSections.add(
          IngredientSection(name: sectionName?.trim(), items: items),
        );
      }

      final translatedInstructionSections = <InstructionSection>[];
      for (final section in rawInstructionSections) {
        final sectionName = (section.name == null || section.name!.isEmpty)
            ? section.name
            : await t(section.name!);
        final steps = <String>[];
        for (final step in section.steps) {
          final translated = await t(step);
          steps.add(translated.trim().isEmpty ? step : translated.trim());
        }
        translatedInstructionSections.add(
          InstructionSection(name: sectionName?.trim(), steps: steps),
        );
      }

      log('✅ Recipe fields translated: ${title.trim()}');

      return _TranslatedRecipeFields(
        title: title.trim().isEmpty ? rawTitle : title.trim(),
        description: description.trim(),
        prepTime: prepTime.trim(),
        cookTime: cookTime.trim(),
        totalTime: totalTime.trim(),
        servings: servings.trim(),
        category: category.trim(),
        cuisine: cuisine.trim(),
        keywords: keywords,
        ingredientSections: translatedIngredientSections,
        instructionSections: translatedInstructionSections,
      );
    } finally {
      await translator.close();
    }
  }

  // ===================================================
  // SAVE
  // ===================================================

  Future<void> saveRecipe() async {
    try {
      if (titleController.text.trim().isEmpty) {
        CustomSnackbar.show(
          title: 'Error',
          message: 'Recipe title required',
          type: SnackbarType.error,
        );

        return;
      }

      // A recipe needs at least one ingredient and one instruction.
      final ingErr = ValidationHelper.nonEmptyList(
        ingredientSections.expand((s) => s.items).toList(),
        field: 'ingredient',
      );
      if (ingErr != null) {
        CustomSnackbar.show(
          title: 'Error',
          message: ingErr,
          type: SnackbarType.error,
        );
        return;
      }
      final insErr = ValidationHelper.nonEmptyList(
        instructionSections.expand((s) => s.steps).toList(),
        field: 'instruction',
      );
      if (insErr != null) {
        CustomSnackbar.show(
          title: 'Error',
          message: insErr,
          type: SnackbarType.error,
        );
        return;
      }

      isSaving.value = true;

      final uid = AuthService.currentUser?.uid;

      if (uid == null) {
        CustomSnackbar.show(
          title: 'Error',
          message: 'User not logged in',
          type: SnackbarType.error,
        );

        return;
      }

      String? imageUrl;

      //------------------------------------------------------------------
      // IMAGE REMOVED
      //------------------------------------------------------------------

      if (imageRemoved.value) {
        if (recipe?.imageUrl != null &&
            recipe!.imageUrl!.isNotEmpty &&
            recipe!.imageUrl!.startsWith('http')) {
          await deleteStorageImage(recipe!.imageUrl!);
        }

        imageUrl = null;
      }
      //------------------------------------------------------------------
      // NEW IMAGE SELECTED
      //------------------------------------------------------------------
      else if (imageFile.value != null) {
        final uploadedUrl = await uploadImageToFirebase(imageFile.value!, uid);

        imageUrl = uploadedUrl;
        log("NEW IMAGE SELECTED => ${imageFile.value!.path}");
        if (isEdit &&
            recipe?.imageUrl != null &&
            recipe!.imageUrl!.isNotEmpty &&
            recipe!.imageUrl!.startsWith('http')) {
          await deleteStorageImage(recipe!.imageUrl!);
        }
        log("UPLOADED URL => $uploadedUrl");
      }
      //------------------------------------------------------------------
      // KEEP OLD IMAGE
      //------------------------------------------------------------------
      else {
        imageUrl = imagePath.value.isEmpty ? null : imagePath.value;
      }

      // ============================================================
      // ALWAYS convert the recipe text to English BEFORE saving — same
      // language-detect + translate approach used for web-imported recipes,
      // so a manually-typed Gujarati (or any other language) recipe is
      // stored in English too.
      // ============================================================

      log('Translating recipe to English before save...');

      final translated = await _translateFieldsToEnglish();

      log('English fields ready');
      log('Title: ${translated.title}');

      // Discovered copies can never be published — never let an edit flip them
      // public even if the toggle somehow says so.
      final bool discoveredCopy = recipe?.isDiscoveredCopy ?? false;
      final bool effectiveIsPublic = discoveredCopy ? false : isPublic.value;

      final recipeData = {
        "title": translated.title,
        "description": translated.description,

        "imageUrl": imageUrl,

        "sourceUrl": "",

        "prepTime": translated.prepTime,
        "cookTime": translated.cookTime,
        "totalTime": translated.totalTime,

        "servings": translated.servings,

        "category": translated.category,

        "cuisine": translated.cuisine,

        "keywords": translated.keywords,

        "ingredients": translated.ingredients,

        "instructions": translated.instructions,

        "ingredientSections": translated.ingredientSections
            .map((s) => s.toMap())
            .toList(),

        "instructionSections": translated.instructionSections
            .map((s) => s.toMap())
            .toList(),

        // Privacy: recipes are private by default. `visibility` is canonical;
        // `isPublic` is kept in sync for backward compatibility.
        // A recipe saved from Discover can never be published, so force it
        // private regardless of the toggle state (the backend enforces this
        // too). `recipeSource` itself is left untouched on edit so provenance
        // is preserved.
        "isPublic": effectiveIsPublic,
        "visibility": effectiveIsPublic ? 'public' : 'private',
        "ownerId": uid,
        "updatedAt": FieldValue.serverTimestamp(),
      };
      log("FINAL IMAGE URL => $imageUrl");
      final collection = FirebaseFirestore.instance.collection("recipes");

      if (isEdit) {
        await collection.doc(recipe!.id).update(recipeData);
        Get.back(result: {...recipeData, "id": recipe!.id});
      } else {
        // New recipes start private with zeroed engagement counters. A recipe
        // written in the editor is the user's own creation, so it is publishable.
        await collection.add({
          ...recipeData,

          "ownerId": uid,

          "recipeSource": RecipePublishPolicy.sourceUserCreated,
          "originalRecipeId": null,

          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),

          "isDeleted": false,

          "likesCount": 0,
          "commentsCount": 0,
          "savesCount": 0,
          "sharesCount": 0,
          "viewsCount": 0,
        });
        Get.back();
      }

      CustomSnackbar.show(
        title: 'Success',
        message: isEdit ? "Recipe Updated" : "Recipe Created",
        type: SnackbarType.success,
      );
    } catch (e) {
      CustomSnackbar.show(
        title: 'Error',
        message: e.toString(),
        type: SnackbarType.error,
      );
    } finally {
      isSaving.value = false;
    }
  }

  /// Combine the total-time number and unit into the stored string, e.g.
  /// "50" + "minutes" → "50 minutes". Empty when no number is entered.
  String _composedTotalTime() {
    final n = totalTimeController.text.trim();
    if (n.isEmpty) return '';
    return '$n ${totalTimeUnit.value}';
  }

  void updateIngredient(int index, String value) {
    ingredients[index] = value;
    ingredients.refresh();
  }

  void updateInstruction(int index, String value) {
    instructions[index] = value;
    instructions.refresh();
  }

  Future<void> deleteStorageImage(String url) async {
    try {
      if (url.isEmpty) return;

      if (!url.startsWith('http')) return;

      await FirebaseStorage.instance.refFromURL(url).delete();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  //------------------------------------------------------------------
  // RE-Oreder
  //------------------------------------------------------------------

  void reorderIngredients(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex--;
    }

    final item = ingredients.removeAt(oldIndex);
    ingredients.insert(newIndex, item);
    ingredients.refresh();
  }

  void reorderInstructions(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex--;
    }

    final item = instructions.removeAt(oldIndex);
    instructions.insert(newIndex, item);
    instructions.refresh();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();

    prepTimeController.dispose();
    cookTimeController.dispose();
    totalTimeController.dispose();

    servingsController.dispose();

    categoryController.dispose();
    cuisineController.dispose();

    super.onClose();
  }
}
