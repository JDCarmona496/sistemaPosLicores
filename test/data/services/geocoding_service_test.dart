import 'package:applicoresestacion/data/services/geocoding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

/// Tests del servicio de geocodificacion (Nominatim/OpenStreetMap).
///
/// Spec: convertir la direccion que da el cliente en coordenadas
/// para alimentar la agrupacion de pedidos por zona.
class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('parseNominatimResponse', () {
    test('extrae lat, lon y display_name del primer resultado', () {
      const body = '''
        [
          {
            "place_id": 12345,
            "lat": "3.5373",
            "lon": "-76.3036",
            "display_name": "Carrera 5, Cerrito, Valle del Cauca, Colombia"
          },
          {
            "place_id": 67890,
            "lat": "3.6",
            "lon": "-76.4",
            "display_name": "Otro lugar"
          }
        ]
      ''';

      final result = GeocodingService.parseNominatimResponse(body);

      expect(result, isNotNull);
      expect(result!.latitude, closeTo(3.5373, 0.0001));
      expect(result.longitude, closeTo(-76.3036, 0.0001));
      expect(result.displayName, contains('Cerrito'));
    });

    test('retorna null cuando no hay resultados', () {
      expect(GeocodingService.parseNominatimResponse('[]'), isNull);
    });

    test('retorna null con JSON invalido', () {
      expect(GeocodingService.parseNominatimResponse('no es json'), isNull);
    });

    test('retorna null cuando lat/lon no son parseables', () {
      const body = '[{"lat": "abc", "lon": null, "display_name": "X"}]';
      expect(GeocodingService.parseNominatimResponse(body), isNull);
    });
  });

  group('geocode', () {
    late MockHttpClient httpClient;
    late GeocodingService service;

    setUp(() {
      httpClient = MockHttpClient();
      service = GeocodingService(client: httpClient);
    });

    test('construye la URL con direccion + contexto de zona y Colombia', () async {
      Uri? captured;
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((invocation) async {
        captured = invocation.positionalArguments.first as Uri;
        return http.Response('[]', 200);
      });

      await service.geocode(
        'Carrera 5 #12-30',
        locationContext: 'Cerrito, Valle del Cauca, Colombia',
      );

      expect(captured, isNotNull);
      expect(captured!.host, 'nominatim.openstreetmap.org');
      expect(captured!.queryParameters['q'], contains('Carrera 5 #12-30'));
      expect(captured!.queryParameters['q'], contains('Cerrito'));
      expect(captured!.queryParameters['countrycodes'], 'co');
      expect(captured!.queryParameters['limit'], '1');
    });

    test('envia User-Agent (requerido por la politica de Nominatim)', () async {
      Map<String, String>? capturedHeaders;
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((invocation) async {
        capturedHeaders =
            invocation.namedArguments[#headers] as Map<String, String>;
        return http.Response('[]', 200);
      });

      await service.geocode('Calle 1', locationContext: 'Cerrito');

      expect(capturedHeaders, isNotNull);
      expect(capturedHeaders!['User-Agent'], isNotEmpty);
    });

    test('retorna coordenadas con respuesta 200 valida', () async {
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
              '[{"lat": "3.5373", "lon": "-76.3036", "display_name": "Cerrito"}]',
              200));

      final result = await service.geocode(
        'Carrera 5',
        locationContext: 'Cerrito, Valle del Cauca',
      );

      expect(result, isNotNull);
      expect(result!.latitude, closeTo(3.5373, 0.0001));
    });

    test('retorna null cuando la respuesta no es 200', () async {
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('error', 500));

      final result = await service.geocode('X', locationContext: 'Cerrito');

      expect(result, isNull);
    });

    test('retorna null cuando la red falla (sin conexion)', () async {
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(Exception('SocketException'));

      final result = await service.geocode('X', locationContext: 'Cerrito');

      expect(result, isNull);
    });
  });
}
