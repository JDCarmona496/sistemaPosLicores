import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../domain/models/user.dart';
import '../services/auth_service.dart';

/// Notifier que expone el estado de autenticación actual y notifica al router
/// cuando cambia.
///
/// Se usa como `refreshListenable` de GoRouter para redirigir a login o
/// dashboard según haya sesión activa.
class AuthStateNotifier extends ChangeNotifier {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  User? _user;
  StreamSubscription<AuthState>? _subscription;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  User? get user => _user;

  AuthStateNotifier() {
    _subscription =
        Supabase.instance.client.auth.onAuthStateChange.listen(_onAuthStateChange);
  }

  /// Inicializa el notifier escuchando los cambios de estado de autenticación.
  ///
  /// Supabase se encarga de restaurar la sesión persistida de forma segura
  /// y emitir el evento correspondiente (signedIn o signedOut).
  Future<void> initialize() async {
    // _isLoading permanece true hasta que llegue el primer evento de
    // onAuthStateChange y _onAuthStateChange actualice el estado.
  }

  Future<void> _onAuthStateChange(AuthState state) async {
    final session = state.session;

    if (session != null) {
      try {
        _user = await AuthService().getCurrentUser();
        _isAuthenticated = true;
      } catch (e) {
        debugPrint('[AuthStateNotifier] Error cargando usuario: $e');
        _user = null;
        _isAuthenticated = false;
      }
    } else {
      _user = null;
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await AuthService().signOut();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
