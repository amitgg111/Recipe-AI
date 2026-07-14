/// Central gate for premium (paid) features.
///
/// This is the ONE place a premium/subscription check lives. Feature code reads
/// these flags to decide whether to offer a paid capability — it must never
/// contain its own subscription logic, and the conversion engine
/// ([UnitConverter]) is completely independent of this class.
///
/// ── Development / testing ──
/// Every premium flag is currently force-unlocked so the features can be built
/// and tested without a subscription. To ship, replace the body of the
/// relevant getter with a real entitlement check, e.g.:
///
///   static bool get unitConversionUnlocked =>
///       SubscriptionService.instance.isPro;
///
/// No other code changes are needed — call sites already read the getter.
library;

import 'package:recipe_ai/Service/subscription_service.dart';

class PremiumGate {
  PremiumGate._();

  /// Metric/Imperial unit switching — a Plus feature.
  static bool get unitConversionUnlocked =>
      SubscriptionService.instance.canUseConverter();
}
