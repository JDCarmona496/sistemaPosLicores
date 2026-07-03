import 'package:flutter/foundation.dart';
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
    debugPrint('[AuthService] Sesión activa. authUserId: $authUserId');

    try {
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', authUserId)
          .maybeSingle();

      debugPrint('[AuthService] Perfil recibido: $profile');

      if (profile == null) {
        throw Exception(
          'No se encontró el perfil para el usuario $authUserId. '
          'Ejecuta el SQL de reparación para crearlo.',
        );
      }

      return User.fromJson(profile);
    } on AuthException catch (e) {
      debugPrint('[AuthService] AuthException: ${e.message}');
      throw Exception('Error de autenticación al cargar perfil: ${e.message}');
    } on PostgrestException catch (e) {
      debugPrint('[AuthService] PostgrestException: ${e.message} (${e.code})');
      throw Exception('Error de base de datos al cargar perfil: ${e.message}');
    } catch (e, st) {
      debugPrint('[AuthService] Error inesperado: $e');
      debugPrint(st.toString());
      throw Exception('Error al cargar usuario: $e');
    }
  }

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[AuthService] Intentando login con $email');
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint('[AuthService] Login response user: ${response.user?.id}');

      if (response.user == null) {
        throw Exception('Credenciales inválidas');
      }

      return await getCurrentUser();
    } on AuthException catch (e) {
      debugPrint('[AuthService] AuthException en login: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[AuthService] Error en login: $e');
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
