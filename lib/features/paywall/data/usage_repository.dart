import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final usageRepositoryProvider = Provider<UsageRepository>((ref) {
  return UsageRepository(Supabase.instance.client);
});

class UsageRepository {
  final SupabaseClient _supabase;

  UsageRepository(this._supabase);

  /// Check if user has credits OR is Pro
  Future<bool> hasFreeCredits() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // 1. Fetch subscription (is_pro + credits)
      final data = await _supabase
          .from('subscriptions')
          .select()
          .eq('user_id', user.id)
          .single();

      final int credits = data['credits'];
      final bool isPro = data['is_pro'] ?? false;

      // 2. If user is Pro (subscription active), they have unlimited access
      if (isPro) {
        // Check if subscription is still valid
        final expiryStr = data['subscription_expiry'] as String?;
        if (expiryStr != null) {
          final expiry = DateTime.tryParse(expiryStr);
          if (expiry != null && expiry.isAfter(DateTime.now())) {
            return true; // Subscription is active
          }
        }
      }

      // 3. If user has credits
      return credits != 0;
    } catch (e) {
      // In case of any error (network, etc), we fallback to true to not block the user
      return true;
    }
  }

  /// Update subscription status after purchase
  Future<void> updateSubscriptionStatus({
    required bool isPro,
    required String subscriptionType,
    DateTime? expiryDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('subscriptions')
          .update({
            'is_pro': isPro,
            'subscription_type': subscriptionType,
            'subscription_expiry': expiryDate?.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Error updating subscription: $e');
    }
  }

  /// Add credits to user account after purchase
  Future<void> addCredits(int amount) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Fetch current credits
      final data = await _supabase
          .from('subscriptions')
          .select('credits')
          .eq('user_id', user.id)
          .single();

      final currentCredits = data['credits'] as int? ?? 0;
      final newCredits = currentCredits + amount;

      // Update credits
      await _supabase
          .from('subscriptions')
          .update({'credits': newCredits})
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Error adding credits: $e');
    }
  }

  /// Get current subscription status
  Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final data = await _supabase
          .from('subscriptions')
          .select()
          .eq('user_id', user.id)
          .single();

      return data;
    } catch (e) {
      return null;
    }
  }
}
