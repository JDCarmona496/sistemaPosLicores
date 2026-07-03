import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../config/supabase_config.dart';
import '../../domain/models/user.dart';

class AuthService {
  SupabaseClient get _client => SupabaseConfig.client;

  /// Devuelve el usuario actual con su perfil extendido.
  /// Lanza excepciones descriptivas si no hay sesión o si falla la carga.
  Future<User> getCurrentUser() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('No hay sesión activa. Inicia sesión nuevamente.');
    }

    final authUserId = session.user.id;

    try {
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', authUserId)
          .maybeSingle();

      if (profile == null) {
        throw Exception(
          'No se encontró el perfil para el usuario $authUserId. '
          'Ejecuta el SQL de diagnóstico para crearlo.',
        );
      }

      return User.fromJson(profile);
    } on AuthException catch (e) {
      throw Exception('Error de autenticación al cargar perfil: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Error de base de datos al cargar perfil: ${e.message}');
    } catch (e) {
      throw Exception('Error al cargar usuario: $e');
    }
  }

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Credenciales inválidas');
      }

      return await getCurrentUser();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
