import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:get/get.dart';

/// Fetches the single `food_cuisines` document and exposes it as
/// category-name → list-of-cuisines. The doc has a random auto-generated ID,
/// so we just take the first (only) document in the collection.
class CuisineController extends GetxController {
  static CuisineController get to => Get.isRegistered<CuisineController>()
      ? Get.find<CuisineController>()
      : Get.put(CuisineController(), permanent: true);

  final RxMap<String, List<String>> categories = <String, List<String>>{}.obs;
  final RxBool isLoading = false.obs;
  bool _fetched = false;
  final RxString selectedCuisine = "".obs;

  /// Call once (e.g. lazily, right before opening the picker). Cached after
  /// the first successful fetch — cuisine list rarely changes.
  Future<void> fetchCuisines({bool force = false}) async {
    if (_fetched && !force) return;
    isLoading.value = true;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('food_cuisines')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        categories.clear();
        return;
      }
      print("Docs : ${snap.docs.length}");

      final data = snap.docs.first.data();
      final result = <String, List<String>>{};
      data.forEach((key, value) {
        if (value is List) {
          result[key] = value.map((e) => e.toString().trim()).toList();
        }
      });
      categories.value = result;
      _fetched = true;
    } catch (_) {
      // best effort — leave categories empty on failure
    } finally {
      isLoading.value = false;
    }
  }

  /// Flat list of every cuisine across all categories (for search).
  List<String> get allCuisines => categories.values.expand((e) => e).toList();
}

class GoalController extends GetxController {
  static GoalController get to => Get.put(GoalController());

  RxList<Map<String, dynamic>> goals = <Map<String, dynamic>>[].obs;
  RxBool isLoading = false.obs;

  Future<void> fetchGoals() async {
    isLoading.value = true;

    final snap = await FirebaseFirestore.instance.collection('goal').get();

    goals.value = snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // document id પણ add કરી દો

      debugPrint("Goal: ${data['title']}");
      debugPrint("Image: ${data['image']}");
      return data;
    }).toList();
    isLoading.value = false;
  }

  @override
  void onInit() {
    fetchGoals();
    super.onInit();
  }
}
