import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/delivery_config.dart';
import '../../domain/models/invoice_config.dart';
import '../services/geocoding_service.dart';
import '../services/local_storage_service.dart';
import '../services/location_service.dart';

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService();
});

/// Servicio de captura GPS (geolocator) para el módulo de domicilios.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(dataSource: GeolocatorDataSource());
});

/// Zona de operacion del negocio (ciudad, departamento, pais).
/// Se usa como contexto al geocodificar direcciones de entrega.
/// Persistida localmente; editable desde Configuracion.
final geocodingContextProvider =
    StateNotifierProvider<GeocodingContextNotifier, String>((ref) {
  return GeocodingContextNotifier();
});

class GeocodingContextNotifier extends StateNotifier<String> {
  static const _prefsKey = 'geocoding_context';
  static const defaultContext = 'Cerrito, Valle del Cauca, Colombia';

  GeocodingContextNotifier() : super(defaultContext) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.trim().isNotEmpty) {
      state = saved;
    }
  }

  Future<void> setContext(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    state = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, trimmed);
  }

  Future<void> resetToDefault() => setContext(defaultContext);
}

/// Configuración de factura / datos del negocio para imprimir en recibos.
/// Persistida localmente en SharedPreferences.
final invoiceConfigProvider =
    StateNotifierProvider<InvoiceConfigNotifier, InvoiceConfig>((ref) {
  return InvoiceConfigNotifier();
});

class InvoiceConfigNotifier extends StateNotifier<InvoiceConfig> {
  static const _prefsKey = 'invoice_config';
  final LocalStorageService _storage;

  InvoiceConfigNotifier()
      : _storage = LocalStorageService(_prefsKey),
        super(const InvoiceConfig()) {
    _loadSync();
    _load();
  }

  InvoiceConfigNotifier.preloaded(super.state)
      : _storage = LocalStorageService(_prefsKey) {
    // Si se pre-cargó, no hace falta volver a leer; ya se leyó antes de runApp.
  }

  void _loadSync() {
    try {
      debugPrint('[InvoiceConfigNotifier] Cargando config síncrona...');
      final json = _storage.readSync();
      debugPrint('[InvoiceConfigNotifier] JSON síncrono: $json');
      if (json != null && json.isNotEmpty) {
        state = InvoiceConfig.fromJson(
          Map<String, dynamic>.from(jsonDecode(json)),
        );
        debugPrint('[InvoiceConfigNotifier] Config cargada síncronamente: $state');
      }
    } catch (e, stack) {
      debugPrint('[InvoiceConfigNotifier] Error carga síncrona: $e');
      debugPrint(stack.toString());
    }
  }

  Future<void> _load() async {
    try {
      debugPrint('[InvoiceConfigNotifier] Cargando config asíncrona...');
      final json = await _storage.read();
      debugPrint('[InvoiceConfigNotifier] JSON guardado: $json');
      if (json != null && json.isNotEmpty) {
        state = InvoiceConfig.fromJson(
          Map<String, dynamic>.from(jsonDecode(json)),
        );
        debugPrint('[InvoiceConfigNotifier] Config cargada: $state');
      } else {
        debugPrint('[InvoiceConfigNotifier] No hay config guardada');
      }
    } catch (e, stack) {
      debugPrint('[InvoiceConfigNotifier] Error cargando config: $e');
      debugPrint(stack.toString());
    }
  }

  Future<bool> save(InvoiceConfig config) async {
    state = config;
    try {
      debugPrint('[InvoiceConfigNotifier] Guardando config: $config');
      final json = jsonEncode(config.toJson());
      final ok = await _storage.write(json);
      debugPrint('[InvoiceConfigNotifier] Guardado exitoso=$ok');
      return ok;
    } catch (e, stack) {
      debugPrint('[InvoiceConfigNotifier] Error guardando config: $e');
      debugPrint(stack.toString());
      return false;
    }
  }

  Future<void> resetToDefault() async {
    await save(const InvoiceConfig());
  }
}

/// Configuración de domicilios: modo de asignación automática o manual.
/// Persistida localmente con respaldo en archivo.
final deliveryConfigProvider =
    StateNotifierProvider<DeliveryConfigNotifier, DeliveryConfig>((ref) {
  return DeliveryConfigNotifier();
});

class DeliveryConfigNotifier extends StateNotifier<DeliveryConfig> {
  static const _prefsKey = 'delivery_config';
  final LocalStorageService _storage;

  DeliveryConfigNotifier()
      : _storage = LocalStorageService(_prefsKey),
        super(const DeliveryConfig()) {
    _loadSync();
    _load();
  }

  DeliveryConfigNotifier.preloaded(super.state)
      : _storage = LocalStorageService(_prefsKey);

  void _loadSync() {
    try {
      debugPrint('[DeliveryConfigNotifier] Cargando config síncrona...');
      final json = _storage.readSync();
      debugPrint('[DeliveryConfigNotifier] JSON síncrono: $json');
      if (json != null && json.isNotEmpty) {
        state = DeliveryConfig.fromJson(
          Map<String, dynamic>.from(jsonDecode(json)),
        );
        debugPrint('[DeliveryConfigNotifier] Config cargada síncronamente: $state');
      }
    } catch (e, stack) {
      debugPrint('[DeliveryConfigNotifier] Error carga síncrona: $e');
      debugPrint(stack.toString());
    }
  }

  Future<void> _load() async {
    try {
      debugPrint('[DeliveryConfigNotifier] Cargando config asíncrona...');
      final json = await _storage.read();
      debugPrint('[DeliveryConfigNotifier] JSON guardado: $json');
      if (json != null && json.isNotEmpty) {
        state = DeliveryConfig.fromJson(
          Map<String, dynamic>.from(jsonDecode(json)),
        );
        debugPrint('[DeliveryConfigNotifier] Config cargada: $state');
      } else {
        debugPrint('[DeliveryConfigNotifier] No hay config guardada');
      }
    } catch (e, stack) {
      debugPrint('[DeliveryConfigNotifier] Error cargando config: $e');
      debugPrint(stack.toString());
    }
  }

  Future<bool> save(DeliveryConfig config) async {
    state = config;
    try {
      debugPrint('[DeliveryConfigNotifier] Guardando config: $config');
      final json = jsonEncode(config.toJson());
      final ok = await _storage.write(json);
      debugPrint('[DeliveryConfigNotifier] Guardado exitoso=$ok');
      return ok;
    } catch (e, stack) {
      debugPrint('[DeliveryConfigNotifier] Error guardando config: $e');
      debugPrint(stack.toString());
      return false;
    }
  }

  Future<void> resetToDefault() async {
    await save(const DeliveryConfig());
  }
}
