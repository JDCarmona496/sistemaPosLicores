import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../models/order.dart';

/// Ordena pedidos de domicilio por distancia desde una posición de referencia
/// (normalmente la ubicación actual del domiciliario). Los que no tienen
/// coordenadas quedan al final, ordenados por fecha de creación.
class RouteOptimizer {
  static List<Order> sortByDistance(
    List<Order> orders,
    Position reference,
  ) {
    final withLocation = <Order>[];
    final withoutLocation = <Order>[];

    for (final order in orders) {
      if (order.deliveryLatitude != null && order.deliveryLongitude != null) {
        withLocation.add(order);
      } else {
        withoutLocation.add(order);
      }
    }

    withLocation.sort((a, b) {
      final distA = _distanceMeters(
        reference.latitude,
        reference.longitude,
        a.deliveryLatitude!,
        a.deliveryLongitude!,
      );
      final distB = _distanceMeters(
        reference.latitude,
        reference.longitude,
        b.deliveryLatitude!,
        b.deliveryLongitude!,
      );
      return distA.compareTo(distB);
    });

    withoutLocation.sort((a, b) {
      final dateA = a.createdAt ?? DateTime(1970);
      final dateB = b.createdAt ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    return [...withLocation, ...withoutLocation];
  }

  static double distanceToOrder(Position reference, Order order) {
    if (order.deliveryLatitude == null || order.deliveryLongitude == null) {
      return double.infinity;
    }
    return _distanceMeters(
      reference.latitude,
      reference.longitude,
      order.deliveryLatitude!,
      order.deliveryLongitude!,
    );
  }

  static double _distanceMeters(
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
