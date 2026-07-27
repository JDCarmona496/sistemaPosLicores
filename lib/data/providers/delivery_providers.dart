import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/models/delivery_config.dart';
import '../../domain/models/order.dart';
import '../../domain/models/user.dart';
import '../../domain/services/order_zone_grouper.dart';
import '../repositories/order_repository.dart';
import '../services/location_service.dart';
import 'order_providers.dart';
import 'settings_providers.dart';
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

enum DeliveryViewMode { list, zones }

class DeliveryOrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;
  final DeliveryFilter filter;
  final DeliveryViewMode viewMode;
  final Position? currentPosition;
  final bool locationPermissionDenied;

  const DeliveryOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.filter = DeliveryFilter.active,
    this.viewMode = DeliveryViewMode.zones,
    this.currentPosition,
    this.locationPermissionDenied = false,
  });

  DeliveryOrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
    DeliveryFilter? filter,
    DeliveryViewMode? viewMode,
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
      viewMode: viewMode ?? this.viewMode,
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
    required this._ref,
    required this._repository,
  }) : super(const DeliveryOrdersState()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    debugPrint('[DeliveryOrdersNotifier] loadOrders iniciado');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final currentUserAsync = _ref.read(currentUserProvider);
      final currentUser = currentUserAsync.valueOrNull ??
          await _ref.read(currentUserProvider.future);

      if (currentUser == null) {
        throw Exception('No se pudo obtener el usuario actual');
      }

      debugPrint(
          '[DeliveryOrdersNotifier] Usuario actual: ${currentUser.id} (${currentUser.fullName})');

      final orders = await _repository.getAssignedOrders(
        deliveryPersonId: currentUser.id,
        statuses: null,
      );

      debugPrint(
          '[DeliveryOrdersNotifier] Pedidos asignados encontrados: ${orders.length}');
      for (final order in orders) {
        debugPrint(
            '[DeliveryOrdersNotifier]   - #${order.orderNumber} status=${order.status.label} deliveryType=${order.deliveryType.label}');
      }

      // Orden de llegada: primero los pedidos más antiguos (FIFO).
      orders.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.now();
        final dateB = b.createdAt ?? DateTime.now();
        return dateA.compareTo(dateB);
      });

      state = state.copyWith(
        orders: orders,
        isLoading: false,
      );
      debugPrint('[DeliveryOrdersNotifier] loadOrders completado');
    } catch (e, st) {
      debugPrint('[DeliveryOrdersNotifier] Error cargando domicilios: $e');
      debugPrint(st.toString());
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

  void setViewMode(DeliveryViewMode viewMode) {
    state = state.copyWith(viewMode: viewMode);
  }

  Future<void> updateOrderInPlace(Order order) async {
    final updatedList = state.orders.map((o) => o.id == order.id ? order : o).toList();
    state = state.copyWith(orders: updatedList);
  }

  User? get currentUser => _ref.read(currentUserProvider).valueOrNull;
}

/// Estados que indican que un domiciliario está ocupado con un pedido.
const _busyStatuses = {
  OrderStatus.ready,
  OrderStatus.inTransit,
  OrderStatus.partiallyDelivered,
};

/// Retorna el domiciliario con menos pedidos activos.
/// Si no hay domiciliarios, retorna null.
final leastBusyDeliveryUserProvider = FutureProvider<User?>((ref) async {
  final users = await ref.watch(deliveryUsersProvider.future);
  final orders = ref.watch(ordersProvider).orders;

  if (users.isEmpty) return null;

  int activeCount(User user) => orders
      .where((o) =>
          o.deliveryPersonId == user.id && _busyStatuses.contains(o.status))
      .length;

  final sorted = List<User>.from(users)
    ..sort((a, b) => activeCount(a).compareTo(activeCount(b)));

  return sorted.first;
});

/// Indica si la asignación automática de domiciliarios está activa.
final isAutoDeliveryAssignmentProvider = Provider<bool>((ref) {
  final config = ref.watch(deliveryConfigProvider);
  return config.assignmentMode == DeliveryAssignmentMode.automatic;
});
