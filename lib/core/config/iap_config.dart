/// Configuration for In-App Purchase product IDs
class IAPConfig {
  /// RevenueCat Public API Key (Google Play)
  static const String revenueCatApiKeyGoogle =
      "goog_bLBANEiuOmeaVywjmhMWLUTuDfQ";

  /// RevenueCat Public API Key (App Store)
  static const String revenueCatApiKeyApple = 'appl_...';

  /// Entitlement ID for Pro access (must match RevenueCat)
  static const String entitlementId = 'pro_access';

  /// Virtual Currency ID (must match RevenueCat)
  static const String virtualCurrencyId = 'UC';
}
