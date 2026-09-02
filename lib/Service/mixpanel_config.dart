/// Mixpanel configuration.
///
/// Replace `projectToken` with your actual Mixpanel Project Token from your Mixpanel project settings.
class MixpanelConfig {
  MixpanelConfig._();

  /// Project token for Mixpanel Analytics.
  static const String projectToken = '02761f902048eb6e54bcd8b75a5f7288';

  /// True once a real key has been provided (guards SDK configuration).
  static bool get isConfigured =>
      projectToken.isNotEmpty && !projectToken.contains('YOUR_');
}
