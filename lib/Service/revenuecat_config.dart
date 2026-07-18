import 'dart:io';

/// RevenueCat configuration.
///
/// Paste your **public SDK keys** here (RevenueCat dashboard →
/// Project settings → API keys → *Public app-specific keys*). These are the
/// keys that start with `goog_` (Android) and `appl_` (iOS) — never put the
/// secret key in the app.
///
/// While the keys are still the placeholder values below, the app keeps working
/// exactly as before (the SDK is not configured and the paywall falls back to
/// its dev unlock). The moment real keys are pasted in, purchases go live.
class RevenueCatConfig {
  RevenueCatConfig._();

  /// Public SDK key for the Android app (starts with `goog_`).
  static const String androidApiKey = 'goog_YOUR_ANDROID_KEY';

  /// Public SDK key for the iOS app (starts with `appl_`).
  static const String iosApiKey = 'appl_fHDinrEsNrzOrmSmETIrRTDiGqW';

  /// The entitlement identifier that grants Plus
  /// (RevenueCat dashboard → Entitlements). Everything the user unlocks hangs
  /// off this one entitlement being active.
  static const String entitlementId = 'plus';

  /// The platform-appropriate public SDK key.
  static String get apiKey => Platform.isIOS ? iosApiKey : androidApiKey;

  /// True once a real key has been pasted in (guards SDK configuration).
  static bool get isConfigured =>
      apiKey.isNotEmpty && !apiKey.contains('YOUR_');
}
