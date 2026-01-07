// import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  Future<bool> signInWithGoogle() async {
    /// Web-based Google Sign-In (opens external browser)
    return _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'unblur.images://login-callback',
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
