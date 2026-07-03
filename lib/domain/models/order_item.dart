import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_item.freezed.dart';
part 'order_item.g.dart';

@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String id,
    required String orderId,
    required String productId,
    @Default(0) double quantity,
    @Default(0) double quantityDelivered,
    @Default(0) double unitPrice,
    @Default(0) double discountAmount,
    @Default(0) double subtotal,
    @Default(false) bool isWholesalePrice,
    String? notes,
    DateTime? deliveredAt,
    String? productName,
    String? productCode,
    String? productPresentation,
    DateTime? createdAt,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      OrderItem._fromJson(json);

  static OrderItem _fromJson(Map<String, dynamic> json) {
    return _$OrderItemFromJson({
      ...json,
      'orderId': json['order_id'],
      'productId': json['product_id'],
      'quantity': (json['quantity'] as num?)?.toDouble() ?? 0,
      'quantityDelivered': (json['quantity_delivered'] as num?)?.toDouble() ?? 0,
      'unitPrice': (json['unit_price'] as num?)?.toDouble() ?? 0,
      'discountAmount': (json['discount_amount'] as num?)?.toDouble() ?? 0,
      'subtotal': (json['subtotal'] as num?)?.toDouble() ?? 0,
      'isWholesalePrice': json['is_wholesale_price'] ?? false,
      'notes': json['notes'],
      'deliveredAt': json['delivered_at'],
      'productName': json['product_name'],
      'productCode': json['product_code'],
      'productPresentation': json['product_presentation'],
      'createdAt': json['created_at'],
    });
  }
}

extension OrderItemExtension on OrderItem {
  double get total => subtotal;
  double get pendingQuantity => quantity - quantityDelivered;
  bool get isFullyDelivered => quantityDelivered >= quantity;
}
