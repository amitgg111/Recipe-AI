import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Wraps `flutter_local_notifications` for the LOCAL notification types:
/// Cook Timer Alerts, Meal Plan Reminders, Weekly Grocery Reminder, and the
/// Trial-Ending Reminder.
///
/// The service only *schedules / shows*. Whether a notification is allowed
/// (device permission granted AND the matching toggle enabled) is decided by
/// the caller ([SettingsController]) — see [NotificationGate].
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  // ── Reserved notification id blocks (so a whole type can be cancelled) ──
  static const int mealPlanReminderId = 100;
  static const int weeklyGroceryReminderId = 200;
  static const int trialEndReminderId = 300;
  static const int _cookTimerBase = 1000; // 1000..1999

  // ── Android channels ──
  static const AndroidNotificationChannel _cookChannel =
      AndroidNotificationChannel(
        'cook_timer_alerts',
        'Cook timer alerts',
        description: 'Fires when a cooking step timer finishes',
        importance: Importance.high,
      );
  static const AndroidNotificationChannel _reminderChannel =
      AndroidNotificationChannel(
        'meal_grocery_reminders',
        'Meal & grocery reminders',
        description: 'Meal plan and weekly grocery reminders',
        importance: Importance.defaultImportance,
      );

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone));
    } catch (_) {
      // Fall back to UTC if the platform timezone can't be resolved.
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS permission is requested via OneSignal, so don't prompt here.
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_cookChannel);
    await android?.createNotificationChannel(_reminderChannel);

    _ready = true;
  }

  NotificationDetails get _cookDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      'cook_timer_alerts',
      'Cook timer alerts',
      channelDescription: 'Fires when a cooking step timer finishes',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  NotificationDetails get _reminderDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      'meal_grocery_reminders',
      'Meal & grocery reminders',
      channelDescription: 'Meal plan and weekly grocery reminders',
    ),
    iOS: DarwinNotificationDetails(),
  );

  // ─────────────────────────── Cook timer ───────────────────────────────────

  /// Fire an immediate cook-timer alert (used when a step timer finishes).
  Future<void> showCookTimerAlert({
    required int slot,
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.show(
      _cookTimerBase + (slot % 1000),
      title,
      body,
      _cookDetails,
    );
  }

  /// Schedule a cook-timer alert to fire at [fireAt] (used so the alert still
  /// arrives if the app is backgrounded before the timer completes).
  Future<void> scheduleCookTimerAlert({
    required int slot,
    required DateTime fireAt,
    required String title,
    required String body,
  }) async {
    await init();
    final when = tz.TZDateTime.from(fireAt, tz.local);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) {
      return showCookTimerAlert(slot: slot, title: title, body: body);
    }
    await _plugin.zonedSchedule(
      _cookTimerBase + (slot % 1000),
      title,
      body,
      when,
      _cookDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelCookTimerAlert(int slot) =>
      _plugin.cancel(_cookTimerBase + (slot % 1000));

  /// Cancel every pending cook-timer alert (called when the toggle is OFF).
  Future<void> cancelAllCookTimerAlerts() async {
    await init();
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= _cookTimerBase && p.id < _cookTimerBase + 1000) {
        await _plugin.cancel(p.id);
      }
    }
  }

  // ─────────────────────── Meal plan reminder (daily) ───────────────────────

  /// Daily meal-plan reminder at 09:00 local time.
  Future<void> scheduleMealPlanReminder({int hour = 9, int minute = 0}) async {
    await init();
    await _plugin.zonedSchedule(
      mealPlanReminderId,
      'Plan your meals 🍳',
      "Open Meal Plan and set up what you're cooking today.",
      _nextInstanceOfTime(hour, minute),
      _reminderDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelMealPlanReminder() => _plugin.cancel(mealPlanReminderId);

  // ──────────────────── Weekly grocery reminder (Sunday) ────────────────────

  /// Weekly grocery reminder — Sundays at 17:00 local time.
  Future<void> scheduleWeeklyGroceryReminder({
    int weekday = DateTime.sunday,
    int hour = 17,
    int minute = 0,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      weeklyGroceryReminderId,
      'Grocery run 🛒',
      'Check your list before the weekly shop.',
      _nextInstanceOfWeekday(weekday, hour, minute),
      _reminderDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelWeeklyGroceryReminder() =>
      _plugin.cancel(weeklyGroceryReminderId);

  // ───────────────────── Trial-ending reminder (one-off) ─────────────────────

  /// Schedule a "your trial is ending" reminder relative to [trialEndDate]
  /// (the date the active plan's trial/period ends — typically read from
  /// RevenueCat's `activeEntitlement.expirationDate`).
  ///
  /// Fires [daysBefore] day(s) before [trialEndDate] by default. If that
  /// moment has already passed, it falls back to firing right at
  /// [trialEndDate]; if even that has already passed, it fires a few seconds
  /// from now instead of silently doing nothing.
  Future<void> scheduleTrialEndReminder({
    required DateTime trialEndDate,
    int daysBefore = 1,
  }) async {
    await init();
    final now = tz.TZDateTime.now(tz.local);
    final end = tz.TZDateTime.from(trialEndDate, tz.local);

    var fireAt = end.subtract(Duration(days: daysBefore));
    if (fireAt.isBefore(now)) {
      fireAt = end.isAfter(now) ? end : now.add(const Duration(seconds: 5));
    }

    await _plugin.zonedSchedule(
      trialEndReminderId,
      'Your free trial is ending soon ⏰',
      "Don't lose your Plus benefits — check your plan before it renews.",
      fireAt,
      _reminderDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelTrialEndReminder() => _plugin.cancel(trialEndReminderId);

  // ─────────────────────────────── helpers ──────────────────────────────────

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  @visibleForTesting
  Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();
}
