import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Model/meal_plan_model.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'dart:async';

import 'dart:developer';

class MealPlanController extends GetxController {
  final RxList<MealPlanItem> mealPlanItems = <MealPlanItem>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<DateTime> selectedWeekStart = DateTime.now().obs;
  StreamSubscription<QuerySnapshot>? _mealPlanSubscription;

  @override
  void onInit() {
    super.onInit();
    // Initialize to the Monday of the current week
    selectedWeekStart.value = _getMonday(DateTime.now());
    // Listen to changes in the selected week and fetch meal plans accordingly
    ever(selectedWeekStart, (_) => fetchMealPlans());
    fetchMealPlans();
  }

  @override
  void onClose() {
    _mealPlanSubscription?.cancel();
    super.onClose();
  }

  DateTime _getMonday(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  void nextWeek() {
    selectedWeekStart.value = selectedWeekStart.value.add(const Duration(days: 7));
  }

  void previousWeek() {
    selectedWeekStart.value = selectedWeekStart.value.subtract(const Duration(days: 7));
  }

  List<DateTime> getDaysOfWeek(DateTime start) {
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  String formatDateRange(DateTime start) {
    final end = start.add(const Duration(days: 6));
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${start.day} ${months[start.month - 1]} ${start.year} - ${end.day} ${months[end.month - 1]} ${end.year}";
  }

  void fetchMealPlans() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      mealPlanItems.clear();
      return;
    }

    final startStr = _formatDate(selectedWeekStart.value);
    final endStr = _formatDate(selectedWeekStart.value.add(const Duration(days: 6)));

    isLoading.value = true;
    _mealPlanSubscription?.cancel();

    _mealPlanSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meal_plans')
        .where('date', isGreaterThanOrEqualTo: startStr)
        .where('date', isLessThanOrEqualTo: endStr)
        .snapshots()
        .listen(
      (snapshot) {
        mealPlanItems.value = snapshot.docs
            .map((doc) => MealPlanItem.fromDocument(doc))
            .toList();
        isLoading.value = false;
      },
      onError: (error) {
        isLoading.value = false;
        log("Error fetching meal plans: $error");
      },
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  Future<void> addMealPlanItem({
    required DateTime date,
    required String mealType,
    required String recipeId,
    required String recipeTitle,
    String? recipeImageUrl,
  }) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    final dateStr = _formatDate(date);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meal_plans')
        .add({
          'date': dateStr,
          'mealType': mealType,
          'recipeId': recipeId,
          'recipeTitle': recipeTitle,
          'recipeImageUrl': recipeImageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> deleteMealPlanItem(String id) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meal_plans')
        .doc(id)
        .delete();
  }
}
