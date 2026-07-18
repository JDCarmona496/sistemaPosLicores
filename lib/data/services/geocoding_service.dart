import 'dart:convert';

import 'package:http/http.dart' as http;

/// Resultado de geocodificar una direccion.
class GeocodingResult {
  final double latitude;
  final double longitude;
  final String displayName;

  const GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });
}

/// Geocodificacion direccion -> coordenadas con Nominatim (OpenStreetMap).
///
/// Gratis y sin API key. Politica de uso: max 1 req/seg y User-Agent
/// identificable obligatorio (https://operations.osmfoundation.org/policies/nominatim/).
/// Suficiente para el volumen de pedidos de la licoreria.
class GeocodingService {
  final http.Client _client;

  static const _endpoint = 'https://nominatim.openstreetmap.org/search';
  static const _userAgent = 'LicoreriaPOS/0.1.0 (applicoresestacion)';
  static const _timeout = Duration(seconds: 10);

  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  /// Geocodifica [address] agregando [locationContext] (ciudad, depto, pais)
  /// para mejorar la precision. Retorna null si no hay resultados o falla.
  Future<GeocodingResult?> geocode(
    String address, {
    required String locationContext,
  }) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'q': '$trimmed, $locationContext',
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'co',
    });

    try {
      final response = await _client.get(uri, headers: {
        'User-Agent': _userAgent,
        'Accept-Language': 'es',
      }).timeout(_timeout);

      if (response.statusCode != 200) return null;
      return parseNominatimResponse(response.body);
    } catch (_) {
      // Sin conexion, timeout o respuesta malformada: se reporta como null
      // y la UI decide como informarlo al usuario.
      return null;
    }
  }

  /// Parsea el cuerpo JSON de Nominatim. Expuesta para tests.
  static GeocodingResult? parseNominatimResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! List || decoded.isEmpty) return null;

      final first = decoded.first;
      if (first is! Map) return null;

      final lat = double.tryParse('${first['lat']}');
      final lon = double.tryParse('${first['lon']}');
      if (lat == null || lon == null) return null;

      return GeocodingResult(
        latitude: lat,
        longitude: lon,
        displayName: '${first['display_name'] ?? ''}',
      );
    } catch (_) {
      return null;
    }
  }
}
