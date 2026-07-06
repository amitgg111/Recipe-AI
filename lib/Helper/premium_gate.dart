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
class PremiumGate {
  PremiumGate._();

  /// Metric/Imperial unit switching. TEMP: always on for dev/testing.
  /// Flip the body to a subscription check to gate it for paying users only.
  static bool get unitConversionUnlocked => true;
}
