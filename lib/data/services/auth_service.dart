import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../domain/models/user.dart';

class AuthService {
  SupabaseClient get _client => SupabaseConfig.client;

  User? get currentUser {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    final userData = session.user.userMetadata;
    if (userData == null) return null;

    return User(
      id: session.user.id,
      email: session.user.email ?? '',
      fullName: userData['full_name'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == userData['role'],
        orElse: () => UserRole.seller,
      ),
    );
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

    final userData = response.user!.userMetadata;
    return User(
      id: response.user!.id,
      email: response.user!.email ?? '',
      fullName: userData?['full_name'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == userData?['role'],
        orElse: () => UserRole.seller,
      ),
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
