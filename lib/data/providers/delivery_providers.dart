import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/models/order.dart';
import '../../domain/models/user.dart';
import '../../domain/services/order_zone_grouper.dart';
import '../repositories/order_repository.dart';
import '../services/location_service.dart';
import 'order_providers.dart';
import 'user_providers.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(dataSource: GeolocatorDataSource());
});

final orderZoneGrouperProvider = Provider<OrderZoneGrouper>((ref) {
  return const OrderZoneGrouper(radiusMeters: 500);
});

final deliveryOrdersProvider =
    StateNotifierProvider<DeliveryOrdersNotifier, DeliveryOrdersState>((ref) {
  return DeliveryOrdersNotifier(
    ref: ref,
    repository: ref.watch(orderRepositoryProvider),
  );
});

enum DeliveryFilter {
  all,
  active,
  delivered,
}

extension DeliveryFilterX on DeliveryFilter {
  String get label {
    switch (this) {
      case DeliveryFilter.all:
        return 'Todos';
      case DeliveryFilter.active:
        return 'Por entregar';
      case DeliveryFilter.delivered:
        return 'Entregados';
    }
  }

  List<OrderStatus>? get statuses {
    switch (this) {
      case DeliveryFilter.all:
        return null;
      case DeliveryFilter.active:
        return [
          OrderStatus.ready,
          OrderStatus.inTransit,
          OrderStatus.partiallyDelivered,
        ];
      case DeliveryFilter.delivered:
        return [OrderStatus.delivered];
    }
  }

  bool matches(OrderStatus status) {
    switch (this) {
      case DeliveryFilter.all:
        return true;
      case DeliveryFilter.active:
        return status == OrderStatus.ready ||
            status == OrderStatus.inTransit ||
            status == OrderStatus.partiallyDelivered;
      case DeliveryFilter.delivered:
        return status == OrderStatus.delivered;
    }
  }
}

class DeliveryOrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;
  final DeliveryFilter filter;
  final Position? currentPosition;
  final bool locationPermissionDenied;

  const DeliveryOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.filter = DeliveryFilter.active,
    this.currentPosition,
    this.locationPermissionDenied = false,
  });

  DeliveryOrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
    DeliveryFilter? filter,
    Position? currentPosition,
    bool? locationPermissionDenied,
    bool clearPosition = false,
    bool clearError = false,
  }) {
    return DeliveryOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filter: filter ?? this.filter,
      currentPosition: clearPosition ? null : (currentPosition ?? this.currentPosition),
      locationPermissionDenied:
          locationPermissionDenied ?? this.locationPermissionDenied,
    );
  }

  List<Order> get filteredOrders =>
      orders.where((o) => filter.matches(o.status)).toList();

  List<Order> get activeOrders =>
      orders.where((o) => DeliveryFilter.active.matches(o.status)).toList();

  List<Order> get deliveredOrders =>
      orders.where((o) => DeliveryFilter.delivered.matches(o.status)).toList();
}

class DeliveryOrdersNotifier extends StateNotifier<DeliveryOrdersState> {
  final Ref _ref;
  final OrderRepository _repository;

  DeliveryOrdersNotifier({
    required Ref ref,
    required OrderRepository repository,
  })  : _ref = ref,
        _repository = repository,
        super(const DeliveryOrdersState()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final currentUser = await _ref.read(currentUserProvider.future);
      final orders = await _repository.getAssignedOrders(
        deliveryPersonId: currentUser.id,
        statuses: null,
      );

      state = state.copyWith(
        orders: orders,
        isLoading: false,
      );

      // La ubicación se intenta en paralelo, no bloquea la carga.
      _captureCurrentPosition();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar domicilios: ${e.toString()}',
      );
    }
  }

  Future<void> refresh() => loadOrders();

  void setFilter(DeliveryFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<void> _captureCurrentPosition() async {
    final locationService = _ref.read(locationServiceProvider);
    try {
      final position = await locationService.captureCurrentPosition();
      if (mounted) {
        state = state.copyWith(
          currentPosition: position,
          locationPermissionDenied: false,
        );
      }
    } on LocationServiceException catch (e) {
      if (mounted) {
        state = state.copyWith(
          locationPermissionDenied:
              e.code == LocationServiceErrorCode.permissionDenied ||
              e.code == LocationServiceErrorCode.permissionDeniedForever,
        );
      }
    } catch (_) {
      // Silencioso: la ruta funciona sin GPS.
    }
  }

  Future<void> updateOrderInPlace(Order order) async {
    final updatedList = state.orders.map((o) => o.id == order.id ? order : o).toList();
    state = state.copyWith(orders: updatedList);
  }

  User? get currentUser => _ref.read(currentUserProvider).valueOrNull;
}
