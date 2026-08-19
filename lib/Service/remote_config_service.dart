import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Reads the app's credit amounts from Firebase Remote Config instead of
/// hardcoding them, so they can be tuned live from the console without an app
/// update.
///
/// The console holds ONE JSON parameter named [_globalKey]:
///
/// ```json
/// { "new_user_credit": "3", "weekly_renewal_credit": "1" }
/// ```
///
/// * [newUserCredit] — credits granted when an account is first created.
/// * [weeklyRenewalCredit] — credits granted when the weekly window rolls over.
///
/// Values are read synchronously from the last activated config (Remote Config
/// caches it on device), so callers get an instant number. If the config has
/// never been fetched (true first launch, offline), the [setDefaults] baseline
/// below is used — it matches the current console values so behaviour is
/// consistent even before the first fetch.
class RemoteConfigService {
  RemoteConfigService._();

  static final RemoteConfigService instance = RemoteConfigService._();

  final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  /// The single JSON parameter key configured in the console.
  static const String _globalKey = 'global';

  static const String _kNewUser = 'new_user_credit';
  static const String _kWeekly = 'weekly_renewal_credit';

  /// Last-resort fallbacks, used only if the config was never fetched and no
  /// default is registered. Kept in sync with the current console values.
  static const int _fallbackNewUser = 10;
  static const int _fallbackWeekly = 5;

  bool _initDone = false;

  /// Sets defaults + config settings and does a first fetch/activate. Safe to
  /// call once at startup; never throws (best-effort, falls back to defaults).
  Future<void> init() async {
    try {
      await _rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // Allow a fresh pull on each cold start so console changes show up
          // quickly; Remote Config still rate-limits on the server side.
          minimumFetchInterval: const Duration(minutes: 30),
        ),
      );

      await _rc.setDefaults(<String, dynamic>{
        _globalKey: jsonEncode({
          _kNewUser: '$_fallbackNewUser',
          _kWeekly: '$_fallbackWeekly',
        }),
      });

      await _rc.fetchAndActivate();
      _initDone = true;

      // ignore: avoid_print
      print(
        '[RemoteConfig] loaded — newUserCredit=$newUserCredit '
        'weeklyRenewalCredit=$weeklyRenewalCredit',
      );
    } catch (e) {
      // ignore: avoid_print
      print('[RemoteConfig] init failed, using defaults: $e');
    }
  }

  /// Best-effort re-fetch (e.g. pull-to-refresh or before a grant). Never
  /// throws. Returns true if new values were activated.
  Future<bool> refresh() async {
    try {
      return await _rc.fetchAndActivate();
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> get _global {
    try {
      final raw = _rc.getString(_globalKey);
      if (raw.isEmpty) return const {};
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return const {};
  }

  int _readInt(String key, int fallback) {
    final v = _global[key];
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim()) ?? fallback;
  }

  /// Credits a brand-new account starts with.
  int get newUserCredit => _readInt(_kNewUser, _fallbackNewUser);

  /// Credits granted each weekly renewal.
  int get weeklyRenewalCredit => _readInt(_kWeekly, _fallbackWeekly);

  /// Largest number of credits a user can hold — used to clamp UI badges.
  int get maxCredit =>
      newUserCredit > weeklyRenewalCredit ? newUserCredit : weeklyRenewalCredit;

  bool get isInitialized => _initDone;
}
