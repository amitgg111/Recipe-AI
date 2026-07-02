import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Local (device) preferences for the Settings / More section: units,
/// language and notification toggles. Persisted with GetStorage — these are
/// pure UI/app preferences and do not touch auth or recipe data.
class SettingsController extends GetxController {
  final _box = GetStorage();

  // Units: 'Metric' | 'US'
  final RxString units = 'Metric'.obs;

  // Selected language display name (e.g. 'English').
  final RxString language = 'English'.obs;

  // Notification toggles (defaults mirror the design).
  final RxBool cookTimerAlerts = true.obs;
  final RxBool mealPlanReminders = true.obs;
  final RxBool weeklyGroceryReminder = false.obs;
  final RxBool likesAndComments = true.obs;
  final RxBool newFollowers = false.obs;
  final RxBool productNews = false.obs;

  static const _kUnits = 'pref_units';
  static const _kLang = 'pref_language';
  static const _kCookTimer = 'pref_notif_cook_timer';
  static const _kMealPlan = 'pref_notif_meal_plan';
  static const _kWeeklyGroc = 'pref_notif_weekly_groc';
  static const _kLikes = 'pref_notif_likes';
  static const _kFollowers = 'pref_notif_followers';
  static const _kNews = 'pref_notif_news';

  @override
  void onInit() {
    super.onInit();
    units.value = _box.read(_kUnits) ?? 'Metric';
    language.value = _box.read(_kLang) ?? 'English';
    cookTimerAlerts.value = _box.read(_kCookTimer) ?? true;
    mealPlanReminders.value = _box.read(_kMealPlan) ?? true;
    weeklyGroceryReminder.value = _box.read(_kWeeklyGroc) ?? false;
    likesAndComments.value = _box.read(_kLikes) ?? true;
    newFollowers.value = _box.read(_kFollowers) ?? false;
    productNews.value = _box.read(_kNews) ?? false;
  }

  void setUnits(String value) {
    units.value = value;
    _box.write(_kUnits, value);
  }

  void setLanguage(String value) {
    language.value = value;
    _box.write(_kLang, value);
  }

  void setCookTimerAlerts(bool v) => _set(_kCookTimer, cookTimerAlerts, v);
  void setMealPlanReminders(bool v) => _set(_kMealPlan, mealPlanReminders, v);
  void setWeeklyGroceryReminder(bool v) => _set(_kWeeklyGroc, weeklyGroceryReminder, v);
  void setLikesAndComments(bool v) => _set(_kLikes, likesAndComments, v);
  void setNewFollowers(bool v) => _set(_kFollowers, newFollowers, v);
  void setProductNews(bool v) => _set(_kNews, productNews, v);

  void _set(String key, RxBool target, bool value) {
    target.value = value;
    _box.write(key, value);
  }
}
