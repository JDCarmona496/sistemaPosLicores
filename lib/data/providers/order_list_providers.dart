import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/order.dart';
import '../../domain/models/order_item.dart';
import '../repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return OrdersNotifier(repository);
});

class OrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final OrderStatus? selectedStatus;
  final SaleType? selectedSaleType;
  final DeliveryType? selectedDeliveryType;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.selectedStatus,
    this.selectedSaleType,
    this.selectedDeliveryType,
  });

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
    String? searchQuery,
    OrderStatus? selectedStatus,
    SaleType? selectedSaleType,
    DeliveryType? selectedDeliveryType,
    bool clearSearch = false,
    bool clearStatus = false,
    bool clearSaleType = false,
    bool clearDeliveryType = false,
    bool clearError = false,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      selectedSaleType:
          clearSaleType ? null : (selectedSaleType ?? this.selectedSaleType),
      selectedDeliveryType: clearDeliveryType
          ? null
          : (selectedDeliveryType ?? this.selectedDeliveryType),
    );
  }
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrderRepository _repository;

  OrdersNotifier(this._repository) : super(const OrdersState()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final orders = await _repository.getAll(
        search: state.searchQuery,
        status: state.selectedStatus,
        saleType: state.selectedSaleType,
        deliveryType: state.selectedDeliveryType,
      );

      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar pedidos: ${e.toString()}',
      );
    }
  }

  void setSearch(String? query) {
    state = state.copyWith(
      searchQuery: query,
      clearSearch: query == null || query.isEmpty,
    );
    loadOrders();
  }

  void setStatus(OrderStatus? status) {
    state = state.copyWith(
      selectedStatus: status,
      clearStatus: status == null,
    );
    loadOrders();
  }

  void setSaleType(SaleType? saleType) {
    state = state.copyWith(
      selectedSaleType: saleType,
      clearSaleType: saleType == null,
    );
    loadOrders();
  }

  void setDeliveryType(DeliveryType? deliveryType) {
    state = state.copyWith(
      selectedDeliveryType: deliveryType,
      clearDeliveryType: deliveryType == null,
    );
    loadOrders();
  }

  void clearFilters() {
    state = state.copyWith(
      clearSearch: true,
      clearStatus: true,
      clearSaleType: true,
      clearDeliveryType: true,
    );
    loadOrders();
  }

  Future<Order> createOrder({
    required String sellerId,
    String? customerId,
    required SaleType saleType,
    required DeliveryType deliveryType,
    required List<OrderItem> items,
    String? notes,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    double deliveryFee = 0,
    String? deliveryPersonId,
  }) async {
    try {
      final created = await _repository.create(
        sellerId: sellerId,
        customerId: customerId,
        saleType: saleType,
        deliveryType: deliveryType,
        items: items,
        notes: notes,
        deliveryAddress: deliveryAddress,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        deliveryFee: deliveryFee,
      );

      var finalOrder = created;
      if (deliveryType == DeliveryType.inStore) {
        // Pedidos en tienda se completan inmediatamente; no requieren fases de entrega.
        await _repository.updateStatus(created.id, OrderStatus.delivered);
        finalOrder = created.copyWith(
          status: OrderStatus.delivered,
          deliveredAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else if (deliveryPersonId != null && deliveryPersonId.isNotEmpty) {
        await _repository.assignDeliveryPerson(created.id, deliveryPersonId);
        finalOrder = created.copyWith(
          deliveryPersonId: deliveryPersonId,
          status: OrderStatus.inTransit,
          updatedAt: DateTime.now(),
        );
      }

      state = state.copyWith(orders: [finalOrder, ...state.orders]);
      return finalOrder;
    } catch (e) {
      throw Exception('Error al crear pedido: ${e.toString()}');
    }
  }

  Future<void> updateStatus(String id, OrderStatus status) async {
    try {
      await _repository.updateStatus(id, status);
      state = state.copyWith(
        orders: state.orders
            .map((o) => o.id == id
                ? o.copyWith(status: status, updatedAt: DateTime.now())
                : o)
            .toList(),
      );
    } catch (e) {
      throw Exception('Error al actualizar estado: ${e.toString()}');
    }
  }

  Future<void> assignDeliveryPerson({
    required String orderId,
    required String deliveryPersonId,
  }) async {
    try {
      await _repository.assignDeliveryPerson(orderId, deliveryPersonId);
      state = state.copyWith(
        orders: state.orders
            .map((o) => o.id == orderId
                ? o.copyWith(
                    deliveryPersonId: deliveryPersonId,
                    status: OrderStatus.inTransit,
                    updatedAt: DateTime.now(),
                  )
                : o)
            .toList(),
      );
    } catch (e) {
      throw Exception('Error al asignar domiciliario: ${e.toString()}');
    }
  }

  Future<void> changeDeliveryPerson({
    required String orderId,
    required String deliveryPersonId,
  }) async {
    try {
      await _repository.updateDeliveryPerson(orderId, deliveryPersonId);
      state = state.copyWith(
        orders: state.orders
            .map((o) => o.id == orderId
                ? o.copyWith(
                    deliveryPersonId: deliveryPersonId,
                    updatedAt: DateTime.now(),
                  )
                : o)
            .toList(),
      );
    } catch (e) {
      throw Exception('Error al cambiar domiciliario: ${e.toString()}');
    }
  }

  Future<void> markItemsDelivered({
    required String orderId,
    required List<({String orderItemId, int quantityDelivered})> items,
  }) async {
    try {
      await _repository.markItemsDelivered(orderId: orderId, items: items);
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('has no field "order_id"') ||
          errorMessage.contains('has no field order_id') ||
          errorMessage.contains("has no field 'order_id'")) {
        debugPrint(
            '[OrdersNotifier] Fallback a entrega directa por error de trigger: $e');
        try {
          await _repository.markItemsDeliveredDirect(
              orderId: orderId, items: items);
          debugPrint(
              '[OrdersNotifier] Entrega directa completada para orden $orderId');
        } catch (fallbackError) {
          debugPrint(
              '[OrdersNotifier] ERROR en entrega directa: $fallbackError');
          throw Exception(
            'Error al registrar entrega (fallback): $fallbackError',
          );
        }
      } else {
        rethrow;
      }
    }
    await loadOrders();
  }

  Future<void> cancelOrder({
    required String id,
    required String reason,
    required String cancelledBy,
  }) async {
    try {
      await _repository.cancel(
        orderId: id,
        reason: reason,
        cancelledBy: cancelledBy,
      );
      state = state.copyWith(
        orders: state.orders
            .map((o) => o.id == id
                ? o.copyWith(
                    status: OrderStatus.cancelled,
                    cancelledReason: reason,
                    cancelledBy: cancelledBy,
                    cancelledAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  )
                : o)
            .toList(),
      );
    } catch (e) {
      throw Exception('Error al cancelar pedido: ${e.toString()}');
    }
  }
}

final orderByIdProvider =
    FutureProvider.family<Order?, String>((ref, id) async {
  final repository = ref.watch(orderRepositoryProvider);
  return await repository.getById(id);
});

final orderItemsProvider =
    FutureProvider.family<List<OrderItem>, String>((ref, orderId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return await repository.getItems(orderId);
});
