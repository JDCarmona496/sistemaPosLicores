import 'package:flutter/foundation.dart';

import '../../config/supabase_config.dart';

/// Servicio que expone la hora actual del servidor de Supabase.
///
/// La primera llamada consulta la función RPC `get_server_time()` y guarda el
/// desfase respecto al reloj del dispositivo. Llamadas posteriores usan ese
/// desfase para evitar nuevas peticiones de red.
///
/// Esto permite que facturas, entregas y cancelaciones usen la hora del
/// servidor como fuente de verdad, sin depender de que el reloj del
/// dispositivo esté correcto.
class ServerTimeService {
  static final ServerTimeService _instance = ServerTimeService._internal();
  factory ServerTimeService() => _instance;
  ServerTimeService._internal();

  Duration? _offset;
  DateTime? _lastSync;

  bool get isSynced => _offset != null;

  /// Sincroniza el reloj local contra el servidor de Supabase.
  /// Devuelve la hora del servidor.
  Future<DateTime> sync() async {
    try {
      final localBefore = DateTime.now();
      final result = await SupabaseConfig.client.rpc('get_server_time');
      final localAfter = DateTime.now();
      final serverTime = DateTime.parse(result as String);
      final localAverage = localBefore.add(localAfter.difference(localBefore) ~/ 2);
      _offset = serverTime.difference(localAverage);
      _lastSync = DateTime.now();
      return serverTime;
    } catch (e) {
      debugPrint('[ServerTimeService] Error al sincronizar: $e');
      // Si falla, usar hora local y dejar el offset en cero.
      _offset ??= Duration.zero;
      return DateTime.now();
    }
  }

  /// Devuelve la mejor estimación de la hora actual del servidor.
  /// Si aún no se ha sincronizado, lo hace automáticamente.
  Future<DateTime> now() async {
    if (_offset == null || _lastSync == null) {
      await sync();
    }
    return DateTime.now().add(_offset ?? Duration.zero);
  }

  /// Fuerza una re-sincronización con el servidor.
  Future<DateTime> refresh() async {
    _offset = null;
    return sync();
  }
}
