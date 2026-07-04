import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/customer.dart';
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
      state = state.copyWith(orders: [created, ...state.orders]);
      return created;
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

  Future<void> markItemsDelivered({
    required String orderId,
    required List<({String orderItemId, int quantityDelivered})> items,
  }) async {
    try {
      await _repository.markItemsDelivered(orderId: orderId, items: items);
      // Invalidar para recargar estado actualizado desde BD
      await loadOrders();
    } catch (e) {
      throw Exception('Error al registrar entrega: ${e.toString()}');
    }
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

// ============================================================================
// CARRITO DE PEDIDO ACTUAL
// ============================================================================

final currentOrderCartProvider =
    StateNotifierProvider<CurrentOrderCartNotifier, CurrentOrderCartState>((ref) {
  return CurrentOrderCartNotifier();
});

class CurrentOrderCartState {
  final String? customerId;
  final String? customerName;
  final CustomerType? customerType;
  final String? customerAddress;
  final List<OrderItem> items;
  final SaleType saleType;
  final DeliveryType deliveryType;
  final double deliveryFee;
  final String? notes;
  final String? deliveryAddress;

  const CurrentOrderCartState({
    this.customerId,
    this.customerName,
    this.customerType,
    this.customerAddress,
    this.items = const [],
    this.saleType = SaleType.cash,
    this.deliveryType = DeliveryType.inStore,
    this.deliveryFee = 0,
    this.notes,
    this.deliveryAddress,
  });

  double get subtotal =>
      items.fold(0, (sum, item) => sum + (item.unitPrice * item.quantity));
  double get discountAmount =>
      items.fold(0, (sum, item) => sum + item.discountAmount);
  double get total => subtotal - discountAmount + deliveryFee;
  int get itemCount => items.length;
  bool get isOccasionalCustomer =>
      customerId == null || customerType == CustomerType.occasional;

  CurrentOrderCartState copyWith({
    String? customerId,
    String? customerName,
    CustomerType? customerType,
    String? customerAddress,
    List<OrderItem>? items,
    SaleType? saleType,
    DeliveryType? deliveryType,
    double? deliveryFee,
    String? notes,
    String? deliveryAddress,
    bool clearCustomer = false,
    bool clearNotes = false,
    bool clearDeliveryAddress = false,
  }) {
    return CurrentOrderCartState(
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      customerName: clearCustomer ? null : (customerName ?? this.customerName),
      customerType: clearCustomer ? null : (customerType ?? this.customerType),
      customerAddress:
          clearCustomer ? null : (customerAddress ?? this.customerAddress),
      items: items ?? this.items,
      saleType: saleType ?? this.saleType,
      deliveryType: deliveryType ?? this.deliveryType,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      notes: clearNotes ? null : (notes ?? this.notes),
      deliveryAddress: clearDeliveryAddress
          ? null
          : (deliveryAddress ?? this.deliveryAddress),
    );
  }
}

class CurrentOrderCartNotifier
    extends StateNotifier<CurrentOrderCartState> {
  CurrentOrderCartNotifier() : super(const CurrentOrderCartState());

  void setCustomer({
    String? id,
    String? name,
    CustomerType? type,
    String? address,
  }) {
    // Si no hay id, forzamos limpieza total del cliente.
    final clear = id == null;
    state = state.copyWith(
      clearCustomer: clear,
      customerId: id,
      customerName: name,
      customerType: type,
      customerAddress: address,
    );
  }

  void setSaleType(SaleType saleType) {
    state = state.copyWith(saleType: saleType);
  }

  void setDeliveryType(DeliveryType deliveryType) {
    state = state.copyWith(deliveryType: deliveryType);
  }

  void setDeliveryFee(double fee) {
    state = state.copyWith(deliveryFee: fee);
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void setDeliveryAddress(String? address) {
    state = state.copyWith(deliveryAddress: address);
  }

  void addItem({
    required String productId,
    required String productName,
    required double price,
    required int quantity,
    required OrderItemPriceType priceType,
    double discountAmount = 0,
  }) {
    final existingIndex = state.items.indexWhere(
      (item) => item.productId == productId && item.priceType == priceType,
    );

    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      final newQuantity = existing.quantity + quantity;
      updateItemQuantity(existing.id, newQuantity);
      return;
    }

    final newItem = OrderItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderId: '',
      productId: productId,
      quantity: quantity,
      unitPrice: price,
      discountAmount: discountAmount,
      subtotal: (price * quantity) - discountAmount,
      priceType: priceType,
    );

    state = state.copyWith(items: [...state.items, newItem]);
  }

  void updateItemQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    state = state.copyWith(
      items: state.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(
            quantity: quantity,
            subtotal: (item.unitPrice * quantity) - item.discountAmount,
          );
        }
        return item;
      }).toList(),
    );
  }

  /// Incrementa la cantidad de un producto con un tipo de precio específico.
  /// Si no existe, lo crea con quantity 1.
  void incrementItem({
    required String productId,
    String? productName,
    required double price,
    required OrderItemPriceType priceType,
  }) {
    final existingIndex = state.items.indexWhere(
      (item) => item.productId == productId && item.priceType == priceType,
    );

    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      updateItemQuantity(existing.id, existing.quantity + 1);
      return;
    }

    if (productName == null) return;

    addItem(
      productId: productId,
      productName: productName,
      price: price,
      quantity: 1,
      priceType: priceType,
    );
  }

  /// Decrementa la cantidad de un producto con un tipo de precio específico.
  /// Si llega a 0, lo elimina.
  void decrementItem({
    required String productId,
    required OrderItemPriceType priceType,
  }) {
    final existingIndex = state.items.indexWhere(
      (item) => item.productId == productId && item.priceType == priceType,
    );

    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      updateItemQuantity(existing.id, existing.quantity - 1);
    }
  }

  /// Cambia el tipo de precio de un item existente.
  /// Si ya existe otro item con el nuevo tipo de precio, se fusiona.
  void updateItemPriceType(String itemId, OrderItemPriceType newPriceType) {
    final index = state.items.indexWhere((item) => item.id == itemId);
    if (index < 0) return;

    final item = state.items[index];
    if (item.priceType == newPriceType) return;

    final mergeIndex = state.items.indexWhere(
      (i) => i.productId == item.productId && i.priceType == newPriceType,
    );

    if (mergeIndex >= 0) {
      final mergeItem = state.items[mergeIndex];
      final merged = mergeItem.copyWith(
        quantity: mergeItem.quantity + item.quantity,
        subtotal: (mergeItem.unitPrice * (mergeItem.quantity + item.quantity)) -
            mergeItem.discountAmount,
      );
      state = state.copyWith(
        items: state.items
            .where((i) => i.id != itemId && i.id != mergeItem.id)
            .toList()
          ..add(merged),
      );
      return;
    }

    // Recalcular unitPrice según el nuevo tipo de precio no es posible
    // sin conocer el producto. Mantenemos el unitPrice actual y solo
    // cambiamos el priceType; el usuario puede ajustar cantidad si es necesario.
    state = state.copyWith(
      items: state.items.map((i) {
        if (i.id == itemId) {
          return i.copyWith(priceType: newPriceType);
        }
        return i;
      }).toList(),
    );
  }

  void updateItemDiscount(String itemId, double discountAmount) {
    state = state.copyWith(
      items: state.items.map((item) {
        if (item.id == itemId) {
          final effectiveDiscount = discountAmount.clamp(0, item.unitPrice * item.quantity).toDouble();
          return item.copyWith(
            discountAmount: effectiveDiscount,
            subtotal: (item.unitPrice * item.quantity) - effectiveDiscount,
          );
        }
        return item;
      }).toList(),
    );
  }

  void removeItem(String itemId) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != itemId).toList(),
    );
  }

  void clearCart() {
    state = const CurrentOrderCartState();
  }
}
