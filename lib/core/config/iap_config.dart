/// Configuration for In-App Purchase product IDs
///
/// IMPORTANT: These product IDs must match exactly with the products
/// created in Google Play Console and App Store Connect.
class IAPConfig {
  // ========================================
  // CONSUMABLE PRODUCTS (Credits)
  // ========================================

  /// RevenueCat Public API Key (Google Play)
  /// TODO: Replace with your actual RevenueCat API Key
  static const String revenueCatApiKeyGoogle = 'goog_...';

  /// RevenueCat Public API Key (App Store)
  /// TODO: Replace with your actual RevenueCat API Key
  static const String revenueCatApiKeyApple = 'appl_...';

  /// Entitlement ID for Pro access (must match RevenueCat)
  static const String entitlementId = 'pro_access';

  // ========================================
  // CONSUMABLE PRODUCTS (Credits)
  // ========================================

  /// 10 credits package
  static const String credits10 = 'credits_10';

  // ========================================
  // SUBSCRIPTION PRODUCTS
  // ========================================

  /// Unlimited credits - Monthly
  static const String unlimitedMonthly = 'pro_monthly';

  // ========================================
  // PRODUCT SETS
  // ========================================

  /// All consumable product IDs
  static Set<String> get consumableProductIds => {credits10};

  /// All subscription product IDs
  static Set<String> get subscriptionProductIds => {unlimitedMonthly};

  /// All product IDs combined
  static Set<String> get allProductIds => {
    ...consumableProductIds,
    ...subscriptionProductIds,
  };

  // ========================================
  // CREDIT AMOUNTS
  // ========================================

  /// Get the number of credits for a consumable product
  static int getCreditsForProduct(String productId) {
    if (productId == credits10) {
      return 10;
    }
    return 0;
  }

  /// Check if a product ID is a subscription
  static bool isSubscription(String productId) {
    return subscriptionProductIds.contains(productId);
  }

  /// Check if a product ID is consumable
  static bool isConsumable(String productId) {
    return consumableProductIds.contains(productId);
  }
}
