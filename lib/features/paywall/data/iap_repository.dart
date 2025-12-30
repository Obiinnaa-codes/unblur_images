import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unblur_images/core/config/iap_config.dart';
import 'dart:io' show Platform;

final iapRepositoryProvider = Provider<IAPRepository>((ref) {
  return IAPRepository(Supabase.instance.client);
});

/// Repository for handling In-App Purchases via RevenueCat
class IAPRepository {
  final SupabaseClient _supabase;

  /// Available offerings fetched from RevenueCat
  Offerings? _offerings;
  Offerings? get offerings => _offerings;

  /// Current customer info
  CustomerInfo? _customerInfo;
  CustomerInfo? get customerInfo => _customerInfo;

  IAPRepository(this._supabase);

  /// Initialize RevenueCat
  Future<void> initialize() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);

      late PurchasesConfiguration configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(
          IAPConfig.revenueCatApiKeyGoogle,
        );
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(IAPConfig.revenueCatApiKeyApple);
      } else {
        return; // Not supported
      }

      await Purchases.configure(configuration);

      // Listen to customer info updates
      Purchases.addCustomerInfoUpdateListener((info) {
        _customerInfo = info;
        _handleCustomerInfoUpdate(info);
      });

      // Fetch initial info
      _customerInfo = await Purchases.getCustomerInfo();
      await loadOfferings();

      // Identify user if logged in
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await Purchases.logIn(userId);
      }

      if (kDebugMode) {
        print('RevenueCat initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing RevenueCat: $e');
      }
    }
  }

  /// Load available offerings
  Future<bool> loadOfferings() async {
    try {
      _offerings = await Purchases.getOfferings();
      if (kDebugMode) {
        print(
          'Offerings loaded: ${_offerings?.current?.availablePackages.length ?? 0} packages',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading offerings: $e');
      }
      return false;
    }
  }

  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    try {
      final purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      _customerInfo = purchaseResult.customerInfo;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error purchasing package: $e');
      }
      return false;
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;
      if (kDebugMode) {
        print('Purchases restored');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error restoring purchases: $e');
      }
      rethrow;
    }
  }

  /// Check if user has active pro entitlement
  bool get isPro {
    if (_customerInfo == null) return false;
    return _customerInfo!.entitlements.all[IAPConfig.entitlementId]?.isActive ??
        false;
  }

  /// Handle updates (e.g., sync with Supabase if needed)
  Future<void> _handleCustomerInfoUpdate(CustomerInfo info) async {
    // Ideally, use RevenueCat Webhooks to update Supabase.
    // Here we can do a client-side sync if strictly necessary,
    // but usually checking `isPro` or `entitlements` locally is enough for UI.

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final isPro =
        info.entitlements.all[IAPConfig.entitlementId]?.isActive ?? false;

    // Optional: Sync minimal status to database for other platforms/web
    // This is "best effort" from client.
    try {
      await _supabase.from('subscriptions').upsert({
        'user_id': userId,
        'is_pro': isPro,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Ignore sync errors
      if (kDebugMode) {
        print('Error syncing status to Supabase: $e');
      }
    }
  }
}
