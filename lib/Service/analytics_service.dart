import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:recipe_ai/Service/mixpanel_service.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // =========================================================
  // SCREEN VIEW
  // =========================================================

  /// Screen view track કરવા માટે
  Future<void> trackScreen(String screenName, {String? screenClass}) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );

      await MixpanelService.instance.trackScreen(
        screenName,
        properties: screenClass != null ? {"screen_class": screenClass} : null,
      );

      if (kDebugMode) {
        print("📊 Screen View → $screenName");
      }
    } catch (e) {
      if (kDebugMode) print("Analytics Error (Screen): $e");
    }
  }

  // =========================================================
  // BUTTON TAP / CUSTOM EVENTS
  // =========================================================

  /// General event track કરવા માટે
  Future<void> trackEvent(
    String eventName, {
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );

      await MixpanelService.instance.trackEvent(
        eventName,
        parameters: parameters,
      );

      if (kDebugMode) {
        print("📊 Event → $eventName | $parameters");
      }
    } catch (e) {
      if (kDebugMode) print("Analytics Error (Event): $e");
    }
  }

  /// Button tap માટે dedicated method
  Future<void> trackButtonTap(
    String buttonName, {
    String? screenName,
    Map<String, Object>? extra,
  }) async {
    await trackEvent(
      "button_tap",
      parameters: {
        "button_name": buttonName,
        if (screenName != null) "screen_name": screenName,
        ...?extra,
      },
    );
  }

  // =========================================================
  // CREDIT SPENT (તમારા માટે important)
  // =========================================================

  Future<void> trackCreditSpent({
    required int amount,
    required String reason, // e.g. generate_recipe, unlock_feature
    Map<String, Object>? extra,
  }) async {
    await trackEvent(
      "credit_spent",
      parameters: {
        "amount": amount,
        "reason": reason,
        ...?extra,
      },
    );
    await MixpanelService.instance.trackCreditSpent(
      amount: amount,
      reason: reason,
      extra: extra,
    );
  }

  // =========================================================
  // USER PROPERTIES & IDENTIFY
  // =========================================================

  /// User login પછી call કરો
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      await MixpanelService.instance.identify(userId);
      if (kDebugMode) print("📊 User ID set → $userId");
    } catch (e) {
      if (kDebugMode) print("Analytics Error (setUserId): $e");
    }
  }

  /// User property set કરવા માટે
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      await MixpanelService.instance.setUserProfile({name: value});
    } catch (e) {
      if (kDebugMode) print("Analytics Error (UserProperty): $e");
    }
  }

  /// Logout વખતે
  Future<void> clearUserId() async {
    try {
      await _analytics.setUserId(id: null);
      await MixpanelService.instance.reset();
    } catch (e) {
      if (kDebugMode) print("Analytics Error (clearUserId): $e");
    }
  }

  // =========================================================
  // COMMON HELPERS (Optional but useful)
  // =========================================================

  Future<void> trackLogin(String method) async {
    await trackEvent("login", parameters: {"method": method});
  }

  Future<void> trackSignUp(String method) async {
    await trackEvent("sign_up", parameters: {"method": method});
  }

  Future<void> trackPurchase({
    required String itemId,
    required double value,
    String currency = "USD",
  }) async {
    await _analytics.logPurchase(
      currency: currency,
      value: value,
      parameters: {
        "item_id": itemId,
      },
    );
    await MixpanelService.instance.trackPurchase(
      itemId: itemId,
      value: value,
      currency: currency,
    );
  }
}
 