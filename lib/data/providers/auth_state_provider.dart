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

  /// Limpia cualquier sesión persistida localmente y fuerza el estado inicial
  /// a "no autenticado". Esto garantiza que la app siempre pida login al
  /// abrirse, sin depender de la sesión anterior.
  Future<void> initialize() async {
    try {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
    } catch (e) {
      debugPrint('[AuthStateNotifier] Error limpiando sesión inicial: $e');
    }

    _isAuthenticated = false;
    _user = null;
    _isLoading = false;
    notifyListeners();
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
