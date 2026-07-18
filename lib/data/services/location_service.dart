import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Excepciones controladas del servicio de ubicación.
enum LocationServiceErrorCode {
  locationDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationServiceException implements Exception {
  final LocationServiceErrorCode code;
  final String message;

  const LocationServiceException(this.code, this.message);

  @override
  String toString() => 'LocationServiceException($code): $message';
}

/// Abstracción sobre la fuente de ubicación (facilita tests y swaps).
abstract class LocationDataSource {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position> getCurrentPosition({LocationAccuracy? desiredAccuracy});
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

/// Implementación real con geolocator.
class GeolocatorDataSource implements LocationDataSource {
  @override
  Future<bool> isLocationServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() => Geolocator.requestPermission();

  @override
  Future<Position> getCurrentPosition({LocationAccuracy? desiredAccuracy}) {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: desiredAccuracy ?? LocationAccuracy.high,
    );
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}

/// Servicio de ubicación pensado para el flujo de domicilios.
///
/// Encapsula el manejo de permisos, GPS apagado, timeout y errores,
/// devolviendo excepciones de dominio en lugar de exponer geolocator.
class LocationService {
  final LocationDataSource _dataSource;

  const LocationService({required LocationDataSource dataSource})
      : _dataSource = dataSource;

  /// Captura la posición actual del dispositivo.
  ///
  /// Lanza [LocationServiceException] con códigos específicos para que la UI
  /// pueda guiar al domiciliario (activar GPS, dar permiso, etc.).
  Future<Position> captureCurrentPosition({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final serviceEnabled = await _dataSource.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException(
        LocationServiceErrorCode.locationDisabled,
        'El servicio de ubicación está apagado. Actívalo para capturar la coordenada.',
      );
    }

    var permission = await _dataSource.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _dataSource.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        LocationServiceErrorCode.permissionDenied,
        'Permiso de ubicación denegado. Se necesita para capturar la coordenada.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        LocationServiceErrorCode.permissionDeniedForever,
        'Permiso de ubicación bloqueado permanentemente. Ábrelo en configuración.',
      );
    }

    try {
      return await _dataSource
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
          .timeout(
            timeout,
            onTimeout: () => throw const LocationServiceException(
              LocationServiceErrorCode.timeout,
              'No se pudo obtener la ubicación a tiempo. Intenta de nuevo.',
            ),
          );
    } on LocationServiceException {
      rethrow;
    } on TimeoutException {
      throw const LocationServiceException(
        LocationServiceErrorCode.timeout,
        'No se pudo obtener la ubicación a tiempo. Intenta de nuevo.',
      );
    } catch (e) {
      throw LocationServiceException(
        LocationServiceErrorCode.unknown,
        'Error al capturar ubicación: $e',
      );
    }
  }
}
