import 'package:app_settings/app_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:get_storage/get_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Detailed outcome of an onboarding permission request, so callers can react
/// to every OS state (granted / denied / permanently-denied / restricted)
/// instead of a bare boolean.
class NotificationPermissionResult {
  /// Whether notifications are authorised after this call.
  final bool granted;

  /// Whether the OS permission dialog was actually shown this time. `false`
  /// when the state was already decided (already granted, already asked, or the
  /// OS will no longer prompt) — lets callers avoid duplicate prompts.
  final bool prompted;

  /// The fine-grained native permission state (iOS distinguishes
  /// notDetermined / denied / authorized / provisional / ephemeral; Android
  /// collapses to authorized / denied).
  final OSNotificationPermission status;

  const NotificationPermissionResult({
    required this.granted,
    required this.prompted,
    required this.status,
  });

  /// Push isn't configured on this build — a no-op that never blocks the flow.
  static const unsupported = NotificationPermissionResult(
    granted: false,
    prompted: false,
    status: OSNotificationPermission.notDetermined,
  );
}

/// OneSignal push integration:
///  • initialises the SDK (without prompting),
///  • links the OneSignal user to the Firebase uid,
///  • stores the push Subscription ID (a.k.a. Player ID) on `users/{uid}`,
///  • mirrors the push toggles as OneSignal data tags so campaigns/segments
///    can respect them,
///  • owns the OS notification-permission flow (request-once + open settings).
class   NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// ⚠️ REQUIRED: paste your OneSignal App ID here (OneSignal Dashboard →
  /// Settings → Keys & IDs). Push will not work until this is set.
  static const String oneSignalAppId = 'b4de6817-d749-42f5-ae39-0331f8aa5a9c';

  static const String _kAskedOnboarding = 'notif_asked_onboarding';
  static const String _kAskedSettings = 'notif_asked_settings';

  final _box = GetStorage();
  final _db = FirebaseFirestore.instance;
  bool _initialized = false;

  bool get isConfigured =>
      oneSignalAppId.isNotEmpty && oneSignalAppId != 'YOUR_ONESIGNAL_APP_ID';

  /// Call once at startup (before any permission request). Does NOT prompt.
  Future<void> init() async {
    if (_initialized || !isConfigured) return;
    _initialized = true;

    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(oneSignalAppId);
    // Do not auto-prompt; we request explicitly from the Notifications screen.

    // Keep the stored Subscription ID fresh whenever it changes.
    OneSignal.User.pushSubscription.addObserver((state) {
      final id = state.current.id;
      if (id != null && id.isNotEmpty) _persistSubscriptionId(id);
    });
  }

  // ─────────────────────────── user linking ─────────────────────────────────

  /// Link the OneSignal user to the signed-in Firebase uid and persist the
  /// Subscription ID on the user document.
  Future<void> loginUser(String uid) async {
    if (!isConfigured) return;
    await init();
    await OneSignal.login(uid);
    await _persistSubscriptionId(OneSignal.User.pushSubscription.id, uid: uid);
  }

  Future<void> logoutUser() async {
    if (!isConfigured) return;
    try {
      await OneSignal.logout();
    } catch (_) {}
  }

  Future<void> _persistSubscriptionId(String? id, {String? uid}) async {
    if (id == null || id.isEmpty) return;
    final userId = uid ?? _box.read<String>('current_uid');
    // Firestore write is best-effort; auth uid is passed in on login.
    if (userId == null || userId.isEmpty) return;
    try {
      await _db.collection('users').doc(userId).set({
        'oneSignalId': id,
        'oneSignalUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('NotificationService: failed to save oneSignalId: $e');
    }
  }

  // ───────────────────────────── permission ─────────────────────────────────

  /// Current OS permission state (true = notifications allowed).
  bool get hasPermission =>
      isConfigured ? OneSignal.Notifications.permission : false;

  /// Whether the onboarding notifications screen has already prompted.
  bool get askedInOnboarding => _box.read<bool>(_kAskedOnboarding) ?? false;

  /// Whether the settings notifications screen has already prompted (the
  /// fallback path used when onboarding was declined).
  bool get askedInSettings => _box.read<bool>(_kAskedSettings) ?? false;

  /// Prompt from the ONBOARDING notifications screen (primary entry point).
  /// Requests the OS permission exactly once and reports the resulting state.
  ///
  /// Safe to call repeatedly: it never shows a second dialog once the
  /// permission has been decided (granted, denied, restricted) or already
  /// requested here — it just reports the current state, so callers can proceed
  /// without ever blocking the flow.
  Future<NotificationPermissionResult> requestPermissionOnboarding() async {
    if (!isConfigured) return NotificationPermissionResult.unsupported;
    await init();

    // Already authorised → nothing to prompt.
    if (hasPermission) {
      return NotificationPermissionResult(
        granted: true,
        prompted: false,
        status: await _nativeStatus(),
      );
    }

    // The OS only surfaces a dialog while the state is undecided. If it was
    // already asked here, or the platform reports it can no longer prompt
    // (permanently denied / restricted), report the state without re-asking.
    final canPrompt = await _canRequest();
    if (askedInOnboarding || !canPrompt) {
      return NotificationPermissionResult(
        granted: hasPermission,
        prompted: false,
        status: await _nativeStatus(),
      );
    }

    await _box.write(_kAskedOnboarding, true);
    bool granted;
    try {
      // fallbackToSettings=false: during onboarding we never bounce the user to
      // system settings — the Settings screen owns that fallback path later.
      granted = await OneSignal.Notifications.requestPermission(false);
    } catch (_) {
      granted = hasPermission;
    }
    return NotificationPermissionResult(
      granted: granted,
      prompted: true,
      status: await _nativeStatus(),
    );
  }

  /// Whether the OS can still surface a permission dialog (false once the state
  /// is permanently denied / restricted). Defensive against platform errors.
  Future<bool> _canRequest() async {
    try {
      return await OneSignal.Notifications.canRequest();
    } catch (_) {
      // If we can't tell, fall back to "haven't asked in onboarding yet".
      return !askedInOnboarding;
    }
  }

  /// Best-effort fine-grained permission state, tolerant of platform errors.
  Future<OSNotificationPermission> _nativeStatus() async {
    try {
      return await OneSignal.Notifications.permissionNative();
    } catch (_) {
      return hasPermission
          ? OSNotificationPermission.authorized
          : OSNotificationPermission.denied;
    }
  }

  /// Fallback prompt from the SETTINGS notifications screen — used when the user
  /// did not grant permission during onboarding. Prompts once here; afterwards
  /// the UI offers "Open settings" instead of re-prompting.
  Future<bool> requestPermissionFromSettings() async {
    if (!isConfigured) return false;
    await init();
    if (hasPermission) return true;
    if (askedInSettings) return false; // already tried here → open settings
    await _box.write(_kAskedSettings, true);
    return OneSignal.Notifications.requestPermission(true);
  }

  /// Open the system app-settings page so the user can flip the permission.
  Future<void> openSystemSettings() =>
      AppSettings.openAppSettings(type: AppSettingsType.notification);

  void addPermissionObserver(void Function(bool granted) cb) {
    if (!isConfigured) return;
    OneSignal.Notifications.addPermissionObserver(cb);
  }

  // ─────────────────────────────── tags ─────────────────────────────────────

  /// Mirror the three push toggles as OneSignal tags so dashboard segments /
  /// campaigns (and the Cloud Function) can honour them.
  Future<void> syncPushTags({
    required bool likesAndComments,
    required bool newFollowers,
    required bool productNews,
  }) async {
    if (!isConfigured) return;
    await init();
    OneSignal.User.addTags({
      'likes_comments': likesAndComments ? '1' : '0',
      'new_followers': newFollowers ? '1' : '0',
      'product_news': productNews ? '1' : '0',
    });
  }
}
