import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementación segura de [LocalStorage] para Supabase Auth.
///
/// Usa [FlutterSecureStorage] para guardar el token de sesión de forma
/// encriptada en el dispositivo, en lugar de SharedPreferences.
class SecureLocalStorage extends LocalStorage {
  static const _sessionKey = 'supabase_session';

  final FlutterSecureStorage _storage;

  const SecureLocalStorage({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        );

  @override
  Future<void> initialize() async {
    // No se requiere inicialización adicional.
  }

  @override
  Future<bool> hasAccessToken() async {
    final token = await _storage.read(key: _sessionKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> accessToken() async {
    return _storage.read(key: _sessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _storage.write(key: _sessionKey, value: persistSessionString);
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: _sessionKey);
  }
}
