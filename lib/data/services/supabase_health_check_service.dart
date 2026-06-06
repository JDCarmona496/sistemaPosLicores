import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';

class SupabaseHealthCheckResult {
  final String testName;
  final bool success;
  final String message;
  final Duration duration;

  SupabaseHealthCheckResult({
    required this.testName,
    required this.success,
    required this.message,
    required this.duration,
  });
}

class SupabaseHealthCheckService {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<SupabaseHealthCheckResult>> runAllChecks() async {
    final results = <SupabaseHealthCheckResult>[];

    results.add(await _checkConnection());
    results.add(await _checkTableAccess('categories'));
    results.add(await _checkTableAccess('brands'));
    results.add(await _checkTableAccess('cash_registers'));
    results.add(await _checkTableAccess('products'));
    results.add(await _checkTableAccess('orders'));
    results.add(await _checkTableAccess('customers'));
    results.add(await _checkInitialData());
    results.add(await _checkAuthStatus());

    return results;
  }

  Future<SupabaseHealthCheckResult> _checkConnection() async {
    final stopwatch = Stopwatch()..start();
    try {
      await _client.from('categories').select('id').limit(1);
      stopwatch.stop();
      return SupabaseHealthCheckResult(
        testName: 'Conexión a Supabase',
        success: true,
        message: 'Conexión exitosa',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return SupabaseHealthCheckResult(
        testName: 'Conexión a Supabase',
        success: false,
        message: 'Error: ${e.toString()}',
        duration: stopwatch.elapsed,
      );
    }
  }

  Future<SupabaseHealthCheckResult> _checkTableAccess(String table) async {
    final stopwatch = Stopwatch()..start();
    try {
      await _client.from(table).select('id').limit(1);
      stopwatch.stop();
      return SupabaseHealthCheckResult(
        testName: 'Acceso a tabla: $table',
        success: true,
        message: 'Tabla accesible',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return SupabaseHealthCheckResult(
        testName: 'Acceso a tabla: $table',
        success: false,
        message: 'Error: ${e.toString()}',
        duration: stopwatch.elapsed,
      );
    }
  }

  Future<SupabaseHealthCheckResult> _checkInitialData() async {
    final stopwatch = Stopwatch()..start();
    try {
      final categories = await _client.from('categories').select('id');
      final cashRegisters = await _client.from('cash_registers').select('id');
      stopwatch.stop();

      final hasCategories = categories.isNotEmpty;
      final hasCashRegisters = cashRegisters.isNotEmpty;

      if (hasCategories && hasCashRegisters) {
        return SupabaseHealthCheckResult(
          testName: 'Datos iniciales',
          success: true,
          message: '${categories.length} categorías, ${cashRegisters.length} cajas registradas',
          duration: stopwatch.elapsed,
        );
      } else {
        return SupabaseHealthCheckResult(
          testName: 'Datos iniciales',
          success: false,
          message: 'Faltan datos iniciales (categorías o cajas)',
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return SupabaseHealthCheckResult(
        testName: 'Datos iniciales',
        success: false,
        message: 'Error: ${e.toString()}',
        duration: stopwatch.elapsed,
      );
    }
  }

  Future<SupabaseHealthCheckResult> _checkAuthStatus() async {
    final stopwatch = Stopwatch()..start();
    try {
      final session = _client.auth.currentSession;
      stopwatch.stop();

      if (session != null) {
        return SupabaseHealthCheckResult(
          testName: 'Estado de autenticación',
          success: true,
          message: 'Usuario autenticado: ${session.user.email}',
          duration: stopwatch.elapsed,
        );
      } else {
        return SupabaseHealthCheckResult(
          testName: 'Estado de autenticación',
          success: true,
          message: 'No hay sesión activa (normal si no has iniciado sesión)',
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return SupabaseHealthCheckResult(
        testName: 'Estado de autenticación',
        success: false,
        message: 'Error: ${e.toString()}',
        duration: stopwatch.elapsed,
      );
    }
  }
}
