import 'dart:async';
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

  StreamSubscription? _authSub;
  StreamSubscription? _cookbooksSub;

  @override
  void onInit() {
    super.onInit();
    // Re-fetch on every auth change (fixes empty data right after first login,
    // since this permanent controller is created before the user signs in).
    _authSub = AuthService.authStateChanges.listen((user) {
      if (user != null) {
        fetchCookbooks();
      } else {
        _cookbooksSub?.cancel();
        cookbooks.clear();
      }
    });
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _cookbooksSub?.cancel();
    super.onClose();
  }

  void fetchCookbooks() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    _cookbooksSub?.cancel();
    _cookbooksSub = FirebaseFirestore.instance
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
    String? recipeImageUrl, {
    bool showToast = true,
  }) async {
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
        if (showToast) {
          CustomSnackbar.show(
            title: 'Already Added',
            message: 'Recipe is already in this cookbook',
            type: SnackbarType.error,
          );
        }
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

      if (showToast) {
        CustomSnackbar.show(
          title: 'Added',
          message: 'Recipe added to cookbook',
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      log("Add recipe to cookbook error => $e");
      if (showToast) {
        CustomSnackbar.show(
          title: 'Error',
          message: 'Failed to add recipe',
          type: SnackbarType.error,
        );
      }
    }
  }

  Future<void> removeRecipeFromCookbook(
    String cookbookId,
    String recipeId, {
    bool showToast = true,
  }) async {
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

      if (showToast) {
        CustomSnackbar.show(
          title: 'Removed',
          message: 'Recipe removed from cookbook',
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      log("Remove recipe error => $e");
      if (showToast) {
        CustomSnackbar.show(
          title: 'Error',
          message: 'Failed to remove recipe',
          type: SnackbarType.error,
        );
      }
    }
  }

  /// Cascade cleanup for when a recipe is deleted *directly* (e.g. from the
  /// recipe detail screen), not by removing it from a specific cookbook.
  ///
  /// Finds every cookbook that references [recipeId] and strips it from
  /// `recipeIds` + decrements `recipeCount`, so no cookbook is left pointing
  /// at a recipe that no longer exists (which was showing as a phantom
  /// "1/2 recipes" count with nothing inside).
  Future<void> removeRecipeFromAllCookbooks(String recipeId) async {
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) return;

      final cookbooksRef = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("cookbooks");

      final snapshot = await cookbooksRef
          .where("recipeIds", arrayContains: recipeId)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          "recipeIds": FieldValue.arrayRemove([recipeId]),
          "recipeCount": FieldValue.increment(-1),
        });
      }
      await batch.commit();
    } catch (e) {
      log("Remove recipe from all cookbooks error => $e");
      // Best-effort cleanup — don't block the recipe deletion flow on this.
    }
  }
}
