// import 'dart:convert';

// import 'package:firebase_remote_config/firebase_remote_config.dart';

// /// Reads the app's credit amounts from Firebase Remote Config instead of
// /// hardcoding them, so they can be tuned live from the console without an app
// /// update.
// ///
// /// The console holds ONE JSON parameter named [_globalKey]:
// ///
// /// ```json
// /// { "new_user_credit": "3", "weekly_renewal_credit": "1" }
// /// ```
// ///
// /// * [newUserCredit] — credits granted when an account is first created.
// /// * [weeklyRenewalCredit] — credits granted when the weekly window rolls over.
// ///
// /// Values are read synchronously from the last activated config (Remote Config
// /// caches it on device), so callers get an instant number. If the config has
// /// never been fetched (true first launch, offline), the [setDefaults] baseline
// /// below is used — it matches the current console values so behaviour is
// /// consistent even before the first fetch.
// class RemoteConfigService {
//   RemoteConfigService._();

//   static final RemoteConfigService instance = RemoteConfigService._();

//   final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

//   /// The single JSON parameter key configured in the console.
//   static const String _globalKey = 'global';

//   static const String _kNewUser = 'new_user_credit';
//   static const String _kWeekly = 'weekly_renewal_credit';

//   /// Last-resort fallbacks, used only if the config was never fetched and no
//   /// default is registered. Kept in sync with the current console values.
//   static const int _fallbackNewUser = 10;
//   static const int _fallbackWeekly = 5;

//   bool _initDone = false;

//   /// Sets defaults + config settings and does a first fetch/activate. Safe to
//   /// call once at startup; never throws (best-effort, falls back to defaults).
//   Future<void> init() async {
//     try {
//       await _rc.setConfigSettings(
//         RemoteConfigSettings(
//           fetchTimeout: const Duration(seconds: 10),
//           // Allow a fresh pull on each cold start so console changes show up
//           // quickly; Remote Config still rate-limits on the server side.
//           minimumFetchInterval: const Duration(minutes: 30),
//         ),
//       );

//       await _rc.setDefaults(<String, dynamic>{
//         _globalKey: jsonEncode({
//           _kNewUser: '$_fallbackNewUser',
//           _kWeekly: '$_fallbackWeekly',
//         }),
//       });

//       await _rc.fetchAndActivate();
//       _initDone = true;

//       // ignore: avoid_print
//       print(
//         '[RemoteConfig] loaded — newUserCredit=$newUserCredit '
//         'weeklyRenewalCredit=$weeklyRenewalCredit',
//       );
//     } catch (e) {
//       // ignore: avoid_print
//       print('[RemoteConfig] init failed, using defaults: $e');
//     }
//   }

//   /// Best-effort re-fetch (e.g. pull-to-refresh or before a grant). Never
//   /// throws. Returns true if new values were activated.
//   Future<bool> refresh() async {
//     try {
//       return await _rc.fetchAndActivate();
//     } catch (_) {
//       return false;
//     }
//   }

//   Map<String, dynamic> get _global {
//     try {
//       final raw = _rc.getString(_globalKey);
//       if (raw.isEmpty) return const {};
//       final decoded = jsonDecode(raw);
//       if (decoded is Map) return Map<String, dynamic>.from(decoded);
//     } catch (_) {}
//     return const {};
//   }

//   int _readInt(String key, int fallback) {
//     final v = _global[key];
//     if (v == null) return fallback;
//     if (v is num) return v.toInt();
//     return int.tryParse(v.toString().trim()) ?? fallback;
//   }

//   /// Credits a brand-new account starts with.
//   int get newUserCredit => _readInt(_kNewUser, _fallbackNewUser);

//   /// Credits granted each weekly renewal.
//   int get weeklyRenewalCredit => _readInt(_kWeekly, _fallbackWeekly);

//   /// Largest number of credits a user can hold — used to clamp UI badges.
//   int get maxCredit =>
//       newUserCredit > weeklyRenewalCredit ? newUserCredit : weeklyRenewalCredit;

//   bool get isInitialized => _initDone;
// }

import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/widgets/custom_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reads the app's credit amounts AND legal URLs from Firebase Remote Config
/// instead of hardcoding them, so they can be tuned live from the console
/// without an app update.
///
/// The console holds ONE JSON parameter named [_globalKey]:
///
/// ```json
/// {
///   "new_user_credit": "5",
///   "weekly_renewal_credit": "5",
///   "privacy_policy": "https://...",
///   "terms_of_service": "https://...",
///   "refund_policy": "https://..."
/// }
/// ```
class RemoteConfigService {
  RemoteConfigService._();

  static final RemoteConfigService instance = RemoteConfigService._();

  final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  /// The single JSON parameter key configured in the console.
  static const String _globalKey = 'global';

  static const String _kNewUser = 'new_user_credit';
  static const String _kWeekly = 'weekly_renewal_credit';
  static const String _kPrivacyPolicy = 'privacy_policy';
  static const String _kTermsOfService = 'terms_of_service';
  static const String _kRefundPolicy = 'refund_policy';

  /// Last-resort fallbacks, used only if the config was never fetched and no
  /// default is registered. Kept in sync with the current console values.
  static const int _fallbackNewUser = 10;
  static const int _fallbackWeekly = 5;

  static const String _fallbackPrivacyPolicy = 'https://example.com/privacy';
  static const String _fallbackTermsOfService = 'https://example.com/terms';
  static const String _fallbackRefundPolicy = 'https://example.com/refunds';

  bool _initDone = false;

  /// Sets defaults + config settings and does a first fetch/activate. Safe to
  /// call once at startup; never throws (best-effort, falls back to defaults).
  Future<void> init() async {
    try {
      await _rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(minutes: 30),
        ),
      );

      await _rc.setDefaults(<String, dynamic>{
        _globalKey: jsonEncode({
          _kNewUser: '$_fallbackNewUser',
          _kWeekly: '$_fallbackWeekly',
          _kPrivacyPolicy: _fallbackPrivacyPolicy,
          _kTermsOfService: _fallbackTermsOfService,
          _kRefundPolicy: _fallbackRefundPolicy,
        }),
      });

      await _rc.fetchAndActivate();
      _initDone = true;

      // ignore: avoid_print
      print(
        '[RemoteConfig] loaded — newUserCredit=$newUserCredit '
        'weeklyRenewalCredit=$weeklyRenewalCredit '
        'privacyPolicyUrl=$privacyPolicyUrl',
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

  String _readString(String key, String fallback) {
    final v = _global[key];
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  /// Credits a brand-new account starts with.
  int get newUserCredit => _readInt(_kNewUser, _fallbackNewUser);

  /// Credits granted each weekly renewal.
  int get weeklyRenewalCredit => _readInt(_kWeekly, _fallbackWeekly);

  /// Largest number of credits a user can hold — used to clamp UI badges.
  int get maxCredit =>
      newUserCredit > weeklyRenewalCredit ? newUserCredit : weeklyRenewalCredit;

  // ── Legal links (live-editable from console, no app update needed) ───────

  String get privacyPolicyUrl =>
      _readString(_kPrivacyPolicy, _fallbackPrivacyPolicy);

  String get termsOfServiceUrl =>
      _readString(_kTermsOfService, _fallbackTermsOfService);

  String get refundPolicyUrl =>
      _readString(_kRefundPolicy, _fallbackRefundPolicy);

  bool get isInitialized => _initDone;
}

class LegalLinkLauncher {
  LegalLinkLauncher._();

  static Future<void> open(String url) async {
    if (url.isEmpty) {
      CustomSnackbar.show(
        title: 'unavailable'.tr,
        message: 'could_not_open_link'.tr,
        type: SnackbarType.error,
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      CustomSnackbar.show(
        title: 'unavailable'.tr,
        message: 'could_not_open_link'.tr,
        type: SnackbarType.error,
      );
      return;
    }

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('could not launch');
    } catch (_) {
      CustomSnackbar.show(
        title: 'unavailable'.tr,
        message: 'could_not_open_link'.tr,
        type: SnackbarType.error,
      );
    }
  }
}
