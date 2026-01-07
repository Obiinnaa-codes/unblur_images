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

  IAPRepository(this._supabase);

  /// Initialize RevenueCat
  Future<void> initialize() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);

      final userId = _supabase.auth.currentUser?.id;

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

      if (userId != null) {
        configuration.appUserID = userId;
      }

      if (kDebugMode) {
        print(
          'Configuring RevenueCat for ${Platform.isAndroid ? 'Android' : 'iOS'}...',
        );
      }

      await Purchases.configure(configuration);

      if (kDebugMode) {
        print('RevenueCat configured successfully');
      }

      // If user is already logged in, identify them
      if (userId != null) {
        await logIn(userId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing RevenueCat: $e');
      }
    }
  }

  /// Identify the user in RevenueCat and sync their attributes (name, email)
  Future<void> logIn(String userId, {String? name, String? email}) async {
    try {
      if (kDebugMode) {
        print('Logging in user to RevenueCat: $userId');
      }

      final result = await Purchases.logIn(userId);

      // Set user attributes
      if (name != null) await Purchases.setDisplayName(name);
      if (email != null) await Purchases.setEmail(email);

      if (kDebugMode) {
        print('User identified successfully. Created: ${result.created}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging in user to RevenueCat: $e');
      }
    }
  }

  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    try {
      await Purchases.purchase(PurchaseParams.package(package));
      // Invalidate virtual currency cache after a successful purchase
      // ignore: undefined_method
      await Purchases.invalidateVirtualCurrenciesCache();
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
      await Purchases.restorePurchases();
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
}
