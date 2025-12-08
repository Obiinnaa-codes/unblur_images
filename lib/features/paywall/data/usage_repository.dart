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

      // 3. If user has credits
      return credits != 0;
    } catch (e) {
      // In case of any error (network, etc), we fallback to true to not block the user
      return true;
    }
  }
}
