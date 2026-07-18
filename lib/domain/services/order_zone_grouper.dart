import 'dart:math' as math;

import '../models/order.dart';

/// Una zona de entrega: pedidos de domicilio cercanos entre si que
/// pueden compartir un mismo viaje para economizar combustible.
class OrderZone {
  final int zoneNumber;
  final List<Order> orders;

  const OrderZone({required this.zoneNumber, required this.orders});

  int get orderCount => orders.length;

  double get totalAmount => orders.fold(0, (sum, o) => sum + o.total);

  String get referenceAddress =>
      orders.first.deliveryAddress ?? 'Sin dirección';
}

/// Resultado del agrupamiento: zonas con coordenadas y, aparte,
/// los pedidos sin ubicacion (sin GPS o en tienda).
class OrderZoneResult {
  final List<OrderZone> zones;
  final List<Order> withoutLocation;

  const OrderZoneResult({
    required this.zones,
    required this.withoutLocation,
  });
}

/// Agrupa pedidos por proximidad geografica con clustering greedy
/// single-linkage: un pedido se une a la primera zona que tenga
/// algun miembro dentro del radio; si no, crea una zona nueva.
///
/// Single-link permite cadenas: si A-B estan cerca y B-C estan cerca,
/// los tres comparten zona aunque A-C supere el radio (es el mismo
/// recorrido de todas formas).
class OrderZoneGrouper {
  /// Radio maximo en metros para considerar dos pedidos en la misma zona.
  final double radiusMeters;

  const OrderZoneGrouper({this.radiusMeters = 500});

  OrderZoneResult group(List<Order> orders) {
    final zones = <List<Order>>[];
    final withoutLocation = <Order>[];

    for (final order in orders) {
      final lat = order.deliveryLatitude;
      final lng = order.deliveryLongitude;

      if (lat == null || lng == null) {
        withoutLocation.add(order);
        continue;
      }

      var assigned = false;
      for (final zone in zones) {
        final near = zone.any((member) {
          return distanceMeters(
                lat,
                lng,
                member.deliveryLatitude!,
                member.deliveryLongitude!,
              ) <=
              radiusMeters;
        });
        if (near) {
          zone.add(order);
          assigned = true;
          break;
        }
      }

      if (!assigned) {
        zones.add([order]);
      }
    }

    // Mayor ahorro primero: zonas con mas pedidos arriba.
    zones.sort((a, b) => b.length.compareTo(a.length));

    return OrderZoneResult(
      zones: [
        for (var i = 0; i < zones.length; i++)
          OrderZone(zoneNumber: i + 1, orders: zones[i]),
      ],
      withoutLocation: withoutLocation,
    );
  }

  /// Distancia Haversine en metros entre dos coordenadas.
  static double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
