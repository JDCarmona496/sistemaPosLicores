import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/invoice_config.dart';
import '../services/geocoding_service.dart';
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

  InvoiceConfigNotifier() : super(const InvoiceConfig()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_prefsKey);
      if (json != null && json.isNotEmpty) {
        state = InvoiceConfig.fromJson(
          Map<String, dynamic>.from(jsonDecode(json)),
        );
      }
    } catch (e) {
      debugPrint('[InvoiceConfigNotifier] Error cargando config: $e');
    }
  }

  Future<void> save(InvoiceConfig config) async {
    state = config;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(config.toJson()));
    } catch (e) {
      debugPrint('[InvoiceConfigNotifier] Error guardando config: $e');
    }
  }

  Future<void> resetToDefault() async {
    await save(const InvoiceConfig());
  }
}
