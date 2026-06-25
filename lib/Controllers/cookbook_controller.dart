

import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';

class CookbookModel {
  final String id;
  final String name;
  final String? imageUrl;
  final int recipeCount;
  final List<String> recipeIds;

  CookbookModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.recipeCount,
    required this.recipeIds,
  });

  factory CookbookModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CookbookModel(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'],
      recipeCount: data['recipeCount'] ?? 0,
      recipeIds: List<String>.from(data['recipeIds'] ?? []),
    );
  }
}

class CookbookController extends GetxController {
  final RxList<CookbookModel> cookbooks = <CookbookModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCookbooks();
  }

  void fetchCookbooks() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("cookbooks")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .listen((snapshot) {
          cookbooks.value = snapshot.docs
              .map((e) => CookbookModel.fromDocument(e))
              .toList();
        });
  }

  Future<void> createCookbook(String name) async {
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) throw Exception("User not logged in");

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("cookbooks")
          .add({
            "name": name,
            "imageUrl": "",
            "recipeCount": 0,
            "recipeIds": [],
            "createdAt": FieldValue.serverTimestamp(),
          });

      CustomSnackbar.show(
        title: 'Created',
        message: '"$name" cookbook created',
        type: SnackbarType.success,
      );
    } catch (e) {
      log("Create cookbook error => $e");
      CustomSnackbar.show(
        title: 'Error',
        message: 'Failed to create cookbook',
        type: SnackbarType.error,
      );
    }
  }

  Future<void> updateCookbook(String cookbookId, String newName) async {
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) throw Exception("User not logged in");

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("cookbooks")
          .doc(cookbookId)
          .update({"name": newName});

      CustomSnackbar.show(
        title: 'Updated',
        message: 'Cookbook renamed to "$newName"',
        type: SnackbarType.success,
      );
    } catch (e) {
      log("Update cookbook error => $e");
      CustomSnackbar.show(
        title: 'Error',
        message: 'Failed to update cookbook',
        type: SnackbarType.error,
      );
    }
  }

  Future<void> deleteCookbook(String cookbookId) async {
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) throw Exception("User not logged in");

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("cookbooks")
          .doc(cookbookId)
          .delete();

      CustomSnackbar.show(
        title: 'Deleted',
        message: 'Cookbook deleted',
        type: SnackbarType.success,
      );
    } catch (e) {
      log("Delete cookbook error => $e");
      CustomSnackbar.show(
        title: 'Error',
        message: 'Failed to delete cookbook',
        type: SnackbarType.error,
      );
    }
  }

  Future<void> addRecipeToCookbook(
    String cookbookId,
    String recipeId,
    String? recipeImageUrl,
  ) async {
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) throw Exception("User not logged in");

      final ref = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("cookbooks")
          .doc(cookbookId);

      final snap = await ref.get();
      final data = snap.data() ?? {};
      final existingIds = List<String>.from(data['recipeIds'] ?? []);

      if (existingIds.contains(recipeId)) {
        CustomSnackbar.show(
          title: 'Already Added',
          message: 'Recipe is already in this cookbook',
          type: SnackbarType.error,
        );
        return;
      }

      final Map<String, dynamic> updateData = {
        "recipeIds": FieldValue.arrayUnion([recipeId]),
        "recipeCount": FieldValue.increment(1),
      };

      final currentImage = data['imageUrl']?.toString() ?? '';

      if (currentImage.isEmpty &&
          recipeImageUrl != null &&
          recipeImageUrl.isNotEmpty) {
        updateData["imageUrl"] = recipeImageUrl;
      }

      await ref.update(updateData);

      CustomSnackbar.show(
        title: 'Added',
        message: 'Recipe added to cookbook',
        type: SnackbarType.success,
      );
    } catch (e) {
      log("Add recipe to cookbook error => $e");
      CustomSnackbar.show(
        title: 'Error',
        message: 'Failed to add recipe',
        type: SnackbarType.error,
      );
    }
  }

  Future<void> removeRecipeFromCookbook(
    String cookbookId,
    String recipeId,
  ) async {
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) throw Exception("User not logged in");

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("cookbooks")
          .doc(cookbookId)
          .update({
            "recipeIds": FieldValue.arrayRemove([recipeId]),
            "recipeCount": FieldValue.increment(-1),
          });

      CustomSnackbar.show(
        title: 'Removed',
        message: 'Recipe removed from cookbook',
        type: SnackbarType.success,
      );
    } catch (e) {
      log("Remove recipe error => $e");
      CustomSnackbar.show(
        title: 'Error',
        message: 'Failed to remove recipe',
        type: SnackbarType.error,
      );
    }
  }
}
