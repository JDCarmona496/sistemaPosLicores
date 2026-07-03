import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../config/supabase_config.dart';
import '../../domain/models/user.dart';

class AuthService {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<User?> getCurrentUser() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    try {
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', session.user.id)
          .single();

      return User.fromJson(profile);
    } catch (e) {
      return null;
    }
  }

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Error al iniciar sesión');
    }

    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .single();

    return User.fromJson(profile);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
