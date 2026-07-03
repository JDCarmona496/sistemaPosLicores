import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_helpers.dart';

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
      'orderId': jsonStringRequired(json['order_id']),
      'productId': jsonStringRequired(json['product_id']),
      'quantity': jsonDouble(json['quantity']),
      'quantityDelivered': jsonDouble(json['quantity_delivered']),
      'unitPrice': jsonDouble(json['unit_price']),
      'discountAmount': jsonDouble(json['discount_amount']),
      'subtotal': jsonDouble(json['subtotal']),
      'isWholesalePrice': jsonBool(json['is_wholesale_price']),
      'notes': jsonString(json['notes']),
      'deliveredAt': jsonDateTime(json['delivered_at']),
      'productName': jsonString(json['product_name']),
      'productCode': jsonString(json['product_code']),
      'productPresentation': jsonString(json['product_presentation']),
      'createdAt': jsonDateTime(json['created_at']),
    });
  }
}

extension OrderItemExtension on OrderItem {
  double get total => subtotal;
  double get pendingQuantity => quantity - quantityDelivered;
  bool get isFullyDelivered => quantityDelivered >= quantity;
}
