// import 'dart:async';
// import 'dart:developer';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import 'package:recipe_ai/Service/auth_service.dart';
// import 'package:recipe_ai/widgets/custom_snackbar.dart';

// class CookbookModel {
//   final String id;
//   final String name;
//   final String? imageUrl;
//   final int recipeCount;
//   final List<String> recipeIds;
//   final DateTime? createdAt;

//   CookbookModel({
//     required this.id,
//     required this.name,
//     this.imageUrl,
//     required this.recipeCount,
//     required this.recipeIds,
//     this.createdAt,
//   });

//   factory CookbookModel.fromDocument(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;

//     DateTime? createdAt;
//     final createdAtValue = data['createdAt'];
//     if (createdAtValue is Timestamp) {
//       createdAt = createdAtValue.toDate();
//     } else if (createdAtValue is DateTime) {
//       createdAt = createdAtValue;
//     }
//     return CookbookModel(
//       id: doc.id,
//       name: data['name'] ?? '',
//       imageUrl: data['imageUrl'],
//       recipeCount: data['recipeCount'] ?? 0,
//       recipeIds: List<String>.from(data['recipeIds'] ?? []),
//       createdAt: createdAt, // ✅ IMPORTANT
//     );
//   }
// }

// class CookbookController extends GetxController {
//   final RxList<CookbookModel> cookbooks = <CookbookModel>[].obs;
//   final RxBool isLoading = false.obs;

//   StreamSubscription? _authSub;
//   StreamSubscription? _cookbooksSub;

//   @override
//   void onInit() {
//     super.onInit();
//     // Re-fetch on every auth change (fixes empty data right after first login,
//     // since this permanent controller is created before the user signs in).
//     _authSub = AuthService.authStateChanges.listen((user) {
//       if (user != null) {
//         fetchCookbooks();
//       } else {
//         _cookbooksSub?.cancel();
//         cookbooks.clear();
//       }
//     });
//   }

//   @override
//   void onClose() {
//     _authSub?.cancel();
//     _cookbooksSub?.cancel();
//     super.onClose();
//   }

//   void fetchCookbooks() {
//     final uid = AuthService.currentUser?.uid;
//     if (uid == null) return;

//     _cookbooksSub?.cancel();
//     _cookbooksSub = FirebaseFirestore.instance
//         .collection("users")
//         .doc(uid)
//         .collection("cookbooks")
//         .orderBy("createdAt", descending: true)
//         .snapshots()
//         .listen((snapshot) {
//           cookbooks.value = snapshot.docs
//               .map((e) => CookbookModel.fromDocument(e))
//               .toList();
//         });
//   }

//   Future<void> createCookbook(String name) async {
//     try {
//       final uid = AuthService.currentUser?.uid;
//       if (uid == null) throw Exception("User not logged in");

//       await FirebaseFirestore.instance
//           .collection("users")
//           .doc(uid)
//           .collection("cookbooks")
//           .add({
//             "name": name,
//             "imageUrl": "",
//             "recipeCount": 0,
//             "recipeIds": [],
//             "createdAt": FieldValue.serverTimestamp(),
//           });

//       // CustomSnackbar.show(
//       //   title: 'Created',
//       //   message: '"$name" cookbook created',
//       //   type: SnackbarType.success,
//       // );
//     } catch (e) {
//       log("Create cookbook error => $e");
//       CustomSnackbar.show(
//         title: 'Error',
//         message: 'Failed to create cookbook',
//         type: SnackbarType.error,
//       );
//     }
//   }

//   Future<void> updateCookbook(String cookbookId, String newName) async {
//     try {
//       final uid = AuthService.currentUser?.uid;
//       if (uid == null) throw Exception("User not logged in");

//       await FirebaseFirestore.instance
//           .collection("users")
//           .doc(uid)
//           .collection("cookbooks")
//           .doc(cookbookId)
//           .update({"name": newName});

//       // CustomSnackbar.show(
//       //   title: 'Updated',
//       //   message: 'Cookbook renamed to "$newName"',
//       //   type: SnackbarType.success,
//       // );
//     } catch (e) {
//       log("Update cookbook error => $e");
//       CustomSnackbar.show(
//         title: 'Error',
//         message: 'Failed to update cookbook',
//         type: SnackbarType.error,
//       );
//     }
//   }

//   Future<void> deleteCookbook(String cookbookId) async {
//     try {
//       final uid = AuthService.currentUser?.uid;
//       if (uid == null) throw Exception("User not logged in");

//       await FirebaseFirestore.instance
//           .collection("users")
//           .doc(uid)
//           .collection("cookbooks")
//           .doc(cookbookId)
//           .delete();

//       // CustomSnackbar.show(
//       //   title: 'Deleted',
//       //   message: 'Cookbook deleted',
//       //   type: SnackbarType.success,
//       // );
//     } catch (e) {
//       log("Delete cookbook error => $e");
//       CustomSnackbar.show(
//         title: 'Error',
//         message: 'Failed to delete cookbook',
//         type: SnackbarType.error,
//       );
//     }
//   }

//   Future<void> addRecipeToCookbook(
//     String cookbookId,
//     String recipeId,
//     String? recipeImageUrl, {
//     bool showToast = true,
//   }) async {
//     try {
//       final uid = AuthService.currentUser?.uid;
//       if (uid == null) throw Exception("User not logged in");

//       final ref = FirebaseFirestore.instance
//           .collection("users")
//           .doc(uid)
//           .collection("cookbooks")
//           .doc(cookbookId);

//       final snap = await ref.get();
//       final data = snap.data() ?? {};
//       final existingIds = List<String>.from(data['recipeIds'] ?? []);

//       if (existingIds.contains(recipeId)) {
//         if (showToast) {
//           CustomSnackbar.show(
//             title: 'Already Added',
//             message: 'Recipe is already in this cookbook',
//             type: SnackbarType.error,
//           );
//         }
//         return;
//       }

//       final Map<String, dynamic> updateData = {
//         "recipeIds": FieldValue.arrayUnion([recipeId]),
//         "recipeCount": FieldValue.increment(1),
//       };

//       final currentImage = data['imageUrl']?.toString() ?? '';

//       if (currentImage.isEmpty &&
//           recipeImageUrl != null &&
//           recipeImageUrl.isNotEmpty) {
//         updateData["imageUrl"] = recipeImageUrl;
//       }

//       await ref.update(updateData);

//       if (showToast) {
//         CustomSnackbar.show(
//           title: 'Added',
//           message: 'Recipe added to cookbook',
//           type: SnackbarType.success,
//         );
//       }
//     } catch (e) {
//       log("Add recipe to cookbook error => $e");
//       if (showToast) {
//         CustomSnackbar.show(
//           title: 'Error',
//           message: 'Failed to add recipe',
//           type: SnackbarType.error,
//         );
//       }
//     }
//   }

//   Future<void> removeRecipeFromCookbook(
//     String cookbookId,
//     String recipeId, {
//     bool showToast = true,
//   }) async {
//     try {
//       final uid = AuthService.currentUser?.uid;
//       if (uid == null) throw Exception("User not logged in");

//       await FirebaseFirestore.instance
//           .collection("users")
//           .doc(uid)
//           .collection("cookbooks")
//           .doc(cookbookId)
//           .update({
//             "recipeIds": FieldValue.arrayRemove([recipeId]),
//             "recipeCount": FieldValue.increment(-1),
//           });

//       if (showToast) {
//         CustomSnackbar.show(
//           title: 'Removed',
//           message: 'Recipe removed from cookbook',
//           type: SnackbarType.success,
//         );
//       }
//     } catch (e) {
//       log("Remove recipe error => $e");
//       if (showToast) {
//         CustomSnackbar.show(
//           title: 'Error',
//           message: 'Failed to remove recipe',
//           type: SnackbarType.error,
//         );
//       }
//     }
//   }

//   /// Cascade cleanup for when a recipe is deleted *directly* (e.g. from the
//   /// recipe detail screen), not by removing it from a specific cookbook.
//   ///
//   /// Finds every cookbook that references [recipeId] and strips it from
//   /// `recipeIds` + decrements `recipeCount`, so no cookbook is left pointing
//   /// at a recipe that no longer exists (which was showing as a phantom
//   /// "1/2 recipes" count with nothing inside).
//   Future<void> removeRecipeFromAllCookbooks(String recipeId) async {
//     try {
//       final uid = AuthService.currentUser?.uid;
//       if (uid == null) return;

//       final cookbooksRef = FirebaseFirestore.instance
//           .collection("users")
//           .doc(uid)
//           .collection("cookbooks");

//       final snapshot = await cookbooksRef
//           .where("recipeIds", arrayContains: recipeId)
//           .get();

//       if (snapshot.docs.isEmpty) return;

//       final batch = FirebaseFirestore.instance.batch();
//       for (final doc in snapshot.docs) {
//         batch.update(doc.reference, {
//           "recipeIds": FieldValue.arrayRemove([recipeId]),
//           "recipeCount": FieldValue.increment(-1),
//         });
//       }
//       await batch.commit();
//     } catch (e) {
//       log("Remove recipe from all cookbooks error => $e");
//       // Best-effort cleanup — don't block the recipe deletion flow on this.
//     }
//   }
// }
import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/widgets/custom_snackbar.dart';

class CookbookModel {
  final String id;
  final String name;
  final String? imageUrl;
  final int recipeCount;
  final List<String> recipeIds;
  final DateTime? createdAt;

  CookbookModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.recipeCount,
    required this.recipeIds,
    this.createdAt,
  });

  /// Translated display name for the current app language. Reads straight
  /// from AiTranslationService's cache (no async work here) — the cache is
  /// warmed by [CookbookController] right after cookbooks load, and the UI
  /// picks up the translated value automatically once `cookbooks.refresh()`
  /// fires. Falls back to [name] itself if no translation is cached yet
  /// (English, offline, or not warmed up yet).
  String get displayName => AiTranslationService.cachedOrSelf(name);

  factory CookbookModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime? createdAt;
    final createdAtValue = data['createdAt'];
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is DateTime) {
      createdAt = createdAtValue;
    }
    return CookbookModel(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'],
      recipeCount: data['recipeCount'] ?? 0,
      recipeIds: List<String>.from(data['recipeIds'] ?? []),
      createdAt: createdAt, // ✅ IMPORTANT
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
          // Warm the translation cache for every cookbook name in the
          // current language, then refresh so `CookbookModel.displayName`
          // (read by the UI) picks up the translated text.
          _translateCookbookNames();
        });
  }

  /// Pre-translates every currently-loaded cookbook's name into the active
  /// app language and refreshes the list once done. Safe to call as often as
  /// needed — [AiTranslationService.translateCookbookNames] only translates
  /// names that aren't already cached, so repeat calls are cheap.
  Future<void> _translateCookbookNames() async {
    final names = cookbooks
        .map((c) => c.name)
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) return;
    try {
      await AiTranslationService.translateCookbookNames(names);
      cookbooks.refresh();
    } catch (e) {
      log("Translate cookbook names error => $e");
      // Best-effort — UI just falls back to showing the original names.
    }
  }

  /// Call this after the user switches app language (e.g. from the Language
  /// screen) so cookbook names get re-translated into the new language too.
  Future<void> refreshCookbookTranslations() => _translateCookbookNames();

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

      // Warm the translation for the newly-created name right away instead
      // of waiting for the next full-list translate pass.
      unawaited(AiTranslationService.translateCookbookName(name));

      // CustomSnackbar.show(
      //   title: 'Created',
      //   message: '"$name" cookbook created',
      //   type: SnackbarType.success,
      // );
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

      // Warm the translation for the renamed cookbook right away.
      await AiTranslationService.translateCookbookName(newName);
      cookbooks.refresh();

      // CustomSnackbar.show(
      //   title: 'Updated',
      //   message: 'Cookbook renamed to "$newName"',
      //   type: SnackbarType.success,
      // );
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

      // CustomSnackbar.show(
      //   title: 'Deleted',
      //   message: 'Cookbook deleted',
      //   type: SnackbarType.success,
      // );
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
