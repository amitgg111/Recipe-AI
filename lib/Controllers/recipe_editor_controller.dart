import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';

import '../Controllers/home_controller.dart';
import '../Model/recipe_section_model.dart';
import '../Service/auth_service.dart';

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
  final RxList<IngredientSection> ingredientSections = <IngredientSection>[].obs;

  // -----------------------------
  // Instructions (flat + sections)
  // -----------------------------

  final RxList<String> instructions = <String>[].obs;
  final RxList<InstructionSection> instructionSections = <InstructionSection>[].obs;

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

    totalTimeController.text = recipe!.totalTime ?? '';

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
      ingredientSections.assignAll([IngredientSection(items: List.from(recipe!.ingredients))]);
    }

    if (recipe!.instructionSections.isNotEmpty &&
        recipe!.instructionSections.any((s) => s.steps.isNotEmpty)) {
      instructionSections.assignAll(recipe!.instructionSections);
    } else if (recipe!.instructions.isNotEmpty) {
      instructionSections.assignAll([InstructionSection(steps: List.from(recipe!.instructions))]);
    }
  }

  // ===================================================
  // IMAGE PICKER
  // ===================================================

  // Future<void> pickImage() async {
  //   final picker = ImagePicker();

  //   final picked = await picker.pickImage(
  //     source: ImageSource.gallery,
  //     imageQuality: 80,
  //   );

  //   if (picked == null) return;

  //   imageFile.value = File(picked.path);

  //   imagePath.value = picked.path;
  // }
  Future<void> pickImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(source: ImageSource.gallery);

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
    final s = ingredientSections[sectionIdx];
    final newItems = List<String>.from(s.items)..removeAt(itemIdx);
    ingredientSections[sectionIdx] = IngredientSection(name: s.name, items: newItems);
    _syncFlatFromSections();
  }

  void updateIngredientInSection(int sectionIdx, int itemIdx, String value) {
    final s = ingredientSections[sectionIdx];
    final newItems = List<String>.from(s.items);
    newItems[itemIdx] = value;
    ingredientSections[sectionIdx] = IngredientSection(name: s.name, items: newItems);
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
    final s = instructionSections[sectionIdx];
    final newSteps = List<String>.from(s.steps)..removeAt(stepIdx);
    instructionSections[sectionIdx] = InstructionSection(name: s.name, steps: newSteps);
    _syncFlatFromSections();
  }

  void updateInstructionInSection(int sectionIdx, int stepIdx, String value) {
    final s = instructionSections[sectionIdx];
    final newSteps = List<String>.from(s.steps);
    newSteps[stepIdx] = value;
    instructionSections[sectionIdx] = InstructionSection(name: s.name, steps: newSteps);
    _syncFlatFromSections();
  }

  void addInstructionGroup(String name) {
    instructionSections.add(InstructionSection(name: name.trim(), steps: []));
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

      final recipeData = {
        "title": titleController.text.trim(),
        "description": descriptionController.text.trim(),

        "imageUrl": imageUrl,

        "sourceUrl": "",

        "prepTime": prepTimeController.text.trim(),
        "cookTime": cookTimeController.text.trim(),
        "totalTime": totalTimeController.text.trim(),

        "servings": servingsController.text.trim(),

        "category": categoryController.text.trim(),

        "cuisine": cuisineController.text.trim(),

        "keywords": tags.toList(),

        "ingredients": ingredients.toList(),

        "instructions": instructions.toList(),

        "ingredientSections": ingredientSections.isNotEmpty
            ? ingredientSections.map((s) => s.toMap()).toList()
            : [IngredientSection(items: ingredients.toList()).toMap()],

        "instructionSections": instructionSections.isNotEmpty
            ? instructionSections.map((s) => s.toMap()).toList()
            : [InstructionSection(steps: instructions.toList()).toMap()],

        "isPublic": isPublic.value,
      };
      log("FINAL IMAGE URL => $imageUrl");
      final collection = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("recipes");

      if (isEdit) {
        await collection.doc(recipe!.id).update(recipeData);
        log("UPDATED DATA => $recipeData");
      } else {
        await collection.add({
          ...recipeData,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }
      if (isEdit) {
        await collection.doc(recipe!.id).update(recipeData);

        Get.back(result: {...recipeData, "id": recipe!.id});
      } else {
        await collection.add({
          ...recipeData,
          "createdAt": FieldValue.serverTimestamp(),
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
