import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../config/supabase_config.dart';
import '../../domain/models/user.dart';

/// Repositorio para la gestión de usuarios y roles.
///
/// Solo los administradores tienen permisos para crear, actualizar o
/// desactivar usuarios. La creación de un nuevo usuario utiliza
/// `supabase.auth.signUp`, que inserta el registro en `auth.users`; el trigger
/// `on_auth_user_created` se encarga de crear el perfil en `public.profiles`.
/// Luego se actualiza el perfil con los datos completos.
class UserManagementRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<User>> getAll() async {
    final data = await _client
        .from('profiles')
        .select()
        .order('full_name');

    return data.map((json) => User.fromJson(json)).toList();
  }

  Future<User?> getById(String id) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return User.fromJson(data);
  }

  Future<User> create({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
    bool isActive = true,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'role': role.name,
        },
      );

      final newUser = response.user;
      if (newUser == null) {
        throw Exception('No se pudo crear el usuario. Verifica la configuración de confirmación de email.');
      }

      await _client.from('profiles').update({
        'phone': phone?.trim(),
        'is_active': isActive,
      }).eq('id', newUser.id);

      final created = await getById(newUser.id);
      if (created == null) {
        throw Exception('Usuario creado en auth pero no se encontró el perfil.');
      }
      return created;
    } on AuthException catch (e) {
      debugPrint('[UserManagementRepository] AuthException: ${e.message}');
      throw Exception(e.message);
    } on PostgrestException catch (e) {
      debugPrint('[UserManagementRepository] PostgrestException: ${e.message}');
      throw Exception('Error de base de datos: ${e.message}');
    } catch (e) {
      debugPrint('[UserManagementRepository] Error creando usuario: $e');
      throw Exception('Error al crear usuario: ${e.toString()}');
    }
  }

  Future<User> update(User user) async {
    try {
      await _client.from('profiles').update({
        'full_name': user.fullName.trim(),
        'role': user.role.name,
        'phone': user.phone?.trim(),
        'is_active': user.isActive,
      }).eq('id', user.id);

      final updated = await getById(user.id);
      if (updated == null) {
        throw Exception('No se pudo recuperar el usuario actualizado.');
      }
      return updated;
    } on PostgrestException catch (e) {
      debugPrint('[UserManagementRepository] PostgrestException: ${e.message}');
      throw Exception('Error de base de datos: ${e.message}');
    } catch (e) {
      debugPrint('[UserManagementRepository] Error actualizando usuario: $e');
      throw Exception('Error al actualizar usuario: ${e.toString()}');
    }
  }

  Future<void> toggleActive(String userId, bool isActive) async {
    try {
      await _client.from('profiles').update({
        'is_active': isActive,
      }).eq('id', userId);
    } on PostgrestException catch (e) {
      debugPrint('[UserManagementRepository] PostgrestException: ${e.message}');
      throw Exception('Error de base de datos: ${e.message}');
    } catch (e) {
      debugPrint('[UserManagementRepository] Error cambiando estado: $e');
      throw Exception('Error al cambiar estado: ${e.toString()}');
    }
  }
}
