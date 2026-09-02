import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/local_notification_service.dart';
import 'package:recipe_ai/Service/notification_service.dart';
import 'package:recipe_ai/Helper/unit_converter.dart';

/// Preferences for the Settings / More section: units, language and the six
/// notification toggles.
///
/// Notification toggles are backed by Firestore (`users/{uid}.
/// notificationPrefs`) and cached in GetStorage for instant/offline paint.
/// Each setter updates the reactive value immediately (so only that Obx switch
/// rebuilds — never the whole screen), writes Firestore, and drives the
/// matching notification side effect:
///   • local toggles (cook timer / meal plan / weekly grocery) schedule or
///     cancel local notifications,
///   • push toggles (likes & comments / new followers / product news) sync
///     OneSignal tags so campaigns respect the preference.
class SettingsController extends GetxController {
  final _box = GetStorage();
  final _local = LocalNotificationService.instance;
  final _push = NotificationService.instance;

  // Units: 'Metric' | 'US'
  final RxString units = 'Metric'.obs;

  // Selected language display name (e.g. 'English').
  final RxString language = 'English'.obs;

  // Notification toggles (defaults mirror the design).
  final RxBool cookTimerAlerts = true.obs;
  final RxBool mealPlanReminders = true.obs;
  final RxBool weeklyGroceryReminder = true.obs;
  final RxBool likesAndComments = true.obs;
  final RxBool newFollowers = true.obs;
  final RxBool productNews = true.obs;

  String? _uid;

  static const _kUnits = 'pref_units';
  static const _kLang = 'pref_language';
  static const _kCookTimer = 'pref_notif_cook_timer';
  static const _kMealPlan = 'pref_notif_meal_plan';
  static const _kWeeklyGroc = 'pref_notif_weekly_groc';
  static const _kLikes = 'pref_notif_likes';
  static const _kFollowers = 'pref_notif_followers';
  static const _kNews = 'pref_notif_news';

  // Firestore keys under `notificationPrefs`.
  static const _fCookTimer = 'cookTimerAlerts';
  static const _fMealPlan = 'mealPlanReminders';
  static const _fWeeklyGroc = 'weeklyGroceryReminder';
  static const _fLikes = 'likesAndComments';
  static const _fFollowers = 'newFollowers';
  static const _fNews = 'productNews';

  @override
  void onInit() {
    super.onInit();
    // Instant paint from the local cache (works offline / before auth).
    units.value = _box.read(_kUnits) ?? 'Metric';
    language.value = _box.read(_kLang) ?? 'English';
    cookTimerAlerts.value = _box.read(_kCookTimer) ?? true;
    mealPlanReminders.value = _box.read(_kMealPlan) ?? true;
    weeklyGroceryReminder.value = _box.read(_kWeeklyGroc) ?? true;
    likesAndComments.value = _box.read(_kLikes) ?? true;
    newFollowers.value = _box.read(_kFollowers) ?? true;
    productNews.value = _box.read(_kNews) ?? true;
  }

  DocumentReference<Map<String, dynamic>>? get _userRef => _uid == null
      ? null
      : FirebaseFirestore.instance.collection('users').doc(_uid);

  /// Bind to the signed-in user: load their stored prefs from Firestore and
  /// reconcile scheduled notifications + push tags with the current values.
  /// Safe to call repeatedly (e.g. after login and on app start).
  Future<void> bindUser(String uid) async {
    _uid = uid;
    _box.write('current_uid', uid);
    try {
      final snap = await _userRef!.get();
      final prefs = (snap.data()?['notificationPrefs'] as Map?) ?? const {};
      if (prefs.isNotEmpty) {
        _applyBool(cookTimerAlerts, _kCookTimer, prefs[_fCookTimer]);
        _applyBool(mealPlanReminders, _kMealPlan, prefs[_fMealPlan]);
        _applyBool(weeklyGroceryReminder, _kWeeklyGroc, prefs[_fWeeklyGroc]);
        _applyBool(likesAndComments, _kLikes, prefs[_fLikes]);
        _applyBool(newFollowers, _kFollowers, prefs[_fFollowers]);
        _applyBool(productNews, _kNews, prefs[_fNews]);
      } else {
        // First run for this user — seed Firestore from the current values.
        await _writeAllPrefs();
      }
    } catch (_) {
      // Offline / permission error — keep the cached values.
    }
    await reconcileNotifications();
  }

  /// Stop scheduling for the previous user (called on logout).
  Future<void> onLogout() async {
    await _local.cancelMealPlanReminder();
    await _local.cancelWeeklyGroceryReminder();
    await _local.cancelAllCookTimerAlerts();
    await _push.logoutUser();
    _uid = null;
  }

  /// Re-apply the current toggle state to the OS: (re)schedule enabled local
  /// reminders, cancel disabled ones, and push the current tags. Called after
  /// binding a user and whenever the OS permission changes.
  Future<void> reconcileNotifications() async {
    final allowed = _push.hasPermission;

    // Local reminders — only schedule when permission is granted AND enabled.
    if (allowed && mealPlanReminders.value) {
      await _local.scheduleMealPlanReminder();
    } else {
      await _local.cancelMealPlanReminder();
    }
    if (allowed && weeklyGroceryReminder.value) {
      await _local.scheduleWeeklyGroceryReminder();
    } else {
      await _local.cancelWeeklyGroceryReminder();
    }
    if (!allowed || !cookTimerAlerts.value) {
      await _local.cancelAllCookTimerAlerts();
    }

    // Push tags always reflect the stored preference.
    await _push.syncPushTags(
      likesAndComments: likesAndComments.value,
      newFollowers: newFollowers.value,
      productNews: productNews.value,
    );
  }

  /// May a cook-timer notification be shown right now?
  /// (device permission granted AND the toggle enabled).
  bool get canFireCookTimer => _push.hasPermission && cookTimerAlerts.value;

  // ─────────────────────────── units / language ─────────────────────────────

  void setUnits(String value) {
    units.value = value;
    _box.write(_kUnits, value);
  }

  /// The active measurement system, derived reactively from [units].
  /// Reading this inside an Obx makes a widget rebuild when the user switches
  /// between Metric and US so quantities recalculate instantly.
  UnitSystem get unitSystem =>
      units.value == 'US' ? UnitSystem.imperial : UnitSystem.metric;

  void setLanguage(String value) {
    language.value = value;
    _box.write(_kLang, value);
  }

  // ─────────────────────────── notification setters ─────────────────────────

  void setCookTimerAlerts(bool v) {
    _apply(cookTimerAlerts, _kCookTimer, _fCookTimer, v);
    if (!v) _local.cancelAllCookTimerAlerts();
  }

  void setMealPlanReminders(bool v) {
    _apply(mealPlanReminders, _kMealPlan, _fMealPlan, v);
    if (v && _push.hasPermission) {
      _local.scheduleMealPlanReminder();
    } else {
      _local.cancelMealPlanReminder();
    }
  }

  void setWeeklyGroceryReminder(bool v) {
    _apply(weeklyGroceryReminder, _kWeeklyGroc, _fWeeklyGroc, v);
    if (v && _push.hasPermission) {
      _local.scheduleWeeklyGroceryReminder();
    } else {
      _local.cancelWeeklyGroceryReminder();
    }
  }

  void setLikesAndComments(bool v) {
    _apply(likesAndComments, _kLikes, _fLikes, v);
    _syncTags();
  }

  void setNewFollowers(bool v) {
    _apply(newFollowers, _kFollowers, _fFollowers, v);
    _syncTags();
  }

  void setProductNews(bool v) {
    _apply(productNews, _kNews, _fNews, v);
    _syncTags();
  }

  // ─────────────────────────────── internals ────────────────────────────────

  /// Update the reactive value (instant UI), cache locally, and write Firestore.
  void _apply(RxBool target, String cacheKey, String fireKey, bool value) {
    target.value = value; // reactive → only this Obx switch rebuilds
    _box.write(cacheKey, value);
    _writePref(fireKey, value);
  }

  void _applyBool(RxBool target, String cacheKey, dynamic remote) {
    if (remote is bool) {
      target.value = remote;
      _box.write(cacheKey, remote);
    }
  }

  void _writePref(String fireKey, bool value) {
    final ref = _userRef;
    if (ref == null) return;
    ref
        .set({
          'notificationPrefs': {fireKey: value},
        }, SetOptions(merge: true))
        .catchError((_) {});
  }

  Future<void> _writeAllPrefs() async {
    final ref = _userRef;
    if (ref == null) return;
    await ref.set({
      'notificationPrefs': {
        _fCookTimer: cookTimerAlerts.value,
        _fMealPlan: mealPlanReminders.value,
        _fWeeklyGroc: weeklyGroceryReminder.value,
        _fLikes: likesAndComments.value,
        _fFollowers: newFollowers.value,
        _fNews: productNews.value,
      },
    }, SetOptions(merge: true));
  }

  void _syncTags() {
    _push.syncPushTags(
      likesAndComments: likesAndComments.value,
      newFollowers: newFollowers.value,
      productNews: productNews.value,
    );
  }

  /// Convenience used by callers that need the current uid.
  String? get boundUid => _uid ?? AuthService.currentUser?.uid;
}
