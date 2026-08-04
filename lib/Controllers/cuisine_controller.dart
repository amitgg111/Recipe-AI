import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:get/get.dart';

/// Fetches the single `food_cuisines` document and exposes it as
/// category-name → list-of-cuisines. The doc has a random auto-generated ID,
/// so we just take the first (only) document in the collection.
import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class CuisineController extends GetxController {
  static CuisineController get to => Get.isRegistered<CuisineController>()
      ? Get.find<CuisineController>()
      : Get.put(CuisineController(), permanent: true);

  final RxMap<String, List<String>> categories = <String, List<String>>{}.obs;

  final RxBool isLoading = false.obs;
  final RxString selectedCuisine = "".obs;

  final GetStorage _storage = GetStorage();

  static const String _cacheKey = 'food_cuisines_cache';

  bool _fetched = false;

  @override
  void onInit() {
    super.onInit();

    // Local cache FIRST.
    _loadFromLocalCache();

    // Firestore background refresh.
    fetchCuisines();
  }

  /// ------------------------------------------------------------
  /// LOAD FROM LOCAL STORAGE
  /// ------------------------------------------------------------

  void _loadFromLocalCache() {
    try {
      final cached = _storage.read(_cacheKey);

      if (cached == null) {
        debugPrint('[Cuisine] No local cache found');
        return;
      }

      final Map<String, dynamic> decoded = jsonDecode(cached.toString());

      final result = <String, List<String>>{};

      decoded.forEach((key, value) {
        if (value is List) {
          result[key] = value
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      });

      if (result.isNotEmpty) {
        categories.assignAll(result);

        debugPrint(
          '[Cuisine] Loaded from local cache: '
          '${result.length} categories',
        );
      }
    } catch (e) {
      debugPrint('[Cuisine] Local cache error: $e');
    }
  }

  /// ------------------------------------------------------------
  /// FETCH FROM FIRESTORE
  /// ------------------------------------------------------------

  Future<void> fetchCuisines({bool force = false}) async {
    // Already fetched in this controller session.
    if (_fetched && !force) {
      return;
    }

    // If we already have local data, don't show loader.
    if (categories.isEmpty) {
      isLoading.value = true;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('food_cuisines')
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        debugPrint('[Cuisine] No Firestore documents found');
        return;
      }

      final data = snap.docs.first.data();

      final result = <String, List<String>>{};

      data.forEach((key, value) {
        if (value is List) {
          result[key] = value
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      });

      if (result.isNotEmpty) {
        // Update UI immediately.
        categories.assignAll(result);

        // Save for next time.
        await _storage.write(_cacheKey, jsonEncode(result));

        debugPrint('[Cuisine] Firestore data updated');
      }

      _fetched = true;
    } catch (e) {
      debugPrint('[Cuisine] Firestore fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// ------------------------------------------------------------
  /// REFRESH
  /// ------------------------------------------------------------

  Future<void> refreshCuisines() async {
    await fetchCuisines(force: true);
  }

  /// ------------------------------------------------------------
  /// ALL CUISINES
  /// ------------------------------------------------------------

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
