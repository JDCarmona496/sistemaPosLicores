import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/order_item.dart';

final orderEditCartProvider =
    StateNotifierProvider<OrderEditCartNotifier, OrderEditCartState>((ref) {
  return OrderEditCartNotifier();
});

class OrderEditCartState {
  final List<OrderItem> items;
  final List<OrderItem> originalItems;

  const OrderEditCartState({
    this.items = const [],
    this.originalItems = const [],
  });

  double get subtotal =>
      items.fold(0, (sum, item) => sum + (item.unitPrice * item.quantity));

  double get discountAmount =>
      items.fold(0, (sum, item) => sum + item.discountAmount);

  int get itemCount => items.length;

  OrderEditCartState copyWith({
    List<OrderItem>? items,
    List<OrderItem>? originalItems,
  }) {
    return OrderEditCartState(
      items: items ?? this.items,
      originalItems: originalItems ?? this.originalItems,
    );
  }
}

class OrderEditCartNotifier extends StateNotifier<OrderEditCartState> {
  OrderEditCartNotifier() : super(const OrderEditCartState());

  int _idSeq = 0;
  String _nextTempItemId() => 'edit-new-${_idSeq++}';

  void load(List<OrderItem> items) {
    state = OrderEditCartState(
      items: items,
      originalItems: items,
    );
  }

  void clear() {
    state = const OrderEditCartState();
  }

  void addItem({
    required String productId,
    required String productName,
    String? productPresentation,
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
      updateItemQuantity(existing.id, existing.quantity + quantity);
      return;
    }

    final newItem = OrderItem(
      id: _nextTempItemId(),
      orderId: '',
      productId: productId,
      productName: productName,
      productPresentation: productPresentation,
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

  void updateItemPriceType(String itemId, OrderItemPriceType newPriceType) {
    final index = state.items.indexWhere((item) => item.id == itemId);
    if (index < 0) return;

    final item = state.items[index];
    if (item.priceType == newPriceType) return;

    // Si el item es nuevo (aún no existe en la BD), solo se actualiza el tipo.
    if (item.orderId.isEmpty) {
      state = state.copyWith(
        items: state.items.map((i) {
          if (i.id == itemId) {
            return i.copyWith(priceType: newPriceType);
          }
          return i;
        }).toList(),
      );
      return;
    }

    // Para ítems existentes cambiar el tipo de precio implica quitar el
    // anterior y agregar uno nuevo (el backend no permite cambiar precio).
    final mergeIndex = state.items.indexWhere(
      (i) =>
          i.productId == item.productId &&
          i.priceType == newPriceType &&
          i.id != itemId,
    );

    if (mergeIndex >= 0) {
      final mergeItem = state.items[mergeIndex];
      final merged = mergeItem.copyWith(
        quantity: mergeItem.quantity + item.quantity,
        subtotal:
            (mergeItem.unitPrice * (mergeItem.quantity + item.quantity)) -
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
          final effectiveDiscount =
              discountAmount.clamp(0, item.unitPrice * item.quantity).toDouble();
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
}
