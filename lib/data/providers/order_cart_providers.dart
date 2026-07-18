import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/customer.dart';
import '../../domain/models/order_item.dart';
import '../../domain/models/order.dart';

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
