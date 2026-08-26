import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Model/meal_plan_model.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:recipe_ai/widgets/custom_snackbar.dart';
import 'dart:async';
import 'dart:developer';

class MealPlanController extends GetxController {
  final RxList<MealPlanItem> mealPlanItems = <MealPlanItem>[].obs;
  final RxList<MealPlanItem> monthMealPlanItems = <MealPlanItem>[].obs;

  // English originals (Firestore stores English) so re-translating on a language
  // switch always starts from the source, never from an already-translated title.
  List<MealPlanItem> _enWeek = [];
  List<MealPlanItem> _enMonth = [];

  /// Translate each item's display title into the current language (id/date/
  /// mealType are untouched — all logic keys off recipeId). No-op for English.
  Future<List<MealPlanItem>> _translateItems(List<MealPlanItem> items) async {
    if (items.isEmpty || !AiTranslationService.isTranslating) return items;
    return Future.wait(
      items.map(
        (m) async => m.copyWith(
          recipeTitle: await AiTranslationService.translate(m.recipeTitle),
        ),
      ),
    );
  }

  /// Re-translate already-loaded meals after the app language changes.
  Future<void> refreshLanguage() async {
    mealPlanItems.value = await _translateItems(_enWeek);
    monthMealPlanItems.value = await _translateItems(_enMonth);
  }

  final RxBool isLoading = false.obs;
  final Rx<DateTime> selectedWeekStart = DateTime.now().obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxInt viewMode = 0.obs;
  StreamSubscription<QuerySnapshot>? _mealPlanSubscription;
  StreamSubscription<QuerySnapshot>? _monthSubscription;
  StreamSubscription? _authSub;

  // static const mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  static const mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
  @override
  void onInit() {
    super.onInit();
    selectedWeekStart.value = _getMonday(DateTime.now());
    selectedDate.value = DateTime.now();
    ever(selectedWeekStart, (_) => fetchMealPlans());
    // Re-fetch when auth changes — this controller is permanent and created
    // BEFORE login (fresh install / reinstall), so meals must load once the
    // user signs in, not only at startup.
    _authSub = AuthService.authStateChanges.listen((user) {
      if (user != null) {
        fetchMealPlans();
      } else {
        _mealPlanSubscription?.cancel();
        _monthSubscription?.cancel();
        mealPlanItems.clear();
        monthMealPlanItems.clear();
      }
    });
    fetchMealPlans();
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _mealPlanSubscription?.cancel();
    _monthSubscription?.cancel();
    super.onClose();
  }

  DateTime _getMonday(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
  }

  void selectDate(DateTime date) {
    // The Week view is pinned to the CURRENT week (see [goToToday] / [onInit])
    // and must never drift. Selecting a date — e.g. tapping a future day in the
    // Month calendar — only moves the highlighted day, never the week window.
    selectedDate.value = date;
  }

  void goToToday() {
    selectedDate.value = DateTime.now();
    selectedWeekStart.value = _getMonday(DateTime.now());
  }

  void nextWeek() {
    selectedWeekStart.value = selectedWeekStart.value.add(
      const Duration(days: 7),
    );
    selectedDate.value = selectedWeekStart.value;
  }

  void previousWeek() {
    selectedWeekStart.value = selectedWeekStart.value.subtract(
      const Duration(days: 7),
    );
    selectedDate.value = selectedWeekStart.value;
  }

  List<DateTime> getDaysOfWeek(DateTime start) {
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  List<MealPlanItem> getMealsForDate(DateTime date) {
    final dateStr = _formatDate(date);
    return mealPlanItems.where((m) => m.date == dateStr).toList();
  }

  List<MealPlanItem> getMealsForDateAndType(DateTime date, String mealType) {
    final dateStr = _formatDate(date);
    return mealPlanItems
        .where((m) => m.date == dateStr && m.mealType == mealType)
        .toList();
  }

  List<MealPlanItem> getMonthMealsForDate(DateTime date) {
    final dateStr = _formatDate(date);
    return monthMealPlanItems.where((m) => m.date == dateStr).toList();
  }

  Set<String> getMealTypesForDate(DateTime date) {
    final dateStr = _formatDate(date);
    return monthMealPlanItems
        .where((m) => m.date == dateStr)
        .map((m) => m.mealType)
        .toSet();
  }

  String formatDateRange(DateTime start) {
    final end = start.add(const Duration(days: 6));
    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${start.day} ${months[start.month - 1]} ${start.year} - ${end.day} ${months[end.month - 1]} ${end.year}";
  }

  void fetchMealPlans() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      mealPlanItems.clear();
      return;
    }

    final startStr = _formatDate(selectedWeekStart.value);
    final endStr = _formatDate(
      selectedWeekStart.value.add(const Duration(days: 6)),
    );

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
          (snapshot) async {
            final en = snapshot.docs
                .map((doc) => MealPlanItem.fromDocument(doc))
                .toList();
            _enWeek = en;
            mealPlanItems.value = await _translateItems(en);
            isLoading.value = false;
          },
          onError: (error) {
            isLoading.value = false;
            log("Error fetching meal plans: $error");
          },
        );
  }

  void fetchMonthMealPlans(DateTime month) {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      monthMealPlanItems.clear();
      return;
    }

    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startStr = _formatDate(firstDay);
    final endStr = _formatDate(lastDay);

    _monthSubscription?.cancel();

    _monthSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meal_plans')
        .where('date', isGreaterThanOrEqualTo: startStr)
        .where('date', isLessThanOrEqualTo: endStr)
        .snapshots()
        .listen(
          (snapshot) async {
            final en = snapshot.docs
                .map((doc) => MealPlanItem.fromDocument(doc))
                .toList();
            _enMonth = en;
            monthMealPlanItems.value = await _translateItems(en);
          },
          onError: (error) {
            log("Error fetching month meal plans: $error");
          },
        );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  String formatDatePublic(DateTime date) => _formatDate(date);

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

  /// Remove every meal-plan entry that references [recipeId], across ALL
  /// weeks/months. Called when the source recipe is deleted so no dangling
  /// meals remain. The active week/month snapshot listeners refresh the UI.
  Future<void> removeMealsByRecipe(String recipeId) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null || recipeId.isEmpty) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meal_plans')
        .where('recipeId', isEqualTo: recipeId)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> clearWeek() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    final startStr = _formatDate(selectedWeekStart.value);
    final endStr = _formatDate(
      selectedWeekStart.value.add(const Duration(days: 6)),
    );

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meal_plans')
        .where('date', isGreaterThanOrEqualTo: startStr)
        .where('date', isLessThanOrEqualTo: endStr)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    CustomSnackbar.show(
      title: 'Cleared',
      message: 'All meals for this week removed',
      type: SnackbarType.info,
    );
  }
}
