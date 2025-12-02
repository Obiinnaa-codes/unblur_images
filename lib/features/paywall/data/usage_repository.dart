import 'package:supabase_flutter/supabase_flutter.dart';

class UsageRepository {
  final SupabaseClient _supabase;

  UsageRepository(this._supabase);

  Future<bool> hasFreeCredits() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    // Check if user is Pro
    final profile = await _supabase
        .from('profiles')
        .select('is_pro')
        .eq('id', user.id)
        .single();

    if (profile['is_pro'] == true) return true;

    // Check usage in last 7 days
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final response = await _supabase
        .from('usage_logs')
        .select('*')
        .eq('user_id', user.id)
        .gte('created_at', sevenDaysAgo.toIso8601String())
        .count(CountOption.exact);

    return response.count < 1;
  }
}
