import 'package:applicoresestacion/domain/models/order.dart';
import 'package:applicoresestacion/domain/services/order_zone_grouper.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests del agrupador de pedidos por zona geografica.
///
/// Spec: agrupar pedidos de domicilio por proximidad de coordenadas
/// para combinar viajes y economizar combustible (criterios AC-1..AC-10).
void main() {
  Order orderAt({
    required String id,
    required int number,
    double? lat,
    double? lng,
    String? address,
    double total = 0,
    DeliveryType deliveryType = DeliveryType.delivery,
  }) {
    return Order(
      id: id,
      orderNumber: number,
      sellerId: 's1',
      deliveryType: deliveryType,
      deliveryLatitude: lat,
      deliveryLongitude: lng,
      deliveryAddress: address,
      total: total,
    );
  }

  group('AC-1: lista vacia', () {
    test('no produce zonas ni pedidos sin ubicacion', () {
      final result = const OrderZoneGrouper().group(const []);

      expect(result.zones, isEmpty);
      expect(result.withoutLocation, isEmpty);
    });
  });

  group('AC-2: pedidos sin coordenadas', () {
    test('van al grupo sin ubicacion', () {
      final result = const OrderZoneGrouper().group([
        orderAt(id: 'a', number: 1, address: 'Calle 1'),
      ]);

      expect(result.zones, isEmpty);
      expect(result.withoutLocation, hasLength(1));
    });

    test('coordenadas parciales (solo latitud) cuentan como sin ubicacion', () {
      final result = const OrderZoneGrouper().group([
        orderAt(id: 'a', number: 1, lat: 4.0),
      ]);

      expect(result.withoutLocation, hasLength(1));
    });
  });

  group('AC-3: pedidos cercanos (<= radio)', () {
    test('dos pedidos a ~110m comparten zona', () {
      final result = const OrderZoneGrouper(radiusMeters: 500).group([
        orderAt(id: 'a', number: 1, lat: 4.000, lng: -74.000),
        orderAt(id: 'b', number: 2, lat: 4.001, lng: -74.000), // ~111m
      ]);

      expect(result.zones, hasLength(1));
      expect(result.zones.first.orders, hasLength(2));
      expect(result.withoutLocation, isEmpty);
    });
  });

  group('AC-4: pedidos lejanos (> radio)', () {
    test('dos pedidos a ~2.2km quedan en zonas separadas', () {
      final result = const OrderZoneGrouper(radiusMeters: 500).group([
        orderAt(id: 'a', number: 1, lat: 4.000, lng: -74.000),
        orderAt(id: 'b', number: 2, lat: 4.020, lng: -74.000), // ~2.2km
      ]);

      expect(result.zones, hasLength(2));
      expect(result.zones.every((z) => z.orders.length == 1), isTrue);
    });
  });

  group('AC-5: encadenamiento single-link', () {
    test('A-B cercanos y B-C cercanos unen A, B y C aunque A-C supere el radio',
        () {
      final result = const OrderZoneGrouper(radiusMeters: 500).group([
        orderAt(id: 'a', number: 1, lat: 4.000, lng: -74.000),
        orderAt(id: 'b', number: 2, lat: 4.003, lng: -74.000), // ~334m de A
        orderAt(id: 'c', number: 3, lat: 4.006, lng: -74.000), // ~668m de A, ~334m de B
      ]);

      expect(result.zones, hasLength(1));
      expect(result.zones.first.orders, hasLength(3));
    });
  });

  group('AC-6: radio configurable', () {
    test('con radio de 100m dos pedidos a ~334m quedan separados', () {
      final result = const OrderZoneGrouper(radiusMeters: 100).group([
        orderAt(id: 'a', number: 1, lat: 4.000, lng: -74.000),
        orderAt(id: 'b', number: 2, lat: 4.003, lng: -74.000),
      ]);

      expect(result.zones, hasLength(2));
    });
  });

  group('AC-7: orden de zonas', () {
    test('las zonas se ordenan por cantidad de pedidos descendente', () {
      final result = const OrderZoneGrouper(radiusMeters: 500).group([
        orderAt(id: 'a', number: 1, lat: 4.000, lng: -74.000),
        orderAt(id: 'b', number: 2, lat: 4.050, lng: -74.000), // zona lejana 1
        orderAt(id: 'c', number: 3, lat: 4.001, lng: -74.000), // se une a 'a'
        orderAt(id: 'd', number: 4, lat: 4.051, lng: -74.000), // se une a 'b'
        orderAt(id: 'e', number: 5, lat: 4.002, lng: -74.000), // se une a 'a'
      ]);

      expect(result.zones, hasLength(2));
      expect(result.zones.first.orders, hasLength(3));
      expect(result.zones.last.orders, hasLength(2));
    });

    test('las zonas se numeran desde 1 en orden', () {
      final result = const OrderZoneGrouper(radiusMeters: 500).group([
        orderAt(id: 'a', number: 1, lat: 4.000, lng: -74.000),
        orderAt(id: 'b', number: 2, lat: 4.050, lng: -74.000),
      ]);

      expect(result.zones.map((z) => z.zoneNumber), [1, 2]);
    });
  });

  group('AC-8: distanceMeters (Haversine)', () {
    test('el mismo punto dista 0', () {
      expect(
        OrderZoneGrouper.distanceMeters(4.0, -74.0, 4.0, -74.0),
        0,
      );
    });

    test('un grado de latitud son ~111km', () {
      final d = OrderZoneGrouper.distanceMeters(4.0, -74.0, 5.0, -74.0);
      expect(d, greaterThan(110000));
      expect(d, lessThan(112500));
    });
  });

  group('AC-9: datos derivados de la zona', () {
    test('totalAmount suma los totales de los pedidos de la zona', () {
      final result = const OrderZoneGrouper().group([
        orderAt(id: 'a', number: 1, lat: 4.0, lng: -74.0, total: 30000),
        orderAt(id: 'b', number: 2, lat: 4.001, lng: -74.0, total: 20000),
      ]);

      expect(result.zones.first.totalAmount, 50000);
    });

    test('referenceAddress usa la direccion del primer pedido', () {
      final result = const OrderZoneGrouper().group([
        orderAt(
            id: 'a', number: 1, lat: 4.0, lng: -74.0, address: 'Barrio San Rafael'),
        orderAt(id: 'b', number: 2, lat: 4.001, lng: -74.0),
      ]);

      expect(result.zones.first.referenceAddress, 'Barrio San Rafael');
    });
  });

  group('AC-10: mezcla de pedidos con y sin ubicacion', () {
    test('los sin ubicacion conservan su orden y van aparte', () {
      final result = const OrderZoneGrouper().group([
        orderAt(id: 'a', number: 1, lat: 4.0, lng: -74.0),
        orderAt(id: 'b', number: 2, address: 'Sin GPS 1'),
        orderAt(id: 'c', number: 3, lat: 4.001, lng: -74.0),
        orderAt(id: 'd', number: 4, address: 'Sin GPS 2'),
      ]);

      expect(result.zones, hasLength(1));
      expect(result.zones.first.orders, hasLength(2));
      expect(result.withoutLocation.map((o) => o.id), ['b', 'd']);
    });
  });
}
