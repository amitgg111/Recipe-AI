import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:recipe_ai/Service/mixpanel_config.dart';

/// Centralized Mixpanel Service for tracking user analytics across the entire application.
class MixpanelService {
  MixpanelService._();
  static final MixpanelService instance = MixpanelService._();

  Mixpanel? _mixpanel;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initializes the Mixpanel SDK. Safe to call multiple times or without a valid token.
  Future<void> init({String? token}) async {
    if (_isInitialized) return;

    final projectToken = token ?? MixpanelConfig.projectToken;
    if (projectToken.isEmpty || projectToken.contains('YOUR_')) {
      if (kDebugMode) {
        print(
          "📊 Mixpanel Notice: SDK not configured (placeholder token used). Tracking calls will log gracefully.",
        );
      }
      return;
    }

    try {
      _mixpanel = await Mixpanel.init(projectToken, trackAutomaticEvents: true);
      _isInitialized = true;
      if (kDebugMode) {
        print("📊 Mixpanel initialized successfully.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("📊 Mixpanel initialization error: $e");
      }
    }
  }

  /// Explicitly ping last-active timestamp — extra safety on top of automatic events
  Future<void> pingLastActive() async {
    try {
      if (_isInitialized && _mixpanel != null) {
        _mixpanel!.track("app_active_ping");
      }
    } catch (e) {
      if (kDebugMode) print("📊 Mixpanel LastSeen Ping Error: $e");
    }
  }

  // =========================================================
  // SCREEN VIEW TRACKING
  // =========================================================

  /// Track screen view event in Mixpanel
  Future<void> trackScreen(
    String screenName, {
    Map<String, dynamic>? properties,
  }) async {
    final Map<String, dynamic> eventProps = {
      "screen_name": screenName,
      ...?properties,
    };

    await trackEvent("screen_view", parameters: eventProps);
  }

  // =========================================================
  // GENERAL EVENT TRACKING
  // =========================================================

  /// General event tracking method
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      if (_isInitialized && _mixpanel != null) {
        _mixpanel!.track(eventName, properties: parameters);
      }

      if (kDebugMode) {
        print("📊 Mixpanel Event → $eventName | $parameters");
      }
    } catch (e) {
      if (kDebugMode) {
        print("📊 Mixpanel Track Error ($eventName): $e");
      }
    }
  }

  // =========================================================
  // BUTTON TAP TRACKING
  // =========================================================

  /// Track user button tap / action
  Future<void> trackButtonTap(
    String buttonName, {
    String? screenName,
    Map<String, dynamic>? extra,
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
  // USER IDENTIFICATION & PROPERTIES
  // =========================================================

  /// Identify user on login / app launch
  Future<void> identify(String userId) async {
    try {
      if (_isInitialized && _mixpanel != null) {
        _mixpanel!.identify(userId);
      }
      if (kDebugMode) {
        print("📊 Mixpanel User Identified → $userId");
      }
    } catch (e) {
      if (kDebugMode) {
        print("📊 Mixpanel Identify Error: $e");
      }
    }
  }

  /// Set user profile attributes
  Future<void> setUserProfile(Map<String, dynamic> properties) async {
    try {
      if (_isInitialized && _mixpanel != null) {
        properties.forEach((key, value) {
          _mixpanel!.getPeople().set(key, value);
        });
      }
      if (kDebugMode) {
        print("📊 Mixpanel User Profile Updated → $properties");
      }
    } catch (e) {
      if (kDebugMode) {
        print("📊 Mixpanel User Profile Error: $e");
      }
    }
  }

  /// Register super properties sent with all subsequent events
  Future<void> registerSuperProperties(Map<String, dynamic> properties) async {
    try {
      if (_isInitialized && _mixpanel != null) {
        _mixpanel!.registerSuperProperties(properties);
      }
    } catch (e) {
      if (kDebugMode) {
        print("📊 Mixpanel Register Super Properties Error: $e");
      }
    }
  }

  /// Reset user state on logout
  Future<void> reset() async {
    try {
      if (_isInitialized && _mixpanel != null) {
        _mixpanel!.reset();
      }
      if (kDebugMode) {
        print("📊 Mixpanel Session Reset");
      }
    } catch (e) {
      if (kDebugMode) {
        print("📊 Mixpanel Reset Error: $e");
      }
    }
  }

  // =========================================================
  // SPECIFIC BUSINESS DOMAIN HELPERS
  // =========================================================

  /// Track credit spent
  Future<void> trackCreditSpent({
    required int amount,
    required String reason,
    Map<String, dynamic>? extra,
  }) async {
    await trackEvent(
      "credit_spent",
      parameters: {"amount": amount, "reason": reason, ...?extra},
    );
  }

  /// Track purchases / subscription upgrades
  Future<void> trackPurchase({
    required String itemId,
    required double value,
    String currency = "USD",
    Map<String, dynamic>? extra,
  }) async {
    await trackEvent(
      "subscription_purchased",
      parameters: {
        "item_id": itemId,
        "value": value,
        "currency": currency,
        ...?extra,
      },
    );
  }

  /// Track search queries
  Future<void> trackSearch({
    required String query,
    required String searchType,
    Map<String, dynamic>? extra,
  }) async {
    await trackEvent(
      "search_performed",
      parameters: {"query": query, "search_type": searchType, ...?extra},
    );
  }

  /// Track AI generations
  Future<void> trackAiGeneration({
    required String actionType,
    String? prompt,
    Map<String, dynamic>? extra,
  }) async {
    await trackEvent(
      "ai_generation",
      parameters: {
        "action_type": actionType,
        if (prompt != null) "prompt": prompt,
        ...?extra,
      },
    );
  }

  /// Track recipe actions (save, delete, share, edit, cook mode, etc.)
  Future<void> trackRecipeAction({
    required String action,
    required String recipeId,
    String? recipeTitle,
    Map<String, dynamic>? extra,
  }) async {
    await trackEvent(
      "recipe_action",
      parameters: {
        "action": action,
        "recipe_id": recipeId,
        if (recipeTitle != null) "recipe_title": recipeTitle,
        ...?extra,
      },
    );
  }

  /// Track bottom tab switches
  Future<void> trackTabSwitch({required String tabName, int? tabIndex}) async {
    await trackEvent(
      "tab_switch",
      parameters: {
        "tab_name": tabName,
        if (tabIndex != null) "tab_index": tabIndex,
      },
    );
  }

  /// Track onboarding steps
  Future<void> trackOnboardingStep({
    required String stepName,
    int? stepIndex,
    Map<String, dynamic>? extra,
  }) async {
    await trackEvent(
      "onboarding_step",
      parameters: {
        "step_name": stepName,
        if (stepIndex != null) "step_index": stepIndex,
        ...?extra,
      },
    );
  }
}
