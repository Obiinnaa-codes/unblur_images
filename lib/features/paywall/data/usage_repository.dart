import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:unblur_images/core/config/iap_config.dart';

final usageRepositoryProvider = Provider<UsageRepository>((ref) {
  return UsageRepository(ref);
});

class UsageRepository {
  // ignore: unused_field
  final Ref _ref;
  final _supabase = Supabase.instance.client;

  UsageRepository(this._ref);

  /// 1️⃣ Check if user has free credits (Boolean)
  /// Responsibility: Determine whether the user currently has any usable credit.
  Future<bool> hasFreeCredits() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return true;

      // 1. Read has_used_free_trial from the subscriptions table.
      final response = await _supabase
          .from('subscriptions')
          .select('has_used_free_trial')
          .eq('user_id', userId)
          .maybeSingle();

      final bool hasUsedFreeTrial = response?['has_used_free_trial'] ?? false;

      // 2. If hasUsedFreeTrial === false: Return true (means user has 1 free credit)
      if (!hasUsedFreeTrial) {
        return true;
      }

      // 3. If hasUsedFreeTrial === true: Call Purchase.VirtualCurrency
      final virtualCurrencies = await Purchases.getVirtualCurrencies();
      final balance =
          virtualCurrencies.all[IAPConfig.virtualCurrencyId]?.balance ?? 0;

      // If virtual currency > 0 → return true, else return false
      return balance > 0;
    } catch (e) {
      print('hasFreeCredits error: $e');
      // try catch the entire function body: return true if an error occurs
      return true;
    }
  }

  /// 2️⃣ Get simplified usage status: { credit: number; isSubscribed: boolean }
  /// Responsibility: Fetch subscription status and resolve credit concurrently.
  Future<Map<String, dynamic>> getUsageStatus() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {'credit': 1, 'isSubscribed': false};

      // Credits and Subscription Fetched Concurrently
      final results = await Future.wait([
        _resolveCredits(userId),
        Purchases.getCustomerInfo(),
      ]);

      final int credit = results[0] as int;
      final CustomerInfo customerInfo = results[1] as CustomerInfo;
      print('getUsageStatus credit: $credit');
      print('getUsageStatus isSubscribed: ${customerInfo.entitlements}');

      // Subscription logic: Fetch subscription status from RevenueCat
      final bool isSubscribed =
          customerInfo.entitlements.all[IAPConfig.entitlementId]?.isActive ??
          false;

      return {'credit': credit, 'isSubscribed': isSubscribed};
    } catch (e) {
      // try catch returns credit 1 subscription false
      return {'credit': 1, 'isSubscribed': false};
    }
  }

  /// Internal credit resolution logic (MUST MATCH EXACTLY)
  Future<int> _resolveCredits(String userId) async {
    // 1. Read hasUsedFreeTrial from subscriptions
    final response = await _supabase
        .from('subscriptions')
        .select('has_used_free_trial')
        .eq('user_id', userId)
        .maybeSingle();

    final bool hasUsedFreeTrial = response?['has_used_free_trial'] ?? false;

    // 2. If hasUsedFreeTrial === false: credit = 1, Do NOT call Purchase.VirtualCurrency
    if (!hasUsedFreeTrial) {
      return 1;
    }

    // 3. If hasUsedFreeTrial === true: Call Purchase.VirtualCurrency
    final virtualCurrencies = await Purchases.getVirtualCurrencies();
    final balance =
        virtualCurrencies.all[IAPConfig.virtualCurrencyId]?.balance ?? 0;

    // If currency > 0 → credit = currency, else credit = 0
    return balance > 0 ? balance.toInt() : 0;
  }
}
